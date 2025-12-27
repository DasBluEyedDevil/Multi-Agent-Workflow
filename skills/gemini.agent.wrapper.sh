#!/bin/bash

# Gemini CLI Wrapper Script - "The Eyes"
# Enhanced version with role-based prompting, templates, and context injection
# Gemini has unlimited context (1M+ tokens) and should be used for all code reading/analysis

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default settings
OUTPUT_FORMAT="text"
USE_CHECKPOINT=false
USE_SANDBOX=false
ALL_FILES=false
DIRECTORIES=""
ROLE=""
TEMPLATE=""
DRY_RUN=false

# Role definitions
declare -A ROLES
ROLES[reviewer]="You are a senior code reviewer. Focus on: code quality, potential bugs, security vulnerabilities, performance issues, and adherence to best practices. Always provide specific file:line references."
ROLES[planner]="You are a technical architect. Focus on: system design, file organization, component relationships, and implementation strategies. Provide clear step-by-step plans with file paths."
ROLES[explainer]="You are a patient technical mentor. Focus on: explaining how code works, tracing data flow, clarifying architecture decisions. Use simple language and provide concrete examples."
ROLES[debugger]="You are a debugging expert. Focus on: tracing errors through call stacks, identifying root causes, finding related failure points. Provide specific file:line references and fix recommendations."

# Template definitions
get_template() {
    local template_name="$1"
    case "$template_name" in
        feature)
            cat <<'TMPL'
I need to implement a new feature.

Please analyze:
1. Which files will need to be modified? (with line numbers)
2. What existing patterns should I follow?
3. What dependencies or services already exist?
4. Are there similar features I can reference?
5. What risks or edge cases should I consider?

Feature Description:
TMPL
            ;;
        bug)
            cat <<'TMPL'
Bug Investigation Request.

Please trace:
1. Root cause analysis
2. Call stack leading to the issue
3. All affected files with line numbers
4. Similar patterns that might have the same bug
5. Recommended fix approach

Bug Details:
TMPL
            ;;
        verify)
            cat <<'TMPL'
Post-Implementation Verification Request.

Please verify:
1. Architectural consistency with existing patterns
2. No obvious regressions or breaking changes
3. Edge cases are handled
4. Security implications (if applicable)
5. Performance considerations

Provide specific file:line references for any issues found.

Changes Made:
TMPL
            ;;
        architecture)
            cat <<'TMPL'
Architecture Overview Request.

Provide:
1. High-level component organization
2. Key files and their responsibilities
3. Data flow diagram (in mermaid format if possible)
4. Inter-component communication patterns
5. Important design decisions or patterns

Focus Area:
TMPL
            ;;
        *)
            echo ""
            ;;
    esac
}

# Function to find and load GEMINI.md context
load_context() {
    local context=""
    local context_files=(".gemini/GEMINI.md" "GEMINI.md" ".gemini/context.md")
    
    for cf in "${context_files[@]}"; do
        if [ -f "$cf" ]; then
            context=$(cat "$cf")
            echo -e "${CYAN}📄 Loaded context from: $cf${NC}" >&2
            break
        fi
    done
    
    echo "$context"
}

# Function to display usage
usage() {
    cat << EOF
${GREEN}Gemini CLI Wrapper - The Eyes (Enhanced Context Manager)${NC}

${BLUE}USAGE:${NC}
    $0 [OPTIONS] "<prompt>"

${BLUE}OPTIONS:${NC}
    -d, --dir DIRS         Directories to include (e.g., "@src/ @lib/")
    -a, --all-files        Include all files in analysis
    -c, --checkpoint       Enable checkpointing (for modifications)
    -s, --sandbox          Use sandbox mode (safe experimentation)
    -o, --output FORMAT    Output format: text, json (default: text)
    -r, --role ROLE        Use a predefined role: reviewer, planner, explainer, debugger
    -t, --template TMPL    Use a query template: feature, bug, verify, architecture
    --dry-run              Show constructed prompt without executing
    -h, --help             Display this help message

${BLUE}ROLES:${NC}
    ${YELLOW}reviewer${NC}    - Code review focus (quality, bugs, security)
    ${YELLOW}planner${NC}     - Architecture and implementation planning
    ${YELLOW}explainer${NC}   - Code explanation and mentoring
    ${YELLOW}debugger${NC}    - Bug tracing and root cause analysis

${BLUE}TEMPLATES:${NC}
    ${YELLOW}feature${NC}     - Pre-implementation analysis for new features
    ${YELLOW}bug${NC}         - Bug investigation and tracing
    ${YELLOW}verify${NC}      - Post-implementation verification
    ${YELLOW}architecture${NC} - System architecture overview

${BLUE}EXAMPLES:${NC}
    ${YELLOW}# Analyze with reviewer role${NC}
    $0 -d "@src/" -r reviewer "Review the authentication module"

    ${YELLOW}# Plan a new feature${NC}
    $0 -d "@src/" -t feature "Add user profile editing"

    ${YELLOW}# Debug an issue${NC}
    $0 -d "@src/" -r debugger "Error at auth.ts:145 - token validation fails"

    ${YELLOW}# Verify changes after implementation${NC}
    $0 -d "@src/" -t verify "Added password reset in auth/reset.ts"

${BLUE}CONTEXT INJECTION:${NC}
    Place a GEMINI.md file in .gemini/ or project root to auto-inject context.
    This file should contain project-specific rules and constraints.

${BLUE}WORKFLOW:${NC}
    1. Gemini analyzes (The Eyes) → provides file paths, code excerpts
    2. Claude implements (The Hands) → writes code based on analysis
    3. Gemini verifies (The Reviewer) → checks for regressions

EOF
    exit 1
}

# Parse arguments
PROMPT=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            DIRECTORIES="$2"
            shift 2
            ;;
        -a|--all-files)
            ALL_FILES=true
            shift
            ;;
        -c|--checkpoint)
            USE_CHECKPOINT=true
            shift
            ;;
        -s|--sandbox)
            USE_SANDBOX=true
            shift
            ;;
        -o|--output)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -r|--role)
            ROLE="$2"
            shift 2
            ;;
        -t|--template)
            TEMPLATE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            PROMPT="$1"
            shift
            ;;
    esac
done

# Validate prompt
if [ -z "$PROMPT" ]; then
    echo -e "${RED}Error: Prompt is required${NC}"
    usage
fi

# Check if gemini CLI is available (skip in dry-run)
if [ "$DRY_RUN" = false ] && ! command -v gemini &> /dev/null; then
    echo -e "${RED}Error: gemini CLI not found. Please install Gemini CLI.${NC}"
    echo -e "${YELLOW}Installation: Visit https://ai.google.dev/gemini-api/docs/cli${NC}"
    exit 1
fi

# Build the command
CMD="gemini"

if [ "$ALL_FILES" = true ]; then
    CMD="$CMD --all-files"
fi

if [ "$USE_CHECKPOINT" = true ]; then
    CMD="$CMD -c"
fi

if [ "$USE_SANDBOX" = true ]; then
    CMD="$CMD -s"
fi

if [ "$OUTPUT_FORMAT" != "text" ]; then
    CMD="$CMD -o $OUTPUT_FORMAT"
fi

# Build the full prompt
FULL_PROMPT=""

# 1. Load context from GEMINI.md if available
CONTEXT=$(load_context)
if [ -n "$CONTEXT" ]; then
    FULL_PROMPT="$CONTEXT

---

"
fi

# 2. Add role system prompt if specified
if [ -n "$ROLE" ]; then
    if [ -n "${ROLES[$ROLE]:-}" ]; then
        FULL_PROMPT="${FULL_PROMPT}**Your Role**: ${ROLES[$ROLE]}

"
    else
        echo -e "${RED}Error: Unknown role '$ROLE'. Available: reviewer, planner, explainer, debugger${NC}"
        exit 1
    fi
fi

# 3. Add directories if specified
if [ -n "$DIRECTORIES" ]; then
    FULL_PROMPT="${FULL_PROMPT}$DIRECTORIES

"
fi

# 4. Add template if specified
if [ -n "$TEMPLATE" ]; then
    TEMPLATE_CONTENT=$(get_template "$TEMPLATE")
    if [ -z "$TEMPLATE_CONTENT" ]; then
        echo -e "${RED}Error: Unknown template '$TEMPLATE'. Available: feature, bug, verify, architecture${NC}"
        exit 1
    fi
    FULL_PROMPT="${FULL_PROMPT}${TEMPLATE_CONTENT}
"
fi

# 5. Add user prompt
FULL_PROMPT="${FULL_PROMPT}${PROMPT}"

# Display info
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Gemini CLI - The Eyes (Enhanced Context Manager)    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Directories:${NC} ${DIRECTORIES:-[all]}"
echo -e "${BLUE}Role:${NC} ${ROLE:-[none]}"
echo -e "${BLUE}Template:${NC} ${TEMPLATE:-[none]}"
echo -e "${BLUE}Output Format:${NC} $OUTPUT_FORMAT"
echo -e "${BLUE}Context Loaded:${NC} $([ -n "$CONTEXT" ] && echo 'Yes' || echo 'No')"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}═══ DRY RUN - Full Prompt ═══${NC}"
    echo ""
    echo "$FULL_PROMPT"
    echo ""
    echo -e "${YELLOW}═══ End of Prompt ═══${NC}"
    echo ""
    echo -e "${CYAN}Command that would run: $CMD${NC}"
    exit 0
fi

echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""

# Execute gemini command with positional prompt
eval "$CMD" '"$FULL_PROMPT"'

EXIT_CODE=$?

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ Gemini analysis complete${NC}"
else
    echo -e "${RED}✗ Gemini analysis failed (exit code: $EXIT_CODE)${NC}"
fi
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"

exit $EXIT_CODE

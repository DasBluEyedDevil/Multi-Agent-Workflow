#!/usr/bin/env bash

# Multi-Agent-Workflow Uninstaller
# Removes Gemini Research and Kimi Delegation integrations from Claude Code

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default target
DEFAULT_TARGET="$HOME/.claude"
TARGET_DIR="$DEFAULT_TARGET"
DRY_RUN=false
SHOW_HELP=false

# -- Command-line argument parsing -------------------------------------------
usage() {
    cat <<'USAGE_EOF'
Multi-Agent-Workflow Uninstaller

Usage: uninstall.sh [OPTIONS]

Options:
  -t, --target PATH   Uninstall from custom directory (default: ~/.claude)
  --dry-run           Show what would be removed without removing
  -h, --help          Show this help

Examples:
  uninstall.sh                    # Interactive mode (default)
  uninstall.sh --target ~/.claude # Uninstall from ~/.claude/
  uninstall.sh --dry-run          # Preview what would be removed
USAGE_EOF
    exit 0
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--target)
            [[ -z "${2:-}" ]] && { echo "Error: --target requires a path argument" >&2; exit 1; }
            TARGET_DIR="${2/#\~/$HOME}"
            shift 2 ;;
        --dry-run)
            DRY_RUN=true
            shift ;;
        -h|--help)
            usage ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use --help for usage information" >&2
            exit 1 ;;
    esac
done

echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║   Multi-Agent-Workflow Uninstaller                     ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# -- Check for existing installation -----------------------------------------

# Detect what's installed
FOUND_GEMINI=false
FOUND_KIMI=false

if [ -f "$TARGET_DIR/skills/gemini.agent.wrapper.sh" ]; then
    FOUND_GEMINI=true
fi

if [ -f "$TARGET_DIR/skills/kimi.agent.wrapper.sh" ]; then
    FOUND_KIMI=true
fi

if [ "$FOUND_GEMINI" = false ] && [ "$FOUND_KIMI" = false ]; then
    echo -e "${YELLOW}No Multi-Agent-Workflow integration found at:${NC} $TARGET_DIR"
    echo ""
    echo "To specify a different location, use: uninstall.sh --target /path/to/dir"
    exit 0
fi

echo -e "${BLUE}Found installation at:${NC} $TARGET_DIR"
[ "$FOUND_GEMINI" = true ] && echo -e "  ${CYAN}•${NC} Gemini integration"
[ "$FOUND_KIMI" = true ] && echo -e "  ${CYAN}•${NC} Kimi integration"
echo ""

# -- Interactive mode (select what to remove) --------------------------------

if [ "$DRY_RUN" = false ]; then
    echo -e "${BLUE}What would you like to uninstall?${NC}"
    echo ""
    echo "  1) ${RED}Everything${NC} - Remove all Multi-Agent-Workflow components"
    [ "$FOUND_KIMI" = true ] && echo "  2) ${YELLOW}Kimi only${NC} - Remove Kimi integration, keep Gemini"
    [ "$FOUND_GEMINI" = true ] && echo "  3) ${YELLOW}Gemini only${NC} - Remove Gemini integration, keep Kimi"
    echo "  4) ${GREEN}Cancel${NC} - Exit without changes"
    echo ""

    read -p "Choose [1/2/3/4]: " -n 1 -r UNINSTALL_TYPE
    echo ""
    echo ""

    case "$UNINSTALL_TYPE" in
        1)
            REMOVE_GEMINI=true
            REMOVE_KIMI=true
            ;;
        2)
            REMOVE_GEMINI=false
            REMOVE_KIMI=true
            ;;
        3)
            REMOVE_GEMINI=true
            REMOVE_KIMI=false
            ;;
        4)
            echo "Uninstall cancelled."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid selection${NC}"
            exit 1
            ;;
    esac
else
    # Dry-run removes everything for preview
    REMOVE_GEMINI=true
    REMOVE_KIMI=true
fi

# -- Show what will be removed -----------------------------------------------

echo -e "${YELLOW}This will remove:${NC}"

ITEMS_TO_REMOVE=()

if [ "$REMOVE_KIMI" = true ]; then
    # Kimi components
    [ -f "$TARGET_DIR/skills/kimi.agent.wrapper.sh" ] && ITEMS_TO_REMOVE+=("$TARGET_DIR/skills/kimi.agent.wrapper.sh")
    [ -d "$TARGET_DIR/skills/kimi-delegation" ] && ITEMS_TO_REMOVE+=("$TARGET_DIR/skills/kimi-delegation/")
    [ -d "$TARGET_DIR/.claude/skills/kimi-delegation" ] && ITEMS_TO_REMOVE+=("$TARGET_DIR/.claude/skills/kimi-delegation/")
    [ -d "$TARGET_DIR/commands/kimi" ] && ITEMS_TO_REMOVE+=("$TARGET_DIR/commands/kimi/")
    [ -d "$TARGET_DIR/.claude/commands/kimi" ] && ITEMS_TO_REMOVE+=("$TARGET_DIR/.claude/commands/kimi/")
    [ -d "$TARGET_DIR/.kimi/agents" ] && ITEMS_TO_REMOVE+=("$TARGET_DIR/.kimi/agents/")
    [ -d "$TARGET_DIR/.kimi/templates" ] && ITEMS_TO_REMOVE+=("$TARGET_DIR/.kimi/templates/")
    [ -f "$TARGET_DIR/.kimi-version" ] && ITEMS_TO_REMOVE+=("$TARGET_DIR/.kimi-version")
fi

if [ "$REMOVE_GEMINI" = true ]; then
    # Gemini components
    [ -f "$TARGET_DIR/skills/gemini.agent.wrapper.sh" ] && ITEMS_TO_REMOVE+=("$TARGET_DIR/skills/gemini.agent.wrapper.sh")
    [ -f "$TARGET_DIR/skills/gemini-parse.sh" ] && ITEMS_TO_REMOVE+=("$TARGET_DIR/skills/gemini-parse.sh")
    [ -f "$TARGET_DIR/skills/gemini.ps1" ] && ITEMS_TO_REMOVE+=("$TARGET_DIR/skills/gemini.ps1")
    [ -d "$TARGET_DIR/skills/gemini-research" ] && ITEMS_TO_REMOVE+=("$TARGET_DIR/skills/gemini-research/")
    [ -d "$TARGET_DIR/.claude/skills/gemini-research" ] && ITEMS_TO_REMOVE+=("$TARGET_DIR/.claude/skills/gemini-research/")
    [ -d "$TARGET_DIR/.gemini" ] && ITEMS_TO_REMOVE+=("$TARGET_DIR/.gemini/")
    [ -f "$TARGET_DIR/GeminiContext.md" ] && ITEMS_TO_REMOVE+=("$TARGET_DIR/GeminiContext.md")
fi

# Print items to remove
for item in "${ITEMS_TO_REMOVE[@]}"; do
    if [ "$DRY_RUN" = true ]; then
        echo -e "  [DRY-RUN] Would remove: $item"
    else
        echo "  - $item"
    fi
done

echo ""
echo -e "${YELLOW}This will NOT remove:${NC}"
echo "  - .claude/settings.json (may have other settings)"
echo "  - Your project files"
echo "  - Parent directories (skills/, .claude/, etc.)"
echo ""

# Dry-run exits here
if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}[DRY-RUN] No files were removed.${NC}"
    exit 0
fi

# -- Confirm removal ---------------------------------------------------------

read -p "Are you sure? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}Removing files...${NC}"

# -- Perform removal ---------------------------------------------------------

REMOVED_COUNT=0

# Remove Kimi components
if [ "$REMOVE_KIMI" = true ]; then
    if [ -f "$TARGET_DIR/skills/kimi.agent.wrapper.sh" ]; then
        rm "$TARGET_DIR/skills/kimi.agent.wrapper.sh"
        echo -e "  ${GREEN}✓${NC} Removed kimi.agent.wrapper.sh"
        ((REMOVED_COUNT++))
    fi
    
    if [ -d "$TARGET_DIR/skills/kimi-delegation" ]; then
        rm -rf "$TARGET_DIR/skills/kimi-delegation"
        echo -e "  ${GREEN}✓${NC} Removed skills/kimi-delegation/"
        ((REMOVED_COUNT++))
    fi
    
    if [ -d "$TARGET_DIR/.claude/skills/kimi-delegation" ]; then
        rm -rf "$TARGET_DIR/.claude/skills/kimi-delegation"
        echo -e "  ${GREEN}✓${NC} Removed .claude/skills/kimi-delegation/"
        ((REMOVED_COUNT++))
    fi
    
    if [ -d "$TARGET_DIR/commands/kimi" ]; then
        rm -rf "$TARGET_DIR/commands/kimi"
        echo -e "  ${GREEN}✓${NC} Removed commands/kimi/"
        ((REMOVED_COUNT++))
    fi
    
    if [ -d "$TARGET_DIR/.claude/commands/kimi" ]; then
        rm -rf "$TARGET_DIR/.claude/commands/kimi"
        echo -e "  ${GREEN}✓${NC} Removed .claude/commands/kimi/"
        ((REMOVED_COUNT++))
    fi
    
    if [ -d "$TARGET_DIR/.kimi/agents" ]; then
        rm -rf "$TARGET_DIR/.kimi/agents"
        echo -e "  ${GREEN}✓${NC} Removed .kimi/agents/"
        ((REMOVED_COUNT++))
    fi
    
    if [ -d "$TARGET_DIR/.kimi/templates" ]; then
        rm -rf "$TARGET_DIR/.kimi/templates"
        echo -e "  ${GREEN}✓${NC} Removed .kimi/templates/"
        ((REMOVED_COUNT++))
    fi
    
    if [ -f "$TARGET_DIR/.kimi-version" ]; then
        rm "$TARGET_DIR/.kimi-version"
        echo -e "  ${GREEN}✓${NC} Removed .kimi-version"
        ((REMOVED_COUNT++))
    fi
    
    # Clean up empty .kimi directory
    if [ -d "$TARGET_DIR/.kimi" ] && [ -z "$(ls -A "$TARGET_DIR/.kimi" 2>/dev/null)" ]; then
        rmdir "$TARGET_DIR/.kimi"
        echo -e "  ${GREEN}✓${NC} Removed empty .kimi/"
    fi
fi

# Remove Gemini components
if [ "$REMOVE_GEMINI" = true ]; then
    if [ -f "$TARGET_DIR/skills/gemini.agent.wrapper.sh" ]; then
        rm "$TARGET_DIR/skills/gemini.agent.wrapper.sh"
        echo -e "  ${GREEN}✓${NC} Removed gemini.agent.wrapper.sh"
        ((REMOVED_COUNT++))
    fi
    
    if [ -f "$TARGET_DIR/skills/gemini-parse.sh" ]; then
        rm "$TARGET_DIR/skills/gemini-parse.sh"
        echo -e "  ${GREEN}✓${NC} Removed gemini-parse.sh"
        ((REMOVED_COUNT++))
    fi
    
    if [ -f "$TARGET_DIR/skills/gemini.ps1" ]; then
        rm "$TARGET_DIR/skills/gemini.ps1"
        echo -e "  ${GREEN}✓${NC} Removed gemini.ps1"
        ((REMOVED_COUNT++))
    fi
    
    if [ -d "$TARGET_DIR/skills/gemini-research" ]; then
        rm -rf "$TARGET_DIR/skills/gemini-research"
        echo -e "  ${GREEN}✓${NC} Removed skills/gemini-research/"
        ((REMOVED_COUNT++))
    fi
    
    if [ -d "$TARGET_DIR/.claude/skills/gemini-research" ]; then
        rm -rf "$TARGET_DIR/.claude/skills/gemini-research"
        echo -e "  ${GREEN}✓${NC} Removed .claude/skills/gemini-research/"
        ((REMOVED_COUNT++))
    fi
    
    if [ -d "$TARGET_DIR/.gemini" ]; then
        rm -rf "$TARGET_DIR/.gemini"
        echo -e "  ${GREEN}✓${NC} Removed .gemini/"
        ((REMOVED_COUNT++))
    fi
    
    if [ -f "$TARGET_DIR/GeminiContext.md" ]; then
        rm "$TARGET_DIR/GeminiContext.md"
        echo -e "  ${GREEN}✓${NC} Removed GeminiContext.md"
        ((REMOVED_COUNT++))
    fi
fi

# Clean up empty skills directory (only if nothing else is in it)
if [ -d "$TARGET_DIR/skills" ] && [ -z "$(ls -A "$TARGET_DIR/skills" 2>/dev/null)" ]; then
    rmdir "$TARGET_DIR/skills"
    echo -e "  ${GREEN}✓${NC} Removed empty skills/"
fi

echo ""
echo -e "${GREEN}Uninstall complete. Removed ${REMOVED_COUNT} components.${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} You may want to manually:"
echo "  - Remove Kimi/Gemini sections from ~/.claude/CLAUDE.md"
echo "  - Remove related hooks from .claude/settings.json"
echo ""

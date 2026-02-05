# Phase 3: Prompt Assembly - Research

**Researched:** 2026-02-04
**Domain:** Bash scripting, Git CLI integration, Prompt engineering templates
**Confidence:** HIGH

## Summary

Phase 3 requires extending the existing kimi.agent.wrapper.sh with three core capabilities: template-based prompt prepending, git diff injection, and context file auto-loading. The implementation must handle file I/O safely in bash, capture git output programmatically, and assemble prompts in a specific order while maintaining clear error boundaries between required (templates) and optional (context) files.

**Primary recommendation:** Use bash heredocs for prompt assembly with explicit variable substitution, implement two-tier error handling (fatal vs warning), and structure the 6 built-in templates around Context-Task-Output Format-Constraints sections.

## Standard Stack

The implementation uses standard Unix tools available on all supported platforms:

### Core
| Tool | Purpose | Why Standard |
|------|---------|--------------|
| bash 4.0+ | Scripting language | Already used in wrapper |
| git | Diff capture | Universal version control |
| cat | File content reading | POSIX standard, handles binary-safe reading |
| printf | Formatted output | Safer than echo for control characters |

### File Location Patterns
| File Type | Path Pattern | Priority |
|-----------|--------------|----------|
| Templates | `.kimi/templates/{name}.md` | Only location |
| Context (preferred) | `.kimi/context.md` | First |
| Context (legacy) | `KimiContext.md` | Fallback |

**No external dependencies required** — implementation uses only built-in shell capabilities.

## Architecture Patterns

### Prompt Assembly Pipeline

The prompt assembly follows a strict sequence:

```
+-----------------+
| Template (-t)   | ------+
+-----------------+       |
                          v
+-----------------+   +----------+
| Context file    | --| Assembly | ---> Final prompt to kimi
+-----------------+   | (concat) |
                      +----------+
+-----------------+       ^
| Git diff        | -------+
+-----------------+
      |
User prompt
```

**Assembly order:** Template → Context → Git diff → User prompt

This creates a natural information flow: setup context → project rules → current changes → specific question.

### File Reading Pattern (Bash Best Practice)

**Recommended approach using command substitution with cat:**

```bash
# Safe file reading — preserves newlines, handles empty files
read_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cat "$file"
    else
        return 1
    fi
}
```

**Why not `$(<file)`?**
- `$(<file)` is bash-specific and strips trailing newlines
- `cat` is POSIX-compatible and behavior is more predictable
- Both work, but `cat` is more explicit for team readability

### Variable Substitution in Templates

Kimi CLI handles variable substitution natively. Templates should include variables in this format:

```markdown
# Template: feature.md

Working directory: ${KIMI_WORK_DIR}
Current time: ${KIMI_NOW}
Model: ${KIMI_MODEL}

## Context
...template content...
```

**Important:** Template files should be stored with literal `${VAR}` syntax. The kimi CLI performs the substitution, not bash. This avoids double-substitution issues and maintains template portability.

### Git Diff Capture Pattern

**Complete diff (staged + unstaged):**

```bash
# Captures all changes from HEAD to working tree
capture_git_diff() {
    local diff_output=""
    
    # Check if we're in a git repo
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        return 1  # Not a git repo
    fi
    
    # Get diff: HEAD vs working tree (includes staged and unstaged)
    diff_output=$(git diff HEAD 2>/dev/null) || return 1
    
    # Check if there are any changes
    if [[ -z "$diff_output" ]]; then
        return 2  # No changes
    fi
    
    echo "$diff_output"
}
```

**Diff format options:**

| Command | Captures | Use Case |
|---------|----------|----------|
| `git diff` | Unstaged only | Pre-add review |
| `git diff --staged` | Staged only | Pre-commit review |
| `git diff HEAD` | Staged + unstaged | Complete current work view |

**Context uses `git diff HEAD`** for comprehensive view of all current changes.

### Error Handling Strategy

Different handling for required vs optional resources:

```bash
# REQUIRED: Template file
# Behavior: Error with available list, exit non-zero
load_template() {
    local template_name="$1"
    local template_file="${TEMPLATE_DIR}/${template_name}.md"
    
    if [[ ! -f "$template_file" ]]; then
        echo "Error: Template '$template_name' not found." >&2
        list_available_templates >&2
        return 1
    fi
    
    cat "$template_file"
}

# OPTIONAL: Context file
# Behavior: Silent continue if not found
load_context() {
    local work_dir="${1:-.}"
    local context_file=""
    
    # Check in priority order
    if [[ -f "${work_dir}/.kimi/context.md" ]]; then
        context_file="${work_dir}/.kimi/context.md"
    elif [[ -f "${work_dir}/KimiContext.md" ]]; then
        context_file="${work_dir}/KimiContext.md"
    else
        return 0  # Silent continue — optional feature
    fi
    
    cat "$context_file"
}

# OPTIONAL: Git diff
# Behavior: Warning if git unavailable, continue without diff
load_git_diff() {
    local work_dir="${1:-.}"
    
    # Check if git is available
    if ! command -v git > /dev/null 2>&1; then
        echo "Warning: git not found, skipping diff injection" >&2
        return 0
    fi
    
    # Check if in git repo
    if ! git -C "$work_dir" rev-parse --git-dir > /dev/null 2>&1; then
        echo "Warning: Not a git repository, skipping diff injection" >&2
        return 0
    fi
    
    # Capture diff
    local diff_output
    diff_output=$(git -C "$work_dir" diff HEAD 2>/dev/null) || {
        echo "Warning: Could not capture git diff" >&2
        return 0
    }
    
    if [[ -n "$diff_output" ]]; then
        echo "## Git Changes"
        echo '```diff'
        echo "$diff_output"
        echo '```'
    fi
}
```

### Anti-Patterns to Avoid

| Anti-Pattern | Why Bad | What To Do Instead |
|--------------|---------|-------------------|
| `echo $variable` | Word splitting, glob expansion | `echo "$variable"` or `printf '%s\n' "$variable"` |
| `cat file | cmd` | Unnecessary pipe | `cmd < file` or `cmd < <(cat file)` |
| `if [ -f $file ]` | Unquoted variable | `if [[ -f "$file" ]]` |
| Reading files with `read` loop | Loses trailing newlines, slow | Use `cat` with command substitution |
| `exit` without code | Ambiguous failure reason | Use specific exit codes (documented) |

## Don't Hand-Roll

### Problems That Look Simple But Aren't

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Template variable substitution | Custom sed/awk replacement | Kimi CLI's native `${VAR}` support | Kimi handles it, avoids double-substitution bugs |
| Git diff formatting | Parsing `git status` output | `git diff HEAD` unified format | Standard format, kimis read it natively |
| File existence checks | Complex directory walking | `[[ -f "$file" ]]` | Bash built-in, race-condition safe |
| Prompt assembly | String concatenation with `+=` | Heredoc or printf with variables | Clearer, handles newlines correctly |

### Git Diff: Raw vs Processed

**Don't parse or reformat git diff output.** The unified diff format is standard and models understand it:

```diff
diff --git a/file.txt b/file.txt
index 1234567..abcdefg 100644
--- a/file.txt
+++ b/file.txt
@@ -10,7 +10,7 @@ context line
 removed line
+added line
 context line
```

Passing raw diff output is superior to:
- Creating custom summaries
- Filtering to specific file types (complexity not needed now)
- Attempting to truncate or summarize

## Common Pitfalls

### Pitfall 1: Unquoted Variables in File Operations

**What goes wrong:** Word splitting on filenames with spaces

```bash
# BAD: Fails on "my file.txt"
if [[ -f $filename ]]; then
    cat $filename
fi

# GOOD: Quotes protect spaces
if [[ -f "$filename" ]]; then
    cat "$filename"
fi
```

**Warning signs:** Works locally, fails in CI or on user machines with different file naming conventions.

### Pitfall 2: Losing Newlines in Prompt Assembly

**What goes wrong:** Prompt parts run together without separation

```bash
# BAD: All runs together
prompt="${template}${context}${diff}${user_prompt}"

# GOOD: Clear separation with heredoc
prompt=$(cat <<EOF
${template}

${context}

${diff}

${user_prompt}
EOF
)
```

**How to avoid:** Always add blank lines between sections in assembled prompt.

### Pitfall 3: Git Commands in Non-Git Directories

**What goes wrong:** Git commands fail with confusing errors when run outside repos

```bash
# BAD: Fails messily
DIFF=$(git diff HEAD)

# GOOD: Check first
if git rev-parse --git-dir > /dev/null 2>&1; then
    DIFF=$(git diff HEAD)
fi
```

**How to avoid:** Always verify git context before running git commands.

### Pitfall 4: Template Variable Pre-Substitution

**What goes wrong:** Bash substitutes `${VAR}` before kimi sees it

```bash
# BAD: Bash substitutes, kimi sees empty values
template_content=$(cat "$template_file")
echo "$template_content"  # ${KIMI_WORK_DIR} already replaced (probably with "")

# GOOD: Pass through literally, let kimi substitute
# Store and pass content without echoing through bash multiple times
cmd+=("--prompt" "${template_content}${rest_of_prompt}")
```

**How to avoid:** Single-quote heredoc delimiters or escape variables that should pass through.

### Pitfall 5: Silent Failures on Optional Features

**What goes wrong:** Context file silently not loading and user doesn't know why

```bash
# BAD: Silent failure
load_context || true

# GOOD: Inform but continue
if ! context=$(load_context); then
    warn "Context file not found, continuing without project context"
fi
```

**Context requirement says:** Missing context = silent continue. Keep this behavior but document it clearly.

## Code Examples

### Complete Prompt Assembly Function

```bash
#!/usr/bin/env bash
set -euo pipefail

# Assemble the final prompt from all components
# Order: Template → Context → Git diff → User prompt
assemble_prompt() {
    local user_prompt="$1"
    local template_name="${2:-}"
    local include_diff="${3:-false}"
    local work_dir="${4:-.}"
    
    local template_content=""
    local context_content=""
    local diff_content=""
    local assembled=""
    
    # 1. Load template (if specified)
    if [[ -n "$template_name" ]]; then
        template_file="${work_dir}/.kimi/templates/${template_name}.md"
        if [[ ! -f "$template_file" ]]; then
            echo "Error: Template '${template_name}' not found." >&2
            list_templates "$work_dir" >&2
            return 1
        fi
        template_content=$(cat "$template_file")
    fi
    
    # 2. Load context file (optional, silent if missing)
    if [[ -f "${work_dir}/.kimi/context.md" ]]; then
        context_content=$(cat "${work_dir}/.kimi/context.md")
    elif [[ -f "${work_dir}/KimiContext.md" ]]; then
        context_content=$(cat "${work_dir}/KimiContext.md")
    fi
    
    # 3. Capture git diff (optional, warning if unavailable)
    if [[ "$include_diff" == "true" ]]; then
        if command -v git >/dev/null 2>&1 && \
           git -C "$work_dir" rev-parse --git-dir >/dev/null 2>&1; then
            local raw_diff
            raw_diff=$(git -C "$work_dir" diff HEAD 2>/dev/null) || true
            if [[ -n "$raw_diff" ]]; then
                diff_content=$(printf '## Current Changes\n\n```diff\n%s\n```\n' "$raw_diff")
            fi
        else
            echo "Warning: git diff unavailable" >&2
        fi
    fi
    
    # 4. Assemble in order with separation
    assembled=$(cat <<EOF
${template_content}

${context_content}

${diff_content}

${user_prompt}
EOF
)
    
    echo "$assembled"
}
```

### Template File Structure (feature.md)

```markdown
# Feature Development Mode

You are assisting with implementing a new feature. The user will describe what they want to build.

## Context
- Working directory: ${KIMI_WORK_DIR}
- Current time: ${KIMI_NOW}
- Model: ${KIMI_MODEL}

You have access to the codebase and can read files, run tests, and make changes.

## Task
1. Understand the feature requirements
2. Explore the existing codebase for relevant patterns
3. Design an implementation approach
4. Write the minimal code needed
5. Verify the implementation works

## Output Format
- Start with a brief summary of your understanding
- Present implementation in logical chunks
- Include file paths for all changes
- End with verification steps

## Constraints
- Follow existing code style in the project
- Prefer simple solutions over clever ones
- Add tests if the project has a test suite
- Update documentation if behavior changes
```

### Argument Parsing Extension

Add to existing argument parsing in kimi.agent.wrapper.sh:

```bash
# New variables (add to defaults section)
TEMPLATE=""
DIFF_MODE=false

# Add to while loop case statement
while [[ $# -gt 0 ]]; do
    case "$1" in
        # ... existing cases ...
        -t|--template)
            [[ -z "${2:-}" ]] && die "Option $1 requires an argument" "$EXIT_BAD_ARGS"
            TEMPLATE="$2"; shift 2 ;;
        --diff)
            DIFF_MODE=true; shift ;;
        # ... rest of cases ...
    esac
done
```

## Template Content Guidelines

### The 6 Built-in Templates

| Template | Purpose | Key Sections |
|----------|---------|--------------|
| **feature** | New feature implementation | Context exploration, incremental implementation, verification |
| **bug** | Bug investigation and fix | Reproduction steps, root cause analysis, fix verification |
| **verify** | Code review and verification | Readability, correctness, edge cases, testing |
| **architecture** | Design and structure decisions | Constraints exploration, tradeoff analysis, recommendation |
| **implement-ready** | Execute pre-planned implementation | Follow specification exactly, minimal deviation |
| **fix-ready** | Execute pre-planned fix | Apply fix precisely, verify resolution |

### Template Writing Principles

1. **Start with clear context statement** — What is this template mode for?
2. **Define expected output format** — Structure guides the model
3. **Include constraints** — What to avoid, what to prioritize
4. **Keep 50-150 lines** — Substantial enough to guide, not overwhelm
5. **Use Kimi CLI variables** — `${KIMI_WORK_DIR}`, `${KIMI_NOW}`, `${KIMI_MODEL}`
6. **Standard sections:**
   - **Context** — Background information
   - **Task** — Step-by-step instructions
   - **Output Format** — Expected response structure
   - **Constraints** — Boundaries and priorities

## State of the Art

### Bash Patterns (2025 Best Practices)

| Old Approach | Current Approach | Why Changed |
|--------------|------------------|-------------|
| Backticks `` | `$(cmd)` | Nesting, readability |
| `[ test ]` | `[[ test ]]` | Word splitting safety, regex support |
| `echo` | `printf` | Portability, control chars |
| `eval` string building | Arrays + `"${cmd[@]}"` | Security, spaces in args |
| `cat file | cmd` | `cmd < file` | Performance, simplicity |

### Git Integration

Git diff unified format has been stable for 15+ years. No changes anticipated.

## Open Questions

None — all requirements are well-defined in CONTEXT.md.

## Sources

### Primary (HIGH confidence)
- Git official documentation: https://git-scm.com/docs/git-diff
- BashGuide/InputAndOutput: https://mywiki.wooledge.org/BashGuide/InputAndOutput
- BashFAQ/105 (error handling): https://mywiki.wooledge.org/BashFAQ/105
- Bash Style Guide: https://bsg.hthompson.dev/

### Secondary (MEDIUM confidence)
- Bash best practices cheat sheet: https://bertvv.github.io/cheat-sheets/Bash.html
- Bash error handling patterns: https://www.howtogeek.com/bash-error-handling-patterns/
- Prompt engineering structure: https://learnprompting.org/docs/basics/prompt_structure

### Tertiary (LOW confidence)
- Community patterns from Stack Overflow discussions

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Only standard Unix tools
- Architecture: HIGH — Well-established bash patterns
- Pitfalls: HIGH — Documented in official bash resources

**Research date:** 2026-02-04
**Valid until:** 2026-08-04 (stable domain, 6 month validity)

**Key implementation notes for planner:**
1. Template loading must list available templates on error (similar to existing role handling)
2. Git diff injection should format with markdown code block for clarity
3. Context file search order: `.kimi/context.md` → `KimiContext.md`
4. All file operations must use quoted variables
5. Assembly order is strict: Template → Context → Git diff → User prompt

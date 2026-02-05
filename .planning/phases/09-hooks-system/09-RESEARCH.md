# Phase 9: Hooks System - Research

**Researched:** 2026-02-05
**Domain:** Git Hooks - Automation - Kimi Integration
**Confidence:** HIGH

## Summary

**Key finding:** Git hooks are well-established, but integrating them with AI delegation requires careful UX design to avoid user frustration.

**Architecture:** Hooks are executable scripts in `.git/hooks/` (or global `~/.config/git/hooks/`) that Git runs at specific lifecycle points. They communicate via exit codes (0 = success, non-zero = failure) and stdout/stderr.

**Primary recommendation:** Implement hooks as Bash scripts that:
1. Check if Kimi hooks are enabled (config file + env var bypass)
2. Determine which files are relevant (diff against HEAD/staged)
3. Invoke MCP tools (from Phase 8) for delegation
4. Present results to user and optionally apply fixes
5. Return appropriate exit code based on user choice

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Git | 2.20+ | Hook infrastructure | Universal VCS |
| Bash | 4.0+ | Hook scripts | Target shell per project |
| jq | 1.6+ | JSON config parsing | Consistent with Phase 8 |
| MCP Tools | Phase 8 | AI delegation | Already implemented |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| git diff | File change detection | All hooks |
| git stash | Temporary preservation | Pre-commit fixes |
| timeout | Hook protection | Prevent hanging |

## Architecture Patterns

### Pattern 1: Hook Script Structure
**What:** Standard template for all hook types
**When to use:** Every git hook we implement

```bash
#!/bin/bash
# Template for Kimi git hooks

# 1. Check bypass conditions
if [[ -n "$KIMI_HOOKS_SKIP" ]]; then
    exit 0
fi

# 2. Load configuration
load_hook_config

# 3. Check if this hook type is enabled
if ! is_hook_enabled "$HOOK_TYPE"; then
    exit 0
fi

# 4. Determine changed files
CHANGED_FILES=$(get_changed_files)

# 5. Check if any files match our patterns
if ! has_matching_files "$CHANGED_FILES"; then
    exit 0
fi

# 6. Run hook logic
run_hook_logic "$CHANGED_FILES"
```

### Pattern 2: Configuration Hierarchy
**What:** Load config from multiple sources with precedence
**Precedence (highest to lowest):**
1. Environment variables (e.g., `KIMI_HOOKS_TIMEOUT`)
2. Project config (`.kimi/hooks.json`)
3. User config (`~/.config/kimi/hooks.json`)
4. Built-in defaults

```bash
load_hook_config() {
    # Start with defaults
    TIMEOUT=60
    ENABLED_HOOKS="pre-commit,pre-push"
    FILE_PATTERNS="*.py,*.js,*.ts,*.sh,*.bash"
    AUTO_FIX=false
    
    # Load user config if exists
    if [[ -f "$HOME/.config/kimi/hooks.json" ]]; then
        # Parse with jq
        TIMEOUT=$(jq -r '.timeout // 60' "$HOME/.config/kimi/hooks.json")
        ENABLED_HOOKS=$(jq -r '.enabled_hooks // "pre-commit,pre-push"' "$HOME/.config/kimi/hooks.json")
    fi
    
    # Load project config if exists (overrides user)
    if [[ -f ".kimi/hooks.json" ]]; then
        TIMEOUT=$(jq -r '.timeout // '$TIMEOUT'' ".kimi/hooks.json")
        ENABLED_HOOKS=$(jq -r '.enabled_hooks // "'$ENABLED_HOOKS'"' ".kimi/hooks.json")
    fi
    
    # Environment variables override everything
    TIMEOUT="${KIMI_HOOKS_TIMEOUT:-$TIMEOUT}"
}
```

### Pattern 3: Pre-Commit Hook Flow
**What:** Auto-fix code issues before commit
**Flow:**
1. Get list of staged files
2. Filter to relevant file types
3. Run analysis via MCP
4. If issues found and auto-fix enabled:
   - Stash unstaged changes
   - Apply fixes
   - Stage fixed files
   - Restore stashed changes
5. Return exit code based on outcome

```bash
run_precommit_hook() {
    local staged_files="$1"
    
    # Check for lint/type issues
    local result
    result=$(echo '{"prompt": "Check these files for issues...", "files": ['"$staged_files"']}' | kimi-mcp-tool call analyze)
    
    if [[ -n "$result" ]]; then
        echo "Kimi found potential issues:"
        echo "$result"
        
        if [[ "$AUTO_FIX" == "true" ]]; then
            echo "Attempting auto-fix..."
            # Apply fixes logic
        fi
        
        # Ask user if they want to proceed
        read -p "Proceed with commit? [y/N] " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    exit 0
}
```

### Pattern 4: Post-Checkout Hook Flow
**What:** Analyze context after branch switch
**Flow:**
1. Get old and new ref from hook args
2. Get list of files changed between refs
3. Run analysis to summarize changes
4. Present summary to user

```bash
run_postcheckout_hook() {
    local prev_ref="$1"
    local new_ref="$2"
    
    # Get changed files
    local changed_files=$(git diff --name-only "$prev_ref" "$new_ref")
    
    if [[ -z "$changed_files" ]]; then
        exit 0
    fi
    
    # Analyze context
    echo "Analyzing branch changes..."
    kimi-mcp-tool call analyze \
        --prompt "Summarize what changed in these files and any implications" \
        --files "$changed_files"
}
```

### Pattern 5: Pre-Push Hook Flow
**What:** Run tests and fix failures
**Flow:**
1. Get commits being pushed
2. Run test suite
3. If tests fail:
   - Run analysis on failures
   - Attempt fixes if configured
   - Present results to user
4. Return exit code based on outcome

```bash
run_prepush_hook() {
    local remote="$1"
    local url="$2"
    
    echo "Running pre-push checks..."
    
    # Run tests (example: npm test)
    if ! npm test 2>&1; then
        echo "Tests failed. Asking Kimi for help..."
        
        # Get test output and ask Kimi to analyze
        local test_output=$(npm test 2>&1)
        kimi-mcp-tool call analyze \
            --prompt "These tests failed. Analyze and suggest fixes:" \
            --context "$test_output"
        
        exit 1
    fi
    
    exit 0
}
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Config parsing | Custom format | JSON + jq | Standard, consistent with Phase 8 |
| File change detection | Manual git commands | `git diff`, `git diff-tree` | Built-in, handles edge cases |
| Timeout handling | sleep loops | `timeout` command | Signal handling, portable |
| Stash management | Manual state tracking | `git stash push/pop` | Atomic, handles conflicts |

## Common Pitfalls

### Pitfall 1: Hook Blocking Git Operations
**What goes wrong:** Slow hook prevents user from committing/pushing
**Why it happens:** AI analysis takes time, network latency
**How to avoid:**
- Always use timeout (default 60s, configurable)
- Make hooks optional by default (user must opt-in)
- Provide clear bypass mechanism (`--no-verify`, env var)
- Consider async mode: queue for later, don't block

### Pitfall 2: Silent Failures
**What goes wrong:** Hook fails but user doesn't know why
**Why it happens:** Error output not shown, swallowed by git
**How to avoid:**
- Always echo status to stderr (visible to user)
- Use explicit error messages
- Log to file for debugging

### Pitfall 3: Unstaged Changes Conflict
**What goes wrong:** Pre-commit hook modifies files, conflicts with unstaged changes
**Why it happens:** Auto-fix changes files that had unstaged modifications
**How to avoid:**
- Stash unstaged changes before auto-fix
- Restore stash after fixes applied
- Handle stash conflicts gracefully

### Pitfall 4: Hook Recursion
**What goes wrong:** Hook triggers itself (e.g., auto-fix causes new commit which triggers hook)
**Why it happens:** Not setting guard flags during hook execution
**How to avoid:**
- Set `KIMI_HOOKS_RUNNING=1` during hook execution
- Check flag at start of hook and exit if set

### Pitfall 5: Global vs Local Confusion
**What goes wrong:** User expects project hook but global hook runs (or vice versa)
**Why it happens:** Git's hook precedence isn't obvious
**How to avoid:**
- Clear documentation on global vs local
- Installer asks which to use
- Config file indicates which scope it's for

## Configuration Schema

```json
{
  "version": "1.0",
  "enabled_hooks": ["pre-commit", "post-checkout", "pre-push"],
  "timeout_seconds": 60,
  "auto_fix": false,
  "file_patterns": ["*.py", "*.js", "*.ts", "*.sh", "*.bash"],
  "hooks": {
    "pre-commit": {
      "enabled": true,
      "auto_fix": false,
      "check_types": ["lint", "format", "types"]
    },
    "post-checkout": {
      "enabled": true,
      "max_files": 20,
      "show_summary": true
    },
    "pre-push": {
      "enabled": true,
      "run_tests": true,
      "test_command": "npm test",
      "auto_fix_failures": false
    }
  }
}
```

## Git Hook Reference

| Hook | When Called | Arguments | Can Block? |
|------|-------------|-----------|------------|
| pre-commit | Before commit | - | Yes (exit 1) |
| prepare-commit-msg | Before editor | file, source, sha | No |
| commit-msg | After message | file | Yes |
| post-commit | After commit | - | No |
| pre-rebase | Before rebase | - | Yes |
| post-checkout | After checkout | prev, new, flag | No |
| post-merge | After merge | squash | No |
| pre-push | Before push | remote, url | Yes |
| pre-receive | Server-side | - | Yes |

**We focus on:** pre-commit, post-checkout, pre-push (client-side, high value)

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|------------------|-------|
| Husky (JS-only) | Native git hooks | Language agnostic |
| Pre-commit framework | Custom hooks | More flexible, less deps |
| Blocking hooks | Optional + timeout | Better UX |
| Silent auto-fix | Show then fix | Transparency |

## Open Questions

1. **File Watcher Hook**
   - Not a native git hook — requires external tool
   - Options: `entr`, `fswatch`, `chokidar-cli`
   - Recommendation: Defer to Phase 10 or later

2. **Test Integration**
   - How to detect test framework? (jest, pytest, cargo test, etc.)
   - Recommendation: Configurable test command, not auto-detect

3. **Progress Indication**
   - How to show user that Kimi is working?
   - Options: Spinner, progress dots, streaming output
   - Recommendation: Simple "Kimi is analyzing..." message

## Sources

### Primary (HIGH confidence)
- Git Hooks Documentation: https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks
- Git Documentation: https://git-scm.com/docs/githooks

### Secondary (MEDIUM confidence)
- Pre-commit framework: https://pre-commit.com/ (for comparison)
- Husky: https://typicode.github.io/husky/ (for comparison)

## Metadata

**Confidence breakdown:**
- Git hook mechanics: HIGH - Well documented
- Configuration patterns: HIGH - Standard JSON + env vars
- UX best practices: MEDIUM - Based on common frustrations
- Integration with MCP: HIGH - Clear interface from Phase 8

**Research date:** 2026-02-05
**Valid until:** N/A (stable git hooks)

**Key constraint:** Hooks must not frustrate users — make them easy to disable and bypass

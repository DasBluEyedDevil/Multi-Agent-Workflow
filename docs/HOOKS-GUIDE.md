# Hooks Configuration Guide

Configure git hooks for automatic Kimi delegation.

## Overview

Git hooks automatically invoke Kimi during git operations:

- **Pre-commit:** Auto-format and fix issues before committing
- **Post-checkout:** Analyze changed files after switching branches
- **Pre-push:** Run tests and fix failures before pushing

## Installation

### Quick Install

```bash
# Install to current repository
kimi-hooks install

# Or install globally (all repos)
kimi-hooks install --global
```

### Via Installer

```bash
./install.sh --with-hooks
```

## Configuration

### Project Config

File: `.kimi/hooks.json`

```json
{
  "version": "1.0.0",
  "pre_commit": {
    "enabled": true,
    "auto_fix": true,
    "timeout": 120,
    "max_file_size_kb": 100
  },
  "post_checkout": {
    "enabled": true,
    "max_files": 10,
    "analyze_patterns": ["*.js", "*.ts", "*.py", "*.tsx"]
  },
  "pre_push": {
    "enabled": true,
    "run_tests": true,
    "auto_fix": true,
    "timeout": 300
  },
  "global": {
    "model": "k2",
    "timeout": 300,
    "dry_run": false
  }
}
```

### Global Config

File: `~/.config/kimi/hooks.json`

Project config overrides global settings.

## Hook Reference

### Pre-commit

Runs before each commit.

**Behavior:**
1. Stashes unstaged changes
2. Runs auto-formatting on staged files
3. Runs linting and auto-fixes
4. Restores stashed changes
5. Re-stages fixed files

**Configuration:**

```json
{
  "pre_commit": {
    "enabled": true,
    "auto_fix": true,
    "timeout": 120,
    "max_file_size_kb": 100,
    "exclude_patterns": ["*.md", "*.json", "*.lock"]
  }
}
```

| Option | Description | Default |
|--------|-------------|---------|
| `enabled` | Run this hook | true |
| `auto_fix` | Automatically fix issues | true |
| `timeout` | Max seconds per file | 120 |
| `max_file_size_kb` | Skip files larger than this | 100 |
| `exclude_patterns` | Skip matching files | [] |

### Post-checkout

Runs after `git checkout` or `git switch`.

**Behavior:**
1. Detects files changed in checkout
2. Analyzes for potential issues
3. Reports findings to console

**Configuration:**

```json
{
  "post_checkout": {
    "enabled": true,
    "max_files": 10,
    "analyze_patterns": ["*.js", "*.ts", "*.py"],
    "timeout": 60
  }
}
```

| Option | Description | Default |
|--------|-------------|---------|
| `enabled` | Run this hook | true |
| `max_files` | Max files to analyze | 10 |
| `analyze_patterns` | Only analyze matching files | ["*"] |
| `timeout` | Max seconds total | 60 |

### Pre-push

Runs before `git push`.

**Behavior:**
1. Runs test suite
2. Attempts to fix failures
3. Blocks push if fixes fail

**Configuration:**

```json
{
  "pre_push": {
    "enabled": true,
    "run_tests": true,
    "auto_fix": true,
    "timeout": 300,
    "test_command": "npm test"
  }
}
```

| Option | Description | Default |
|--------|-------------|---------|
| `enabled` | Run this hook | true |
| `run_tests` | Run test suite | true |
| `auto_fix` | Attempt to fix failures | true |
| `timeout` | Max seconds total | 300 |
| `test_command` | Command to run tests | auto-detect |

## Examples

### Minimal Config

```json
{
  "pre_commit": { "enabled": true },
  "post_checkout": { "enabled": false },
  "pre_push": { "enabled": true }
}
```

### Frontend Project

```json
{
  "pre_commit": {
    "enabled": true,
    "auto_fix": true,
    "exclude_patterns": ["*.css", "*.scss"]
  },
  "post_checkout": {
    "enabled": true,
    "analyze_patterns": ["*.tsx", "*.ts", "*.jsx", "*.js"]
  },
  "pre_push": {
    "enabled": true,
    "test_command": "npm run test:ci"
  },
  "global": {
    "model": "k2.5"
  }
}
```

### Python Project

```json
{
  "pre_commit": {
    "enabled": true,
    "exclude_patterns": ["*.txt", "*.md", "requirements*.txt"]
  },
  "post_checkout": {
    "analyze_patterns": ["*.py"]
  },
  "pre_push": {
    "test_command": "pytest"
  }
}
```

## Bypassing Hooks

### Emergency Bypass

Skip all hooks for a single command:

```bash
KIMI_HOOKS_SKIP=true git commit -m "urgent fix"
```

### Configure Bypass Variable

```json
{
  "global": {
    "bypass_env_var": "KIMI_HOOKS_SKIP"
  }
}
```

Then use your custom variable:

```bash
MY_BYPASS=true git commit -m "urgent fix"
```

## Dry Run Mode

Test hooks without making changes:

```json
{
  "global": {
    "dry_run": true
  }
}
```

Shows what Kimi would do without executing.

## Troubleshooting

### "Not a git repository"

Run from within a git repository, or use `--global` flag.

### Hooks not running

1. Check installation:
   ```bash
   ls -la .git/hooks/pre-commit
   ```

2. Check git config:
   ```bash
   git config core.hooksPath
   ```

3. Check enablement:
   ```bash
   cat .kimi/hooks.json | jq '.pre_commit.enabled'
   ```

4. Check permissions:
   ```bash
   chmod +x .git/hooks/*
   ```

### Pre-commit too slow

1. Reduce `max_file_size_kb`
2. Add exclusions to `exclude_patterns`
3. Use bypass for quick commits

### Pre-push blocking

By design, pre-push still fails after auto-fix. Review changes:

```bash
git diff HEAD
```

Then retry push.

### Hook logs

Check logs for debugging:

```bash
cat .kimi/hooks.log
tail -f .kimi/hooks.log
```

## Best Practices

1. **Start with dry_run:** Test configuration before enabling
2. **Use bypass sparingly:** Only for genuine emergencies
3. **Tune timeouts:** Balance thoroughness vs speed
4. **Exclude generated files:** Don't analyze build artifacts
5. **Project over global:** Use project config for team consistency

## See Also

- [MCP Setup](./MCP-SETUP.md) — MCP server configuration
- [Model Selection](./MODEL-SELECTION.md) — K2 vs K2.5 guide
- @.claude/commands/kimi/kimi-hooks.md — Slash command reference

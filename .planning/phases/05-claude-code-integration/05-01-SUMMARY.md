---
phase: 05-claude-code-integration
plan: 01
subsystem: claude-code-integration
tags: [slash-commands, kimi-wrapper, delegation]

dependency-graph:
  requires:
    - 01-01: Core wrapper script exists
    - 02-01: Analysis agent roles (reviewer, auditor)
    - 02-02: Action agent roles (debugger)
    - 03-01: Template system (verify template)
  provides:
    - Claude Code slash commands for Kimi delegation
    - /kimi-analyze, /kimi-audit, /kimi-trace, /kimi-verify
  affects:
    - 05-02: SKILL.md may reference these commands
    - 06-xx: Documentation can document slash command usage

tech-stack:
  added: []
  patterns:
    - Slash command markdown format for Claude Code
    - Bash invocation instructions (not PowerShell)

file-tracking:
  key-files:
    created:
      - .claude/commands/kimi/kimi-analyze.md
      - .claude/commands/kimi/kimi-audit.md
      - .claude/commands/kimi/kimi-trace.md
      - .claude/commands/kimi/kimi-verify.md
    modified: []

decisions:
  - id: slash-bash
    decision: Use bash invocation pattern (not PowerShell) for kimi wrapper
    rationale: Wrapper is bash-native, works cross-platform via Git Bash on Windows

metrics:
  duration: ~2 minutes
  completed: 2026-02-05
---

# Phase 5 Plan 1: Claude Code Slash Commands Summary

**One-liner:** 4 slash commands (/kimi-analyze, /kimi-audit, /kimi-trace, /kimi-verify) enabling one-command Kimi delegation from Claude Code

## What Was Built

### Slash Commands Created

| Command | Role/Template | Purpose | Lines |
|---------|---------------|---------|-------|
| `/kimi-analyze` | `-r reviewer` | Codebase analysis and architecture understanding | 73 |
| `/kimi-audit` | `-r auditor` | Code quality and best practices audit | 88 |
| `/kimi-trace` | `-r debugger` | Bug tracing and root cause investigation | 89 |
| `/kimi-verify` | `-t verify --diff` | Change verification before committing | 101 |

### Command Structure

Each slash command includes:
- **Usage section:** Clear syntax with parameters
- **What This Does:** Step-by-step explanation
- **Example Invocations:** 4-5 real-world examples with bash commands
- **When to Use:** Guidance on appropriate scenarios
- **Response Format:** SUMMARY/FILES/ANALYSIS/RECOMMENDATIONS
- **Instructions for Claude:** Exact invocation pattern for automation

### Key Design Decisions

1. **Bash invocation:** All commands use `bash skills/kimi.agent.wrapper.sh` (not PowerShell) since the wrapper is bash-native
2. **Full tool access documented:** kimi-trace explicitly notes debugger role has full tool access (unlike read-only analysis roles)
3. **--diff flag emphasized:** kimi-verify instructions emphasize ALWAYS including --diff flag
4. **Thinking mode documented:** All commands show --thinking as optional parameter for deeper analysis

## Commits

| Commit | Type | Description |
|--------|------|-------------|
| 4a6e625 | feat | Add /kimi-analyze and /kimi-audit slash commands |
| 0de8fd2 | feat | Add /kimi-trace and /kimi-verify slash commands |

## Verification Results

```
✓ 4 slash command files created in .claude/commands/kimi/
✓ All files contain kimi.agent.wrapper.sh invocation
✓ kimi-analyze maps to -r reviewer
✓ kimi-audit maps to -r auditor
✓ kimi-trace maps to -r debugger
✓ kimi-verify maps to -t verify --diff
✓ All files exceed 30 lines minimum
```

## Requirements Satisfied

| Requirement | Status | Evidence |
|-------------|--------|----------|
| INTG-01 | ✅ PASS | /kimi-analyze invokes wrapper with -r reviewer |
| INTG-02 | ✅ PASS | /kimi-audit invokes wrapper with -r auditor |
| INTG-03 | ✅ PASS | /kimi-trace invokes wrapper with -r debugger |
| INTG-04 | ✅ PASS | /kimi-verify invokes wrapper with -t verify --diff |

## Deviations from Plan

None - plan executed exactly as written.

## Next Phase Readiness

**Phase 5 Plan 2:** Already complete (SKILL.md and CLAUDE.md.kimi-section created)

**Phase 6 (Documentation):** Ready to proceed
- All slash commands documented with usage and examples
- Commands can be referenced in user documentation

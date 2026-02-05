# Phase 02 Plan 02: Action Role Agents Summary

**One-liner:** Created 4 action role agents (debugger, refactorer, implementer, simplifier) with full tool access and structured output format for autonomous coding tasks.

## What Was Accomplished

Created the complete set of 4 action role agents that enable users to delegate autonomous coding tasks to Kimi agents:

### Action Roles Created

| Role | Purpose | Key Differentiator |
|------|---------|-------------------|
| **debugger** | Systematic bug investigation and fixing | Audit trail requirement for all shell commands |
| **refactorer** | Code restructuring while preserving behavior | Pattern-based transformations with test verification |
| **implementer** | New feature implementation | Greenfield freedom to introduce optimal patterns |
| **simplifier** | Complexity reduction and dead code removal | Aggressive simplification with functionality preservation |

### Files Created

**YAML Configuration Files (4):**
- `.kimi/agents/debugger.yaml` - Full tool access, no exclusions
- `.kimi/agents/refactorer.yaml` - Full tool access, no exclusions
- `.kimi/agents/implementer.yaml` - Full tool access, no exclusions
- `.kimi/agents/simplifier.yaml` - Full tool access, no exclusions

**System Prompt Files (4):**
- `.kimi/agents/debugger.md` - Systematic debugging with trace → reproduce → hypothesize → verify methodology
- `.kimi/agents/refactorer.md` - Refactoring process with behavior preservation focus
- `.kimi/agents/implementer.md` - Feature implementation with greenfield freedom
- `.kimi/agents/simplifier.md` - Complexity reduction and dead code elimination

## Key Design Decisions

### Full Tool Access for Action Roles
All action roles have **no `exclude_tools`** in their YAML configurations, granting full read/write/execute access. This enables them to:
- Execute shell commands for testing, building, debugging
- Modify files directly to apply fixes and refactoring
- Run tests and linters to verify changes

### Structured Output Format
All 4 agents use the identical output structure:
```
## SUMMARY
## FILES
## ANALYSIS
## RECOMMENDATIONS
```

This consistency enables programmatic parsing and predictable subagent result handling.

### Special Requirements Implemented

**Debugger Audit Trail:**
- Explicit requirement to document all shell commands in ANALYSIS section
- Format: `**Commands executed:** [list of commands]`
- Ensures accountability for investigative actions

**Implementer Greenfield Freedom:**
- Explicit statement: "You may introduce new patterns when justified, regardless of existing conventions"
- Empowers implementer to choose optimal solutions unconstrained by legacy patterns
- Critical for avoiding "cargo cult" programming

### Consistency Mechanisms
- All use `extend: default` for base capability inheritance
- All use Kimi variables: `${KIMI_WORK_DIR}`, `${KIMI_NOW}`
- All include subagent constraint: "You are a subagent reporting back to Claude"
- Uniform section ordering: Identity → Objective → Process → Output → Constraints
- Professional/neutral tone across all roles

## Verification Results

| Criteria | Status |
|----------|--------|
| All 8 files exist in `.kimi/agents/` | ✅ PASS |
| All YAML files pass syntax validation | ✅ PASS |
| All action roles have NO `exclude_tools` (full access) | ✅ PASS |
| All markdown files have SUMMARY/FILES/ANALYSIS/RECOMMENDATIONS | ✅ PASS |
| Debugger has "Commands executed" audit trail requirement | ✅ PASS |
| Implementer has greenfield freedom statement | ✅ PASS |
| All prompts use `${KIMI_WORK_DIR}` and `${KIMI_NOW}` | ✅ PASS |
| All prompts include "subagent reporting back to Claude" | ✅ PASS |

## Deviation Log

**None** - Plan executed exactly as written with no deviations.

## Next Steps

This completes Phase 2 (Agent Roles). All 7 agents are now available:
- **Analysis roles** (from 02-01): reviewer, security, auditor
- **Action roles** (from 02-02): debugger, refactorer, implementer, simplifier

These agents can be invoked directly via:
```bash
kimi --agent-file .kimi/agents/{role}.yaml --prompt "{task description}"
```

Future phases will integrate these agents into the wrapper script with slash commands and template-based prompt assembly.

## Commits

- `2cec138`: feat(02-02): create debugger agent with audit trail
- `96a93bf`: feat(02-02): create refactorer agent for code restructuring
- `b9524e7`: feat(02-02): create implementer agent with greenfield freedom
- `7d29c51`: feat(02-02): create simplifier agent for complexity reduction

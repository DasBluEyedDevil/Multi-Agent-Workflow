---
name: Kimi Research Subagent
description: Delegates large-context code analysis to Kimi K2.5. Use when analyzing codebases, tracing bugs across files, reviewing architecture, or performing security audits. Kimi reads, Claude implements.
dependencies:
  - kimi-cli
---

# Kimi Research Subagent

You have access to Kimi K2.5 as a large-context research assistant. **Use Kimi for reading/analyzing, use yourself for implementation.**

## When to Invoke Kimi

**ALWAYS use Kimi BEFORE:**
- Reading files >100 lines
- Understanding unfamiliar code
- Tracing bugs across multiple files
- Making multi-component changes
- Security or architecture reviews

**DO NOT use Kimi for:**
- Simple single-file edits
- Writing code (that's your job)
- Files already analyzed this session

## How to Invoke

```bash
./skills/kimi.agent.wrapper.sh -r <role> "query"
./skills/kimi.agent.wrapper.sh -r <role> -w <path> "query"
```

## Available Roles

| Role | Use Case |
|------|----------|
| `reviewer` | Code quality, bugs, patterns |
| `auditor` | Architecture, best practices |
| `debugger` | Bug tracing, root cause (can write) |
| `security` | Security vulnerabilities |
| `refactorer` | Restructuring (can write) |
| `implementer` | Feature implementation (can write) |
| `simplifier` | Complexity reduction (can write) |

## Templates

```bash
./skills/kimi.agent.wrapper.sh -t verify --diff "query"  # Post-change verification
./skills/kimi.agent.wrapper.sh -t feature "query"        # Feature planning
./skills/kimi.agent.wrapper.sh -t bug "query"            # Bug analysis
```

## Response Format

Kimi returns structured output:
- **SUMMARY**: 1-2 sentence overview
- **FILES**: file:line references
- **ANALYSIS**: detailed findings
- **RECOMMENDATIONS**: actionable items

## Workflow Pattern

1. **Research**: Invoke Kimi to understand context
2. **Implement**: You write code based on analysis
3. **Verify**: Invoke Kimi to verify changes

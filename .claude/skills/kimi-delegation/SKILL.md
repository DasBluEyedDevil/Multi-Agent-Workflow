---
name: Kimi Research Subagent
description: Delegates development tasks to Kimi K2.5. Use when implementing features, debugging issues, refactoring code, or running tests. Claude architects, Kimi implements.
dependencies:
  - kimi-cli
---

# Kimi R&D Subagent

You have access to Kimi K2.5 as an autonomous R&D agent. **You are the Architect (brain + eyes). Kimi is the Developer (hands).**

## Division of Labor

| Claude (Architect) | Kimi (Developer) |
|-------------------|------------------|
| Design & plan | Implement features |
| Review & approve | Debug & fix bugs |
| Coordinate work | Refactor code |
| Make decisions | Run tests |
| Set direction | Execute tasks |

## When to Delegate to Kimi

**DELEGATE implementation work:**
- Feature implementation from your specs
- Bug investigation and fixing
- Code refactoring tasks
- Test writing and execution
- Multi-file changes you've designed

**KEEP for yourself:**
- Architecture decisions
- Design reviews
- Approving Kimi's work
- User communication
- Strategic planning

## How to Invoke

```bash
# Implementation tasks (action roles - full tool access)
./skills/kimi.agent.wrapper.sh -r implementer "Build the auth module per spec"
./skills/kimi.agent.wrapper.sh -r debugger "Fix the null pointer in UserService"
./skills/kimi.agent.wrapper.sh -r refactorer "Extract payment logic into service"
./skills/kimi.agent.wrapper.sh -r simplifier "Reduce complexity in data layer"

# Analysis tasks (read-only roles)
./skills/kimi.agent.wrapper.sh -r reviewer "Review the PR changes"
./skills/kimi.agent.wrapper.sh -r security "Audit authentication flow"
./skills/kimi.agent.wrapper.sh -r auditor "Check architecture compliance"
```

## Roles

| Role | Type | Use Case |
|------|------|----------|
| `implementer` | Action | Build features from specs |
| `debugger` | Action | Investigate and fix bugs |
| `refactorer` | Action | Restructure code |
| `simplifier` | Action | Reduce complexity |
| `reviewer` | Analysis | Code review (read-only) |
| `security` | Analysis | Security audit (read-only) |
| `auditor` | Analysis | Architecture check (read-only) |

## Templates

```bash
./skills/kimi.agent.wrapper.sh -t implement-ready "spec"  # Implementation spec
./skills/kimi.agent.wrapper.sh -t fix-ready "bug desc"    # Bug fix spec
./skills/kimi.agent.wrapper.sh -t verify --diff "check"   # Post-change verify
```

## Workflow Pattern

1. **You Design**: Create spec/plan for the work
2. **Kimi Implements**: Delegate to appropriate role
3. **Kimi Reports**: Returns structured output
4. **You Review**: Approve or request changes
5. **Kimi Verifies**: Run verification if needed

# Phase 2: Agent Roles - Context

**Gathered:** 2026-02-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Seven specialized agent YAML files with markdown system prompts and tool access scoping. Includes 3 analysis roles (reviewer, security, auditor) with restricted tool access and 4 action roles (debugger, refactorer, implementer, simplifier) with full tool access. All agents use Kimi-native `extend: default` inheritance. Prompt assembly, templates, and slash command integration belong to later phases.

</domain>

<decisions>
## Implementation Decisions

### Role Specialization Depth

**Reviewer role:** Language-specific review criteria
- Different review guidelines for Python, TypeScript, bash, and other languages
- Per-language best practices and anti-patterns
- Not a one-size-fits-all universal approach

**Security role:** Comprehensive security coverage
- Code vulnerabilities (OWASP-style)
- Secrets detection in code
- Dependency vulnerability assessment
- Infrastructure security (config files, deployment scripts)
- Not limited to just code-level security

**Debugger role:** Explicit investigation modes
- Structured phases: trace → reproduce → hypothesize → verify
- Clear methodology for systematic debugging
- Not just general debugging guidance

**Implementer role:** Greenfield approach
- Freedom to implement optimally regardless of existing patterns
- Not constrained to match existing codebase conventions
- Can introduce new patterns when justified

### System Prompt Structure

**Header/Footer conventions:**
- Standardized header on all prompts: role name, version, brief identity statement
- Standardized footer: subagent reminder ("You are a subagent reporting back to Claude")
- Consistent boilerplate across all 7 roles

**Tone calibration:**
- Uniform professional/neutral tone across all roles
- No role-specific tone variations (e.g., auditor is not more critical, debugger is not more curious)
- Consistent voice for predictability

**Variable substitution:**
- Use Kimi-native variables: `${KIMI_WORK_DIR}`, `${KIMI_NOW}`
- Dynamic context where helpful (e.g., "Current directory: ${KIMI_WORK_DIR}")
- Not fully static prompts

**Section ordering:**
- Identity → Objective → Process → Output → Constraints
- Clear narrative flow: who you are, what you do, how you do it, expected format, limits
- Consistent structure aids comprehension

### Tool Access Granularity

**Analysis roles (reviewer, security, auditor):**
- Exclude: Shell, WriteFile, StrReplaceFile, Git
- Read-only tool access only
- Cannot execute commands, modify files, or interact with git
- Cannot accidentally commit or change state

**Debugger role:**
- Full unrestricted tool access
- Must log/report all shell commands executed
- Audit trail for accountability
- Can read, write, execute as needed for investigation

**Refactorer role:**
- Full tool access including shell commands
- Can run tests, linters, formatters after refactoring
- Not limited to just file operations
- Full autonomy to verify changes

**Simplifier role:**
- Full write access
- Direct action mode (not dry-run by default)
- Removes dead code immediately
- No confirmation prompts (Kimi's --quiet mode handles this)

### Output Format Consistency

**All 7 roles use identical output sections:**

```
## SUMMARY
[brief overview of findings/actions]

## FILES
[list of files analyzed or modified]

## ANALYSIS
[detailed findings or work performed]

## RECOMMENDATIONS
[next steps or follow-up actions]
```

**SUMMARY section:**
- Uniform format across all roles
- Brief overview (2-4 sentences max)
- Not role-specific variations

**FILES section:**
- All roles include this section
- Analysis roles: list files analyzed
- Action roles: list files modified
- Absolute paths preferred for clarity

**ANALYSIS section:**
- Role-appropriate depth
- Auditor: deep architectural analysis
- Debugger: step-by-step execution trace
- Reviewer: focused issue-by-issue breakdown
- Implementer: explanation of implementation choices
- Security: vulnerability-by-vulnerability assessment
- Refactorer: what changed and why
- Simplifier: what was removed and rationale

**RECOMMENDATIONS section:**
- All roles include this section
- Action roles provide next steps or follow-up work
- Analysis roles provide actionable suggestions
- Never empty—always something to recommend

</decisions>

<specifics>
## Specific Ideas

- Agent YAML files should live in `.kimi/agents/` directory (project-local) and have mirror in global install location
- System prompts should be markdown files alongside YAML (e.g., `reviewer.yaml` + `reviewer.md`)
- Use `extend: default` for all agents to inherit Kimi's base capabilities
- Analysis roles should explicitly list excluded tools in YAML, not rely on prompt instructions
- Consider adding role-specific variables like `${ROLE_NAME}` for footer text
- Debugger's audit trail should be in ANALYSIS section: "Commands executed: ..."
- Language-specific reviewer guidance should detect file extension and apply appropriate criteria
- Security role should check for common secrets patterns (API keys, tokens, passwords) even in non-code files

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-agent-roles*
*Context gathered: 2026-02-04*

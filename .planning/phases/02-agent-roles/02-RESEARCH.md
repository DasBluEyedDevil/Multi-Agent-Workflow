# Phase 02: Agent Roles - Research

**Researched:** 2026-02-04
**Domain:** Kimi CLI Agent Configuration & System Prompt Engineering
**Confidence:** HIGH

## Summary

This phase implements 7 specialized Kimi CLI agents using YAML configuration files with `extend: default` inheritance. Based on official Kimi CLI documentation (v1.7.0) and current prompt engineering best practices (2025-2026), the implementation follows Kimi's native agent specification format.

**Key architectural decisions:**
- All agents use `extend: default` to inherit Kimi's base toolset and capabilities
- Tool restrictions are enforced via `exclude_tools` in YAML, not just prompt instructions
- System prompts use Kimi's native template variables (`${KIMI_WORK_DIR}`, `${KIMI_NOW}`)
- Structured output format (SUMMARY/FILES/ANALYSIS/RECOMMENDATIONS) is enforced through explicit prompt engineering
- Two-tier role categorization: Analysis roles (read-only) vs Action roles (full access)

**Primary recommendation:** Use Kimi's native `exclude_tools` mechanism for tool restrictions, and implement structured output through clear prompt sections with explicit format examples.

## Standard Stack

### Core Technology
| Component | Version/Format | Purpose | Why Standard |
|-----------|----------------|---------|--------------|
| Kimi CLI | v1.7.0+ | Agent runtime | Official Moonshot AI CLI tool |
| Agent Spec | Version 1 | YAML schema | Only supported format |
| `extend: default` | Inheritance | Base capability | Loads built-in default agent tools |

### Tool Module Paths (Complete List)
| Tool | Module Path | Category | Analysis Roles | Action Roles |
|------|-------------|----------|----------------|--------------|
| Task | `kimi_cli.tools.multiagent:Task` | Multi-agent | Exclude | Include |
| SetTodoList | `kimi_cli.tools.todo:SetTodoList` | Meta | Exclude | Include |
| Shell | `kimi_cli.tools.shell:Shell` | System | **Exclude** | Include |
| ReadFile | `kimi_cli.tools.file:ReadFile` | File | Include | Include |
| ReadMediaFile | `kimi_cli.tools.file:ReadMediaFile` | File | Include | Include |
| Glob | `kimi_cli.tools.file:Glob` | File | Include | Include |
| Grep | `kimi_cli.tools.file:Grep` | File | Include | Include |
| WriteFile | `kimi_cli.tools.file:WriteFile` | File | **Exclude** | Include |
| StrReplaceFile | `kimi_cli.tools.file:StrReplaceFile` | File | **Exclude** | Include |
| SearchWeb | `kimi_cli.tools.web:SearchWeb` | Web | Include | Include |
| FetchURL | `kimi_cli.tools.web:FetchURL` | Web | Include | Include |
| Think | `kimi_cli.tools.think:Think` | Meta | Include | Include |
| SendDMail | `kimi_cli.tools.dmail:SendDMail` | Time-travel | Exclude | Exclude |
| CreateSubagent | `kimi_cli.tools.multiagent:CreateSubagent` | Multi-agent | Exclude | Exclude |

### Built-in Template Variables
| Variable | Description | Example |
|----------|-------------|---------|
| `${KIMI_NOW}` | Current ISO timestamp | `2026-02-04T10:30:00+00:00` |
| `${KIMI_WORK_DIR}` | Working directory path | `/home/user/project` |
| `${KIMI_WORK_DIR_LS}` | Directory listing | File list output |
| `${KIMI_AGENTS_MD}` | AGENTS.md content | Project documentation |
| `${KIMI_SKILLS}` | Available skills list | Skill descriptions |

## Architecture Patterns

### Recommended Project Structure
```
.kimi/
├── agents/
│   ├── reviewer.yaml
│   ├── reviewer.md
│   ├── security.yaml
│   ├── security.md
│   ├── auditor.yaml
│   ├── auditor.md
│   ├── debugger.yaml
│   ├── debugger.md
│   ├── refactorer.yaml
│   ├── refactorer.md
│   ├── implementer.yaml
│   ├── implementer.md
│   ├── simplifier.yaml
│   └── simplifier.md
```

### Pattern 1: Analysis Role (Read-Only)
**What:** Agent that analyzes code but cannot modify it
**When to use:** Code review, security audit, architecture analysis
**YAML Structure:**
```yaml
version: 1
agent:
  extend: default
  name: reviewer
  system_prompt_path: ./reviewer.md
  exclude_tools:
    - "kimi_cli.tools.shell:Shell"
    - "kimi_cli.tools.file:WriteFile"
    - "kimi_cli.tools.file:StrReplaceFile"
```

### Pattern 2: Action Role (Full Access)
**What:** Agent that can read, write, and execute
**When to use:** Debugging, refactoring, implementation
**YAML Structure:**
```yaml
version: 1
agent:
  extend: default
  name: debugger
  system_prompt_path: ./debugger.md
  # No exclude_tools - retains full default toolset
```

### Pattern 3: System Prompt Structure
**What:** Consistent prompt organization for all roles
**Template:**
```markdown
# {Role Name} Agent

**Version:** 1.0.0
**Identity:** You are a specialized {role} agent...

## Objective
{Clear statement of purpose}

## Process
{Step-by-step methodology}

## Output Format
You MUST use this exact structure:

## SUMMARY
{Brief overview}

## FILES
{Analyzed/modified files list}

## ANALYSIS
{Detailed findings}

## RECOMMENDATIONS
{Next steps}

## Constraints
- {Tool usage restrictions}
- {Behavioral guidelines}

---
**Context:** Working directory: ${KIMI_WORK_DIR}
**Subagent Note:** You are a subagent reporting back to Claude.
```

### Anti-Patterns to Avoid
- **Don't:** Use prompt-only tool restrictions ("You cannot use Shell")
  - **Why:** Agent may still attempt to use the tool; YAML `exclude_tools` is enforced
- **Don't:** Use `ENSOUL_*` prefix for variables (deprecated in v0.25)
  - **Why:** Use `${KIMI_*}` prefix instead
- **Don't:** Define tools list explicitly when extending default
  - **Why:** Use `exclude_tools` to remove specific capabilities; duplicating the full list is error-prone
- **Don't:** Use absolute paths in `system_prompt_path`
  - **Why:** Path is relative to agent YAML file location

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tool restriction system | Custom permission logic | `exclude_tools` in YAML | Kimi enforces this at runtime; prompt-only restrictions can be bypassed |
| Template variable system | Custom `${VAR}` parser | Kimi built-in variables | Native `${KIMI_WORK_DIR}`, `${KIMI_NOW}` provided automatically |
| Agent inheritance | Copy-paste YAML | `extend: default` | Inherits updates to default agent; reduces maintenance |
| Structured output parsing | Regex extraction | Explicit prompt format + tool results | LLMs follow explicit format instructions reliably |
| Multi-agent coordination | Custom IPC | Built-in `Task` tool | Kimi handles subagent spawning and result return |

**Key insight:** Kimi CLI's agent system is designed for inheritance and composition. Build on `default` agent rather than recreating from scratch.

## Common Pitfalls

### Pitfall 1: Tool Exclusion Not Applied
**What goes wrong:** Agent still attempts to use Shell/WriteFile despite being "restricted"
**Why it happens:** `exclude_tools` not specified in YAML; only mentioned in system prompt
**How to avoid:** 
```yaml
# CORRECT
exclude_tools:
  - "kimi_cli.tools.shell:Shell"
  - "kimi_cli.tools.file:WriteFile"
  - "kimi_cli.tools.file:StrReplaceFile"
```
**Warning signs:** Agent tries to use tools that should be unavailable

### Pitfall 2: Variable Substitution Failures
**What goes wrong:** `${VAR}` appears literally in prompt instead of being replaced
**Why it happens:** Using wrong prefix (`ENSOUL_` instead of `KIMI_`) or undefined custom variable
**How to avoid:** 
- Use `${KIMI_*}` prefix for built-in variables
- Define custom variables in `system_prompt_args`:
```yaml
system_prompt_args:
  ROLE_NAME: "security"
```

### Pitfall 3: Inheritance Override Confusion
**What goes wrong:** Extending agent doesn't inherit tools as expected
**Why it happens:** Specifying `tools` list overrides parent's tools completely; use `exclude_tools` instead
**How to avoid:** 
```yaml
# WRONG - replaces all tools
agent:
  extend: default
  tools:
    - "kimi_cli.tools.file:ReadFile"  # Only ReadFile available!

# CORRECT - inherits and removes
agent:
  extend: default
  exclude_tools:
    - "kimi_cli.tools.shell:Shell"
```

### Pitfall 4: Structured Output Inconsistency
**What goes wrong:** Agent outputs free-form text instead of required SUMMARY/FILES/ANALYSIS/RECOMMENDATIONS format
**Why it happens:** Format instructions too vague or buried in long prompt
**How to avoid:**
- Put format section prominently in prompt
- Use "MUST" and "exact structure" language
- Include example in prompt

### Pitfall 5: Subagent Recursion Risk
**What goes wrong:** Subagent tries to spawn further subagents, causing deep nesting
**Why it happens:** Subagent inherits Task tool; not excluded in subagent YAML
**How to avoid:**
```yaml
# In subagent YAML
exclude_tools:
  - "kimi_cli.tools.multiagent:Task"
  - "kimi_cli.tools.todo:SetTodoList"
```

## Code Examples

### Example 1: Analysis Role YAML (Reviewer)
```yaml
version: 1
agent:
  extend: default
  name: reviewer
  system_prompt_path: ./reviewer.md
  exclude_tools:
    - "kimi_cli.tools.shell:Shell"
    - "kimi_cli.tools.file:WriteFile"
    - "kimi_cli.tools.file:StrReplaceFile"
```

### Example 2: Action Role YAML (Debugger)
```yaml
version: 1
agent:
  extend: default
  name: debugger
  system_prompt_path: ./debugger.md
  # Full tool access - no exclusions
```

### Example 3: System Prompt Template
```markdown
# Reviewer Agent

**Version:** 1.0.0
**Identity:** You are a code reviewer specializing in finding bugs,
anti-patterns, and improvement opportunities.

## Objective
Analyze code for correctness, maintainability, and adherence to best practices.

## Process
1. Read relevant files using ReadFile, Glob, Grep
2. Analyze code against language-specific criteria
3. Document findings in structured format

## Output Format
You MUST use this exact structure:

## SUMMARY
Brief overview (2-4 sentences)

## FILES
- `/absolute/path/to/file1` - purpose
- `/absolute/path/to/file2` - purpose

## ANALYSIS
### Issue 1: [Title]
- **Location:** File:line
- **Severity:** high/medium/low
- **Description:** Explanation
- **Recommendation:** Fix approach

## RECOMMENDATIONS
1. [First priority action item]
2. [Second priority action item]

## Constraints
- READ-ONLY: You cannot modify files or execute commands
- Use only: ReadFile, Glob, Grep, SearchWeb, FetchURL

---
**Context:** ${KIMI_WORK_DIR}
**Time:** ${KIMI_NOW}
**Note:** You are a subagent reporting back to Claude Code.
```

### Example 4: Invoking Agent
```bash
# Via wrapper script from Phase 1
kimi --agent-file .kimi/agents/reviewer.yaml --prompt "Review src/auth.py"

# With --quiet for programmatic use
kimi --agent-file .kimi/agents/reviewer.yaml \
     --quiet \
     --prompt "Review src/auth.py for security issues"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom agent framework | Kimi native `--agent-file` | Kimi CLI v1.0+ | Use official mechanism instead of wrappers |
| `ENSOUL_*` variables | `KIMI_*` variables | v0.25 (2024) | Breaking change; use new prefix |
| Separate Bash/CMD tools | Unified Shell tool | v0.57 | Single tool for all platforms |
| Think tool enabled | Think tool disabled | v0.53 | Reduces context overhead |
| Absolute path restrictions | Relative paths supported | v0.82 | Simpler path handling |

**Deprecated/outdated:**
- `ENSOUL_WORK_DIR`, `ENSOUL_NOW` → Use `KIMI_*` prefix
- `kimi_cli.tools.bash:Bash` → Use `kimi_cli.tools.shell:Shell`

## Role Differentiation Strategy

### Analysis Roles (3)
| Role | Focus | Differentiation |
|------|-------|-----------------|
| **reviewer** | Code quality, bugs, best practices | Language-specific criteria, per-file analysis |
| **security** | Vulnerabilities, OWASP, secrets | Security-first lens, CVE references, secret detection patterns |
| **auditor** | Architecture, patterns, maintainability | System-level view, coupling analysis, tech debt assessment |

### Action Roles (4)
| Role | Focus | Differentiation |
|------|-------|-----------------|
| **debugger** | Bug investigation, fixes | Structured methodology: trace → reproduce → hypothesize → verify |
| **refactorer** | Code restructuring | Pattern-based transformations, test preservation |
| **implementer** | New features | Greenfield approach, spec-driven, can introduce new patterns |
| **simplifier** | Complexity reduction | Dead code removal, consolidation, minimalism focus |

**Consistency mechanisms:**
- All use identical output section headers
- All use same header/footer boilerplate
- All use `${KIMI_WORK_DIR}` and `${KIMI_NOW}`
- Professional/neutral tone across all roles

## Open Questions

1. **SendDMail tool availability**
   - What we know: Only available in `okabe` agent, not `default`
   - What's unclear: Whether to include in any action roles
   - Recommendation: Exclude from all 7 roles; time-travel belongs to main agent only

2. **Think tool usage**
   - What we know: Disabled in default agent as of v0.53
   - What's unclear: Whether to explicitly enable for complex analysis roles
   - Recommendation: Don't enable; increases context overhead without clear benefit

3. **CreateSubagent tool**
   - What we know: Available but not enabled in default
   - What's unclear: Whether action roles should have this capability
   - Recommendation: Exclude from all roles; wrapper script handles coordination

## Sources

### Primary (HIGH confidence)
- https://moonshotai.github.io/kimi-cli/en/customization/agents.html - Official agent documentation
- https://deepwiki.com/MoonshotAI/kimi-cli/5.1-agent-specification-format - Agent spec format
- https://deepwiki.com/MoonshotAI/kimi-cli/6-tool-system - Complete tool list
- https://moonshotai.github.io/kimi-cli/en/reference/kimi-command.html - CLI options

### Secondary (MEDIUM confidence)
- https://www.getmaxim.ai/articles/a-practitioners-guide-to-prompt-engineering-in-2025/ - Prompt engineering best practices
- https://levelup.gitconnected.com/prompt-engineering-best-practices-for-structured-ai-outputs-ee44b7a9c293 - Structured output patterns
- https://graphite.dev/guides/effective-prompt-engineering-ai-code-reviews - Code review prompting

### Tertiary (LOW confidence)
- Web search results on AI agent security (OWASP) - General security context, not Kimi-specific

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - From official Kimi CLI documentation
- Architecture: HIGH - Verified against official agent examples
- Pitfalls: MEDIUM-HIGH - Based on documentation + common YAML patterns
- Tool list: HIGH - Complete list from official docs

**Research date:** 2026-02-04
**Valid until:** 2026-03-04 (30 days for stable Kimi CLI version)
**Kimi CLI version researched:** 1.7.0

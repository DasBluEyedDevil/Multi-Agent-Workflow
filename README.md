# Multi-Agent Workflow

A token-efficient orchestration system that delegates specialized tasks to multiple AI CLI agents, reducing Claude's token consumption by up to 90%.

## Overview

Instead of Claude reading files and writing code directly (expensive), this workflow delegates:

| Task | Agent | Why |
|------|-------|-----|
| Code analysis | **Gemini** | 1M+ token context window - reads entire codebases |
| UI/Visual work | **Codex** | Specialized for frontend, complex algorithms |
| Backend/GitHub | **Copilot** | Native GitHub integration, backend expertise |
| Orchestration | **Claude** | Strategic decisions, coordination, specs |

**Result**: Claude uses ~3k tokens per task instead of ~35k (91% savings).

## Prerequisites

### Platform
- **Windows**: WSL or Git Bash required (all wrappers are bash scripts)
- **macOS/Linux**: Native bash

### CLI Tools

| CLI | Installation | Purpose |
|-----|--------------|---------|
| Gemini | See [Google AI docs](https://ai.google.dev/gemini-api/docs/cli) | Code analysis |
| Codex | `npm install -g @openai/codex-cli` | UI/frontend work |
| Copilot | `npm install -g @github/copilot-cli` | Backend/GitHub ops |

## Quick Start

### 1. Clone and Setup
```bash
git clone <repo-url>
cd Multi-Agent-Workflow
chmod +x skills/*.sh
```

### 2. Verify CLIs
```bash
gemini --version
codex --version
copilot --version
```

### 3. Basic Usage

**Analyze code (Gemini)**:
```bash
./skills/gemini.agent.wrapper.sh -d "@src/" "How is authentication implemented?"
```

**Implement UI (Codex)**:
```bash
./skills/codex.agent.wrapper.sh "IMPLEMENTATION TASK:
**Objective**: Create login form component
**Requirements**: Email/password fields, validation, submit button
**After Completion**: Run tests, take screenshots"
```

**Implement backend (Copilot)**:
```bash
./skills/copilot.agent.wrapper.sh --allow-write "IMPLEMENTATION TASK:
**Objective**: Add user authentication endpoint
**Requirements**: JWT tokens, password hashing, rate limiting
**After Completion**: Run tests, report results"
```

## Workflow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Claude    │────▶│   Gemini    │────▶│   Codex/    │
│ Orchestrator│     │  Analyzer   │     │   Copilot   │
└─────────────┘     └─────────────┘     └─────────────┘
      │                   │                    │
      │ 1. Requirements   │ 2. Analysis        │ 3. Implementation
      │ (~1k tokens)      │ (0 Claude tokens)  │ (0 Claude tokens)
      ▼                   ▼                    ▼
┌─────────────────────────────────────────────────────┐
│                  Cross-Check                         │
│         Codex reviews Copilot's work                │
│         Copilot reviews Codex's work                │
└─────────────────────────────────────────────────────┘
                          │
                          ▼ 4. Verify (Gemini)
                    ┌───────────┐
                    │  Complete │
                    └───────────┘
```

## File Structure

```
./
├── CLAUDE.md                      # Quick reference for Claude
├── README.md                      # This file
└── skills/
    ├── Claude-Orchestrator.md     # Orchestration patterns
    ├── Gemini-Researcher.md       # Analysis query patterns
    ├── gemini.agent.wrapper.sh    # Gemini CLI wrapper
    ├── Codex-Engineer.md          # UI implementation patterns
    ├── codex.agent.wrapper.sh     # Codex CLI wrapper
    ├── Copilot-Engineer.md        # Backend implementation patterns
    └── copilot.agent.wrapper.sh   # Copilot CLI wrapper
```

## Wrapper Reference

### Gemini (Code Analysis)
```bash
./skills/gemini.agent.wrapper.sh [OPTIONS] "<prompt>"

Options:
  -d, --dir DIRS      Directories to include (e.g., "@src/ @lib/")
  -a, --all-files     Include all files
  -c, --checkpoint    Enable checkpointing
  -s, --sandbox       Sandbox mode
  -o, --output FORMAT Output format (text, json)
```

### Codex (UI/Algorithms)
```bash
./skills/codex.agent.wrapper.sh [OPTIONS] "<prompt>"

Options:
  -m, --model MODEL   Model: gpt-5 (default), o3, o3-mini
  --safe-mode         Require approval for operations
  --sandbox MODE      read-only, workspace-write, danger-full-access
  -C, --working-dir   Set working directory
  --enable-search     Enable web search
  -f, --prompt-file   Read prompt from file
```

### Copilot (Backend/GitHub)
```bash
./skills/copilot.agent.wrapper.sh [OPTIONS] "<prompt>"

Options:
  --allow-write       Allow file write operations
  --allow-git         Allow git ops (denies force push)
  --allow-npm         Allow npm commands
  --allow-github      Allow GitHub operations
  --allow-tool PAT    Allow specific tool pattern
  --deny-tool PAT     Deny specific tool pattern
```

## Task Templates

### Implementation Task
```
IMPLEMENTATION TASK:

**Objective**: [Clear, one-line goal]

**Requirements**:
- [Requirement 1]
- [Requirement 2]

**Context from Gemini**:
[Paste analysis results]

**Files to Modify**:
- path/file.ext: [changes needed]

**TDD Required**: Yes/No

**After Completion**:
1. Run tests
2. Report: changes, test results, issues
```

### Code Review Task
```
CODE REVIEW:

**Feature**: [name]
**Files**: [list]

**Check**:
1. Logic errors
2. Edge cases
3. Code quality
4. Test coverage

**Verdict**: APPROVED / NEEDS CHANGES
```

## Best Practices

### Do
- Always query Gemini before implementing
- Use specific, structured prompts
- Include context from previous agent responses
- Request file paths and line numbers
- Cross-check between Codex and Copilot

### Don't
- Have Claude read large files directly
- Skip the analysis phase
- Use vague prompts ("fix this", "improve code")
- Forget to specify acceptance criteria

## Troubleshooting

### "command not found: gemini/codex/copilot"
Ensure CLIs are installed and in PATH. On Windows, run from WSL or Git Bash.

### EMFILE: too many open files
When analyzing large directories with Gemini, use targeted subdirectories:
```bash
# Instead of
./skills/gemini.agent.wrapper.sh -d "@large-project/" "..."

# Use
./skills/gemini.agent.wrapper.sh -d "@large-project/src/specific/" "..."
```

### Wrapper permission denied
```bash
chmod +x skills/*.sh
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Update relevant skill documentation
4. Test wrapper scripts
5. Submit PR

## License

MIT

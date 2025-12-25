# Multi-Agent Workflow

Delegate tasks to specialized CLI agents to conserve tokens.

## Agent Selection

| Need | Agent | Skill | Wrapper |
|------|-------|-------|---------|
| **Code analysis** | Gemini | `skills/Gemini-Researcher.md` | `skills/gemini.agent.wrapper.sh` |
| **UI/Visual work** | Codex | `skills/Codex-Engineer.md` | `skills/codex.agent.wrapper.sh` |
| **Backend/BLE/GitHub** | Copilot | `skills/Copilot-Engineer.md` | `skills/copilot.agent.wrapper.sh` |
| **Orchestration** | Claude | `skills/Claude-Orchestrator.md` | (you are Claude) |

## Quick Reference

```bash
# Gemini: Code analysis (1M+ context)
./skills/gemini.agent.wrapper.sh -d "@src/" "How is [feature] implemented?"

# Codex: UI/Compose work
./skills/codex.agent.wrapper.sh "IMPLEMENTATION TASK: Create [component]..."

# Codex: Complex algorithm (max reasoning)
./skills/codex.agent.wrapper.sh -m o3 "Optimize [algorithm]..."

# Copilot: Backend/BLE
./skills/copilot.agent.wrapper.sh --allow-write "IMPLEMENTATION TASK: Implement [service]..."

# Copilot: GitHub operations
./skills/copilot.agent.wrapper.sh --allow-github "Create PR for [feature]..."

# Copilot: Git operations
./skills/copilot.agent.wrapper.sh --allow-git "Commit and push [changes]..."
```

## Workflow

1. **Analyze** → Ask Gemini before reading any code
2. **Delegate** → Send implementation to Codex (UI) or Copilot (Backend)
3. **Cross-check** → Have the other engineer review
4. **Verify** → Ask Gemini to confirm changes

## Platform Notes

All wrappers are bash scripts requiring WSL or Git Bash on Windows.

| CLI | Installation |
|-----|--------------|
| Gemini | See https://ai.google.dev/gemini-api/docs/cli |
| Codex | `npm install -g @openai/codex-cli` |
| Copilot | `npm install -g @github/copilot-cli` |

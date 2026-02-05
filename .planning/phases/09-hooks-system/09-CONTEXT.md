# Phase 9: Hooks System - Context

**Gathered:** 2026-02-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement predefined git hooks that auto-delegate hands-on coding tasks to Kimi. The hooks system provides automatic delegation at key git workflow points:
- **pre-commit**: Auto-fix issues before commits
- **post-checkout**: Analyze changed files after branch switches
- **pre-push**: Run tests and fix failures before pushing
- **on-save** (file watcher): Real-time assistance during development

This phase builds on Phase 8's MCP Bridge by using the MCP tools for actual delegation.

</domain>

<decisions>
## Implementation Decisions

### Hook Types & Triggers
- **pre-commit**: Run linting, formatting, type checking; auto-fix if possible
- **post-checkout**: Analyze files changed between branches; suggest context
- **pre-push**: Run tests; auto-fix failures if possible
- **on-save**: File watcher for real-time assistance (optional, may be deferred)

### Hook Installation Strategy
- **Global installation**: Hooks in `~/.config/git/hooks/` (applies to all repos)
- **Per-project installation**: Hooks in `.git/hooks/` (repo-specific)
- **Installer command**: `kimi hooks install [--global|--local]`

### Configuration Approach
- **Hook config file**: `~/.config/kimi/hooks.json` for global settings
- **Per-project override**: `.kimi/hooks.json` in project root
- **Selective enablement**: Each hook type can be enabled/disabled independently
- **Bypass mechanism**: `git commit --no-verify` or `KIMI_HOOKS_SKIP=1`
- **Dry-run mode**: Preview what Kimi would do without actually delegating

### Delegation Logic
- **Smart triggering**: Only delegate when files match configured patterns
- **Timeout protection**: Hooks must complete within reasonable time (default: 60s)
- **Failure handling**: Hook failures should not block git operation (configurable)
- **Output capture**: Show Kimi's analysis/fixes to user before proceeding

### Integration with MCP
- Hooks invoke MCP tools (from Phase 8) for delegation
- Use `kimi_analyze` for post-checkout analysis
- Use `kimi_implement` for auto-fixes
- Use `kimi_verify` for pre-push validation

### OpenCode's Discretion
- Exact hook script implementation details
- File watcher implementation (if included)
- Progress indication during hook execution
- Caching strategy for repeated analyses
- UI/UX for presenting Kimi's output to user

</decisions>

<specifics>
## Specific Ideas

- "I want hooks to be helpful, not annoying — make them easy to disable"
- "Show me what Kimi found before I commit, don't just auto-fix silently"
- "Pre-push should catch test failures and offer to fix them"
- "Post-checkout should summarize what changed so I know the context"
- "Make dry-run useful — show what WOULD happen without doing it"

</specifics>

<deferred>
## Deferred Ideas

- File watcher hook (on-save) — may add later if performance permits
- Custom user-defined hooks — start with built-in hooks only
- Hook chaining/composition — simple independent hooks for now
- Webhook-style remote triggers — local git only for now

</deferred>

<dependencies>
## Dependencies from Phase 8

- MCP server executable (`kimi-mcp-server`)
- MCP tool definitions (analyze, implement, refactor, verify)
- Configuration system pattern (from 08-02)
- Error handling approach (from 08-03)

</dependencies>

---

*Phase: 09-hooks-system*
*Context gathered: 2026-02-05*

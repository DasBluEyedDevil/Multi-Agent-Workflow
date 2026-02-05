# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-05)

**Core value:** Claude Code users can delegate any R&D task to Kimi K2.5 -- research, analysis, implementation, debugging, refactoring -- while Claude stays in the architect seat.
**Current focus:** v2.0 Autonomous Delegation — MCP Bridge, Hooks System, Enhanced SKILL.md

## Current Position

Phase: 12 of 12 (v2.0 Gap Closure)
Plan: 1 of 1 in current phase
Status: Phase complete
Last activity: 2026-02-05 — Completed 12-01-PLAN.md

Progress: [████████████████████████░░░░░░░░░░░░░░░░] 60%

## Milestones

| Version | Status | Phases | Plans | Shipped |
|---------|--------|--------|-------|---------|
| v1.0 MVP | SHIPPED | 1-7 | 15 | 2026-02-05 |
| v2.0 | Complete | 8-12 | 18 | 2026-02-05 |

See: .planning/MILESTONES.md for details

## Accumulated Context

### Decisions

All v1.0 decisions archived in `.planning/milestones/v1.0-ROADMAP.md`.

Key decisions carried forward:
- Exit codes 10-13 for wrapper errors; 1-9 reserved for kimi CLI
- Analysis roles exclude: Shell, WriteFile, StrReplaceFile, SetTodoList, CreateSubagent, Task
- Bash resolution order: Git Bash > WSL > MSYS2 > Cygwin > PATH

**v2.0 Phase 8 decisions:**
| Phase | Decision | Rationale |
|-------|----------|-----------|
| 8-01 | Pure Bash MCP implementation (no SDK deps) | Minimize dependencies for CLI integration |
| 8-01 | jq required for all JSON operations | Prevent injection, ensure spec compliance |
| 8-01 | Protocol version 2025-11-25 | Current MCP specification |
| 8-02 | Configuration precedence: env > user config > defaults | Flexible deployment and local customization |
| 8-02 | Model validation with fallback to k2 | Prevent invalid model selections |
| 8-02 | 4 built-in analysis roles (general, security, performance, refactor) | Support different analysis contexts |
| 8-03 | Platform-specific stat commands (Linux/macOS/Windows) | Cross-platform file size detection |
| 8-03 | Binary file detection using 'file' command or null byte check | Skip binary files gracefully |
| 8-03 | Tool handlers validate required 'prompt' parameter | Fail fast on invalid tool calls |
| 8-03 | Prompt structure: system + files + context + task | Consistent prompt building across tools |
| 8-04 | All stdout must be valid JSON-RPC (no debug prints) | Protocol compliance |
| 8-04 | Logging to stderr only | Avoid protocol corruption |
| 8-04 | Single sequential request processing | Simple, predictable behavior |
| 8-04 | Tool errors return isError=true (not JSON-RPC error) | Distinguish protocol vs tool errors |
| 8-05 | CLI wrapper locates server via relative path | Works in dev and installed contexts |
| 8-05 | Setup helper manages ~/.kimi/mcp.json | Kimi CLI MCP client integration |
| 8-05 | Default config only copied if not exists | Preserve user configuration changes |

**v2.0 Phase 9 decisions:**
| Phase | Decision | Rationale |
|-------|----------|-----------|
| 9-01 | Project config (.kimi/hooks.json) > user config (~/.config/kimi/hooks.json) | Project-specific needs take priority |
| 9-01 | Hook-specific settings override global settings | Different hooks have different requirements |
| 9-01 | Bypass env var configurable (default: KIMI_HOOKS_SKIP) | Consistent naming but allows customization |
| 9-01 | Boolean validation accepts only "true"/"false" | Strict validation prevents ambiguity |
| 9-02 | Shared library approach for all hooks | Reduces duplication, ensures consistency |
| 9-02 | Hooks return 0 on skip (don't block git) | Git operations should not be blocked unnecessarily |
| 9-02 | Pre-commit stashes unstaged changes during auto-fix | Prevents conflicts with unstaged work |
| 9-02 | Post-checkout max_files limit prevents overload | Large branch switches could analyze hundreds of files |
| 9-02 | Pre-push still fails after auto-fix | User should review fixes before pushing |
| 9-03 | Global hooks use ~/.config/git/hooks/ | Git 2.9+ core.hooksPath support |
| 9-03 | Installation creates symlinks, not copies | Easy updates when hook scripts change |
| 9-03 | Existing hooks backed up before overwrite | Prevent data loss during installation |
| 9-03 | kimi-hooks delegates to kimi-hooks-setup | DRY principle for shared operations |
| 9-04 | Follow MCP bridge pattern for hooks installation | Consistency across components |
| 9-04 | Added logging abstraction for installer feedback | Cleaner code, consistent output |

**v2.0 Phase 10 decisions:**
| Phase | Decision | Rationale |
|-------|----------|-----------|
| 10-01 | K2 for backend files (.py, .js, .go, .rs, etc.) | Routine tasks need fast, efficient model |
| 10-01 | K2.5 for UI files (.tsx, .jsx, .css, .vue, etc.) | Creative/UI tasks benefit from stronger model |
| 10-01 | Test files (*.test.*, *.spec.*) force K2 | Tests are routine, not creative work |
| 10-01 | Component files (*component*) boost K2.5 score | Component creation is creative work |
| 10-01 | Default confidence threshold: 75% | Balances automation with accuracy |
| 10-02 | Confidence formula: 50 base + 20 (files agree) + 20 (task clear) + 10 (patterns match) | Multi-factor scoring reflects signal strength |
| 10-02 | Tie-breaker defaults to K2 | Cost efficiency when signals are balanced |
| 10-02 | KIMI_FORCE_MODEL takes absolute precedence | User control over automatic selection |
| 10-03 | K2.5 cost multiplier = 1.5x | Research-derived cost ratio between models |
| 10-03 | Token estimate = characters / 4 | Industry-standard heuristic when exact count unavailable |
| 10-03 | Multi-path script resolution | Enables wrapper to find dependencies from any directory |
| 10-03 | Session persistence via --session flag | Kimi CLI maintains context across related delegations |
| 10-04 | Keep existing structure and add new sections | Don't break v1.0 workflows, gradual adoption |
| 10-04 | Make v2.0 features opt-in via flags | Users choose when to enable auto-model |
| 10-04 | Include ASCII diagrams for visual decision flow | Visual representation aids understanding |
| 10-04 | Add Troubleshooting section for common issues | Self-service problem resolution |
| 10-04 | Document all environment variables and defaults | Complete configuration reference |

**v2.0 Phase 11 decisions:**
| Phase | Decision | Rationale |
|-------|----------|-----------|
| 11-01 | Maintain backward compatibility: v1.0 behavior preserved as default | Existing users can upgrade seamlessly |
| 11-01 | v2.0 features are additive: installed alongside v1.0 components | No breaking changes for existing installations |
| 11-01 | jq is required for MCP: clear error message with install instructions | Help users resolve dependency issues quickly |
| 11-01 | Interactive hooks installation with --with-hooks flag | Balance user control with automation needs |
| 11-01 | Dry-run mode for safe installation testing | Allow users to preview changes before applying |
| 11-01 | PATH verification with helpful guidance | Ensure installed tools are accessible |
| 11-02 | Kept v1.0 commands in quick reference | Backward compatibility for existing users |
| 11-02 | Structured MCP/Hooks as top-level sections | Highlight v2.0 capabilities prominently |
| 11-02 | Two-tier documentation approach | Full guide (CLAUDE.md) + concise reference (kimi-section) |
| 11-03 | Followed existing slash command patterns for consistency | Users get familiar structure across all commands |
| 11-03 | Documented all actions with usage examples | Users can understand commands without reading source |
| 11-03 | Included troubleshooting sections | Self-service problem resolution for common issues |
| 11-04 | Cross-referencing pattern for all guides | Users can navigate between related documentation |
| 11-04 | Consistent structure across all guides | Predictable documentation experience |
| 11-04 | Migration path in README.md | Clear guidance for v1.0 users upgrading to v2.0 |
| 11-04 | Examples by project type in hooks guide | Practical guidance for different tech stacks |

**v2.0 Phase 12 decisions:**
| Phase | Decision | Rationale |
|-------|----------|-----------|
| 12-01 | auto_model parameter defaults to false | Backward compatibility - existing calls unaffected |
| 12-01 | Multi-path resolution for model selector | Works in both dev and installed contexts |
| 12-01 | Graceful fallback to k2 on selector errors | Safe default prevents failures |
| 12-01 | Uniform auto_model support across all 4 tools | Consistent API for tool users |

### Pending Todos

None - v2.0 milestone complete.

### Blockers/Concerns

None - v2.0 milestone complete.

## Session Continuity

Last session: 2026-02-05T20:16:20Z
Stopped at: Completed 12-01-PLAN.md (Phase 12, Plan 1 - v2.0 Gap Closure Complete)
Resume file: None

**Resumption notes:** Phase 12 (v2.0 Gap Closure) **COMPLETE**. Integration gap between Phase 10 (Model Selection) and Phase 8 (MCP Tools) resolved:
 - 12-01: Wire model selector into MCP tools ✓ (mcp_select_model helper, auto_model parameter, hooks updated)
 
 **Milestone v2.0 COMPLETE!** All 41 requirements satisfied, all integration gaps resolved.
 - MCP Bridge: Kimi exposed as callable MCP tools ✓
 - Hooks System: Auto-delegate coding tasks via git hooks ✓
 - Enhanced SKILL.md: Smart triggers with intelligent K2 vs K2.5 selection ✓
 - Integration & Distribution: Updated installer and documentation ✓
 - Gap Closure: Model selection wired into MCP tools ✓

## Archives

- `.planning/milestones/v1.0-ROADMAP.md` - Full phase details
- `.planning/milestones/v1.0-REQUIREMENTS.md` - All 39 requirements
- `.planning/milestones/v1.0-MILESTONE-AUDIT.md` - Audit report

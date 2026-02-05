---
phase: 10-enhanced-skill
plan: 03
subsystem: skills
tags: [bash, kimi, cost-estimation, model-selection, session-management]

# Dependency graph
requires:
  - phase: 10-enhanced-skill
    plan: "10-02"
    provides: "Model selector (kimi-model-selector.sh) for auto-selection integration"
provides:
  - "Cost estimation with token counting (chars/4 heuristic)"
  - "Auto-model selection integration in wrapper"
  - "Session management for context preservation"
affects:
  - "Future plans using kimi.agent.wrapper.sh"
  - "Plans requiring cost-aware delegation"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Cost estimation before delegation"
    - "Multi-path script resolution for cross-directory usage"
    - "Session-based context preservation"

key-files:
  created:
    - skills/kimi-cost-estimator.sh
  modified:
    - skills/kimi.agent.wrapper.sh

key-decisions:
  - "K2.5 cost multiplier = 1.5x (research-derived)"
  - "Token estimate = characters / 4 (industry heuristic)"
  - "Auto-model selection uses existing kimi-model-selector.sh"
  - "Session management uses kimi CLI --session flag"

patterns-established:
  - "Cost estimation: estimate_tokens, estimate_cost, display_cost functions"
  - "Multi-path resolution: Try SCRIPT_DIR, parent, pwd for dependencies"
  - "Session persistence: Store in /tmp/kimi-session-$$ with cleanup trap"

# Metrics
duration: 8min
completed: 2026-02-05
---

# Phase 10 Plan 03: Cost Estimation and Model Selection Integration Summary

**Cost estimation with token counting (chars/4 heuristic), auto-model selection integrated into wrapper, and session-based context preservation using kimi CLI --session flag.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-02-05T18:07:40Z
- **Completed:** 2026-02-05T18:15:08Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Created kimi-cost-estimator.sh with token/cost estimation functions
- Enhanced kimi.agent.wrapper.sh with --auto-model flag for intelligent model selection
- Added --show-cost flag to display cost estimates before delegation
- Implemented session management with --session-id and KIMI_SESSION_ID support
- Integrated cost estimator and model selector via multi-path resolution
- All existing wrapper functionality preserved (additive changes only)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create kimi-cost-estimator.sh** - `e12df7e` (feat)
2. **Task 2: Enhance wrapper with auto-model selection** - `d76a020` (feat)
3. **Task 3: Add context preservation** - included in Task 2 commit (session management)

**Plan metadata:** (pending)

## Files Created/Modified

- `skills/kimi-cost-estimator.sh` - Cost estimation library with CLI interface
  - estimate_tokens(): character count / 4 heuristic
  - estimate_cost(): prompt + files with model multiplier
  - display_cost(): human-readable format with speed category
  - should_prompt_user(): confidence and cost threshold checking
  - CLI with --prompt, --files, --model, --json options

- `skills/kimi.agent.wrapper.sh` - Enhanced wrapper with auto-delegation
  - --auto-model flag for automatic K2/K2.5 selection
  - --show-cost flag for cost display before delegation
  - --confidence-threshold option (default: 75)
  - --session-id option for context preservation
  - auto_select_model() using kimi-model-selector.sh
  - estimate_and_display_cost() using kimi-cost-estimator.sh
  - Session management with get_session_id() and persist_session_id()
  - Multi-path resolution for cross-directory usage

## Decisions Made

- **K2.5 cost multiplier = 1.5x** - Based on research indicating K2.5 typically costs more than K2
- **Token estimate = characters / 4** - Industry-standard heuristic when exact token count unavailable
- **Multi-path resolution** - Try SCRIPT_DIR, parent directory, and pwd to find dependencies
- **Session persistence** - Store session ID in /tmp/kimi-session-$$ with trap cleanup

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

1. **Model selector path resolution** - Wrapper couldn't find selector when run from different directories
   - **Resolution:** Implemented multi-path resolution trying SCRIPT_DIR, parent, and pwd

2. **Empty files argument** - Wrapper passed `--files ''` when no files found, causing selector to fail
   - **Resolution:** Added whitespace trimming before checking if files is non-empty

3. **local keyword at top level** - Bash doesn't allow `local` outside functions
   - **Resolution:** Removed `local` keywords from top-level if blocks

4. **grep -P locale warnings** - Model selector's fallback parsing uses grep -P which warns on some locales
   - **Resolution:** Non-blocking warning; functionality works correctly

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Cost estimation and model selection fully integrated
- Wrapper ready for use with --auto-model and --show-cost flags
- Session management enables context preservation across related delegations
- Ready for Phase 10 Plan 04 (SKILL.md documentation update)

---
*Phase: 10-enhanced-skill*
*Completed: 2026-02-05*

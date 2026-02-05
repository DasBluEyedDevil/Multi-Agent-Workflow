---
phase: 09-hooks-system
plan: 03
subsystem: cli
tags: [bash, git-hooks, installer, cli]

# Dependency graph
requires:
  - phase: 09-02
    provides: Hook scripts (pre-commit, post-checkout, pre-push)
provides:
  - Hook installation library (hooks/lib/install.sh)
  - Setup helper CLI (bin/kimi-hooks-setup)
  - User-friendly CLI wrapper (bin/kimi-hooks)
  - Global and per-project hook installation
  - Hook enable/disable configuration commands
affects:
  - 09-04 (Integration with install.sh)
  - Phase 11 (Documentation)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Library sourcing pattern for shared bash functions"
    - "CLI delegation pattern (kimi-hooks -> kimi-hooks-setup)"
    - "Symlink-based hook installation"
    - "Backup before overwrite for existing hooks"

key-files:
  created:
    - hooks/lib/install.sh
    - bin/kimi-hooks-setup
    - bin/kimi-hooks
  modified: []

key-decisions:
  - "Global hooks use ~/.config/git/hooks/ (Git 2.9+ core.hooksPath)"
  - "Local hooks use .git/hooks/ per repository"
  - "Installation creates symlinks, not copies (easy updates)"
  - "Existing hooks backed up before overwriting"
  - "kimi-hooks delegates install/uninstall/status to kimi-hooks-setup"

patterns-established:
  - "Setup helper pattern: Simple CLI for basic operations"
  - "Wrapper CLI pattern: Extended functionality with delegation"
  - "JSON config manipulation with jq for enable/disable"

# Metrics
duration: 2min
completed: 2026-02-05
---

# Phase 9 Plan 3: Hook Installer Summary

**Hook installer with global/per-project installation, CLI tools for setup and configuration management**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-05T16:55:30Z
- **Completed:** 2026-02-05T16:57:47Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Created installation library with functions for global/local install, uninstall, and status
- Created kimi-hooks-setup CLI for basic setup operations (install/uninstall/status)
- Created kimi-hooks CLI wrapper with extended functionality (enable/disable/config)
- Both CLIs follow patterns from kimi-mcp-setup for consistency
- Installation uses symlinks for easy updates when hook scripts change

## Task Commits

1. **Task 1: Create hooks installation library** - `27966a7` (feat)
2. **Task 2: Create kimi-hooks-setup CLI tool** - `9b397ba` (feat)
3. **Task 3: Create kimi-hooks CLI wrapper** - `fcd38d9` (feat)

**Plan metadata:** TBD (docs commit)

## Files Created/Modified

- `hooks/lib/install.sh` - Installation library with functions:
  - `hooks_get_global_dir()` - Returns ~/.config/git/hooks/
  - `hooks_get_local_dir()` - Returns .git/hooks/ for current repo
  - `hooks_install_global()` - Installs symlinks globally
  - `hooks_install_local()` - Installs symlinks locally
  - `hooks_uninstall()` - Removes installed symlinks
  - `hooks_status()` - Shows installation state
- `bin/kimi-hooks-setup` - Setup helper CLI (install/uninstall/status)
- `bin/kimi-hooks` - User-friendly CLI wrapper with enable/disable/config commands

## Decisions Made

- Global hooks target `~/.config/git/hooks/` (Git 2.9+ with core.hooksPath)
- Local hooks target `.git/hooks/` per repository
- Installation creates symlinks to hook scripts (not copies) for easy updates
- Existing hooks backed up with timestamp before overwriting
- kimi-hooks delegates install/uninstall/status to kimi-hooks-setup for DRY
- Enable/disable commands manipulate ~/.config/kimi/hooks.json using jq

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All installer components ready for 09-04 (Integration)
- Can now install hooks globally or per-project
- Ready to integrate with main install.sh for v2.0 distribution
- HOOK-05 requirement (Hook installer global/local) is met

---
*Phase: 09-hooks-system*
*Completed: 2026-02-05*

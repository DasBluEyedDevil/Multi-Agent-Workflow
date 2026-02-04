# Phase 01 Plan 01: Core Wrapper Script Summary

**One-liner:** Kimi CLI wrapper with KIMI_PATH/PATH detection, semver version check, two-tier agent resolution, and array-based command construction

---
phase: 01-core-wrapper
plan: 01
subsystem: cli-wrapper
tags: [bash, kimi-cli, wrapper, agent-resolution, cross-platform]

requires: []
provides: [kimi-wrapper-script, cli-detection, agent-resolution, flag-passthrough]
affects: [02-agent-roles, 03-prompt-assembly, 04-developer-experience, 05-claude-integration, 06-distribution]

tech-stack:
  added: []
  patterns: [array-command-construction, two-tier-file-resolution, stderr-stdout-separation, manual-arg-parsing]

key-files:
  created: [skills/kimi.agent.wrapper.sh]
  modified: []

decisions:
  - id: WRAP-EXIT-CODES
    decision: "Exit codes 10-13 for wrapper errors; 1-9 reserved for kimi CLI propagation"
    context: "Needed distinct wrapper exit codes that don't collide with kimi's own codes"
  - id: WRAP-DEFAULT-MODEL
    decision: "Default model is kimi-for-coding (inherits user's kimi config mapping)"
    context: "Matches kimi-cli's own default; user overrides with -m flag"
  - id: WRAP-PASSTHROUGH
    decision: "Unknown flags pass through to kimi CLI"
    context: "Future-compatible; kimi's own error messages handle mistyped flags"
  - id: WRAP-STDIN
    decision: "Support piped stdin as prompt source; positional arg takes precedence"
    context: "Standard Unix pattern; enables echo 'prompt' | kimi.agent.wrapper.sh"

metrics:
  duration: ~6 minutes
  completed: 2026-02-04
---

## Tasks Completed

| # | Task | Commit | Key Changes |
|---|------|--------|-------------|
| 1 | Write complete kimi.agent.wrapper.sh script | 5deca7c | 282-line bash script covering all 7 Phase 1 requirements |
| 2 | Validate wrapper against all success criteria | 32ad0a9 | 7 behavioral tests passed; executable bit set |

## What Was Built

A 282-line bash script (`skills/kimi.agent.wrapper.sh`) that wraps Kimi CLI with:

1. **CLI Detection (WRAP-01, WRAP-13):** Resolves kimi binary via `KIMI_PATH` env var first (Windows PATH workaround), then `command -v kimi` fallback. Exits with code 10 and platform-specific install instructions (macOS: brew, Linux: uv/pip, Windows: uv/pip + KIMI_PATH tip) if not found.

2. **Version Validation (WRAP-03):** Extracts semver from `kimi --version` output, compares against `MIN_VERSION=1.7.0` using `sort -V`. Warns on stderr if below minimum but continues execution (not a hard block).

3. **Agent Resolution (WRAP-02):** Two-tier lookup: project-local `.kimi/agents/<role>.yaml` first, then global `SCRIPT_DIR/../.kimi/agents/<role>.yaml`. Shows available roles on role-not-found error (exit 12).

4. **Argument Parsing (WRAP-08, WRAP-10):** Manual while-case loop handles `-r/--role`, `-m/--model`, `-w/--work-dir`, `-h/--help`. Unknown flags pass through to kimi CLI. Prompt from positional arg or piped stdin.

5. **Command Invocation (WRAP-12):** Builds kimi command as bash array with `--quiet` mode. Emits `[kimi:role:model]` header to stderr. Executes and propagates kimi's exit code.

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Exit code scheme | 10-13 for wrapper, 1-9 propagated from kimi | Avoids collision; each wrapper error has distinct code |
| Default model | `kimi-for-coding` | Matches kimi-cli default; inherits user config mapping |
| Unknown flags | Pass through to kimi | Future-compatible; kimi handles its own flag errors |
| Stdin support | Piped stdin detected via `! -t 0` | Standard Unix pattern; positional arg takes precedence |
| Version check | Warning only, not hard block | Per CONTEXT.md decision; lets users run older versions |
| Output streams | All wrapper output to stderr | Keeps stdout clean for piping kimi output |

## Deviations from Plan

None -- plan executed exactly as written.

## Verification Results

### Structural Checks (12/12 passed)
1. `bash -n` syntax check: PASS
2. Line count: 282 (within 250-320)
3. Shebang: `#!/usr/bin/env bash`
4. Strict mode: `set -euo pipefail` present
5. `EXIT_CLI_NOT_FOUND=10` defined
6. `resolve_agent` appears 2+ times (definition + usage)
7. `command -v kimi` present
8. `--quiet` present
9. `KIMI_PATH` referenced 7 times
10. `[kimi:` header format present
11. `sort -V` for version comparison present
12. `>&2` appears 22 times (all wrapper output to stderr)

### Behavioral Tests (7/7 passed)
1. `-h` prints usage and exits 0
2. Missing prompt exits 13 with error message
3. Piped stdin is detected (reaches validation/invocation stage)
4. Role not found shows available roles and exits 12
5. All 4 wrapper exit codes defined (10, 11, 12, 13)
6. No error/warning output leaks to stdout
7. Machine-parseable header `[kimi:role:model]` present on stderr

### Success Criteria (5/5 met)
1. SC1: Script parses `-r` and positional prompt, builds correct kimi command array
2. SC2: `resolve_agent()` checks project-local then `SCRIPT_DIR/../.kimi/agents/`
3. SC3: Missing kimi CLI produces platform-specific install instructions and exit 10
4. SC4: `check_version()` warns if below 1.7.0, continues execution
5. SC5: Argument parser handles `-m/--model` and `-w/--work-dir`, adds to command array

## Requirements Coverage

| Requirement | Description | Status |
|------------|-------------|--------|
| WRAP-01 | Invoke kimi CLI with selected agent role | Implemented |
| WRAP-02 | Two-tier agent file resolution | Implemented |
| WRAP-03 | CLI presence validation with install instructions | Implemented |
| WRAP-08 | Flag pass-through (-r, -m, -w) | Implemented |
| WRAP-10 | Version check with minimum version | Implemented |
| WRAP-12 | Machine-parseable header for Claude Code | Implemented |
| WRAP-13 | KIMI_PATH env var for Windows PATH workaround | Implemented |

## Next Phase Readiness

Phase 1 is complete. The wrapper script is ready for:
- **Phase 2 (Agent Roles):** Agent YAML files can be placed in `.kimi/agents/` and resolved by name
- **Phase 3 (Prompt Assembly):** Template and diff injection can be added to prompt construction
- **Phase 4 (Developer Experience):** `--dry-run`, `--verbose`, and expanded `--help` can extend the argument parser
- **Phase 5 (Claude Code Integration):** Machine-parseable header format `[kimi:role:model]` is established

No blockers. No concerns.

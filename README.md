# Multi-Agent-Workflow

**Gemini CLI as a Research Subagent for Claude Code**

Leverage Gemini's 1M+ token context window for large-scale code analysis while Claude handles implementation. Division of labor: **Gemini reads, Claude writes**.

## Quick Start

```bash
# 1. Clone and install
git clone <repo-url>
cd Multi-Agent-Workflow
./install.sh

# 2. Choose installation type:
#    1) Global  - Available in all projects (~/.claude/)
#    2) Project - Current directory only
#    3) Custom  - Specify path

# 3. Test it works
./skills/gemini.agent.wrapper.sh --dry-run -r reviewer "test"
```

## Upgrading

Run `./install.sh` again. The installer detects existing installations and:

- **Updates**: wrapper scripts, roles, skill definition, config.example
- **Preserves**: your `.claude/settings.json`, `.gemini/config`, custom templates
- **Offers backup**: Creates timestamped backup before overwriting

```bash
# Upgrade existing installation
./install.sh
# Select same target → prompted to backup → files updated
```

## Prerequisites

| Dependency | Required | Installation |
|------------|----------|--------------|
| **Gemini CLI** | Yes | [ai.google.dev/gemini-api/docs/cli](https://ai.google.dev/gemini-api/docs/cli) |
| **jq** | Yes | `brew install jq` / `apt install jq` / [stedolan.github.io/jq](https://stedolan.github.io/jq/) |
| **git** | Optional | For `--diff` feature |

## How It Works

```
┌─────────────────┐                    ┌─────────────────┐
│   Claude Code   │                    │   Gemini CLI    │
│  (The Hands)    │                    │   (The Eyes)    │
├─────────────────┤                    ├─────────────────┤
│ • Writes code   │  1. Research       │ • 1M+ tokens    │
│ • Makes changes │ ──────────────────▶│ • Analyzes code │
│ • Runs tests    │                    │ • Finds patterns│
│                 │  2. Structured     │                 │
│                 │     response       │                 │
│                 │ ◀──────────────────│                 │
│ 3. Implement    │                    │                 │
└─────────────────┘                    └─────────────────┘
```

**Workflow Pattern:**
1. **Research** → Gemini analyzes codebase
2. **Implement** → Claude writes code based on analysis
3. **Verify** → Gemini reviews changes

## Usage

### Basic Commands

```bash
# Code review
./skills/gemini.agent.wrapper.sh -r reviewer -d "@src/" "Review authentication module"

# Debug an issue
./skills/gemini.agent.wrapper.sh -r debugger "Error at auth.ts:145 - token validation fails"

# Security audit
./skills/gemini.agent.wrapper.sh -r security -d "@src/" "Audit for vulnerabilities"

# Plan a feature
./skills/gemini.agent.wrapper.sh -t implement-ready -d "@src/" "Add user profiles"

# Verify changes
./skills/gemini.agent.wrapper.sh -t verify --diff "Added password reset feature"
```

### Available Roles

All roles are defined in `.gemini/roles/*.md` and can be customized or extended.

| Role | Flag | Use Case |
|------|------|----------|
| `reviewer` | `-r reviewer` | Code quality, bugs, best practices |
| `debugger` | `-r debugger` | Bug tracing, root cause analysis |
| `planner` | `-r planner` | Architecture, implementation planning |
| `security` | `-r security` | Security vulnerabilities, OWASP |
| `auditor` | `-r auditor` | Tech debt, patterns, inconsistencies |
| `explainer` | `-r explainer` | Code explanation, documentation |
| `migrator` | `-r migrator` | Migration planning, breaking changes |
| `documenter` | `-r documenter` | API docs, component relationships |
| `dependency-mapper` | `-r dependency-mapper` | Dependency graphs, circular deps |
| `onboarder` | `-r onboarder` | Project overview, key decisions |
| `kotlin-expert` | `-r kotlin-expert` | Kotlin/Android, coroutines, Compose |
| `typescript-expert` | `-r typescript-expert` | TypeScript, type safety |
| `python-expert` | `-r python-expert` | Python async, type hints |
| `api-designer` | `-r api-designer` | REST API design, endpoints |
| `database-expert` | `-r database-expert` | Query optimization, schemas |

### Templates

| Template | Flag | Output |
|----------|------|--------|
| `feature` | `-t feature` | Pre-implementation analysis |
| `bug` | `-t bug` | Bug investigation |
| `verify` | `-t verify` | Post-implementation verification |
| `architecture` | `-t architecture` | System overview with diagrams |
| `implement-ready` | `-t implement-ready` | Claude-optimized with exact files/patterns |
| `fix-ready` | `-t fix-ready` | Copy-paste ready bug fixes |

## Command Reference

```
USAGE:
    ./skills/gemini.agent.wrapper.sh [OPTIONS] "<prompt>"

CORE OPTIONS:
    -d, --dir DIRS         Directories to include (@src/ @lib/)
    -r, --role ROLE        Use predefined role
    -t, --template TMPL    Use query template
    -m, --model MODEL      Specify model (default: gemini-3-pro-preview)
    --no-fallback          Disable automatic fallback model

CONTEXT OPTIONS:
    --diff [TARGET]        Include git diff (default: HEAD)
    --smart-ctx KEYWORDS   Auto-find files containing keywords
    --chat SESSION         Enable conversation mode with history
    --files FILE1,FILE2    Target specific files only

CACHING:
    --cache                Cache response for repeated queries
    --cache-ttl SECONDS    Cache time-to-live (default: 86400 = 24h)
    --clear-cache          Clear all cached responses

OUTPUT:
    --schema SCHEMA        Structured output: files, issues, plan, json
    --summarize            Request compressed response
    --save-response        Save to .gemini/last-response.txt
    --validate             Validate response format

EXECUTION:
    --retry N              Retry attempts on failure (default: 2)
    --estimate             Show token estimate without executing
    --dry-run              Show prompt without executing
    --verbose              Show status messages
    --batch FILE           Process multiple queries from file

HELP:
    -h, --help             Display help message
```

## Response Format

All Gemini responses follow a structured format for easy parsing:

```markdown
## SUMMARY
[1-2 sentence overview]

## FILES
[List as: path/to/file.ext:LINE - description]

## ANALYSIS
[Detailed findings with code excerpts]

## RECOMMENDATIONS
[Numbered actionable items]
```

Parse responses programmatically:

```bash
# Extract specific section
./skills/gemini-parse.sh --section FILES response.txt

# Get file references as JSON
./skills/gemini-parse.sh --files-only --json response.txt

# Validate format
./skills/gemini-parse.sh --validate response.txt
```

## File Structure

```
Multi-Agent-Workflow/
├── install.sh                    # Automated installer
├── uninstall.sh                  # Uninstaller
├── GeminiContext.md              # Auto-injected into every query
│
├── skills/
│   ├── gemini.agent.wrapper.sh   # Core wrapper (1000+ lines)
│   ├── gemini-parse.sh           # Response parser
│   └── Claude-Code-Integration.md # Integration guide
│
├── .gemini/
│   ├── roles/                    # 15 role definitions
│   │   ├── reviewer.md
│   │   ├── debugger.md
│   │   ├── planner.md
│   │   ├── security.md
│   │   └── ... (11 more)
│   ├── templates/                # Custom query templates
│   ├── cache/                    # Response cache (auto-created)
│   ├── history/                  # Chat session history
│   └── config.example            # Configuration template
│
├── .claude/
│   ├── settings.json             # Hooks for Claude Code
│   └── skills/gemini-research/
│       └── SKILL.md              # Claude skill definition
│
└── tests/
    └── test-wrapper.sh           # Test harness (20 tests)
```

## Configuration

Copy `.gemini/config.example` to `.gemini/config` to set defaults:

```bash
# .gemini/config
VERBOSE=false
MODEL="gemini-3-pro-preview"
MAX_RETRIES=3
CACHE_TTL=86400  # 24 hours
SAVE_LAST_RESPONSE=true
```

## Claude Code Integration

### Hooks

The `.claude/settings.json` includes intelligent hooks:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "(?i)(review|analyze|trace|debug|security|audit|architecture)",
        "prompt": "Consider using Gemini Research for analysis..."
      }
    ],
    "Stop": [
      {
        "prompt": "Consider verifying changes with Gemini..."
      }
    ]
  }
}
```

Hooks trigger only on relevant requests (review, analyze, debug, etc.) to reduce noise.

### Skill Definition

The skill at `.claude/skills/gemini-research/SKILL.md` teaches Claude:
- **When** to use Gemini (files >100 lines, multi-file analysis)
- **How** to invoke the wrapper
- **What** roles and templates are available
- **How** to interpret structured responses

## Testing

Run the test harness to verify functionality:

```bash
./tests/test-wrapper.sh
```

**Test Coverage (20 tests):**
- Basic prompt passthrough
- Role loading (reviewer, security, planner)
- Template loading (feature, bug, verify)
- Directory and schema flags
- Cache TTL and retry options
- Parser: case-insensitive sections
- Parser: validation and JSON output

All tests use `--dry-run` to validate without API calls.

## Features

### Retry Logic
Automatic retry with exponential backoff (2s, 4s, 8s) on API failures. Configurable via `--retry N` or `MAX_RETRIES` in config.

### Cache with TTL
Responses are cached by model+prompt hash. Cache expires after 24 hours by default. Use `--cache-ttl SECONDS` to customize.

### Model Fallback
If `gemini-3-pro-preview` fails, automatically falls back to `gemini-3-flash-preview` unless `--no-fallback` is specified.

### Cross-Platform
Works on Linux, macOS, and Windows (Git Bash/WSL). Handles platform differences in `stat`, `sed`, and line endings.

## Adding Custom Roles

Create `.gemini/roles/my-role.md`:

```markdown
# My Custom Role

You are a [description]. Focus on:
- Specific area 1
- Specific area 2

When analyzing, prioritize [criteria].
```

Use with `-r my-role`.

## Adding Custom Templates

Create `.gemini/templates/my-template.md`:

```markdown
Custom Analysis Request.

Please analyze:
1. First thing
2. Second thing
3. Third thing

Context:
```

Use with `-t my-template`.

## Troubleshooting

**"gemini CLI not found"**
```bash
# Verify installation
gemini --version

# Check PATH
which gemini
```

**"jq is required but not found"**
```bash
# Install jq
brew install jq      # macOS
apt install jq       # Linux
# Windows: download from stedolan.github.io/jq
```

**Cache not working**
```bash
# Clear and retry
./skills/gemini.agent.wrapper.sh --clear-cache
./skills/gemini.agent.wrapper.sh --cache "your query"
```

**Response format issues**
```bash
# Validate response
./skills/gemini-parse.sh --validate response.txt
```

## License

MIT

## Contributing

1. Make changes
2. Run tests: `./tests/test-wrapper.sh`
3. All 20 tests must pass
4. Submit PR

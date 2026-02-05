# Phase 3: Prompt Assembly - Context

**Gathered:** 2026-02-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Enrich Kimi CLI invocations with templates, git diffs, and project context without manual prompt construction. Users can run `-t <template>` to prepend structured context, `--diff` to include changed files, and have project context auto-loaded from context files.

**Requirements from ROADMAP.md:** WRAP-04, WRAP-05, WRAP-06, WRAP-07
</domain>

<decisions>
## Implementation Decisions

### Template Structure
- Templates are plain markdown files (not complex templating engines)
- Use Kimi CLI's native variable substitution: `${KIMI_WORK_DIR}`, `${KIMI_NOW}`, `${KIMI_MODEL}`
- Standard sections in each template: **Context**, **Task**, **Output Format**, **Constraints**
- Stored in `.kimi/templates/` directory with naming: `{template-name}.md`
- 6 built-in templates required: feature, bug, verify, architecture, implement-ready, fix-ready

### Git Diff Injection
- `--diff` flag injects `git diff` output into the prompt context
- Raw unified diff format (standard, readable by both humans and models)
- Includes all changes: staged + unstaged (comprehensive view of current work)
- Injected after template/context, before user's prompt
- No `--diff-staged` variant for now (can add later if needed)

### Context File Discovery
- Search order (first wins): `.kimi/context.md` → `KimiContext.md`
- `.kimi/context.md` preferred (cleaner project structure)
- `KimiContext.md` supported for legacy/compatibility
- Context file content is prepended to every prompt automatically (if exists)
- Optional feature — silent continue if no context file found

### Prompt Assembly Order
Final prompt constructed in this sequence:
1. **Template content** (if `-t <template>` specified)
2. **Context file content** (if context file exists)
3. **Git diff** (if `--diff` specified)
4. **User's prompt** (from `-p` or stdin)

This gives natural flow: setup → context → changes → specific question.

### Missing File Handling
- **Missing template**: Clear error message listing available templates, exit non-zero
- **Missing context file**: Silent continue (optional enhancement, not required)
- **Git not available**: Warning message, continue without diff injection
- **Not a git repo**: Same as git unavailable — warning, continue

### Template Content Guidelines
Each template should:
- Start with clear context statement about what the template is for
- Define expected output format and structure
- Include constraints (what to avoid, what to prioritize)
- Be 50-150 lines (substantial enough to guide, not overwhelm)

### OpenCode's Discretion
- Exact wording within templates (as long as structure follows guidelines)
- Whether to include file path context in diff output
- Error message formatting and specific exit codes
- Whether to support `.kimi/templates/` user overrides (nice-to-have, not required)
</decisions>

<specifics>
## Specific Ideas

- Templates should feel like "priming the pump" — give Kimi context about what kind of task it's doing
- Git diff should include file names so Kimi knows what's being changed
- Context file is for project-specific rules ("we use TypeScript", "follow these naming conventions")
- Think of templates as "modes" — verify mode, bug-fix mode, feature mode
</specifics>

<deferred>
## Deferred Ideas

- Custom user templates (beyond the 6 built-in) — could be a future enhancement
- Interactive template selection (menu/TUI) — Phase 4+ consideration
- Template variables with user-defined values — adds complexity, defer until needed
- Multiple context files (context.d/ directory) — overkill for now
- Git diff filtering (only certain file types) — can add if requested
</deferred>

---

*Phase: 03-prompt-assembly*
*Context gathered: 2026-02-05*

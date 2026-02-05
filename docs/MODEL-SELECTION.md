# Model Selection Best Practices

Choose between Kimi K2 and K2.5 for optimal results and cost efficiency.

## Overview

| Model | Strengths | Best For | Cost |
|-------|-----------|----------|------|
| **K2** | Fast, efficient, reliable | Routine tasks | Base rate |
| **K2.5** | Creative, nuanced, powerful | Complex/UI tasks | ~1.5x |

## Quick Decision Tree

```
Task Type?
├── Refactoring ────────→ K2
├── Testing ────────────→ K2
├── Debugging ──────────→ K2
├── API/Backend ────────→ K2
├── UI Components ──────→ K2.5
├── Styling/CSS ────────→ K2.5
├── Feature Design ─────→ K2.5
└── Complex Logic ──────→ K2.5
```

## When to Use K2

### Refactoring

**Why K2:** Refactoring is structural transformation, not creative work.

**Examples:**
- Extract method/function
- Rename variables consistently
- Move code between files
- Simplify conditionals

**Command:**
```bash
./skills/kimi.agent.wrapper.sh -r refactorer "Extract validation logic"
```

### Testing

**Why K2:** Tests follow patterns, require consistency.

**Examples:**
- Unit test generation
- Test coverage improvement
- Mock setup
- Assertion patterns

**Command:**
```bash
./skills/kimi.agent.wrapper.sh -r implementer "Add tests for auth module"
```

### Debugging

**Why K2:** Debugging is systematic investigation.

**Examples:**
- Trace error sources
- Fix null pointer issues
- Resolve type errors
- Fix off-by-one errors

**Command:**
```bash
./skills/kimi.agent.wrapper.sh -r debugger "Fix the login error"
```

### Backend/API Work

**Why K2:** APIs need consistency, not creativity.

**Examples:**
- Endpoint implementation
- Database queries
- Validation logic
- Error handling

**File Patterns:** `.py`, `.go`, `.rs`, `.java`, `.rb`

## When to Use K2.5

### UI Components

**Why K2.5:** Components require design sense, UX understanding.

**Examples:**
- React/Vue/Angular components
- Form layouts
- Modal dialogs
- Navigation elements

**Command:**
```bash
./skills/kimi.agent.wrapper.sh -r implementer "Create user profile card"
```

### Styling

**Why K2.5:** CSS requires aesthetic judgment.

**Examples:**
- Responsive layouts
- Animation design
- Theme implementation
- Visual polish

**File Patterns:** `.css`, `.scss`, `.less`, `.styled.js`

### Creative Features

**Why K2.5:** Novel features need creative problem-solving.

**Examples:**
- New user flows
- Interactive features
- Data visualization
- Custom components

### Complex Logic

**Why K2.5:** Nuanced algorithms benefit from deeper reasoning.

**Examples:**
- State machines
- Complex validations
- Business rule engines
- Optimization algorithms

## File Extension Mapping

The auto-selection system uses file extensions:

| Extension | Default Model | Reason |
|-----------|---------------|--------|
| `.tsx`, `.jsx` | K2.5 | React components |
| `.vue`, `.svelte` | K2.5 | UI frameworks |
| `.css`, `.scss` | K2.5 | Styling |
| `.html` | K2.5 | Markup/layout |
| `.py`, `.go` | K2 | Backend languages |
| `.rs`, `.java` | K2 | System languages |
| `.js`, `.ts` | K2 | Logic/utility |
| `.test.*` | K2 | Test files |

## Confidence Scoring

The system calculates confidence (0-100) for auto-selection:

| Factor | Weight | Description |
|--------|--------|-------------|
| File agreement | +20 | All files suggest same model |
| Task clarity | +20 | Task type clearly identified |
| Pattern match | +10 | Code patterns match model |
| Base score | 50 | Starting point |

**Thresholds:**
- > 75%: Auto-select with confidence
- 50-75%: Select but warn user
- < 50%: Ask user to specify

## Override Mechanisms

### Force Specific Model

```bash
# Force K2.5
KIMI_FORCE_MODEL=k2.5 ./skills/kimi.agent.wrapper.sh ...

# Force K2
KIMI_FORCE_MODEL=k2 ./skills/kimi.agent.wrapper.sh ...
```

### Disable Auto-Selection

```bash
# Use default model (no auto-selection)
./skills/kimi.agent.wrapper.sh -r implementer "task"
```

### Per-Project Defaults

In `.kimi/config`:

```yaml
model:
  default: k2
  overrides:
    "*.tsx": k2.5
    "*.css": k2.5
```

## Cost Considerations

### Estimation

Before delegation, estimate cost:

```bash
./skills/kimi-cost-estimator.sh "prompt text" --files src/
```

**Output:**
```
Estimated tokens: ~2,400
K2 cost: $0.00036
K2.5 cost: $0.00054 (1.5x)
```

### When to Accept Higher Cost

Use K2.5 when:
- Task is user-facing (quality matters)
- One-time creative work
- Complex logic with edge cases
- Learning/exploration phase

Use K2 when:
- Bulk operations (many files)
- Routine maintenance
- Well-defined transformations
- Cost-sensitive context

## Examples by Scenario

### Scenario 1: New Feature

```bash
# Design phase (creative) → K2.5
./skills/kimi.agent.wrapper.sh -r planner "Design the checkout flow"

# Implementation (routine) → K2
./skills/kimi.agent.wrapper.sh -r implementer "Build checkout API"

# UI components (creative) → K2.5
./skills/kimi.agent.wrapper.sh -r implementer "Create checkout form"

# Tests (routine) → K2
./skills/kimi.agent.wrapper.sh -r implementer "Add checkout tests"
```

### Scenario 2: Refactoring

```bash
# All refactoring → K2
./skills/kimi.agent.wrapper.sh -r refactorer "Extract service layer"
```

### Scenario 3: Bug Fix

```bash
# Investigation → K2
./skills/kimi.agent.wrapper.sh -r debugger "Find the race condition"

# Fix implementation → K2
./skills/kimi.agent.wrapper.sh -r debugger "Fix the race condition"
```

## Best Practices

1. **Start with auto-selection:** Let the system choose, override when wrong
2. **Use K2 for bulk:** Large refactors, many files → K2
3. **Use K2.5 for polish:** UI finishing touches → K2.5
4. **Estimate first:** Check cost before large operations
5. **Review selections:** Tune based on results over time

## Troubleshooting

### "Wrong model selected"

Override with environment variable:

```bash
KIMI_FORCE_MODEL=k2.5 ./skills/kimi.agent.wrapper.sh ...
```

### "Auto-selection confidence low"

Be more specific in your prompt:

```bash
# Vague (low confidence)
./skills/kimi.agent.wrapper.sh "Fix the code"

# Specific (high confidence)
./skills/kimi.agent.wrapper.sh "Refactor the auth middleware"
```

### "Cost too high"

- Use K2 instead of K2.5
- Reduce context with more specific file selection
- Break large tasks into smaller chunks

## See Also

- [MCP Setup](./MCP-SETUP.md) — MCP server configuration
- [Hooks Guide](./HOOKS-GUIDE.md) — Git hooks configuration
- @.claude/skills/kimi-delegation/SKILL.md — Complete delegation guide

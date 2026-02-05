# Phase 10: Enhanced SKILL.md - Research

**Researched:** 2026-02-05
**Domain:** Intelligent Model Selection & Auto-Delegation
**Confidence:** MEDIUM

## Summary

This research investigates implementing smart triggers for autonomous delegation with intelligent model selection between Kimi K2 and K2.5. The existing infrastructure includes a wrapper script (`kimi.agent.wrapper.sh`), MCP bridge, hooks system, and agent role definitions. The goal is to add automatic model selection based on task characteristics (file extensions, task types, code patterns) with confidence thresholds, cost estimation, and user override capabilities.

**Key findings:**
- Kimi CLI supports `-m` flag for model selection but uses provider-based model names (e.g., `kimi-for-coding`)
- Current MCP bridge hardcodes `k2`/`k2.5` model selection via `mcp_call_kimi()` function
- File extension mapping is straightforward but task type classification requires pattern detection
- Confidence scoring can leverage existing hooks infrastructure with pre-delegation analysis
- Cost estimation requires token counting or API rate lookup (not directly available in kimi CLI)

**Primary recommendation:** Implement a decision engine in bash that analyzes task characteristics before delegation, maps to appropriate models, and provides user confirmation with cost estimates.

## Standard Stack

### Core
| Library/Tool | Version | Purpose | Why Standard |
|--------------|---------|---------|--------------|
| kimi-cli | 1.7.0+ | AI agent execution | Primary delegation target |
| bash | 4.0+ | Scripting engine | Existing wrapper infrastructure |
| jq | 1.6+ | JSON processing | Configuration and API handling |
| git | 2.30+ | Context detection | File change analysis |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| grep/ripgrep | Pattern detection | Code pattern matching |
| file command | MIME type detection | File type classification |
| wc | Token estimation | Rough cost calculation |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| bash logic | Python decision engine | Python adds dependency; bash integrates with existing wrapper |
| File extension only | AST parsing | AST is more accurate but much heavier |
| Static thresholds | ML-based classification | ML is overkill for this use case |

## Architecture Patterns

### Recommended Project Structure
```
skills/
├── kimi.agent.wrapper.sh          # Existing wrapper (enhanced)
├── kimi-model-selector.sh         # NEW: Model selection logic
├── kimi-cost-estimator.sh         # NEW: Cost estimation
└── lib/
    ├── model-rules.json           # NEW: File ext → model mapping
    ├── task-classifier.sh         # NEW: Task type detection
    └── confidence-scorer.sh       # NEW: Confidence calculation

.kimi/
├── agents/
│   ├── implementer.yaml           # Existing (K2.5 for creative)
│   ├── refactorer.yaml            # Existing (K2 for routine)
│   └── ...                        # Other roles
└── config/
    └── model-selection.json       # NEW: User overrides

mcp-bridge/
├── lib/
│   ├── mcp-tools.sh               # Enhanced with model selection
│   └── model-router.sh            # NEW: Model routing logic
```

### Pattern 1: Decision Engine Pipeline
**What:** Multi-stage pipeline for task analysis → model selection → delegation
**When to use:** All delegation decisions
**Example:**
```bash
# Source: Research-derived pattern
delegate_task() {
    local task="$1"
    local files="$2"
    
    # Stage 1: Extract characteristics
    local extensions=$(extract_extensions "$files")
    local task_type=$(classify_task "$task")
    local complexity=$(estimate_complexity "$task" "$files")
    
    # Stage 2: Score confidence
    local confidence=$(calculate_confidence "$extensions" "$task_type" "$complexity")
    
    # Stage 3: Select model
    local model=$(select_model "$extensions" "$task_type" "$confidence")
    
    # Stage 4: Estimate cost
    local cost=$(estimate_cost "$task" "$files" "$model")
    
    # Stage 5: Delegate or prompt
    if [[ "$confidence" -ge "$CONFIDENCE_THRESHOLD" ]]; then
        echo "Auto-delegating to $model (confidence: $confidence%, est. cost: $cost)"
        execute_delegation "$model" "$task" "$files"
    else
        prompt_user "$model" "$cost" "$confidence"
    fi
}
```

### Pattern 2: File Extension Mapping
**What:** Map file extensions to model preferences
**When to use:** UI/creative file detection
**Example:**
```bash
# Source: Research-derived pattern
# model-rules.json structure
{
  "extensions": {
    "k2.5": [".tsx", ".jsx", ".css", ".scss", ".vue", ".svelte", ".html"],
    "k2": [".py", ".js", ".ts", ".go", ".rs", ".java", ".rb", ".sh"]
  },
  "overrides": {
    "*.test.*": "k2",
    "*.spec.*": "k2",
    "*component*": "k2.5"
  }
}

# Bash implementation
get_model_for_extension() {
    local file="$1"
    local ext="${file##*.}"
    
    case ".$ext" in
        .tsx|.jsx|.css|.scss|.vue|.svelte|.html)
            echo "k2.5"
            ;;
        .py|.js|.ts|.go|.rs|.java|.rb|.sh|.bash)
            echo "k2"
            ;;
        *)
            echo "k2"  # Default
            ;;
    esac
}
```

### Pattern 3: Task Type Classification
**What:** Keyword and pattern-based task classification
**When to use:** Determining routine vs creative work
**Example:**
```bash
# Source: Research-derived pattern
classify_task() {
    local task="$1"
    local task_lower=$(echo "$task" | tr '[:upper:]' '[:lower:]')
    
    # Routine task patterns (K2)
    local routine_patterns="refactor|test|testing|fix.*bug|debug|optimize|lint|format"
    routine_patterns="$routine_patterns|extract.*method|rename|move.*file|cleanup"
    
    # Creative/UI patterns (K2.5)
    local creative_patterns="implement.*feature|create.*component|design|ui|ux"
    creative_patterns="$creative_patterns|style|layout|animation|responsive|theme"
    
    if echo "$task_lower" | grep -Eq "$routine_patterns"; then
        echo "routine"
    elif echo "$task_lower" | grep -Eq "$creative_patterns"; then
        echo "creative"
    else
        echo "unknown"
    fi
}
```

### Pattern 4: Confidence Scoring
**What:** Multi-factor confidence calculation
**When to use:** Determining auto-delegation eligibility
**Example:**
```bash
# Source: Research-derived pattern
calculate_confidence() {
    local extensions="$1"
    local task_type="$2"
    local complexity="$3"
    
    local score=50  # Base confidence
    
    # File extension clarity (+20 if all files agree on model)
    if all_files_same_model "$extensions"; then
        score=$((score + 20))
    fi
    
    # Task type clarity (+20 if clearly routine or creative)
    if [[ "$task_type" != "unknown" ]]; then
        score=$((score + 20))
    fi
    
    # Complexity appropriateness (+10 if within model sweet spot)
    if [[ "$complexity" == "appropriate" ]]; then
        score=$((score + 10))
    fi
    
    # Cap at 100
    [[ $score -gt 100 ]] && score=100
    
    echo "$score"
}
```

### Anti-Patterns to Avoid
- **Hardcoding thresholds:** Make confidence threshold configurable
- **Single-factor decisions:** Use multiple signals (extension + task type + patterns)
- **Silent auto-delegation:** Always notify user of automatic decisions
- **Ignoring overrides:** User override must take absolute precedence

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Token counting | Custom tokenizer | `wc -c` with heuristic | Kimi CLI doesn't expose token count; use character count / 4 as estimate |
| File type detection | Complex MIME sniffing | Extension mapping + `file` command | Extensions are sufficient for code files |
| Pattern matching | Full NLP parser | grep/regex with keyword lists | Task descriptions are short and keyword-rich |
| Cost tracking | Custom billing system | Simple rate table lookup | Kimi pricing is flat per model, not token-based |
| Session management | Custom state store | Kimi CLI `--session` flag | Kimi already handles conversation state |

**Key insight:** The decision logic should be lightweight and heuristic-based. Complex ML or AST parsing adds overhead without proportional benefit for this classification task.

## Common Pitfalls

### Pitfall 1: Model Name Mismatch
**What goes wrong:** Using `k2`/`k2.5` with kimi CLI that expects provider model names like `kimi-for-coding`
**Why it happens:** MCP bridge uses `k2`/`k2.5` internally but kimi CLI 1.7+ uses provider-prefixed names
**How to avoid:** Map internal `k2`/`k2.5` labels to actual kimi CLI model names via configuration
**Warning signs:** "Model not found" errors from kimi CLI

### Pitfall 2: Over-Auto-Delegation
**What goes wrong:** Delegating too aggressively, causing unexpected costs or wrong model choices
**Why it happens:** Confidence threshold too low or signals weighted incorrectly
**How to avoid:** Start with high threshold (80%+), require user confirmation for expensive operations
**Warning signs:** User complaints about unexpected delegations

### Pitfall 3: Context Loss on Override
**What goes wrong:** User override doesn't persist or breaks conversation context
**Why it happens:** Override is one-off and not passed through delegation chain
**How to avoid:** Store override in environment variable or temp file for session duration
**Warning signs:** Model choice reverts unexpectedly

### Pitfall 4: Cost Estimation Drift
**What goes wrong:** Cost estimates are consistently wrong, eroding user trust
**Why it happens:** Using simple heuristics without calibration
**How to avoid:** Track actual vs estimated costs and adjust multipliers
**Warning signs:** Estimates off by >50% consistently

### Pitfall 5: Hook Integration Race Conditions
**What goes wrong:** Hooks trigger delegation before analysis completes
**Why it happens:** Async processing or multiple hooks conflicting
**How to avoid:** Use file locks or sequential processing in hooks
**Warning signs:** Duplicate delegations or missing analysis

## Code Examples

### Model Selection Logic
```bash
# Source: Research-derived from existing wrapper patterns
#!/bin/bash
# model-selector.sh - Intelligent model selection

# Configuration
K2_MODEL="kimi-for-coding"  # Or provider-specific name
K2_5_MODEL="kimi-for-coding"  # Same model, different behavior via flags
CONFIDENCE_THRESHOLD=75

# File extension to model mapping
declare -A EXT_TO_MODEL=(
    ["tsx"]="k2.5" ["jsx"]="k2.5" ["css"]="k2.5"
    ["scss"]="k2.5" ["vue"]="k2.5" ["svelte"]="k2.5"
    ["html"]="k2.5"
    ["py"]="k2" ["js"]="k2" ["ts"]="k2"
    ["go"]="k2" ["rs"]="k2" ["java"]="k2"
    ["rb"]="k2" ["sh"]="k2" ["bash"]="k2"
)

# Select model based on files and task
select_model() {
    local task="$1"
    shift
    local files=("$@")
    
    local k2_score=0
    local k2_5_score=0
    
    # Score based on file extensions
    for file in "${files[@]}"; do
        local ext="${file##*.}"
        local model="${EXT_TO_MODEL[$ext]:-k2}"
        if [[ "$model" == "k2.5" ]]; then
            ((k2_5_score++))
        else
            ((k2_score++))
        fi
    done
    
    # Score based on task type
    local task_type=$(classify_task "$task")
    case "$task_type" in
        creative|ui|feature)
            ((k2_5_score += 2))
            ;;
        routine|refactor|test|debug)
            ((k2_score += 2))
            ;;
    esac
    
    # Return model with higher score
    if [[ $k2_5_score -gt $k2_score ]]; then
        echo "k2.5"
    else
        echo "k2"
    fi
}

# Calculate confidence percentage
calculate_confidence() {
    local task="$1"
    local files=("$2")
    local selected_model="$3"
    
    local confidence=50
    
    # High confidence if all files agree
    local all_agree=true
    for file in "${files[@]}"; do
        local ext="${file##*.}"
        local expected="${EXT_TO_MODEL[$ext]:-k2}"
        if [[ "$expected" != "$selected_model" ]]; then
            all_agree=false
            break
        fi
    done
    
    $all_agree && confidence=$((confidence + 25))
    
    # High confidence if task type is clear
    local task_type=$(classify_task "$task")
    [[ "$task_type" != "unknown" ]] && confidence=$((confidence + 15))
    
    # Cap at 100
    [[ $confidence -gt 100 ]] && confidence=100
    
    echo "$confidence"
}
```

### Cost Estimation
```bash
# Source: Research-derived
#!/bin/bash
# cost-estimator.sh - Estimate delegation cost

# Approximate rates (should be configurable)
declare -A MODEL_MULTIPLIER=(
    ["k2"]=1.0
    ["k2.5"]=1.5
)

# Estimate cost based on input size
estimate_cost() {
    local task="$1"
    shift
    local files=("$@")
    local model="$2"
    
    # Count characters in task
    local task_chars=${#task}
    
    # Count characters in files (if readable)
    local file_chars=0
    for file in "${files[@]}"; do
        if [[ -r "$file" ]]; then
            local size=$(wc -c < "$file" 2>/dev/null || echo 0)
            file_chars=$((file_chars + size))
        fi
    done
    
    # Rough token estimate (4 chars per token)
    local total_chars=$((task_chars + file_chars))
    local estimated_tokens=$((total_chars / 4))
    
    # Apply model multiplier (K2.5 typically costs more)
    local multiplier="${MODEL_MULTIPLIER[$model]:-1.0}"
    local normalized_cost=$(echo "$estimated_tokens * $multiplier" | bc -l 2>/dev/null || echo "$estimated_tokens")
    
    # Return normalized cost units
    printf "%.0f" "$normalized_cost"
}

# Display human-readable cost
display_cost() {
    local cost_units="$1"
    local model="$2"
    
    # Convert to approximate API calls or time
    if [[ $cost_units -lt 1000 ]]; then
        echo "~$cost_units tokens ($model, fast)"
    elif [[ $cost_units -lt 5000 ]]; then
        echo "~$cost_units tokens ($model, moderate)"
    else
        echo "~$cost_units tokens ($model, may take time)"
    fi
}
```

### Integration with Existing Wrapper
```bash
# Source: Enhanced from existing kimi.agent.wrapper.sh
# Add to wrapper script:

# Auto-delegation with model selection
delegate_with_auto_model() {
    local prompt="$1"
    local role="${2:-}"
    local files=()
    
    # Extract file paths from prompt (simple heuristic)
    files=$(echo "$prompt" | grep -oE '[[:alnum:]_./-]+\.[[:alnum:]]+' | sort -u)
    
    # Select model
    local model=$(select_model "$prompt" $files)
    local confidence=$(calculate_confidence "$prompt" "$files" "$model")
    
    # Check for user override
    if [[ -n "${KIMI_FORCE_MODEL:-}" ]]; then
        model="$KIMI_FORCE_MODEL"
        echo "[model-selection] Using user override: $model" >&2
    fi
    
    # Estimate cost
    local cost=$(estimate_cost "$prompt" $files "$model")
    
    # Decide on auto-delegation
    if [[ -z "${KIMI_FORCE_MODEL:-}" && "$confidence" -lt "$CONFIDENCE_THRESHOLD" ]]; then
        # Low confidence - prompt user
        echo "[model-selection] Uncertain which model to use ($confidence% confidence)" >&2
        echo "[model-selection] Recommended: $model (est. cost: $cost units)" >&2
        echo "[model-selection] Override with KIMI_FORCE_MODEL=k2 or k2.5" >&2
        
        # In interactive mode, could prompt here
        # For now, proceed with recommendation but warn
    fi
    
    # Map internal model name to kimi CLI model
    local kimi_model="$DEFAULT_MODEL"
    if [[ "$model" == "k2.5" ]]; then
        # K2.5 might use same model with different flags, or different model name
        : # kimi_model stays default or use specific if available
    fi
    
    echo "[model-selection] Delegating to $model (confidence: $confidence%)" >&2
    
    # Call existing execution with selected model
    execute_kimi "$prompt" "$role" "$kimi_model"
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single model for all tasks | Model selection by task type | Phase 10 | Better cost/performance balance |
| Manual role selection | Auto-detection with override | Phase 10 | Reduced cognitive load |
| Fixed cost assumptions | Dynamic estimation | Phase 10 | Better user expectations |
| No confidence metric | Confidence scoring | Phase 10 | Informed delegation decisions |

**Deprecated/outdated:**
- Hardcoded model names: Use configuration-based mapping
- Single threshold for all tasks: Use per-task-type thresholds
- Silent delegation: Always provide feedback

## Open Questions

1. **K2 vs K2.5 Model Names in kimi CLI**
   - What we know: kimi CLI 1.7 uses `kimi-for-coding` as default
   - What's unclear: Whether `k2` and `k2.5` are distinct models or modes
   - Recommendation: Start with behavioral differences (flags) rather than model names

2. **Token Cost API**
   - What we know: kimi CLI doesn't expose token count directly
   - What's unclear: Whether API provides cost estimation endpoint
   - Recommendation: Use character-count heuristic initially, refine with usage data

3. **Context Preservation Across Delegations**
   - What we know: kimi CLI has `--session` and `--continue` flags
   - What's unclear: How to maintain context when switching models
   - Recommendation: Use same session ID for related delegations

4. **Hook Integration Points**
   - What we know: Hooks exist for pre-commit, post-checkout, pre-push
   - What's unclear: Whether to trigger auto-delegation from hooks or keep manual
   - Recommendation: Start with manual triggers, add hook integration later

## Sources

### Primary (HIGH confidence)
- `skills/kimi.agent.wrapper.sh` - Existing wrapper implementation
- `.kimi/agents/*.yaml` - Agent role definitions
- `mcp-bridge/lib/mcp-tools.sh` - MCP tool handlers with model selection
- `mcp-bridge/lib/config.sh` - Configuration loading with model validation

### Secondary (MEDIUM confidence)
- kimi CLI 1.7.0 help output - Model selection via `-m` flag
- `~/.kimi/config.toml` - Provider-based model configuration
- Kimi Code CLI documentation (moonshotai.github.io) - Configuration patterns

### Tertiary (LOW confidence)
- Kimi K2 vs K2.5 capability differences - No official documentation found
- Token pricing - Not publicly documented, estimates based on industry standards

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Based on existing working infrastructure
- Architecture: MEDIUM - Derived from existing patterns, needs validation
- Pitfalls: MEDIUM - Based on common bash/scripting issues

**Research date:** 2026-02-05
**Valid until:** 2026-03-05 (30 days - kimi CLI updates may change model handling)

## Implementation Notes for Planner

### SKILL-01: Model Selection Logic
- Implement `select_model()` function in `skills/kimi-model-selector.sh`
- Support K2 for routine tasks, K2.5 for creative/UI
- Use task classification + file extension analysis

### SKILL-02: File Extension Mapping
- Create `skills/lib/model-rules.json` with extension → model mapping
- Support `.tsx`, `.jsx`, `.css` → K2.5
- Support `.py`, `.js`, `.go` → K2

### SKILL-03: Task Type Mapping
- Implement `classify_task()` with keyword patterns
- Routine: refactor, test, debug, optimize
- Creative: feature, component, design, UI

### SKILL-04: Code Pattern Detection
- Add pattern detection for component creation
- Use grep/regex for React/Vue/Angular component signatures
- Boost K2.5 score for component patterns

### SKILL-05: Confidence Threshold
- Implement `calculate_confidence()` with multi-factor scoring
- Default threshold: 75%
- Configurable via `KIMI_CONFIDENCE_THRESHOLD` env var

### SKILL-06: Context Preservation
- Use kimi CLI `--session` flag with consistent session ID
- Store session ID in temp file for related delegations
- Pass through wrapper to maintain conversation state

### SKILL-07: Cost Estimation
- Implement `estimate_cost()` using character count / 4 heuristic
- Apply model multiplier (K2.5 = 1.5x K2)
- Display before delegation with `--dry-run` support

### SKILL-08: Override Mechanism
- Support `KIMI_FORCE_MODEL` environment variable
- Add `--model-override` flag to wrapper
- Override takes precedence over all auto-selection logic

### INT-02: SKILL.md Update
- Document new auto-delegation patterns
- Add model selection decision tree
- Include override examples

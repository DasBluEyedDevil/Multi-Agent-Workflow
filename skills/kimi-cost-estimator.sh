#!/usr/bin/env bash
# kimi-cost-estimator.sh -- Cost estimation for Kimi CLI delegation
#
# Usage: ./kimi-cost-estimator.sh --prompt "text" --files "file1,file2" --model k2
#   Or: source kimi-cost-estimator.sh && estimate_cost "prompt" "files" "model"
#
# This script provides cost estimation before delegation to help users
# understand the expected token usage and cost implications.

set -euo pipefail

# -- Constants ----------------------------------------------------------------
readonly COST_ESTIMATOR_VERSION="1.0.0"

# Script directory
COST_ESTIMATOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_INVALID_ARGS=10
readonly EXIT_CONFIG_ERROR=11

# Model cost multipliers (K2.5 costs 1.5x more than K2)
declare -A MODEL_MULTIPLIER=(
    ["k2"]=1.0
    ["k2.5"]=1.5
    ["k2_5"]=1.5
)

# Confidence and cost thresholds
readonly DEFAULT_CONFIDENCE_THRESHOLD=75
readonly DEFAULT_COST_THRESHOLD=10000

# -- Logging ------------------------------------------------------------------
log_error() { echo "[cost-estimator] Error: $1" >&2; }
log_warn() { echo "[cost-estimator] Warning: $1" >&2; }
log_info() { echo "[cost-estimator] Info: $1" >&2; }

# -- Token Estimation ---------------------------------------------------------

# estimate_tokens(text_content)
# Estimates token count from text content using character count / 4 heuristic
# Arguments:
#   $1 - Text content to estimate
# Returns:
#   Integer token estimate
estimate_tokens() {
    local text_content="$1"
    local char_count=${#text_content}
    
    # Simple heuristic: ~4 characters per token
    local token_estimate=$((char_count / 4))
    
    # Ensure at least 1 token for non-empty content
    if [[ $char_count -gt 0 && $token_estimate -eq 0 ]]; then
        token_estimate=1
    fi
    
    echo "$token_estimate"
}

# -- Cost Estimation ----------------------------------------------------------

# estimate_cost(prompt, file_paths..., model)
# Estimates the cost of a delegation based on prompt and files
# Arguments:
#   $1 - Prompt text
#   $2... - File paths (optional, multiple)
#   ${!#} - Model name (k2 or k2.5)
# Returns:
#   Normalized cost units (integer)
estimate_cost() {
    local prompt="$1"
    shift
    
    # Get model from last argument
    local model="${!#}"
    
    # Get files (all but last argument)
    local files=()
    if [[ $# -gt 1 ]]; then
        files=("${@:1:$#-1}")
    fi
    
    # Count characters in prompt
    local prompt_chars=${#prompt}
    local total_chars=$prompt_chars
    
    # Count characters in files (if readable)
    local file_chars=0
    for file in "${files[@]}"; do
        [[ -z "$file" ]] && continue
        
        if [[ -r "$file" && -f "$file" ]]; then
            # Use wc -c for file size (faster than reading entire file)
            local size
            size=$(wc -c < "$file" 2>/dev/null || echo 0)
            file_chars=$((file_chars + size))
        fi
    done
    
    total_chars=$((total_chars + file_chars))
    
    # Estimate tokens (chars / 4)
    local estimated_tokens=$((total_chars / 4))
    
    # Ensure at least 1 token
    [[ $estimated_tokens -eq 0 ]] && estimated_tokens=1
    
    # Apply model multiplier
    local multiplier="${MODEL_MULTIPLIER[$model]:-1.0}"
    
    # Calculate normalized cost (multiply by 10 to preserve some precision, then integer)
    # Using awk for floating point math if available, otherwise bash approximation
    local normalized_cost
    if command -v awk >/dev/null 2>&1; then
        normalized_cost=$(awk "BEGIN {printf \"%.0f\", $estimated_tokens * $multiplier}")
    else
        # Fallback: rough integer approximation
        if [[ "$multiplier" == "1.5" ]]; then
            normalized_cost=$((estimated_tokens + estimated_tokens / 2))
        else
            normalized_cost=$estimated_tokens
        fi
    fi
    
    echo "$normalized_cost"
}

# -- Cost Display -------------------------------------------------------------

# display_cost(cost_units, model)
# Displays cost estimate in human-readable format
# Arguments:
#   $1 - Cost units (normalized cost from estimate_cost)
#   $2 - Model name (k2 or k2.5)
# Returns:
#   Human-readable description on stdout
display_cost() {
    local cost_units="$1"
    local model="$2"
    
    # Determine speed category
    local speed_category
    if [[ $cost_units -lt 1000 ]]; then
        speed_category="fast"
    elif [[ $cost_units -lt 5000 ]]; then
        speed_category="moderate"
    else
        speed_category="may take time"
    fi
    
    # Format with commas for readability (if printf supports)
    local formatted_cost
    if command -v printf >/dev/null 2>&1; then
        formatted_cost=$(printf "%'d" "$cost_units" 2>/dev/null || echo "$cost_units")
    else
        formatted_cost="$cost_units"
    fi
    
    echo "~$formatted_cost tokens ($model, $speed_category)"
}

# -- User Prompt Decision -----------------------------------------------------

# should_prompt_user(confidence, cost_units)
# Determines if user should be prompted before delegation
# Arguments:
#   $1 - Confidence score (0-100)
#   $2 - Cost units (from estimate_cost)
# Returns:
#   "true" if user should be prompted, "false" otherwise
should_prompt_user() {
    local confidence="${1:-0}"
    local cost_units="${2:-0}"
    
    # Get thresholds from environment or use defaults
    local conf_threshold="${KIMI_CONFIDENCE_THRESHOLD:-$DEFAULT_CONFIDENCE_THRESHOLD}"
    local cost_threshold="${KIMI_COST_THRESHOLD:-$DEFAULT_COST_THRESHOLD}"
    
    # Prompt if confidence is low OR cost is high
    if [[ $confidence -lt $conf_threshold ]]; then
        echo "true"
        return 0
    fi
    
    if [[ $cost_units -gt $cost_threshold ]]; then
        echo "true"
        return 0
    fi
    
    echo "false"
}

# -- CLI Interface ------------------------------------------------------------

# show_help()
# Displays usage information
show_help() {
    cat <<EOF
Kimi Cost Estimator v${COST_ESTIMATOR_VERSION}

Usage: $(basename "$0") [OPTIONS]

Options:
  --prompt "TEXT"         Prompt text to analyze (required)
  --files "FILE1,FILE2"   Comma-separated list of file paths (optional)
  --model MODEL           Model to use: k2 or k2.5 (default: k2)
  --json                  Output results as JSON (default: text)
  --help                  Show this help message

Environment Variables:
  KIMI_CONFIDENCE_THRESHOLD  Minimum confidence before prompting (default: 75)
  KIMI_COST_THRESHOLD        Maximum cost before prompting (default: 10000)

Examples:
  $(basename "$0") --prompt "refactor this code" --files "src/main.py" --model k2
  $(basename "$0") --prompt "create component" --files "src/App.tsx" --model k2.5 --json
  $(basename "$0") --prompt "simple task" --json

Exit Codes:
  0  - Success
  10 - Invalid arguments
  11 - Configuration error
EOF
}

# parse_arguments()
# Parses command line arguments
# Sets global variables: PROMPT_TEXT, FILES_ARRAY, MODEL, OUTPUT_JSON
declare -a FILES_ARRAY=()
declare PROMPT_TEXT=""
declare MODEL="k2"
declare OUTPUT_JSON=false

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --prompt)
                if [[ -n "${2:-}" && ! "${2:-}" =~ ^-- ]]; then
                    PROMPT_TEXT="$2"
                    shift 2
                else
                    log_error "--prompt requires a value"
                    return $EXIT_INVALID_ARGS
                fi
                ;;
            --files)
                if [[ -n "${2:-}" && ! "${2:-}" =~ ^-- ]]; then
                    # Split comma-separated files into array
                    IFS=',' read -ra FILES_ARRAY <<< "$2"
                    shift 2
                else
                    log_error "--files requires a value"
                    return $EXIT_INVALID_ARGS
                fi
                ;;
            --model)
                if [[ -n "${2:-}" && ! "${2:-}" =~ ^-- ]]; then
                    MODEL="$2"
                    shift 2
                else
                    log_error "--model requires a value"
                    return $EXIT_INVALID_ARGS
                fi
                ;;
            --json)
                OUTPUT_JSON=true
                shift
                ;;
            --help|-h)
                show_help
                exit $EXIT_SUCCESS
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                return $EXIT_INVALID_ARGS
                ;;
        esac
    done
    
    # Validate required arguments
    if [[ -z "$PROMPT_TEXT" ]]; then
        log_error "--prompt is required"
        show_help
        return $EXIT_INVALID_ARGS
    fi
    
    # Validate model
    local normalized_model
    normalized_model=$(echo "$MODEL" | tr '[:upper:]' '[:lower:]')
    if [[ "$normalized_model" != "k2" && "$normalized_model" != "k2.5" && "$normalized_model" != "k2_5" ]]; then
        log_error "Invalid model: $MODEL (expected: k2 or k2.5)"
        return $EXIT_INVALID_ARGS
    fi
    
    # Normalize model name
    if [[ "$normalized_model" == "k2_5" ]]; then
        MODEL="k2.5"
    else
        MODEL="$normalized_model"
    fi
    
    return $EXIT_SUCCESS
}

# main()
# Main entry point for CLI execution
main() {
    # Parse arguments
    if ! parse_arguments "$@"; then
        exit $EXIT_INVALID_ARGS
    fi
    
    # Estimate cost
    local cost_units
    if [[ ${#FILES_ARRAY[@]} -gt 0 ]]; then
        cost_units=$(estimate_cost "$PROMPT_TEXT" "${FILES_ARRAY[@]}" "$MODEL")
    else
        cost_units=$(estimate_cost "$PROMPT_TEXT" "$MODEL")
    fi
    
    # Output result
    if $OUTPUT_JSON; then
        # Calculate token estimate separately for JSON output
        local prompt_tokens
        prompt_tokens=$(estimate_tokens "$PROMPT_TEXT")
        
        local file_tokens=0
        for file in "${FILES_ARRAY[@]}"; do
            [[ -z "$file" ]] && continue
            if [[ -r "$file" && -f "$file" ]]; then
                local size
                size=$(wc -c < "$file" 2>/dev/null || echo 0)
                file_tokens=$((file_tokens + size / 4))
            fi
        done
        
        cat <<EOF
{"cost_units": $cost_units, "estimated_tokens": $((prompt_tokens + file_tokens)), "model": "$MODEL", "multiplier": ${MODEL_MULTIPLIER[$MODEL]}}
EOF
    else
        # Text output
        local cost_display
        cost_display=$(display_cost "$cost_units" "$MODEL")
        echo "Cost estimate: $cost_display"
    fi
    
    exit $EXIT_SUCCESS
}

# -- Export Functions ---------------------------------------------------------
# Make functions available when sourced
export -f estimate_tokens 2>/dev/null || true
export -f estimate_cost 2>/dev/null || true
export -f display_cost 2>/dev/null || true
export -f should_prompt_user 2>/dev/null || true

# Run main if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

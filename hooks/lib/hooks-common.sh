#!/bin/bash
#
# Common Hooks Library for Kimi Git Hooks
#
# Purpose: Shared functions used by all git hook scripts
#
# Usage:
#   source "${HOOKS_ROOT}/lib/hooks-common.sh"
#
# Dependencies:
#   - hooks-config.sh (must be sourced first)
#   - jq (for JSON operations)
#   - kimi CLI (for MCP tool calls)
#

# Ensure dependencies are loaded
if ! declare -f hooks_config_load >/dev/null 2>&1; then
    echo "Error: hooks-config.sh must be sourced before hooks-common.sh" >&2
    exit 1
fi

# ============================================================================
# Hook Initialization
# ============================================================================

# Initialize a hook: check bypass, load config, check enabled
# Args:
#   $1 - Hook type (pre-commit, post-checkout, pre-push)
# Returns:
#   0 if hook should proceed, 1 if should skip
hooks_init() {
    local hook_type="$1"
    
    # Check bypass conditions
    if hooks_check_bypass; then
        hooks_log_debug "Hook bypassed via environment"
        return 1
    fi
    
    # Check recursion prevention
    if [[ -n "${KIMI_HOOKS_RUNNING:-}" ]]; then
        hooks_log_debug "Hook recursion detected, skipping"
        return 1
    fi
    
    # Set recursion prevention flag
    export KIMI_HOOKS_RUNNING=1
    
    # Set up cleanup trap
    trap hooks_cleanup EXIT
    
    # Load configuration
    if ! hooks_config_load; then
        hooks_log_error "Failed to load configuration"
        hooks_cleanup
        return 1
    fi
    
    # Check if this hook type is enabled
    if ! hooks_config_is_enabled "$hook_type"; then
        hooks_log_debug "Hook '$hook_type' is disabled"
        return 1
    fi
    
    hooks_log_debug "Hook '$hook_type' initialized successfully"
    return 0
}

# ============================================================================
# Bypass and Configuration Checks
# ============================================================================

# Check if hooks should be bypassed
# Returns:
#   0 if should bypass, 1 if should run
hooks_check_bypass() {
    # Check environment variable bypass
    local bypass_var="${KIMI_HOOKS_BYPASS_VAR:-KIMI_HOOKS_SKIP}"
    local bypass_value="${!bypass_var:-}"
    
    if [[ -n "$bypass_value" && "$bypass_value" != "0" && "$bypass_value" != "false" && "$bypass_value" != "" ]]; then
        hooks_log_info "Hooks bypassed via \$$bypass_var"
        return 0
    fi
    
    # Check git config bypass
    if [[ "$(git config --get kimi.hooks.skip 2>/dev/null || echo "false")" == "true" ]]; then
        hooks_log_info "Hooks bypassed via git config (kimi.hooks.skip)"
        return 0
    fi
    
    return 1
}

# ============================================================================
# File Operations
# ============================================================================

# Get changed files based on hook type
# Args:
#   $1 - Hook type (pre-commit, post-checkout, pre-push)
#   $2 - Additional args (for post-checkout: old_ref new_ref)
# Output:
#   List of file paths (one per line)
hooks_get_changed_files() {
    local hook_type="$1"
    local files=""
    
    case "$hook_type" in
        "pre-commit")
            # Get staged files
            files=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)
            ;;
        "post-checkout")
            # Get files changed between refs
            local old_ref="${2:-}"
            local new_ref="${3:-}"
            if [[ -n "$old_ref" && -n "$new_ref" ]]; then
                files=$(git diff --name-only "$old_ref" "$new_ref" 2>/dev/null || true)
            fi
            ;;
        "pre-push")
            # Get files being pushed
            # Try @{push} first, fall back to origin/HEAD
            files=$(git diff --name-only @{push}..HEAD 2>/dev/null || \
                    git diff --name-only origin/HEAD..HEAD 2>/dev/null || \
                    git diff --name-only HEAD~10..HEAD 2>/dev/null || true)
            ;;
        *)
            hooks_log_error "Unknown hook type: $hook_type"
            return 1
            ;;
    esac
    
    echo "$files"
}

# Filter files to only those matching configured patterns
# Args:
#   $1 - List of files (newline-separated)
# Output:
#   Filtered list of files matching patterns
hooks_filter_files() {
    local files="$1"
    local patterns
    patterns=$(hooks_config_file_patterns)
    
    # If no patterns configured, return all files
    if [[ -z "$patterns" || "$patterns" == "[]" || "$patterns" == "null" ]]; then
        echo "$files"
        return 0
    fi
    
    # Convert patterns to grep pattern
    local grep_pattern=""
    local pattern_array
    pattern_array=$(echo "$patterns" | jq -r '.[]' 2>/dev/null || true)
    
    while IFS= read -r pattern; do
        [[ -z "$pattern" ]] && continue
        # Convert glob to regex (basic conversion)
        local regex_pattern="${pattern//\*\.\*/.*}"
        regex_pattern="${regex_pattern//\*/[^/]*}"
        regex_pattern="${regex_pattern//\?/.}"
        if [[ -n "$grep_pattern" ]]; then
            grep_pattern="${grep_pattern}|${regex_pattern}"
        else
            grep_pattern="${regex_pattern}"
        fi
    done <<< "$pattern_array"
    
    # Filter files
    if [[ -n "$grep_pattern" ]]; then
        echo "$files" | grep -E "($grep_pattern)" 2>/dev/null || true
    else
        echo "$files"
    fi
}

# Check if any files match the configured patterns
# Args:
#   $1 - List of files (newline-separated)
# Returns:
#   0 if at least one file matches, 1 otherwise
hooks_has_matching_files() {
    local files="$1"
    local filtered
    filtered=$(hooks_filter_files "$files")
    
    [[ -n "$filtered" ]]
}

# ============================================================================
# Kimi MCP Tool Calls
# ============================================================================

# Run Kimi analysis via MCP
# Args:
#   $1 - Prompt for analysis
#   $2 - JSON array of file paths
#   $3 - Optional context
# Output:
#   Analysis result (or empty on timeout/error)
hooks_run_analysis() {
    local prompt="$1"
    local files="${2:-[]}"
    local context="${3:-}"
    
    # Check dry-run mode
    if [[ "$(hooks_config_is_dry_run)" == "true" ]]; then
        hooks_log_info "[DRY-RUN] Would analyze files: $files"
        return 0
    fi
    
    # Get timeout
    local timeout_val
    timeout_val=$(hooks_config_timeout)
    
    # Build JSON-RPC request for kimi_analyze tool
    local request
    request=$(jq -n \
        --arg prompt "$prompt" \
        --argjson files "$files" \
        --arg context "$context" \
        '{
            jsonrpc: "2.0",
            id: "hooks-analysis",
            method: "tools/call",
            params: {
                name: "kimi_analyze",
                arguments: {
                    prompt: $prompt,
                    files: $files,
                    context: $context
                }
            }
        }')
    
    # Call kimi-mcp with timeout
    local result
    local exit_code
    
    result=$(timeout "$timeout_val" kimi-mcp call 2>&1 <<< "$request" || true)
    exit_code=$?
    
    if [[ $exit_code -eq 124 ]]; then
        hooks_log_error "Analysis timed out after ${timeout_val}s"
        return 1
    elif [[ $exit_code -ne 0 ]]; then
        hooks_log_error "Analysis failed: $result"
        return 1
    fi
    
    # Extract result from JSON-RPC response
    local extracted
    extracted=$(echo "$result" | jq -r '.result.content[0].text // empty' 2>/dev/null || true)
    
    if [[ -n "$extracted" ]]; then
        echo "$extracted"
    else
        # Return raw result if extraction failed
        echo "$result"
    fi
}

# Run Kimi implement via MCP
# Args:
#   $1 - Prompt for implementation
#   $2 - JSON array of file paths
# Output:
#   Implementation result (or empty on timeout/error)
hooks_run_implement() {
    local prompt="$1"
    local files="${2:-[]}"
    
    # Check dry-run mode
    if [[ "$(hooks_config_is_dry_run)" == "true" ]]; then
        hooks_log_info "[DRY-RUN] Would implement changes for files: $files"
        return 0
    fi
    
    # Get timeout
    local timeout_val
    timeout_val=$(hooks_config_timeout)
    
    # Build JSON-RPC request for kimi_implement tool
    local request
    request=$(jq -n \
        --arg prompt "$prompt" \
        --argjson files "$files" \
        '{
            jsonrpc: "2.0",
            id: "hooks-implement",
            method: "tools/call",
            params: {
                name: "kimi_implement",
                arguments: {
                    prompt: $prompt,
                    files: $files
                }
            }
        }')
    
    # Call kimi-mcp with timeout
    local result
    local exit_code
    
    result=$(timeout "$timeout_val" kimi-mcp call 2>&1 <<< "$request" || true)
    exit_code=$?
    
    if [[ $exit_code -eq 124 ]]; then
        hooks_log_error "Implementation timed out after ${timeout_val}s"
        return 1
    elif [[ $exit_code -ne 0 ]]; then
        hooks_log_error "Implementation failed: $result"
        return 1
    fi
    
    # Extract result from JSON-RPC response
    local extracted
    extracted=$(echo "$result" | jq -r '.result.content[0].text // empty' 2>/dev/null || true)
    
    if [[ -n "$extracted" ]]; then
        echo "$extracted"
    else
        echo "$result"
    fi
}

# ============================================================================
# Cleanup
# ============================================================================

# Cleanup function called on exit
# Restores stashed changes if needed and unsets recursion flag
hooks_cleanup() {
    # Unset recursion prevention flag
    unset KIMI_HOOKS_RUNNING
    
    # Clear trap
    trap - EXIT
    
    hooks_log_debug "Hook cleanup complete"
}

# ============================================================================
# Logging
# ============================================================================

# Log info message to stderr
# Args:
#   $1 - Message to log
hooks_log_info() {
    echo "[kimi-hooks] $1" >&2
}

# Log error message to stderr
# Args:
#   $1 - Error message to log
hooks_log_error() {
    echo "[kimi-hooks] ERROR: $1" >&2
}

# Log debug message to stderr (only if KIMI_HOOKS_DEBUG=1)
# Args:
#   $1 - Debug message to log
hooks_log_debug() {
    if [[ "${KIMI_HOOKS_DEBUG:-0}" == "1" ]]; then
        echo "[kimi-hooks] DEBUG: $1" >&2
    fi
}

# ============================================================================
# Export Functions
# ============================================================================

export -f hooks_init
export -f hooks_check_bypass
export -f hooks_get_changed_files
export -f hooks_filter_files
export -f hooks_has_matching_files
export -f hooks_run_analysis
export -f hooks_run_implement
export -f hooks_cleanup
export -f hooks_log_info
export -f hooks_log_error
export -f hooks_log_debug

#!/usr/bin/env bats
#
# Tool Handler Tests for Kimi MCP Server
#
# Purpose: Test the MCP tool handlers (kimi_analyze, kimi_implement,
#          kimi_refactor, kimi_verify) and tool definitions.
#
# Dependencies:
#   - bats (Bash Automated Testing System)
#   - mcp-errors.sh, mcp-core.sh, config.sh, file-reader.sh, mcp-tools.sh
#
# Usage:
#   bats mcp-bridge/tests/test-tools.bats

# Setup - source all dependencies
setup() {
    # Determine test directory
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    LIB_DIR="${TEST_DIR}/../lib"
    CONFIG_DIR="${TEST_DIR}/../config"

    # Export for use in tests
    export MCP_BRIDGE_ROOT="${TEST_DIR}/.."

    # Source all library files
    source "${LIB_DIR}/mcp-errors.sh"
    source "${LIB_DIR}/mcp-core.sh"
    source "${LIB_DIR}/config.sh"
    source "${LIB_DIR}/file-reader.sh"
    source "${LIB_DIR}/mcp-tools.sh"

    # Load configuration
    mcp_config_load >/dev/null 2>&1 || true
}

# ============================================================================
# Tool Definitions Tests
# ============================================================================

@test "tool definitions returns valid JSON" {
    result=$(mcp_get_tool_definitions)
    [ -n "$result" ]
    echo "$result" | jq -e '.' >/dev/null 2>&1
}

@test "tool definitions has exactly 4 tools" {
    result=$(mcp_get_tool_definitions)
    count=$(echo "$result" | jq '.tools | length')
    [ "$count" -eq 4 ]
}

@test "kimi_analyze tool has required fields" {
    result=$(mcp_get_tool_definitions)
    echo "$result" | jq -e '.tools[] | select(.name == "kimi_analyze") | has("name")' >/dev/null
    echo "$result" | jq -e '.tools[] | select(.name == "kimi_analyze") | has("title")' >/dev/null
    echo "$result" | jq -e '.tools[] | select(.name == "kimi_analyze") | has("description")' >/dev/null
    echo "$result" | jq -e '.tools[] | select(.name == "kimi_analyze") | has("inputSchema")' >/dev/null
}

@test "kimi_analyze has role parameter with default" {
    result=$(mcp_get_tool_definitions)
    default=$(echo "$result" | jq -r '.tools[] | select(.name == "kimi_analyze") | .inputSchema.properties.role.default')
    [ "$default" = "general" ]
}

@test "kimi_implement tool has required fields" {
    result=$(mcp_get_tool_definitions)
    echo "$result" | jq -e '.tools[] | select(.name == "kimi_implement") | has("name")' >/dev/null
    echo "$result" | jq -e '.tools[] | select(.name == "kimi_implement") | has("title")' >/dev/null
    echo "$result" | jq -e '.tools[] | select(.name == "kimi_implement") | has("description")' >/dev/null
    echo "$result" | jq -e '.tools[] | select(.name == "kimi_implement") | has("inputSchema")' >/dev/null
}

@test "kimi_refactor tool has required fields" {
    result=$(mcp_get_tool_definitions)
    echo "$result" | jq -e '.tools[] | select(.name == "kimi_refactor") | has("name")' >/dev/null
    echo "$result" | jq -e '.tools[] | select(.name == "kimi_refactor") | has("title")' >/dev/null
    echo "$result" | jq -e '.tools[] | select(.name == "kimi_refactor") | has("description")' >/dev/null
    echo "$result" | jq -e '.tools[] | select(.name == "kimi_refactor") | has("inputSchema")' >/dev/null
}

@test "kimi_refactor has safety_checks parameter with default true" {
    result=$(mcp_get_tool_definitions)
    default=$(echo "$result" | jq -r '.tools[] | select(.name == "kimi_refactor") | .inputSchema.properties.safety_checks.default')
    [ "$default" = "true" ]
}

@test "kimi_verify tool has required fields" {
    result=$(mcp_get_tool_definitions)
    echo "$result" | jq -e '.tools[] | select(.name == "kimi_verify") | has("name")' >/dev/null
    echo "$result" | jq -e '.tools[] | select(.name == "kimi_verify") | has("title")' >/dev/null
    echo "$result" | jq -e '.tools[] | select(.name == "kimi_verify") | has("description")' >/dev/null
    echo "$result" | jq -e '.tools[] | select(.name == "kimi_verify") | has("inputSchema")' >/dev/null
}

@test "all tools require prompt parameter" {
    result=$(mcp_get_tool_definitions)
    for tool in kimi_analyze kimi_implement kimi_refactor kimi_verify; do
        required=$(echo "$result" | jq -r ".tools[] | select(.name == \"$tool\") | .inputSchema.required | contains([\"prompt\"])")
        [ "$required" = "true" ]
    done
}

# ============================================================================
# Parameter Extraction Tests
# ============================================================================

@test "kimi_analyze extracts all parameters correctly" {
    # Mock mcp_send_response to capture the call
    mock_response=""
    mcp_send_response() {
        mock_response="$2"
    }

    # Test with all parameters
    args='{"prompt": "test prompt", "files": ["/tmp/test.txt"], "context": "extra context", "role": "security"}'
    mcp_tool_analyze "$args" "test-id"

    # Verify the prompt was built (we can't easily check internal state,
    # but we can verify the function ran without error)
    [ -n "$mock_response" ]
}

@test "kimi_analyze validates missing prompt parameter" {
    # Mock mcp_send_response to capture error
    mock_error=""
    mock_is_error=""
    mcp_send_response() {
        mock_error="$2"
        mock_is_error="$3"
    }

    # Test without required prompt
    args='{"role": "security"}'
    mcp_tool_analyze "$args" "test-id"

    [ "$mock_is_error" = "true" ]
    [[ "$mock_error" == *"Missing required parameter"* ]]
}

@test "kimi_implement validates missing prompt parameter" {
    mock_error=""
    mock_is_error=""
    mcp_send_response() {
        mock_error="$2"
        mock_is_error="$3"
    }

    args='{"constraints": "use bash"}'
    mcp_tool_implement "$args" "test-id"

    [ "$mock_is_error" = "true" ]
    [[ "$mock_error" == *"Missing required parameter"* ]]
}

@test "kimi_refactor validates missing prompt parameter" {
    mock_error=""
    mock_is_error=""
    mcp_send_response() {
        mock_error="$2"
        mock_is_error="$3"
    }

    args='{"safety_checks": false}'
    mcp_tool_refactor "$args" "test-id"

    [ "$mock_is_error" = "true" ]
    [[ "$mock_error" == *"Missing required parameter"* ]]
}

@test "kimi_verify validates missing prompt parameter" {
    mock_error=""
    mock_is_error=""
    mcp_send_response() {
        mock_error="$2"
        mock_is_error="$3"
    }

    args='{"requirements": "must work"}'
    mcp_tool_verify "$args" "test-id"

    [ "$mock_is_error" = "true" ]
    [[ "$mock_error" == *"Missing required parameter"* ]]
}

# ============================================================================
# Optional Parameter Defaults Tests
# ============================================================================

@test "kimi_analyze defaults role to general" {
    # Create a test file
    echo "test content" > /tmp/mcp_test_file.txt

    # Mock mcp_send_response
    mcp_send_response() {
        :
    }

    # Mock mcp_call_kimi to capture the prompt
    captured_prompt=""
    mcp_call_kimi() {
        captured_prompt="$1"
        echo "mock result"
    }

    # Call without specifying role
    args='{"prompt": "analyze this"}'
    mcp_tool_analyze "$args" "test-id"

    # Should include general role system prompt
    [[ "$captured_prompt" == *"helpful coding assistant"* ]]

    # Cleanup
    rm -f /tmp/mcp_test_file.txt
}

@test "kimi_refactor defaults safety_checks to true" {
    mcp_send_response() {
        :
    }

    captured_prompt=""
    mcp_call_kimi() {
        captured_prompt="$1"
        echo "mock result"
    }

    # Call without specifying safety_checks
    args='{"prompt": "refactor this"}'
    mcp_tool_refactor "$args" "test-id"

    # Should include safety instruction
    [[ "$captured_prompt" == *"safety checks pass"* ]]
}

@test "kimi_refactor respects safety_checks false" {
    mcp_send_response() {
        :
    }

    captured_prompt=""
    mcp_call_kimi() {
        captured_prompt="$1"
        echo "mock result"
    }

    # Call with safety_checks disabled
    args='{"prompt": "refactor this", "safety_checks": false}'
    mcp_tool_refactor "$args" "test-id"

    # Should NOT include safety instruction
    [[ "$captured_prompt" != *"safety checks pass"* ]]
}

# ============================================================================
# File Reading Integration Tests
# ============================================================================

@test "kimi_analyze includes file contents when files provided" {
    # Create test files
    echo "file1 content" > /tmp/mcp_test1.txt
    echo "file2 content" > /tmp/mcp_test2.txt

    mcp_send_response() {
        :
    }

    captured_prompt=""
    mcp_call_kimi() {
        captured_prompt="$1"
        echo "mock result"
    }

    # Call with files
    args='{"prompt": "analyze these", "files": ["/tmp/mcp_test1.txt", "/tmp/mcp_test2.txt"]}'
    mcp_tool_analyze "$args" "test-id"

    # Should include file contents
    [[ "$captured_prompt" == *"file1 content"* ]]
    [[ "$captured_prompt" == *"file2 content"* ]]

    # Cleanup
    rm -f /tmp/mcp_test1.txt /tmp/mcp_test2.txt
}

@test "kimi_analyze skips non-existent files" {
    mcp_send_response() {
        :
    }

    captured_prompt=""
    mcp_call_kimi() {
        captured_prompt="$1"
        echo "mock result"
    }

    # Call with mix of existing and non-existing files
    echo "exists" > /tmp/mcp_exists.txt
    args='{"prompt": "analyze", "files": ["/tmp/mcp_exists.txt", "/tmp/nonexistent.txt"]}'
    mcp_tool_analyze "$args" "test-id"

    # Should include existing file but not fail on non-existing
    [[ "$captured_prompt" == *"exists"* ]]

    # Cleanup
    rm -f /tmp/mcp_exists.txt
}

@test "kimi_implement includes constraints when provided" {
    mcp_send_response() {
        :
    }

    captured_prompt=""
    mcp_call_kimi() {
        captured_prompt="$1"
        echo "mock result"
    }

    # Call with constraints
    args='{"prompt": "implement feature", "constraints": "use pure bash"}'
    mcp_tool_implement "$args" "test-id"

    # Should include constraints
    [[ "$captured_prompt" == *"use pure bash"* ]]
}

@test "kimi_verify includes requirements when provided" {
    mcp_send_response() {
        :
    }

    captured_prompt=""
    mcp_call_kimi() {
        captured_prompt="$1"
        echo "mock result"
    }

    # Call with requirements
    args='{"prompt": "verify this", "requirements": "must handle errors gracefully"}'
    mcp_tool_verify "$args" "test-id"

    # Should include requirements
    [[ "$captured_prompt" == *"must handle errors gracefully"* ]]
}

# ============================================================================
# Context Addition Tests
# ============================================================================

@test "kimi_analyze includes context when provided" {
    mcp_send_response() {
        :
    }

    captured_prompt=""
    mcp_call_kimi() {
        captured_prompt="$1"
        echo "mock result"
    }

    # Call with context
    args='{"prompt": "analyze", "context": "This is a legacy codebase"}'
    mcp_tool_analyze "$args" "test-id"

    # Should include context
    [[ "$captured_prompt" == *"This is a legacy codebase"* ]]
}

# ============================================================================
# Prompt Building Tests
# ============================================================================

@test "kimi_analyze uses correct system prompt for security role" {
    mcp_send_response() {
        :
    }

    captured_prompt=""
    mcp_call_kimi() {
        captured_prompt="$1"
        echo "mock result"
    }

    # Call with security role
    args='{"prompt": "analyze", "role": "security"}'
    mcp_tool_analyze "$args" "test-id"

    # Should include security system prompt
    [[ "$captured_prompt" == *"security-focused code reviewer"* ]]
}

@test "kimi_analyze uses correct system prompt for performance role" {
    mcp_send_response() {
        :
    }

    captured_prompt=""
    mcp_call_kimi() {
        captured_prompt="$1"
        echo "mock result"
    }

    # Call with performance role
    args='{"prompt": "analyze", "role": "performance"}'
    mcp_tool_analyze "$args" "test-id"

    # Should include performance system prompt
    [[ "$captured_prompt" == *"performance optimization expert"* ]]
}

@test "kimi_analyze falls back to general role for unknown role" {
    mcp_send_response() {
        :
    }

    captured_prompt=""
    mcp_call_kimi() {
        captured_prompt="$1"
        echo "mock result"
    }

    # Call with unknown role
    args='{"prompt": "analyze", "role": "unknown_role"}'
    mcp_tool_analyze "$args" "test-id"

    # Should fall back to general role
    [[ "$captured_prompt" == *"helpful coding assistant"* ]]
}

# ============================================================================
# Kimi CLI Call Tests
# ============================================================================

@test "mcp_call_kimi validates model parameter" {
    result=$(mcp_call_kimi "test" "invalid_model" 30 2>&1)
    [ $? -ne 0 ]
    [[ "$result" == *"Invalid model"* ]]
}

@test "mcp_call_kimi accepts k2 model" {
    # Mock kimi command for testing
    kimi() {
        echo "mock k2 response"
    }
    export -f kimi

    result=$(mcp_call_kimi "test prompt" "k2" 30)
    [[ "$result" == *"mock k2 response"* ]]
}

@test "mcp_call_kimi accepts k2.5 model" {
    # Mock kimi command for testing
    kimi() {
        echo "mock k2.5 response"
    }
    export -f kimi

    result=$(mcp_call_kimi "test prompt" "k2.5" 30)
    [[ "$result" == *"mock k2.5 response"* ]]
}

@test "mcp_call_kimi reports error when kimi not found" {
    # Ensure kimi is not in PATH for this test
    PATH="/usr/bin:/bin"
    result=$(mcp_call_kimi "test" "k2" 30 2>&1)
    [ $? -ne 0 ]
    [[ "$result" == *"kimi CLI not found"* ]]
}

# ============================================================================
# Error Handling Tests
# ============================================================================

@test "tool handlers return error response on kimi failure" {
    # Mock kimi to simulate failure
    kimi() {
        echo "Error: API rate limit exceeded" >&2
        return 1
    }
    export -f kimi

    mock_error=""
    mock_is_error=""
    mcp_send_response() {
        mock_error="$2"
        mock_is_error="$3"
    }

    args='{"prompt": "test"}'
    mcp_tool_analyze "$args" "test-id"

    [ "$mock_is_error" = "true" ]
    [[ "$mock_is_error" == *"true"* ]]
}

@test "tool handlers include exit code in error message" {
    # Mock kimi to simulate failure with exit code
    kimi() {
        return 5
    }
    export -f kimi

    mock_error=""
    mcp_send_response() {
        mock_error="$2"
        mock_is_error="$3"
    }

    args='{"prompt": "test"}'
    mcp_tool_analyze "$args" "test-id"

    [[ "$mock_error" == *"exit code"* ]]
}

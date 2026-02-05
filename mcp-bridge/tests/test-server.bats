#!/usr/bin/env bats
#
# Integration tests for Kimi MCP Server
#
# Tests the full server lifecycle: initialize, tools/list, tools/call, errors

# Setup - runs before each test
setup() {
    # Determine test directory and MCP_BRIDGE_ROOT
    TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    MCP_BRIDGE_ROOT="$(dirname "$TEST_DIR")"
    export MCP_BRIDGE_ROOT
    
    # Path to server executable
    SERVER="${MCP_BRIDGE_ROOT}/bin/kimi-mcp-server"
    
    # Verify server exists
    [ -x "$SERVER" ] || skip "Server not found or not executable: $SERVER"
    
    # Check dependencies
    command -v jq >/dev/null 2>&1 || skip "jq not installed"
}

# Helper function to send a JSON-RPC request
# Usage: send_request method params id
send_request() {
    local method="$1"
    local params="${2:-{}}"
    local id="${3:-1}"
    
    jq -n \
        --arg method "$method" \
        --argjson params "$params" \
        --arg id "$id" \
        '{jsonrpc: "2.0", id: $id, method: $method, params: $params}'
}

# Helper function to send request and get response
# Usage: send_and_receive method params id
send_and_receive() {
    local method="$1"
    local params="${2:-{}}"
    local id="${3:-1}"
    
    local request
    request=$(send_request "$method" "$params" "$id")
    
    # Send to server, capture stdout (ignore stderr for logs)
    echo "$request" | "$SERVER" 2>/dev/null
}

# ============================================================================
# Test: Server responds to initialize
# ============================================================================
@test "server responds to initialize with correct protocol version" {
    local request
    request=$(send_request "initialize" '{"protocolVersion": "2025-11-25"}' "init-1")
    
    local response
    response=$(echo "$request" | "$SERVER" 2>/dev/null)
    
    # Verify response is valid JSON
    echo "$response" | jq empty
    
    # Verify protocol version
    [ "$(echo "$response" | jq -r '.result.protocolVersion')" = "2025-11-25" ]
    
    # Verify server info
    [ "$(echo "$response" | jq -r '.result.serverInfo.name')" = "kimi-mcp-server" ]
    [ "$(echo "$response" | jq -r '.result.serverInfo.version')" = "1.0.0" ]
    
    # Verify capabilities
    [ "$(echo "$response" | jq -r '.result.capabilities.tools.listChanged')" = "false" ]
    
    # Verify ID is preserved
    [ "$(echo "$response" | jq -r '.id')" = "init-1" ]
}

# ============================================================================
# Test: Server returns 4 tool definitions
# ============================================================================
@test "server returns 4 tool definitions" {
    local response
    response=$(send_and_receive "tools/list" '{}' 'tools-1')
    
    # Verify response is valid JSON
    echo "$response" | jq empty
    
    # Verify we have 4 tools
    local tool_count
    tool_count=$(echo "$response" | jq '.result.tools | length')
    [ "$tool_count" -eq 4 ]
    
    # Verify all expected tools exist
    echo "$response" | jq -e '.result.tools[] | select(.name == "kimi_analyze")'
    echo "$response" | jq -e '.result.tools[] | select(.name == "kimi_implement")'
    echo "$response" | jq -e '.result.tools[] | select(.name == "kimi_refactor")'
    echo "$response" | jq -e '.result.tools[] | select(.name == "kimi_verify")'
    
    # Verify each tool has required fields
    echo "$response" | jq -e '.result.tools[0] | has("name")'
    echo "$response" | jq -e '.result.tools[0] | has("title")'
    echo "$response" | jq -e '.result.tools[0] | has("description")'
    echo "$response" | jq -e '.result.tools[0] | has("inputSchema")'
}

# ============================================================================
# Test: Tool definitions have correct structure
# ============================================================================
@test "tool definitions have correct structure" {
    local response
    response=$(send_and_receive "tools/list")
    
    # Check kimi_analyze structure
    local analyze_tool
    analyze_tool=$(echo "$response" | jq '.result.tools[] | select(.name == "kimi_analyze")')
    
    [ "$(echo "$analyze_tool" | jq -r '.title')" = "Analyze code with Kimi" ]
    [ "$(echo "$analyze_tool" | jq -r '.inputSchema.type')" = "object" ]
    [ "$(echo "$analyze_tool" | jq -r '.inputSchema.properties.prompt.type')" = "string" ]
    echo "$analyze_tool" | jq -e '.inputSchema.required | contains(["prompt"])'
}

# ============================================================================
# Test: Server handles notifications/initialized
# ============================================================================
@test "server handles notifications/initialized without response" {
    local request
    request=$(jq -n '{jsonrpc: "2.0", method: "notifications/initialized"}')
    
    # Send notification - should not produce any output (no id = no response)
    local response
    response=$(echo "$request" | "$SERVER" 2>/dev/null)
    
    # Response should be empty for notifications
    [ -z "$response" ]
}

# ============================================================================
# Test: Server returns Method Not Found for unknown methods
# ============================================================================
@test "server returns Method Not Found for unknown methods" {
    local response
    response=$(send_and_receive "unknown/method" '{}' 'error-1')
    
    # Verify error response
    [ "$(echo "$response" | jq -r '.error.code')" = "-32601" ]
    [ "$(echo "$response" | jq -r '.error.message')" = "Method not found: unknown/method" ]
    [ "$(echo "$response" | jq -r '.id')" = "error-1" ]
}

# ============================================================================
# Test: Server returns Parse Error for invalid JSON
# ============================================================================
@test "server returns Parse Error for invalid JSON" {
    local response
    response=$(echo "not valid json" | "$SERVER" 2>/dev/null)
    
    # Verify error response
    [ "$(echo "$response" | jq -r '.error.code')" = "-32700" ]
    [[ "$(echo "$response" | jq -r '.error.message')" == *"Parse error"* ]]
}

# ============================================================================
# Test: Server returns Invalid Request for missing method
# ============================================================================
@test "server returns Invalid Request for missing method field" {
    local request
    request=$(jq -n '{jsonrpc: "2.0", id: "missing-method", params: {}}')
    
    local response
    response=$(echo "$request" | "$SERVER" 2>/dev/null)
    
    # Verify error response
    [ "$(echo "$response" | jq -r '.error.code')" = "-32600" ]
    [[ "$(echo "$response" | jq -r '.error.message')" == *"missing method"* ]]
    [ "$(echo "$response" | jq -r '.id')" = "missing-method" ]
}

# ============================================================================
# Test: Server skips empty lines
# ============================================================================
@test "server skips empty lines in input" {
    local request
    request=$(send_request "initialize" '{}' 'empty-test')
    
    # Send with empty lines before and after
    local response
    response=$(printf '\n\n%s\n\n' "$request" | "$SERVER" 2>/dev/null)
    
    # Should still get valid response
    [ "$(echo "$response" | jq -r '.result.protocolVersion')" = "2025-11-25" ]
    [ "$(echo "$response" | jq -r '.id')" = "empty-test" ]
}

# ============================================================================
# Test: Server preserves request IDs in responses
# ============================================================================
@test "server preserves request IDs in responses" {
    # Test with different ID types
    local response
    
    # String ID
    response=$(send_and_receive "tools/list" '{}' 'string-id')
    [ "$(echo "$response" | jq -r '.id')" = "string-id" ]
    
    # Numeric ID
    response=$(send_and_receive "tools/list" '{}' '123')
    [ "$(echo "$response" | jq -r '.id')" = "123" ]
}

# ============================================================================
# Test: Server handles tools/call with unknown tool
# ============================================================================
@test "server returns tool error for unknown tool" {
    local params
    params=$(jq -n '{name: "unknown_tool", arguments: {}}')
    
    local response
    response=$(send_and_receive "tools/call" "$params" 'unknown-tool-test')
    
    # Should be a successful JSON-RPC response (not an error)
    # but with isError=true in the result
    [ -z "$(echo "$response" | jq -r '.error // empty')" ]
    [ "$(echo "$response" | jq -r '.result.isError')" = "true" ]
    [[ "$(echo "$response" | jq -r '.result.content[0].text')" == *"Unknown tool"* ]]
}

# ============================================================================
# Test: Server handles tools/call with missing name parameter
# ============================================================================
@test "server returns tool error for tools/call with missing name" {
    local params
    params=$(jq -n '{arguments: {}}')
    
    local response
    response=$(send_and_receive "tools/call" "$params" 'missing-name-test')
    
    # Should be a successful JSON-RPC response with isError=true
    [ -z "$(echo "$response" | jq -r '.error // empty')" ]
    [ "$(echo "$response" | jq -r '.result.isError')" = "true" ]
    [[ "$(echo "$response" | jq -r '.result.content[0].text')" == *"Missing required parameter"* ]]
}

# ============================================================================
# Test: Server logs to stderr
# ============================================================================
@test "server logs startup message to stderr" {
    local stderr_output
    stderr_output=$(send_request "initialize" | "$SERVER" 2>&1 >/dev/null)
    
    # Should contain startup message
    [[ "$stderr_output" == *"Kimi MCP Server starting"* ]]
}

# ============================================================================
# Test: Server handles multiple sequential requests
# ============================================================================
@test "server handles multiple sequential requests" {
    # Send initialize followed by tools/list
    local init_request
    init_request=$(send_request "initialize" '{}' 'multi-1')
    local tools_request
    tools_request=$(send_request "tools/list" '{}' 'multi-2')
    
    # Send both requests
    local response
    response=$(printf '%s\n%s\n' "$init_request" "$tools_request" | "$SERVER" 2>/dev/null)
    
    # Count responses (should be 2 lines)
    local response_count
    response_count=$(echo "$response" | wc -l)
    [ "$response_count" -eq 2 ]
    
    # Verify first response is initialize result
    local first_response
    first_response=$(echo "$response" | head -1)
    [ "$(echo "$first_response" | jq -r '.id')" = "multi-1" ]
    [ "$(echo "$first_response" | jq -r '.result.protocolVersion')" = "2025-11-25" ]
    
    # Verify second response is tools list
    local second_response
    second_response=$(echo "$response" | tail -1)
    [ "$(echo "$second_response" | jq -r '.id')" = "multi-2" ]
    [ "$(echo "$second_response" | jq -r '.result.tools | length')" -eq 4 ]
}

# ============================================================================
# Test: Server shuts down cleanly when stdin closes
# ============================================================================
@test "server exits cleanly when stdin closes" {
    # Send single request then close stdin
    local request
    request=$(send_request "initialize")
    
    # Run server and check exit code
    run bash -c "echo '$request' | '$SERVER' >/dev/null 2>&1"
    
    # Should exit with code 0
    [ "$status" -eq 0 ]
}

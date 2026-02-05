#!/usr/bin/env bats
# test-mcp-core.bats - Unit tests for MCP protocol functions
#
# Requirements: bats (Bash Automated Testing System)
# Install: https://github.com/bats-core/bats-core
#
# Run: bats mcp-bridge/tests/test-mcp-core.bats

setup() {
    # Source the libraries being tested
    load '../lib/mcp-errors.sh'
    load '../lib/mcp-core.sh'
}

# ============================================================================
# mcp_parse_request tests
# ============================================================================

@test "mcp_parse_request extracts fields from valid JSON-RPC" {
    local request='{"jsonrpc":"2.0","id":"123","method":"test","params":{"foo":"bar"}}'
    local result
    result=$(mcp_parse_request "$request")
    
    [ "$(echo "$result" | jq -r '.id')" = "123" ]
    [ "$(echo "$result" | jq -r '.method')" = "test" ]
    [ "$(echo "$result" | jq -r '.params.foo')" = "bar" ]
}

@test "mcp_parse_request handles request with null id (notification)" {
    local request='{"jsonrpc":"2.0","id":null,"method":"notify","params":{}}'
    local result
    result=$(mcp_parse_request "$request")
    
    [ "$(echo "$result" | jq -r '.id')" = "null" ]
    [ "$(echo "$result" | jq -r '.method')" = "notify" ]
}

@test "mcp_parse_request handles request without params (defaults to empty object)" {
    local request='{"jsonrpc":"2.0","id":"456","method":"simple"}'
    local result
    result=$(mcp_parse_request "$request")
    
    [ "$(echo "$result" | jq -r '.id')" = "456" ]
    [ "$(echo "$result" | jq -r '.method')" = "simple" ]
    [ "$(echo "$result" | jq -r '.params | type')" = "object" ]
}

@test "mcp_parse_request handles request with numeric id" {
    local request='{"jsonrpc":"2.0","id":42,"method":"test"}'
    local result
    result=$(mcp_parse_request "$request")
    
    [ "$(echo "$result" | jq -r '.id')" = "42" ]
}

@test "mcp_parse_request returns empty object for invalid JSON" {
    local request='{"jsonrpc":"2.0", invalid json}'
    local result
    result=$(mcp_parse_request "$request")
    
    [ "$result" = "{}" ]
}

@test "mcp_parse_request returns empty object for empty line" {
    local result
    result=$(mcp_parse_request "")
    
    [ "$result" = "{}" ]
}

@test "mcp_parse_request handles nested params" {
    local request='{"jsonrpc":"2.0","id":"789","method":"complex","params":{"nested":{"deep":"value"},"array":[1,2,3]}}'
    local result
    result=$(mcp_parse_request "$request")
    
    [ "$(echo "$result" | jq -r '.params.nested.deep')" = "value" ]
    [ "$(echo "$result" | jq -r '.params.array[1]')" = "2" ]
}

# ============================================================================
# mcp_send_result tests
# ============================================================================

@test "mcp_send_result returns valid JSON-RPC with string ID" {
    local result
    result=$(mcp_send_result "123" '"test result"')
    
    [ "$(echo "$result" | jq -r '.jsonrpc')" = "2.0" ]
    [ "$(echo "$result" | jq -r '.id')" = "123" ]
    [ "$(echo "$result" | jq -r '.result')" = "test result" ]
    [ "$(echo "$result" | jq 'has("error")')" = "false" ]
}

@test "mcp_send_result returns valid JSON-RPC with numeric ID" {
    local result
    result=$(mcp_send_result "456" '{"key":"value"}')
    
    [ "$(echo "$result" | jq -r '.jsonrpc')" = "2.0" ]
    [ "$(echo "$result" | jq -r '.id')" = "456" ]
    [ "$(echo "$result" | jq -r '.result.key')" = "value" ]
}

@test "mcp_send_result handles null ID" {
    local result
    result=$(mcp_send_result "" '"null result"')
    
    [ "$(echo "$result" | jq -r '.id')" = "null" ]
}

@test "mcp_send_result handles complex result objects" {
    local result
    result=$(mcp_send_result "789" '{"tools":[{"name":"tool1"},{"name":"tool2"}]}')
    
    [ "$(echo "$result" | jq -r '.result.tools | length')" = "2" ]
    [ "$(echo "$result" | jq -r '.result.tools[0].name')" = "tool1" ]
}

# ============================================================================
# mcp_send_response tests (MCP ToolResult format)
# ============================================================================

@test "mcp_send_response returns success response (isError: false)" {
    local result
    result=$(mcp_send_response "123" "Success message" "false")
    
    [ "$(echo "$result" | jq -r '.jsonrpc')" = "2.0" ]
    [ "$(echo "$result" | jq -r '.id')" = "123" ]
    [ "$(echo "$result" | jq -r '.result.isError')" = "false" ]
    [ "$(echo "$result" | jq -r '.result.content[0].type')" = "text" ]
    [ "$(echo "$result" | jq -r '.result.content[0].text')" = "Success message" ]
}

@test "mcp_send_response returns error response (isError: true)" {
    local result
    result=$(mcp_send_response "456" "Error occurred" "true")
    
    [ "$(echo "$result" | jq -r '.result.isError')" = "true" ]
    [ "$(echo "$result" | jq -r '.result.content[0].text')" = "Error occurred" ]
}

@test "mcp_send_response defaults isError to false" {
    local result
    result=$(mcp_send_response "789" "Default test")
    
    [ "$(echo "$result" | jq -r '.result.isError')" = "false" ]
}

@test "mcp_send_response handles special characters in text" {
    local result
    result=$(mcp_send_response "999" 'Text with "quotes" and \backslash'
    
    [ "$(echo "$result" | jq -r '.result.content[0].text')" = 'Text with "quotes" and \backslash' ]
}

@test "mcp_send_response handles multiline text" {
    local result
    result=$(mcp_send_response "000" $'Line 1\nLine 2\nLine 3')
    
    [ "$(echo "$result" | jq -r '.result.content[0].text' | wc -l)" = "3" ]
}

# ============================================================================
# mcp_send_initialize_result tests
# ============================================================================

@test "mcp_send_initialize_result returns valid InitializeResult" {
    local result
    result=$(mcp_send_initialize_result "init-123")
    
    [ "$(echo "$result" | jq -r '.jsonrpc')" = "2.0" ]
    [ "$(echo "$result" | jq -r '.id')" = "init-123" ]
    [ "$(echo "$result" | jq -r '.result.protocolVersion')" = "2025-11-25" ]
    [ "$(echo "$result" | jq -r '.result.capabilities.tools.listChanged')" = "false" ]
    [ "$(echo "$result" | jq -r '.result.serverInfo.name')" = "kimi-mcp-server" ]
    [ "$(echo "$result" | jq -r '.result.serverInfo.version')" = "1.0.0" ]
}

@test "mcp_send_initialize_result handles null ID" {
    local result
    result=$(mcp_send_initialize_result "")
    
    [ "$(echo "$result" | jq -r '.id')" = "null" ]
}

@test "mcp_send_initialize_result accepts custom protocol version" {
    local result
    result=$(mcp_send_initialize_result "id" "2024-11-05")
    
    [ "$(echo "$result" | jq -r '.result.protocolVersion')" = "2024-11-05" ]
}

# ============================================================================
# mcp_send_tools_list tests
# ============================================================================

@test "mcp_send_tools_list returns tools wrapped in result" {
    local tools='[{"name":"tool1","description":"First tool"},{"name":"tool2","description":"Second tool"}]'
    local result
    result=$(mcp_send_tools_list "list-123" "$tools")
    
    [ "$(echo "$result" | jq -r '.jsonrpc')" = "2.0" ]
    [ "$(echo "$result" | jq -r '.id')" = "list-123" ]
    [ "$(echo "$result" | jq -r '.result.tools | length')" = "2" ]
    [ "$(echo "$result" | jq -r '.result.tools[0].name')" = "tool1" ]
}

@test "mcp_send_tools_list handles empty tools array" {
    local result
    result=$(mcp_send_tools_list "empty" "[]")
    
    [ "$(echo "$result" | jq -r '.result.tools | length')" = "0" ]
}

@test "mcp_send_tools_list defaults to empty array" {
    local result
    result=$(mcp_send_tools_list "default")
    
    [ "$(echo "$result" | jq -r '.result.tools | length')" = "0" ]
}

# ============================================================================
# Error function tests
# ============================================================================

@test "mcp_error_parse returns correct error code -32700" {
    local result
    result=$(mcp_error_parse "123" "Parse error test")
    
    [ "$(echo "$result" | jq -r '.error.code')" = "-32700" ]
    [ "$(echo "$result" | jq -r '.error.message')" = "Parse error test" ]
    [ "$(echo "$result" | jq -r '.id')" = "123" ]
}

@test "mcp_error_invalid_request returns correct error code -32600" {
    local result
    result=$(mcp_error_invalid_request "456" "Invalid request test")
    
    [ "$(echo "$result" | jq -r '.error.code')" = "-32600" ]
}

@test "mcp_error_method_not_found returns correct error code -32601" {
    local result
    result=$(mcp_error_method_not_found "789" "unknown_method")
    
    [ "$(echo "$result" | jq -r '.error.code')" = "-32601" ]
    [[ "$(echo "$result" | jq -r '.error.message')" == *"unknown_method"* ]]
}

@test "mcp_error_invalid_params returns correct error code -32602" {
    local result
    result=$(mcp_error_invalid_params "000" "Missing parameter: prompt")
    
    [ "$(echo "$result" | jq -r '.error.code')" = "-32602" ]
}

@test "mcp_error_internal returns correct error code -32603" {
    local result
    result=$(mcp_error_internal "111" "Internal server error")
    
    [ "$(echo "$result" | jq -r '.error.code')" = "-32603" ]
}

@test "mcp_error_server returns correct error code -32000" {
    local result
    result=$(mcp_error_server "222" "Server configuration error")
    
    [ "$(echo "$result" | jq -r '.error.code')" = "-32000" ]
}

@test "error functions handle null ID correctly" {
    local result
    result=$(mcp_error_parse "" "Test with null ID")
    
    [ "$(echo "$result" | jq -r '.id')" = "null" ]
}

@test "error functions include data field when provided" {
    local result
    result=$(mcp_error_parse "123" "Test" '{"line": 5, "column": 10}')
    
    [ "$(echo "$result" | jq -r '.error.data.line')" = "5" ]
    [ "$(echo "$result" | jq -r '.error.data.column')" = "10" ]
}

# ============================================================================
# Integration tests
# ============================================================================

@test "full request-response cycle" {
    # Parse a request
    local request='{"jsonrpc":"2.0","id":"cycle-123","method":"test","params":{"value":42}}'
    local parsed
    parsed=$(mcp_parse_request "$request")
    
    local id
    id=$(echo "$parsed" | jq -r '.id')
    local method
    method=$(echo "$parsed" | jq -r '.method')
    
    # Send a result
    local response
    response=$(mcp_send_result "$id" '{"received":true,"method":"'$method'"}')
    
    [ "$(echo "$response" | jq -r '.id')" = "cycle-123" ]
    [ "$(echo "$response" | jq -r '.result.method')" = "test" ]
}

@test "error response cycle" {
    # Simulate an unknown method error
    local request='{"jsonrpc":"2.0","id":"err-456","method":"unknown","params":{}}'
    local parsed
    parsed=$(mcp_parse_request "$request")
    
    local id
    id=$(echo "$parsed" | jq -r '.id')
    local method
    method=$(echo "$parsed" | jq -r '.method')
    
    # Send error response
    local response
    response=$(mcp_error_method_not_found "$id" "$method")
    
    [ "$(echo "$response" | jq -r '.id')" = "err-456" ]
    [ "$(echo "$response" | jq -r '.error.code')" = "-32601" ]
    [[ "$(echo "$response" | jq -r '.error.message')" == *"unknown"* ]]
}

@test "tool call response cycle" {
    # Simulate a tool call
    local request='{"jsonrpc":"2.0","id":"tool-789","method":"tools/call","params":{"name":"kimi_analyze","arguments":{"prompt":"test"}}}'
    local parsed
    parsed=$(mcp_parse_request "$request")
    
    local id
    id=$(echo "$parsed" | jq -r '.id')
    
    # Send tool result
    local response
    response=$(mcp_send_response "$id" "Analysis complete: test passed" "false")
    
    [ "$(echo "$response" | jq -r '.id')" = "tool-789" ]
    [ "$(echo "$response" | jq -r '.result.content[0].text')" = "Analysis complete: test passed" ]
    [ "$(echo "$response" | jq -r '.result.isError')" = "false" ]
}

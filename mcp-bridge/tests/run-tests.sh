#!/usr/bin/env bash
#
# Test Runner for Kimi MCP Server
#
# Purpose: Run all MCP server tests, detecting bats availability

set -euo pipefail

# Determine script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCP_BRIDGE_ROOT="$(dirname "$SCRIPT_DIR")"
export MCP_BRIDGE_ROOT

echo "Running Kimi MCP Server tests..."
echo "================================"
echo ""

# Check if bats is installed
if ! command -v bats >/dev/null 2>&1; then
    echo "WARNING: bats not installed. Manual testing required."
    echo ""
    echo "To install bats:"
    echo "  - macOS: brew install bats-core"
    echo "  - Linux: npm install -g bats"
    echo "  - Or see: https://github.com/bats-core/bats-core"
    echo ""
    echo "Manual test checklist:"
    echo "========================"
    echo ""
    echo "1. Test server startup:"
    echo "   echo '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{}}' | ./bin/kimi-mcp-server"
    echo ""
    echo "2. Test tools/list:"
    echo "   echo '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\"}' | ./bin/kimi-mcp-server"
    echo ""
    echo "3. Test unknown method (should return error -32601):"
    echo "   echo '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"unknown\"}' | ./bin/kimi-mcp-server"
    echo ""
    echo "4. Test invalid JSON (should return error -32700):"
    echo "   echo 'not json' | ./bin/kimi-mcp-server"
    echo ""
    echo "5. Test missing method field (should return error -32600):"
    echo "   echo '{\"jsonrpc\":\"2.0\",\"id\":1}' | ./bin/kimi-mcp-server"
    echo ""
    echo "6. Test tools/call with unknown tool:"
    echo "   echo '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"unknown\",\"arguments\":{}}}' | ./bin/kimi-mcp-server"
    echo ""
    exit 0
fi

echo "bats version: $(bats --version)"
echo "MCP_BRIDGE_ROOT: $MCP_BRIDGE_ROOT"
echo ""

# Run all test files
failed=0
passed=0
total=0

for test_file in "$SCRIPT_DIR"/*.bats; do
    if [[ -f "$test_file" ]]; then
        echo "Running: $(basename "$test_file")"
        echo "----------------------------------------"
        
        if bats "$test_file"; then
            ((passed++)) || true
        else
            ((failed++)) || true
        fi
        ((total++)) || true
        echo ""
    fi
done

# Summary
echo "================================"
echo "Test Summary"
echo "================================"
echo "Total test files: $total"
echo "Passed: $passed"
echo "Failed: $failed"
echo ""

if [[ $failed -eq 0 ]]; then
    echo "All tests passed!"
    exit 0
else
    echo "Some tests failed!"
    exit 1
fi

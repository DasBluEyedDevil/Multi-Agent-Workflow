# MCP Setup Guide

Configure the Kimi MCP server for external tool integration.

## Overview

The Model Context Protocol (MCP) server exposes Kimi as callable tools that external AI systems can invoke. This enables:

- Claude Code to delegate tasks to Kimi via MCP
- Other AI assistants to use Kimi's capabilities
- Integration with MCP-compatible tools

## Prerequisites

- Kimi CLI installed (`kimi --version`)
- jq installed (`jq --version`)
- Bash 4.0+ (`bash --version`)

## Installation

### 1. Install MCP Components

Run the installer:

```bash
./install.sh
```

This installs:
- `kimi-mcp` command to `~/.local/bin/`
- `kimi-mcp-server` to `~/.local/bin/`
- Default config to `~/.config/kimi-mcp/config.json`

### 2. Verify Installation

```bash
# Check command is available
which kimi-mcp

# Check version
kimi-mcp --version

# Check server binary
which kimi-mcp-server
```

### 3. Configure PATH

Ensure `~/.local/bin` is in your PATH:

```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="$HOME/.local/bin:$PATH"
```

## Configuration

### Default Config

File: `~/.config/kimi-mcp/config.json`

```json
{
  "model": "k2",
  "timeout": 300,
  "roles": {
    "analyze": "reviewer",
    "implement": "implementer",
    "refactor": "refactorer",
    "verify": "reviewer"
  }
}
```

### Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `model` | Default model (k2 or k2.5) | k2 |
| `timeout` | Request timeout in seconds | 300 |
| `roles.analyze` | Role for analyze tool | reviewer |
| `roles.implement` | Role for implement tool | implementer |
| `roles.refactor` | Role for refactor tool | refactorer |
| `roles.verify` | Role for verify tool | reviewer |

### Environment Variables

Override config with environment variables:

```bash
export KIMI_MCP_MODEL=k2.5
export KIMI_MCP_TIMEOUT=600
```

## Usage

### Start the Server

```bash
kimi-mcp start
```

The server reads JSON-RPC from stdin and writes responses to stdout.

### Test the Server

```bash
# Initialize
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' | kimi-mcp start

# List tools
echo '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' | kimi-mcp start

# Call a tool
echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"kimi_analyze","arguments":{"prompt":"Analyze this code","files":["src/main.py"]}}}' | kimi-mcp start
```

## Claude Code Integration

### 1. Configure Claude Code

Add to Claude Code settings:

```json
{
  "mcpServers": {
    "kimi": {
      "command": "kimi-mcp",
      "args": ["start"]
    }
  }
}
```

### 2. Use via Slash Command

In Claude Code:

```
/kimi-mcp start
```

## Available Tools

### kimi_analyze

Analyze code or files with specified context.

**Input:**
```json
{
  "prompt": "Analyze the authentication flow",
  "files": ["src/auth.py", "src/middleware.py"],
  "role": "reviewer"
}
```

### kimi_implement

Implement features or fixes autonomously.

**Input:**
```json
{
  "prompt": "Add user profile endpoint",
  "files": ["src/routes.py"],
  "role": "implementer"
}
```

### kimi_refactor

Refactor code with safety checks.

**Input:**
```json
{
  "prompt": "Extract utility functions",
  "files": ["src/utils.py"],
  "role": "refactorer"
}
```

### kimi_verify

Verify changes against requirements.

**Input:**
```json
{
  "prompt": "Verify all endpoints require auth",
  "files": ["src/routes.py"],
  "role": "reviewer"
}
```

## Troubleshooting

### "kimi-mcp: command not found"

```bash
# Check if in PATH
echo $PATH | grep ".local/bin"

# Add to PATH
export PATH="$HOME/.local/bin:$PATH"
```

### "jq: command not found"

Install jq:

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# Windows (Git Bash)
choco install jq
```

### Server not responding

- Check input is valid JSON
- Ensure proper newline termination
- Verify protocol version (2025-11-25)

### Permission denied

```bash
chmod +x ~/.local/bin/kimi-mcp
chmod +x ~/.local/bin/kimi-mcp-server
```

## Advanced

### Custom Roles

Add custom roles to config:

```json
{
  "roles": {
    "custom": "path/to/custom-role.md"
  }
}
```

### Logging

Enable debug logging:

```bash
KIMI_MCP_DEBUG=1 kimi-mcp start
```

## See Also

- [Hooks Guide](./HOOKS-GUIDE.md) — Git hooks configuration
- [Model Selection](./MODEL-SELECTION.md) — K2 vs K2.5 guide
- @.claude/commands/kimi/kimi-mcp.md — Slash command reference

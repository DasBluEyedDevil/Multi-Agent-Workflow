#!/bin/bash
#
# File Reader Library for Kimi MCP Server
#
# Purpose: Provides safe file reading utilities with size limits and validation.
#          Handles platform differences (Linux vs macOS) and binary file detection.
#
# Usage:
#   source "${MCP_BRIDGE_ROOT}/lib/file-reader.sh"
#
#   # Validate a single file
#   if mcp_validate_file "/path/to/file" 1048576; then
#       content=$(mcp_read_file "/path/to/file" 1048576)
#   fi
#
#   # Read multiple files
#   files_json='["/path/to/file1", "/path/to/file2"]'
#   formatted=$(mcp_read_files "$files_json" 1048576)
#
# Dependencies: None (uses standard POSIX utilities)

# ============================================================================
# Platform Detection
# ============================================================================

# Detect platform for stat command differences
_mcp_detect_platform() {
    case "$(uname -s)" in
        Linux*)
            echo "linux"
            ;;
        Darwin*)
            echo "macos"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

readonly MCP_PLATFORM=$(_mcp_detect_platform)

# ============================================================================
# File Validation
# ============================================================================

# Validate that a file exists, is readable, and is within size limits
#
# Arguments:
#   $1 - File path to validate
#   $2 - Maximum allowed size in bytes (optional, defaults to 1MB)
#
# Returns:
#   0 if file is valid
#   1 if file is invalid (error message to stderr)
#
# Example:
#   if mcp_validate_file "/path/to/file" 1048576; then
#       echo "File is valid"
#   fi
mcp_validate_file() {
    local file_path="${1:-}"
    local max_size="${2:-1048576}"

    # Check if file path is provided
    if [[ -z "$file_path" ]]; then
        echo "Error: No file path provided" >&2
        return 1
    fi

    # Check if file exists
    if [[ ! -e "$file_path" ]]; then
        echo "Error: File does not exist: $file_path" >&2
        return 1
    fi

    # Check if it's a regular file (not a directory or special file)
    if [[ ! -f "$file_path" ]]; then
        echo "Error: Not a regular file: $file_path" >&2
        return 1
    fi

    # Check if file is readable
    if [[ ! -r "$file_path" ]]; then
        echo "Error: File not readable: $file_path" >&2
        return 1
    fi

    # Get file size
    local file_size
    file_size=$(_mcp_get_file_size "$file_path")

    if [[ -z "$file_size" ]]; then
        echo "Error: Could not determine file size: $file_path" >&2
        return 1
    fi

    # Check size limit
    if [[ "$file_size" -gt "$max_size" ]]; then
        echo "Error: File exceeds size limit ($max_size bytes): $file_path ($file_size bytes)" >&2
        return 1
    fi

    return 0
}

# Internal: Get file size in bytes (platform-specific)
#
# Arguments:
#   $1 - File path
#
# Output:
#   File size in bytes, or empty string on error
_mcp_get_file_size() {
    local file_path="$1"

    case "$MCP_PLATFORM" in
        linux)
            stat -c%s "$file_path" 2>/dev/null
            ;;
        macos)
            stat -f%z "$file_path" 2>/dev/null
            ;;
        windows|unknown)
            # Fallback: use wc -c (less reliable for binary files but portable)
            wc -c < "$file_path" 2>/dev/null | tr -d ' '
            ;;
    esac
}

# ============================================================================
# File Reading
# ============================================================================

# Read file content if it passes validation
#
# Arguments:
#   $1 - File path to read
#   $2 - Maximum allowed size in bytes (optional, defaults to 1MB)
#
# Output:
#   File content to stdout, or empty string with error to stderr
#
# Example:
#   content=$(mcp_read_file "/path/to/file" 1048576)
#   if [[ -n "$content" ]]; then
#       echo "Read $(wc -c <<< "$content") bytes"
#   fi
mcp_read_file() {
    local file_path="${1:-}"
    local max_size="${2:-1048576}"

    # Validate first
    if ! mcp_validate_file "$file_path" "$max_size"; then
        return 1
    fi

    # Check if file might be binary
    if _mcp_is_binary_file "$file_path"; then
        echo "Warning: File appears to be binary, skipping: $file_path" >&2
        return 1
    fi

    # Read and output file content
    cat "$file_path" 2>/dev/null
}

# Internal: Check if a file appears to be binary
#
# Arguments:
#   $1 - File path
#
# Returns:
#   0 if file appears binary
#   1 if file appears text
#
# Uses the 'file' command if available, otherwise checks for null bytes
_mcp_is_binary_file() {
    local file_path="$1"

    # If 'file' command is available, use it
    if command -v file >/dev/null 2>&1; then
        local file_type
        file_type=$(file -b --mime-type "$file_path" 2>/dev/null)
        case "$file_type" in
            text/*|application/json|application/javascript|application/xml|application/x-shellscript)
                return 1
                ;;
            *)
                return 0
                ;;
        esac
    fi

    # Fallback: check for null bytes in first 1KB
    if head -c 1024 "$file_path" 2>/dev/null | grep -qP '\x00'; then
        return 0
    fi

    return 1
}

# ============================================================================
# Batch File Reading
# ============================================================================

# Read multiple files and format them for prompt inclusion
#
# Arguments:
#   $1 - JSON array of file paths (e.g., '["/path/1", "/path/2"]')
#   $2 - Maximum allowed size per file in bytes (optional, defaults to 1MB)
#
# Output:
#   Formatted string with all file contents:
#   File: /path/to/file1
#   [content]
#
#   File: /path/to/file2
#   [content]
#
# Example:
#   files='["/etc/hosts", "/etc/resolv.conf"]'
#   formatted=$(mcp_read_files "$files" 1048576)
mcp_read_files() {
    local files_json="${1:-}"
    local max_size="${2:-1048576}"
    local result=""

    # Handle empty input
    if [[ -z "$files_json" || "$files_json" == "null" || "$files_json" == "[]" ]]; then
        return 0
    fi

    # Check if jq is available for JSON parsing
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required for parsing files JSON" >&2
        return 1
    fi

    # Get the number of files
    local count
    count=$(echo "$files_json" | jq 'length' 2>/dev/null)

    if [[ -z "$count" || "$count" == "null" ]]; then
        echo "Error: Invalid files JSON format" >&2
        return 1
    fi

    # Process each file
    local i=0
    while [[ $i -lt $count ]]; do
        local file_path
        file_path=$(echo "$files_json" | jq -r ".[$i]" 2>/dev/null)

        if [[ -n "$file_path" && "$file_path" != "null" ]]; then
            # Try to read the file
            local content
            if content=$(mcp_read_file "$file_path" "$max_size" 2>/dev/null); then
                # Format and append to result
                result="${result}File: ${file_path}
${content}

"
            else
                # File was skipped (logged by mcp_read_file)
                : # Continue to next file
            fi
        fi

        ((i++))
    done

    # Output result (trim trailing newlines)
    echo -n "$result" | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba'
}

# Format a single file's content for inclusion in prompt
#
# Arguments:
#   $1 - File path
#   $2 - File content
#
# Output:
#   Formatted string: "File: [path]\n[content]\n"
#
# Example:
#   formatted=$(mcp_format_file_content "/path/to/file" "file content here")
mcp_format_file_content() {
    local file_path="${1:-}"
    local content="${2:-}"

    if [[ -z "$file_path" ]]; then
        return 1
    fi

    printf "File: %s\n%s\n" "$file_path" "$content"
}

# ============================================================================
# Export Functions
# ============================================================================

export -f mcp_validate_file
export -f mcp_read_file
export -f mcp_read_files
export -f mcp_format_file_content

# Export platform constant
export MCP_PLATFORM

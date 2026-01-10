#!/bin/bash

# Multi-Agent-Workflow Installer
# Installs Gemini Research integration for Claude Code

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Multi-Agent-Workflow Installer                       ║${NC}"
echo -e "${GREEN}║   Gemini Research Integration for Claude Code          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# ═══════════════════════════════════════════════════════════
# Prerequisite Checks
# ═══════════════════════════════════════════════════════════

echo -e "${BLUE}Checking prerequisites...${NC}"

MISSING_DEPS=()

# Check for jq
if ! command -v jq &> /dev/null; then
    MISSING_DEPS+=("jq")
    echo -e "  ${RED}✗${NC} jq not found"
else
    echo -e "  ${GREEN}✓${NC} jq $(jq --version)"
fi

# Check for gemini CLI
if ! command -v gemini &> /dev/null; then
    MISSING_DEPS+=("gemini-cli")
    echo -e "  ${RED}✗${NC} gemini CLI not found"
else
    echo -e "  ${GREEN}✓${NC} gemini CLI found"
fi

# Check for git (optional but recommended)
if ! command -v git &> /dev/null; then
    echo -e "  ${YELLOW}⚠${NC} git not found (optional, needed for --diff feature)"
else
    echo -e "  ${GREEN}✓${NC} git $(git --version | cut -d' ' -f3)"
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}Missing required dependencies: ${MISSING_DEPS[*]}${NC}"
    echo ""
    echo -e "${YELLOW}Installation instructions:${NC}"

    for dep in "${MISSING_DEPS[@]}"; do
        case "$dep" in
            jq)
                echo -e "  ${CYAN}jq:${NC}"
                echo "    Windows (Git Bash): Download from https://stedolan.github.io/jq/"
                echo "    macOS: brew install jq"
                echo "    Linux: sudo apt install jq"
                ;;
            gemini-cli)
                echo -e "  ${CYAN}gemini-cli:${NC}"
                echo "    Visit: https://ai.google.dev/gemini-api/docs/cli"
                ;;
        esac
    done
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""

# ═══════════════════════════════════════════════════════════
# Installation Type Selection
# ═══════════════════════════════════════════════════════════

echo -e "${BLUE}Select installation type:${NC}"
echo ""
echo "  1) ${GREEN}Global${NC} - Install to ~/.claude/ (available in all projects)"
echo "  2) ${CYAN}Project${NC} - Install to current directory"
echo "  3) ${YELLOW}Custom${NC} - Specify target directory"
echo ""

read -p "Choose [1/2/3]: " -n 1 -r INSTALL_TYPE
echo ""
echo ""

case "$INSTALL_TYPE" in
    1)
        TARGET_DIR="$HOME/.claude"
        INSTALL_MODE="global"
        ;;
    2)
        TARGET_DIR="$(pwd)"
        INSTALL_MODE="project"
        ;;
    3)
        read -p "Enter target directory: " TARGET_DIR
        TARGET_DIR="${TARGET_DIR/#\~/$HOME}"  # Expand ~
        INSTALL_MODE="custom"
        ;;
    *)
        echo -e "${RED}Invalid selection${NC}"
        exit 1
        ;;
esac

echo -e "${BLUE}Installing to:${NC} $TARGET_DIR"
echo -e "${BLUE}Mode:${NC} $INSTALL_MODE"
echo ""

# ═══════════════════════════════════════════════════════════
# Detect Existing Installation
# ═══════════════════════════════════════════════════════════

EXISTING_INSTALL=false
if [ -f "$TARGET_DIR/skills/gemini.agent.wrapper.sh" ]; then
    EXISTING_INSTALL=true
    echo -e "${YELLOW}Existing installation detected!${NC}"
    echo ""
    echo "  This will:"
    echo "  ${GREEN}✓${NC} Update wrapper scripts (gemini.agent.wrapper.sh, gemini-parse.sh)"
    echo "  ${GREEN}✓${NC} Update role definitions (.gemini/roles/*.md)"
    echo "  ${GREEN}✓${NC} Update skill definition (SKILL.md)"
    echo "  ${GREEN}✓${NC} Update slash commands (.claude/commands/gemini-*.md)"
    echo "  ${YELLOW}⚠${NC} Preserve your .claude/settings.json"
    echo "  ${YELLOW}⚠${NC} Preserve your .gemini/config (if exists)"
    echo "  ${YELLOW}⚠${NC} Preserve your custom templates"
    echo ""

    read -p "Create backup before upgrading? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        BACKUP_DIR="$TARGET_DIR/.gemini-backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$BACKUP_DIR"

        # Backup existing files
        [ -f "$TARGET_DIR/skills/gemini.agent.wrapper.sh" ] && cp "$TARGET_DIR/skills/gemini.agent.wrapper.sh" "$BACKUP_DIR/"
        [ -f "$TARGET_DIR/skills/gemini-parse.sh" ] && cp "$TARGET_DIR/skills/gemini-parse.sh" "$BACKUP_DIR/"
        [ -d "$TARGET_DIR/.gemini/roles" ] && cp -r "$TARGET_DIR/.gemini/roles" "$BACKUP_DIR/"
        [ -f "$TARGET_DIR/.gemini/config" ] && cp "$TARGET_DIR/.gemini/config" "$BACKUP_DIR/"
        [ -f "$TARGET_DIR/GeminiContext.md" ] && cp "$TARGET_DIR/GeminiContext.md" "$BACKUP_DIR/"
        if [ "$INSTALL_MODE" = "global" ]; then
            if ls "$TARGET_DIR/commands/gemini-"*.md &> /dev/null; then
                mkdir -p "$BACKUP_DIR/commands"
                cp "$TARGET_DIR/commands/gemini-"*.md "$BACKUP_DIR/commands/"
            fi
        else
            if ls "$TARGET_DIR/.claude/commands/gemini-"*.md &> /dev/null; then
                mkdir -p "$BACKUP_DIR/commands"
                cp "$TARGET_DIR/.claude/commands/gemini-"*.md "$BACKUP_DIR/commands/"
            fi
        fi

        echo -e "${GREEN}✓${NC} Backup created at: $BACKUP_DIR"
        echo ""
    fi
fi

# Confirm
if [ "$EXISTING_INSTALL" = true ]; then
    read -p "Proceed with upgrade? (Y/n) " -n 1 -r
else
    read -p "Proceed with installation? (Y/n) " -n 1 -r
fi
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""

# ═══════════════════════════════════════════════════════════
# Installation
# ═══════════════════════════════════════════════════════════

if [ "$EXISTING_INSTALL" = true ]; then
    echo -e "${BLUE}Upgrading files...${NC}"
else
    echo -e "${BLUE}Installing files...${NC}"
fi

# Create directories
mkdir -p "$TARGET_DIR/skills"
mkdir -p "$TARGET_DIR/.gemini/roles"
mkdir -p "$TARGET_DIR/.gemini/templates"

if [ "$INSTALL_MODE" = "global" ]; then
    mkdir -p "$TARGET_DIR/skills/gemini-research"
    mkdir -p "$TARGET_DIR/commands"
else
    mkdir -p "$TARGET_DIR/.claude/skills/gemini-research"
    mkdir -p "$TARGET_DIR/.claude/commands"
fi

# Copy wrapper scripts
cp "$SCRIPT_DIR/skills/gemini.agent.wrapper.sh" "$TARGET_DIR/skills/"
cp "$SCRIPT_DIR/skills/gemini-parse.sh" "$TARGET_DIR/skills/"
chmod +x "$TARGET_DIR/skills/"*.sh
echo -e "  ${GREEN}✓${NC} Copied wrapper scripts"

# Copy roles
cp "$SCRIPT_DIR/.gemini/roles/"*.md "$TARGET_DIR/.gemini/roles/"
echo -e "  ${GREEN}✓${NC} Copied roles ($(ls -1 "$SCRIPT_DIR/.gemini/roles/"*.md | wc -l) files)"

# Copy templates (if any exist)
if ls "$SCRIPT_DIR/.gemini/templates/"*.md &> /dev/null; then
    cp "$SCRIPT_DIR/.gemini/templates/"*.md "$TARGET_DIR/.gemini/templates/"
    echo -e "  ${GREEN}✓${NC} Copied templates"
fi

# Copy config example (don't overwrite existing config)
if [ -f "$SCRIPT_DIR/.gemini/config.example" ]; then
    cp "$SCRIPT_DIR/.gemini/config.example" "$TARGET_DIR/.gemini/"
    echo -e "  ${GREEN}✓${NC} Copied config.example"
fi
if [ -f "$TARGET_DIR/.gemini/config" ]; then
    echo -e "  ${YELLOW}⚠${NC} Existing .gemini/config preserved"
fi

# Copy context file
if [ -f "$SCRIPT_DIR/GeminiContext.md" ]; then
    cp "$SCRIPT_DIR/GeminiContext.md" "$TARGET_DIR/"
    echo -e "  ${GREEN}✓${NC} Copied GeminiContext.md"
fi

# Copy skill definition
if [ "$INSTALL_MODE" = "global" ]; then
    cp "$SCRIPT_DIR/.claude/skills/gemini-research/SKILL.md" "$TARGET_DIR/skills/gemini-research/"
else
    cp "$SCRIPT_DIR/.claude/skills/gemini-research/SKILL.md" "$TARGET_DIR/.claude/skills/gemini-research/"
fi
echo -e "  ${GREEN}✓${NC} Copied skill definition"

# Copy slash commands (if provided)
if ls "$SCRIPT_DIR/.claude/commands/"*.md &> /dev/null; then
    if [ "$INSTALL_MODE" = "global" ]; then
        cp "$SCRIPT_DIR/.claude/commands/"*.md "$TARGET_DIR/commands/"
    else
        cp "$SCRIPT_DIR/.claude/commands/"*.md "$TARGET_DIR/.claude/commands/"
    fi
    echo -e "  ${GREEN}✓${NC} Copied slash commands"
fi

# Handle settings.json (don't overwrite existing)
if [ "$INSTALL_MODE" != "global" ]; then
    SETTINGS_FILE="$TARGET_DIR/.claude/settings.json"
    if [ -f "$SETTINGS_FILE" ]; then
        echo -e "  ${YELLOW}⚠${NC} .claude/settings.json exists - not overwriting"
        echo -e "    ${CYAN}→${NC} See $SCRIPT_DIR/.claude/settings.json for hook examples"
    else
        mkdir -p "$TARGET_DIR/.claude"
        cp "$SCRIPT_DIR/.claude/settings.json" "$SETTINGS_FILE"
        echo -e "  ${GREEN}✓${NC} Copied settings.json with hooks"
    fi
fi

# For global install, update CLAUDE.md if it doesn't have Gemini section
if [ "$INSTALL_MODE" = "global" ]; then
    CLAUDE_MD="$TARGET_DIR/CLAUDE.md"
    if [ -f "$CLAUDE_MD" ]; then
        if ! grep -q "Gemini Context Companion" "$CLAUDE_MD"; then
            echo -e "  ${YELLOW}⚠${NC} Consider adding Gemini section to $CLAUDE_MD"
            echo -e "    ${CYAN}→${NC} See $SCRIPT_DIR/.claude/CLAUDE.md for example"
        else
            echo -e "  ${GREEN}✓${NC} CLAUDE.md already has Gemini section"
        fi
    fi
fi

echo ""

# ═══════════════════════════════════════════════════════════
# Post-Installation
# ═══════════════════════════════════════════════════════════

echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""

# Show usage based on install mode
if [ "$INSTALL_MODE" = "global" ]; then
    WRAPPER_PATH="~/.claude/skills/gemini.agent.wrapper.sh"
else
    WRAPPER_PATH="./skills/gemini.agent.wrapper.sh"
fi

echo -e "${BLUE}Quick Start:${NC}"
echo ""
echo -e "  ${CYAN}# Test installation${NC}"
echo "  $WRAPPER_PATH --dry-run -r reviewer \"test\""
echo ""
echo -e "  ${CYAN}# Analyze code with reviewer role${NC}"
echo "  $WRAPPER_PATH -r reviewer -d \"@src/\" \"Review authentication module\""
echo ""
echo -e "  ${CYAN}# Debug an issue${NC}"
echo "  $WRAPPER_PATH -r debugger \"Error at line 45 in auth.ts\""
echo ""
echo -e "  ${CYAN}# Plan a feature${NC}"
echo "  $WRAPPER_PATH -t implement-ready -d \"@src/\" \"Add user profiles\""
echo ""
echo -e "  ${CYAN}# Verify changes${NC}"
echo "  $WRAPPER_PATH -t verify --diff \"Added caching layer\""
echo ""

echo -e "${BLUE}Available Roles:${NC}"
echo "  reviewer, debugger, planner, security, auditor, explainer,"
echo "  migrator, documenter, dependency-mapper, onboarder,"
echo "  kotlin-expert, typescript-expert, python-expert, api-designer, database-expert"
echo ""

echo -e "${BLUE}Available Templates:${NC}"
echo "  feature, bug, verify, architecture, implement-ready, fix-ready"
echo ""

if [ "$INSTALL_MODE" = "global" ]; then
    echo -e "${YELLOW}Note:${NC} For per-project roles, create .gemini/roles/*.md in your project."
    echo "      Project roles override global roles of the same name."
    echo ""
fi

echo -e "${BLUE}Documentation:${NC}"
echo "  $SCRIPT_DIR/README.md"
echo "  $SCRIPT_DIR/skills/Claude-Code-Integration.md"
echo ""

# Verification test
echo -e "${BLUE}Running verification test...${NC}"
if [ "$INSTALL_MODE" = "global" ]; then
    TEST_OUTPUT=$("$HOME/.claude/skills/gemini.agent.wrapper.sh" --dry-run "test" 2>&1) || true
else
    TEST_OUTPUT=$("$TARGET_DIR/skills/gemini.agent.wrapper.sh" --dry-run "test" 2>&1) || true
fi

if echo "$TEST_OUTPUT" | grep -q "DRY RUN"; then
    echo -e "  ${GREEN}✓${NC} Wrapper script works correctly"
else
    echo -e "  ${RED}✗${NC} Verification failed. Check installation."
    echo "  Output: ${TEST_OUTPUT:0:100}..."
fi

echo ""
echo -e "${GREEN}Done!${NC}"

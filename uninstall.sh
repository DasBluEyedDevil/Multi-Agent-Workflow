#!/bin/bash

# Multi-Agent-Workflow Uninstaller
# Removes Gemini Research integration from Claude Code

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║   Multi-Agent-Workflow Uninstaller                     ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}Select what to uninstall:${NC}"
echo ""
echo "  1) ${GREEN}Global${NC} - Remove from ~/.claude/"
echo "  2) ${YELLOW}Project${NC} - Remove from current directory"
echo "  3) ${RED}Custom${NC} - Specify directory"
echo ""

read -p "Choose [1/2/3]: " -n 1 -r UNINSTALL_TYPE
echo ""
echo ""

case "$UNINSTALL_TYPE" in
    1)
        TARGET_DIR="$HOME/.claude"
        ;;
    2)
        TARGET_DIR="$(pwd)"
        ;;
    3)
        read -p "Enter target directory: " TARGET_DIR
        TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
        ;;
    *)
        echo -e "${RED}Invalid selection${NC}"
        exit 1
        ;;
esac

echo -e "${YELLOW}This will remove:${NC}"
echo "  - $TARGET_DIR/skills/gemini.agent.wrapper.sh"
echo "  - $TARGET_DIR/skills/gemini-parse.sh"
echo "  - $TARGET_DIR/skills/gemini.ps1"
echo "  - $TARGET_DIR/skills/gemini-research/ (if global)"
echo "  - $TARGET_DIR/.gemini/ directory"
echo "  - $TARGET_DIR/GeminiContext.md"
echo ""
echo -e "${YELLOW}This will NOT remove:${NC}"
echo "  - .claude/settings.json (may have other settings)"
echo "  - .claude/skills/gemini-research/ (project installs)"
echo ""

read -p "Are you sure? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}Removing files...${NC}"

# Remove wrapper scripts
[ -f "$TARGET_DIR/skills/gemini.agent.wrapper.sh" ] && rm "$TARGET_DIR/skills/gemini.agent.wrapper.sh" && echo -e "  ${GREEN}✓${NC} Removed gemini.agent.wrapper.sh"
[ -f "$TARGET_DIR/skills/gemini-parse.sh" ] && rm "$TARGET_DIR/skills/gemini-parse.sh" && echo -e "  ${GREEN}✓${NC} Removed gemini-parse.sh"
[ -f "$TARGET_DIR/skills/gemini.ps1" ] && rm "$TARGET_DIR/skills/gemini.ps1" && echo -e "  ${GREEN}✓${NC} Removed gemini.ps1"

# Remove skill definition (global)
[ -d "$TARGET_DIR/skills/gemini-research" ] && rm -rf "$TARGET_DIR/skills/gemini-research" && echo -e "  ${GREEN}✓${NC} Removed skills/gemini-research/"

# Remove .gemini directory
[ -d "$TARGET_DIR/.gemini" ] && rm -rf "$TARGET_DIR/.gemini" && echo -e "  ${GREEN}✓${NC} Removed .gemini/"

# Remove context file
[ -f "$TARGET_DIR/GeminiContext.md" ] && rm "$TARGET_DIR/GeminiContext.md" && echo -e "  ${GREEN}✓${NC} Removed GeminiContext.md"

echo ""
echo -e "${GREEN}Uninstall complete.${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} You may want to manually:"
echo "  - Remove gemini-research from .claude/settings.json enabledSkills"
echo "  - Remove Gemini hooks from .claude/settings.json"
echo "  - Remove Gemini section from ~/.claude/CLAUDE.md"

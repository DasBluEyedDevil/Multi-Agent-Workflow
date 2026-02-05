#!/bin/bash
# Hook installation library

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_SCRIPTS_DIR="$HOOKS_DIR/hooks"

# Hook types we support
HOOK_TYPES=("pre-commit" "post-checkout" "pre-push")

# Get global hooks directory (~/.config/git/hooks/)
hooks_get_global_dir() {
    echo "${HOME}/.config/git/hooks"
}

# Get local hooks directory (.git/hooks/)
hooks_get_local_dir() {
    if [[ -d ".git" ]]; then
        echo "$(pwd)/.git/hooks"
    else
        git rev-parse --git-path hooks 2>/dev/null
    fi
}

# Check if global hooks directory exists
hooks_global_dir_exists() {
    [[ -d "$(hooks_get_global_dir)" ]]
}

# Create global hooks directory
hooks_create_global_dir() {
    local global_dir
    global_dir=$(hooks_get_global_dir)
    mkdir -p "$global_dir"
    echo "Created global hooks directory: $global_dir"
}

# Install hooks globally
hooks_install_global() {
    local global_dir
    global_dir=$(hooks_get_global_dir)
    
    if ! hooks_global_dir_exists; then
        hooks_create_global_dir
    fi
    
    local installed=()
    local skipped=()
    
    for hook in "${HOOK_TYPES[@]}"; do
        local source="$HOOK_SCRIPTS_DIR/$hook"
        local target="$global_dir/$hook"
        
        if [[ -L "$target" ]]; then
            skipped+=("$hook (already installed)")
        elif [[ -e "$target" ]]; then
            skipped+=("$hook (exists, not a symlink - manual install?)")
        else
            ln -s "$source" "$target"
            installed+=("$hook")
        fi
    done
    
    echo "Global installation complete:"
    [[ ${#installed[@]} -gt 0 ]] && echo "  Installed: ${installed[*]}"
    [[ ${#skipped[@]} -gt 0 ]] && echo "  Skipped: ${skipped[*]}"
    
    # Remind about core.hooksPath if needed
    local current_path
    current_path=$(git config --global core.hooksPath 2>/dev/null)
    if [[ -z "$current_path" ]]; then
        echo ""
        echo "Note: To enable global hooks, run:"
        echo "  git config --global core.hooksPath '$global_dir'"
    fi
}

# Install hooks locally
hooks_install_local() {
    local local_dir
    local_dir=$(hooks_get_local_dir)
    
    if [[ -z "$local_dir" ]] || [[ ! -d "$local_dir" ]]; then
        echo "Error: Not in a git repository or .git directory not found"
        return 1
    fi
    
    local installed=()
    local skipped=()
    local backed_up=()
    
    for hook in "${HOOK_TYPES[@]}"; do
        local source="$HOOK_SCRIPTS_DIR/$hook"
        local target="$local_dir/$hook"
        
        if [[ -L "$target" ]]; then
            skipped+=("$hook (already installed)")
        elif [[ -e "$target" ]]; then
            # Backup existing hook
            mv "$target" "$target.backup.$(date +%Y%m%d%H%M%S)"
            backed_up+=("$hook")
            ln -s "$source" "$target"
            installed+=("$hook")
        else
            ln -s "$source" "$target"
            installed+=("$hook")
        fi
    done
    
    echo "Local installation complete:"
    [[ ${#installed[@]} -gt 0 ]] && echo "  Installed: ${installed[*]}"
    [[ ${#backed_up[@]} -gt 0 ]] && echo "  Backed up: ${backed_up[*]}"
    [[ ${#skipped[@]} -gt 0 ]] && echo "  Skipped: ${skipped[*]}"
}

# Uninstall hooks
hooks_uninstall() {
    local scope="${1:-all}"  # global, local, or all
    
    local removed=()
    local not_found=()
    
    if [[ "$scope" == "global" ]] || [[ "$scope" == "all" ]]; then
        local global_dir
        global_dir=$(hooks_get_global_dir)
        
        for hook in "${HOOK_TYPES[@]}"; do
            local target="$global_dir/$hook"
            if [[ -L "$target" ]]; then
                rm "$target"
                removed+=("$hook (global)")
            else
                not_found+=("$hook (global)")
            fi
        done
    fi
    
    if [[ "$scope" == "local" ]] || [[ "$scope" == "all" ]]; then
        local local_dir
        local_dir=$(hooks_get_local_dir)
        
        if [[ -n "$local_dir" ]]; then
            for hook in "${HOOK_TYPES[@]}"; do
                local target="$local_dir/$hook"
                if [[ -L "$target" ]]; then
                    rm "$target"
                    removed+=("$hook (local)")
                else
                    not_found+=("$hook (local)")
                fi
            done
        fi
    fi
    
    echo "Uninstallation complete:"
    [[ ${#removed[@]} -gt 0 ]] && echo "  Removed: ${removed[*]}"
    [[ ${#not_found[@]} -gt 0 ]] && echo "  Not found: ${not_found[*]}"
}

# Show installation status
hooks_status() {
    echo "Kimi Git Hooks Status"
    echo "====================="
    echo ""
    
    # Global status
    local global_dir
    global_dir=$(hooks_get_global_dir)
    echo "Global hooks directory: $global_dir"
    
    if hooks_global_dir_exists; then
        local global_hooks_path
        global_hooks_path=$(git config --global core.hooksPath 2>/dev/null)
        if [[ "$global_hooks_path" == "$global_dir" ]]; then
            echo "  Status: ENABLED via core.hooksPath"
        else
            echo "  Status: directory exists but not enabled (run 'git config --global core.hooksPath $global_dir')"
        fi
        
        echo "  Installed hooks:"
        for hook in "${HOOK_TYPES[@]}"; do
            local target="$global_dir/$hook"
            if [[ -L "$target" ]]; then
                local link_target
                link_target=$(readlink "$target")
                echo "    ✓ $hook -> $link_target"
            else
                echo "    ✗ $hook (not installed)"
            fi
        done
    else
        echo "  Status: directory does not exist"
    fi
    
    echo ""
    
    # Local status
    local local_dir
    local_dir=$(hooks_get_local_dir)
    if [[ -n "$local_dir" ]]; then
        echo "Local hooks directory: $local_dir"
        echo "  Installed hooks:"
        for hook in "${HOOK_TYPES[@]}"; do
            local target="$local_dir/$hook"
            if [[ -L "$target" ]]; then
                local link_target
                link_target=$(readlink "$target")
                echo "    ✓ $hook -> $link_target"
            elif [[ -e "$target" ]]; then
                echo "    ! $hook (exists but not managed by kimi-hooks)"
            else
                echo "    ✗ $hook (not installed)"
            fi
        done
    else
        echo "Local hooks: not in a git repository"
    fi
    
    echo ""
    echo "Configuration:"
    if [[ -f "$HOME/.config/kimi/hooks.json" ]]; then
        echo "  User config: $HOME/.config/kimi/hooks.json"
    else
        echo "  User config: not found (using defaults)"
    fi
    
    if [[ -f ".kimi/hooks.json" ]]; then
        echo "  Project config: .kimi/hooks.json"
    else
        echo "  Project config: not found"
    fi
}

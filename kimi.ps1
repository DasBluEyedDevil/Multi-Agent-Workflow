# kimi.ps1 -- PowerShell shim for kimi.agent.wrapper.sh
# Resolves bash path on Windows and delegates all arguments to the bash wrapper.
#
# Usage: kimi.ps1 [OPTIONS] PROMPT
# All options and arguments are passed through to kimi.agent.wrapper.sh
#
# Bash resolution order:
#   1. Git Bash ($env:ProgramFiles\Git\bin\bash.exe)
#   2. WSL bash (wsl.exe bash)
#   3. MSYS2 ($env:MSYS2_ROOT\usr\bin\bash.exe)
#   4. Cygwin ($env:CYGWIN_ROOT\bin\bash.exe)
#   5. PATH lookup (bash.exe)

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'

# -- Bash Resolution ----------------------------------------------------------

function Find-Bash {
    # 1. Git Bash (most common on Windows)
    $gitBash = Join-Path $env:ProgramFiles "Git\bin\bash.exe"
    if (Test-Path $gitBash) {
        return $gitBash
    }

    # Also check x86 Program Files
    $gitBashX86 = Join-Path ${env:ProgramFiles(x86)} "Git\bin\bash.exe"
    if (Test-Path $gitBashX86) {
        return $gitBashX86
    }

    # 2. WSL bash (Windows Subsystem for Linux)
    try {
        $wslStatus = wsl --status 2>$null
        if ($LASTEXITCODE -eq 0) {
            # WSL is available, use wsl.exe to invoke bash
            return "WSL"
        }
    } catch {
        # WSL not available, continue
    }

    # 3. MSYS2
    if ($env:MSYS2_ROOT -and (Test-Path (Join-Path $env:MSYS2_ROOT "usr\bin\bash.exe"))) {
        return Join-Path $env:MSYS2_ROOT "usr\bin\bash.exe"
    }

    # 4. Cygwin
    if ($env:CYGWIN_ROOT -and (Test-Path (Join-Path $env:CYGWIN_ROOT "bin\bash.exe"))) {
        return Join-Path $env:CYGWIN_ROOT "bin\bash.exe"
    }

    # 5. PATH lookup
    $pathBash = Get-Command bash.exe -ErrorAction SilentlyContinue
    if ($pathBash) {
        return $pathBash.Source
    }

    return $null
}

# -- Wrapper Path Resolution --------------------------------------------------

function Find-Wrapper {
    $scriptDir = $PSScriptRoot
    
    # Check same directory as this script
    $wrapperSameDir = Join-Path $scriptDir "kimi.agent.wrapper.sh"
    if (Test-Path $wrapperSameDir) {
        return $wrapperSameDir
    }

    # Check skills subdirectory
    $wrapperSkills = Join-Path $scriptDir "skills\kimi.agent.wrapper.sh"
    if (Test-Path $wrapperSkills) {
        return $wrapperSkills
    }

    return $null
}

# -- Path Conversion for WSL --------------------------------------------------

function Convert-ToWslPath {
    param([string]$WindowsPath)
    
    # Convert Windows path to WSL path format
    # C:\Users\foo\bar -> /mnt/c/Users/foo/bar
    $wslPath = $WindowsPath -replace '\\', '/'
    if ($wslPath -match '^([A-Za-z]):(.*)$') {
        $drive = $matches[1].ToLower()
        $rest = $matches[2]
        $wslPath = "/mnt/$drive$rest"
    }
    return $wslPath
}

# -- Argument Escaping --------------------------------------------------------

function Format-BashArguments {
    param([string[]]$Args)
    
    if (-not $Args -or $Args.Count -eq 0) {
        return ""
    }
    
    $escaped = @()
    foreach ($arg in $Args) {
        # Escape single quotes by replacing ' with '\''
        $escapedArg = $arg -replace "'", "'\\''"
        # Wrap in single quotes for bash
        $escaped += "'$escapedArg'"
    }
    
    return $escaped -join ' '
}

# -- Main Execution -----------------------------------------------------------

# Find bash
$bashPath = Find-Bash
if (-not $bashPath) {
    Write-Error @"
Error: bash not found. Install one of the following:

  - Git for Windows: https://git-scm.com/download/win
    (Recommended - includes Git Bash)

  - WSL: wsl --install
    (Windows Subsystem for Linux)

  - MSYS2: https://www.msys2.org/
    (Set MSYS2_ROOT environment variable)

  - Cygwin: https://www.cygwin.com/
    (Set CYGWIN_ROOT environment variable)
"@
    exit 1
}

# Find wrapper script
$wrapperPath = Find-Wrapper
if (-not $wrapperPath) {
    $expectedPath = Join-Path $PSScriptRoot "skills\kimi.agent.wrapper.sh"
    Write-Error "Error: kimi.agent.wrapper.sh not found at $expectedPath"
    exit 1
}

# Build and execute command
$formattedArgs = Format-BashArguments $Arguments

if ($bashPath -eq "WSL") {
    # Use WSL to run bash
    $wslWrapperPath = Convert-ToWslPath $wrapperPath
    $bashCmd = "$wslWrapperPath $formattedArgs"
    
    # Execute via WSL
    & wsl bash -c $bashCmd
} else {
    # Use native bash (Git Bash, MSYS2, Cygwin, or PATH)
    # Convert Windows path to Unix-style for Git Bash/MSYS2/Cygwin
    $unixWrapperPath = $wrapperPath -replace '\\', '/'
    
    # For Git Bash, convert drive letters
    if ($unixWrapperPath -match '^([A-Za-z]):(.*)$') {
        $drive = $matches[1].ToLower()
        $rest = $matches[2]
        $unixWrapperPath = "/$drive$rest"
    }
    
    $bashCmd = "$unixWrapperPath $formattedArgs"
    
    # Execute via bash -c
    & $bashPath -c $bashCmd
}

# Propagate exit code
exit $LASTEXITCODE

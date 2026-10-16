#!/bin/bash
#
# Undoes everything setup-mac.sh installed, so you can test it again.
#
# Removes the research-course folder (venv, labs, requirements.txt), the Jupyter kernel,
# Claude Code, VS Code, the uv-managed Python 3.12 and uv itself.
#
# This is destructive. It asks for confirmation unless you pass --force. Lab files in the
# project folder are deleted, so copy out anything you want to keep first.
#
# Git is left alone by default. It comes from Apple's Command Line Tools, which many other
# tools depend on, and removing them needs sudo.
#
# Usage, from Terminal:
#
#     bash teardown-mac.sh
#
# Options:
#     --project-dir DIR       Folder to delete (default: ~/research-course)
#     --installer-dir DIR     Downloaded installers (default: ./installers next to this script)
#     --remove-installers     Also delete the cached installers
#     --include-claude-config Also delete ~/.claude, ~/.claude.json and the Keychain login
#     --include-vscode-data   Also delete VS Code settings and extensions
#     --keep-uv               Leave uv installed
#     --remove-git            Also remove the Command Line Tools (asks for your password)
#     --force                 Do not ask for confirmation
#     -h, --help              Show this text

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$HOME/research-course"
INSTALLER_DIR="$SCRIPT_DIR/installers"
REMOVE_INSTALLERS=0
INCLUDE_CLAUDE_CONFIG=0
INCLUDE_VSCODE_DATA=0
KEEP_UV=0
REMOVE_GIT=0
FORCE=0

while [ $# -gt 0 ]; do
    case "$1" in
        --project-dir)            PROJECT_DIR="${2:?--project-dir needs a folder}"; shift 2 ;;
        --installer-dir)          INSTALLER_DIR="${2:?--installer-dir needs a folder}"; shift 2 ;;
        --remove-installers)      REMOVE_INSTALLERS=1; shift ;;
        --include-claude-config)  INCLUDE_CLAUDE_CONFIG=1; shift ;;
        --include-vscode-data)    INCLUDE_VSCODE_DATA=1; shift ;;
        --keep-uv)                KEEP_UV=1; shift ;;
        --remove-git)             REMOVE_GIT=1; shift ;;
        --force)                  FORCE=1; shift ;;
        -h|--help)                sed -n '2,/^SCRIPT_DIR=/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)                        echo "Unknown option: $1 (try --help)" >&2; exit 1 ;;
    esac
done

# Keep going when one step fails, and report at the end.
FAILURES=()

LOCAL_BIN="$HOME/.local/bin"
VSCODE_APP="$HOME/Applications/Visual Studio Code.app"

if [ -t 1 ]; then
    C_CYAN=$'\033[36m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_GREY=$'\033[90m'; C_OFF=$'\033[0m'
else
    C_CYAN=''; C_GREEN=''; C_YELLOW=''; C_GREY=''; C_OFF=''
fi
step() { printf '\n%s==> %s%s\n' "$C_CYAN" "$1" "$C_OFF"; }
ok()   { printf '    %s%s%s\n' "$C_GREEN" "$1" "$C_OFF"; }
skip() { printf '    %s%s%s\n' "$C_GREY" "$1" "$C_OFF"; }
warn() { printf '    %s%s%s\n' "$C_YELLOW" "$1" "$C_OFF"; }
have() { command -v "$1" >/dev/null 2>&1; }

[ "$(uname -s)" = "Darwin" ] || { echo 'This script is for macOS only.' >&2; exit 1; }

# rm -rf on a bad path is the one thing this script must not get wrong.
PROJECT_DIR="${PROJECT_DIR%/}"
case "$PROJECT_DIR" in
    ""|"$HOME"|"/"|"$HOME/Desktop"|"$HOME/Documents"|"$HOME/Downloads"|"$HOME/Library")
        echo "Refusing to delete '$PROJECT_DIR'. Pass a dedicated folder with --project-dir." >&2
        exit 1 ;;
esac

remove_path() {
    local path="$1" label="$2"
    if [ -e "$path" ] || [ -L "$path" ]; then
        rm -rf "$path" 2>/dev/null
        if [ -e "$path" ] || [ -L "$path" ]; then
            warn "Could not fully delete $label ($path). Close programs using it and retry."
            FAILURES+=("$label")
        else
            ok "Deleted $label"
        fi
    else
        skip "$label not found"
    fi
}

# ---------------------------------------------------------------- confirm
printf '%sThis will delete:%s\n' "$C_YELLOW" "$C_OFF"
echo "  - $PROJECT_DIR (venv, all lab folders and their files)"
echo '  - Jupyter kernel "research-course"'
echo '  - Claude Code (program only)'
echo '  - Visual Studio Code in ~/Applications (program only)'
echo '  - Python 3.12 installed by uv'
[ "$KEEP_UV" -eq 0 ]               && echo '  - uv'
[ "$REMOVE_GIT" -eq 1 ]            && echo '  - Command Line Tools (Git, and whatever else uses them)'
[ "$REMOVE_INSTALLERS" -eq 1 ]     && echo "  - Cached installers in $INSTALLER_DIR"
[ "$INCLUDE_CLAUDE_CONFIG" -eq 1 ] && echo '  - Claude Code login and settings (~/.claude, ~/.claude.json, Keychain)'
[ "$INCLUDE_VSCODE_DATA" -eq 1 ]   && echo '  - VS Code settings and extensions'

if [ "$FORCE" -eq 0 ]; then
    printf '\nType YES to continue: '
    read -r answer
    if [ "$answer" != "YES" ]; then echo 'Cancelled.'; exit 0; fi
fi

# ---------------------------------------------------------------- stop processes
step 'Stopping running programs'
osascript -e 'tell application id "com.microsoft.VSCode" to quit' >/dev/null 2>&1
pkill -f "$VSCODE_APP/Contents" 2>/dev/null
pkill -x claude 2>/dev/null
pkill -f jupyter-lab 2>/dev/null
pkill -f jupyter-notebook 2>/dev/null
# Any python running from the course venv would keep its files open.
pkill -f "$PROJECT_DIR/.venv" 2>/dev/null
sleep 1
ok 'Done'

# ---------------------------------------------------------------- project + kernel
step 'Removing project folder and Jupyter kernel'
remove_path "$PROJECT_DIR" 'project folder'
remove_path "$HOME/Library/Jupyter/kernels/research-course" 'Jupyter kernel'

# ---------------------------------------------------------------- claude code
step 'Removing Claude Code'
remove_path "$LOCAL_BIN/claude" 'claude binary'
remove_path "$HOME/.local/share/claude" 'Claude Code program files'
if [ "$INCLUDE_CLAUDE_CONFIG" -eq 1 ]; then
    remove_path "$HOME/.claude" '~/.claude'
    remove_path "$HOME/.claude.json" '~/.claude.json'
    # Claude Code keeps the login in the Keychain on macOS. Best effort: the item may not exist.
    if security delete-generic-password -s 'Claude Code-credentials' >/dev/null 2>&1; then
        ok 'Deleted Claude Code login from the Keychain'
    else
        skip 'No Claude Code login found in the Keychain'
    fi
else
    skip 'Keeping Claude login and settings (use --include-claude-config to delete)'
fi

# ---------------------------------------------------------------- vs code
step 'Removing Visual Studio Code'
remove_path "$VSCODE_APP" 'VS Code'
# The `code` link setup-mac.sh created. Leave it alone if it points somewhere else.
if [ -L "$LOCAL_BIN/code" ] && [[ "$(readlink "$LOCAL_BIN/code")" == *"Visual Studio Code.app"* ]]; then
    remove_path "$LOCAL_BIN/code" 'code command'
fi
if [ "$INCLUDE_VSCODE_DATA" -eq 1 ]; then
    remove_path "$HOME/Library/Application Support/Code" 'VS Code settings'
    remove_path "$HOME/.vscode" 'VS Code extensions'
else
    skip 'Keeping VS Code settings and extensions (use --include-vscode-data to delete)'
fi

# ---------------------------------------------------------------- python + uv
step 'Removing Python 3.12'
if have uv; then
    if uv python uninstall 3.12 >/dev/null 2>&1; then
        ok 'Python 3.12 removed'
    else
        skip 'No uv-managed Python 3.12 found'
    fi
else
    skip 'uv not found, so no uv-managed Python to remove'
fi

if [ "$KEEP_UV" -eq 1 ]; then
    step 'Keeping uv (--keep-uv)'
else
    step 'Removing uv'
    remove_path "$LOCAL_BIN/uv" 'uv'
    remove_path "$LOCAL_BIN/uvx" 'uvx'
    remove_path "$HOME/.local/share/uv" 'uv data'
    remove_path "$HOME/.cache/uv" 'uv cache'
fi

# ---------------------------------------------------------------- git
if [ "$REMOVE_GIT" -eq 1 ]; then
    step 'Removing the Command Line Tools'
    if [ -d /Library/Developer/CommandLineTools ]; then
        if sudo rm -rf /Library/Developer/CommandLineTools; then
            ok 'Command Line Tools removed'
        else
            warn 'Could not remove /Library/Developer/CommandLineTools'
            FAILURES+=('Command Line Tools')
        fi
    else
        skip 'Command Line Tools not found'
    fi
else
    step 'Keeping Git (use --remove-git to remove the Command Line Tools)'
fi

# ---------------------------------------------------------------- path
# Remove the PATH line setup-mac.sh added, but only once nothing else lives in ~/.local/bin.
if [ -f "$HOME/.zprofile" ] && grep -q '# research-course$' "$HOME/.zprofile"; then
    if [ -d "$LOCAL_BIN" ] && [ -n "$(ls -A "$LOCAL_BIN" 2>/dev/null)" ]; then
        skip '~/.local/bin still has other tools, keeping its PATH line in ~/.zprofile'
    else
        sed -i '' '/# research-course$/d' "$HOME/.zprofile"
        rmdir "$LOCAL_BIN" 2>/dev/null
        ok 'Removed the PATH line from ~/.zprofile'
    fi
fi

# ---------------------------------------------------------------- installers
if [ "$REMOVE_INSTALLERS" -eq 1 ]; then
    step 'Removing cached installers'
    remove_path "$INSTALLER_DIR" 'installers folder'
fi

# ---------------------------------------------------------------- summary
echo
if [ "${#FAILURES[@]}" -eq 0 ]; then
    printf '%sTeardown finished. Open a new Terminal window before running setup-mac.sh again.%s\n' "$C_GREEN" "$C_OFF"
else
    printf '%sTeardown finished with problems:%s\n' "$C_YELLOW" "$C_OFF"
    for f in "${FAILURES[@]}"; do printf '  %s- %s%s\n' "$C_YELLOW" "$f" "$C_OFF"; done
    printf '%sFix those by hand, then open a new Terminal window.%s\n' "$C_YELLOW" "$C_OFF"
fi

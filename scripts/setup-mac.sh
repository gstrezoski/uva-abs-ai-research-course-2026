#!/bin/bash
#
# Installs everything needed for the researchers course on macOS (Apple silicon or Intel).
#
# Installs Git (through Apple's Command Line Tools), Python 3.12 (through uv), VS Code and
# Claude Code, then creates a Python virtual environment with the course libraries (numpy,
# pandas, scrapy, etc.). Each lab folder gets an AGENTS.md and a copy of permissions.md, which
# must sit next to this script.
#
# Nothing here needs sudo. Python, uv, Claude Code and VS Code all go into your home folder.
# The only prompt you will see is the macOS dialog for the Command Line Tools, if Git is missing.
# Safe to run twice. Anything already installed is skipped.
#
# Usage, from Terminal:
#
#     bash setup-mac.sh
#
# Options:
#     --project-dir DIR    Where to put the course folder and venv (default: ~/research-course)
#     --installer-dir DIR  Folder for the downloaded VS Code zip (default: ./installers next to
#                          this script). A file already there is reused, so you can pre-load
#                          a USB stick.
#     --skip-vscode        Skip the VS Code install
#     -h, --help           Show this text

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$HOME/research-course"
INSTALLER_DIR="$SCRIPT_DIR/installers"
SKIP_VSCODE=0

while [ $# -gt 0 ]; do
    case "$1" in
        --project-dir)   PROJECT_DIR="${2:?--project-dir needs a folder}"; shift 2 ;;
        --installer-dir) INSTALLER_DIR="${2:?--installer-dir needs a folder}"; shift 2 ;;
        --skip-vscode)   SKIP_VSCODE=1; shift ;;
        -h|--help)       sed -n '2,/^set -euo/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)               echo "Unknown option: $1 (try --help)" >&2; exit 1 ;;
    esac
done

# Python packages for the course.
PIP_PACKAGES=(
    numpy pandas scipy matplotlib seaborn scikit-learn
    jupyterlab ipykernel
    requests beautifulsoup4 lxml scrapy   # scraping labs
    anthropic                             # Claude API
    python-dotenv
)

# One folder per lab, each with the project structure from the lecture.
# Edit the names here when the lab titles are final.
LABS=(lab0-intro lab1-scraping lab2-privacy-ethics lab3)

LOCAL_BIN="$HOME/.local/bin"
VSCODE_APP="$HOME/Applications/Visual Studio Code.app"
VSCODE_URL="https://update.code.visualstudio.com/latest/darwin-universal/stable"
VSCODE_ZIP="VSCode-darwin-universal.zip"

if [ -t 1 ]; then
    C_CYAN=$'\033[36m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_OFF=$'\033[0m'
else
    C_CYAN=''; C_GREEN=''; C_YELLOW=''; C_OFF=''
fi
step() { printf '\n%s==> %s%s\n' "$C_CYAN" "$1" "$C_OFF"; }
ok()   { printf '    %s%s%s\n' "$C_GREEN" "$1" "$C_OFF"; }
warn() { printf '    %s%s%s\n' "$C_YELLOW" "$1" "$C_OFF"; }
die()  { printf '\n%sError: %s%s\n' "$C_YELLOW" "$1" "$C_OFF" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

export PATH="$LOCAL_BIN:$PATH"

has_git() {
    # /usr/bin/git exists on every Mac but is a stub until the Command Line Tools are installed,
    # so `command -v git` proves nothing.
    xcode-select -p >/dev/null 2>&1 || [ -x /opt/homebrew/bin/git ] || [ -x /usr/local/bin/git ]
}

vscode_cli() {
    local p
    for p in "$VSCODE_APP/Contents/Resources/app/bin/code" \
             "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"; do
        if [ -x "$p" ]; then echo "$p"; return 0; fi
    done
    return 1
}

# ---------------------------------------------------------------- preflight
step 'Checking prerequisites'
[ "$(uname -s)" = "Darwin" ] || die 'This script is for macOS only.'
have curl || die 'curl not found.'
ok "macOS $(sw_vers -productVersion) on $(uname -m)"

# ---------------------------------------------------------------- git
step 'Installing Git'
if has_git; then
    ok 'Git already installed'
else
    echo '    Git comes with Apple'"'"'s Command Line Tools. A macOS dialog will open.'
    echo '    Click Install and wait. This takes a few minutes.'
    xcode-select --install >/dev/null 2>&1 || true
    waited=0
    until xcode-select -p >/dev/null 2>&1; do
        [ "$waited" -lt 1800 ] || die 'Timed out waiting for the Command Line Tools. Install them, then run this script again.'
        sleep 5
        waited=$((waited + 5))
    done
    ok 'Command Line Tools installed'
fi

# ---------------------------------------------------------------- uv + python
step 'Installing uv (used to get Python 3.12 without admin rights)'
if have uv; then
    ok "uv already installed ($(uv --version))"
else
    curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh \
        || die 'uv install failed.'
    have uv || die 'uv installed but was not found on PATH.'
    ok "uv installed ($(uv --version))"
fi

step 'Installing Python 3.12'
PYTHON312="$(uv python find 3.12 2>/dev/null || true)"
if [ -n "$PYTHON312" ]; then
    ok "Python 3.12 already installed ($PYTHON312)"
else
    uv python install 3.12 || die 'Python 3.12 install failed.'
    PYTHON312="$(uv python find 3.12 2>/dev/null || true)"
    [ -n "$PYTHON312" ] || die 'Python 3.12 was not found after installing.'
    ok "Python 3.12 installed ($PYTHON312)"
fi

# ---------------------------------------------------------------- vs code
if [ "$SKIP_VSCODE" -eq 0 ]; then
    step 'Installing Visual Studio Code'
    if vscode_cli >/dev/null; then
        ok 'VS Code already installed'
    else
        mkdir -p "$INSTALLER_DIR" "$HOME/Applications"
        zip="$INSTALLER_DIR/$VSCODE_ZIP"
        if [ -f "$zip" ] && [ "$(stat -f%z "$zip")" -gt 1048576 ]; then
            ok "Using local installer $VSCODE_ZIP"
        else
            echo "    Downloading $VSCODE_ZIP..."
            curl -fL --progress-bar -o "$zip.part" "$VSCODE_URL" || die 'VS Code download failed.'
            mv "$zip.part" "$zip"
        fi
        # ditto keeps the app bundle's symlinks and code signature intact. unzip does not.
        ditto -x -k "$zip" "$HOME/Applications" || die 'Could not unpack VS Code.'
        [ -d "$VSCODE_APP" ] || die 'VS Code app not found after unpacking.'
        ok "VS Code installed in $HOME/Applications"
    fi
    # Put `code` on PATH without the sudo that VS Code's own "Install code command" needs.
    mkdir -p "$LOCAL_BIN"
    ln -sf "$(vscode_cli)" "$LOCAL_BIN/code"
fi

# ---------------------------------------------------------------- claude code
step 'Installing Claude Code'
if have claude; then
    ok "Claude Code already installed ($(claude --version))"
else
    curl -fsSL https://claude.ai/install.sh | bash || die 'Claude Code install failed.'
    if have claude; then
        ok "Claude Code installed ($(claude --version))"
    else
        warn 'Installed, but "claude" is not on PATH yet. Open a new Terminal window after this script finishes.'
    fi
fi

# Make ~/.local/bin (uv, claude, code) available in new Terminal windows.
if ! grep -qs '\.local/bin' "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc"; then
    printf '\nexport PATH="$HOME/.local/bin:$PATH"  # research-course\n' >> "$HOME/.zprofile"
    ok 'Added ~/.local/bin to PATH in ~/.zprofile'
fi

# ---------------------------------------------------------------- python env
step "Creating project folder at $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"

VENV_DIR="$PROJECT_DIR/.venv"
VENV_PY="$VENV_DIR/bin/python"

if [ ! -x "$VENV_PY" ]; then
    step 'Creating virtual environment'
    # Call the 3.12 interpreter directly so another Python on PATH can't interfere.
    "$PYTHON312" -m venv "$VENV_DIR" || die 'Failed to create the virtual environment.'
    ok '.venv created'
else
    ok '.venv already exists'
fi

step 'Installing Python packages (this takes a few minutes)'
"$VENV_PY" -m pip install --upgrade pip
"$VENV_PY" -m pip install "${PIP_PACKAGES[@]}" || die 'pip install failed. See the error above.'
ok 'Packages installed'

# Register the venv as a Jupyter kernel so notebooks can find it.
"$VENV_PY" -m ipykernel install --user --name research-course --display-name 'Python (research-course)' >/dev/null

# Write requirements.txt so the environment can be rebuilt later.
"$VENV_PY" -m pip freeze > "$PROJECT_DIR/requirements.txt"

# ---------------------------------------------------------------- lab folders
step 'Creating lab folders'
read -r -d '' AGENTS_TEMPLATE <<'EOF' || true
# AGENTS.md

## Project
{LAB}: describe what this lab is about in one or two sentences.

## Rules
- Read permissions.md in this folder before you act, and follow it

## Conventions
- Python 3.12, dependencies live in the shared .venv one folder up
- Never overwrite files in data/raw
- Save results to outputs/, keep scripts in scripts/
- Run the script once and check the output before you say you're done

## Style
- Plain language, no marketing tone
EOF

# The same permissions.md goes into every lab folder. It lives next to this script.
PERMISSIONS_SOURCE="$SCRIPT_DIR/permissions.md"
if [ ! -f "$PERMISSIONS_SOURCE" ]; then
    warn "permissions.md not found next to this script ($SCRIPT_DIR). Lab folders will be created without it."
    warn 'Download the whole repository, not just this file, and run the script again.'
fi

for lab in "${LABS[@]}"; do
    lab_dir="$PROJECT_DIR/$lab"
    mkdir -p "$lab_dir/data/raw" "$lab_dir/notes" "$lab_dir/scripts" "$lab_dir/outputs"
    if [ ! -f "$lab_dir/AGENTS.md" ]; then
        printf '%s\n' "${AGENTS_TEMPLATE//\{LAB\}/$lab}" > "$lab_dir/AGENTS.md"
    fi
    if [ -f "$PERMISSIONS_SOURCE" ] && [ ! -f "$lab_dir/permissions.md" ]; then
        cp "$PERMISSIONS_SOURCE" "$lab_dir/permissions.md"
    fi
    ok "$lab"
done

# ---------------------------------------------------------------- vs code extensions
if [ "$SKIP_VSCODE" -eq 0 ] && CODE_CLI="$(vscode_cli)"; then
    step 'Installing VS Code extensions'
    for ext in ms-python.python ms-toolsai.jupyter anthropic.claude-code; do
        if "$CODE_CLI" --install-extension "$ext" --force >/dev/null 2>&1; then
            ok "$ext"
        else
            warn "$ext failed to install. Add it later from the VS Code Extensions panel."
        fi
    done
fi

# ---------------------------------------------------------------- verify
step 'Verifying'
"$VENV_PY" - <<'PY' || die 'A library failed to import.'
import numpy, pandas, scipy, matplotlib, sklearn, scrapy, requests, bs4, anthropic
print("    Python libraries OK. numpy", numpy.__version__, "| pandas", pandas.__version__)
PY

for tool in git claude code; do
    if have "$tool"; then ok "$tool found"; else warn "$tool not found on PATH yet (open a new Terminal window)"; fi
done

# ---------------------------------------------------------------- done
printf '%s' "$C_GREEN"
cat <<EOF

Setup finished.

Next steps:
  1. Close this window and open a new Terminal.
  2. cd $PROJECT_DIR
  3. source .venv/bin/activate
  4. cd lab0-intro   (each lab folder has data, notes, scripts, outputs, AGENTS.md and permissions.md)
  5. claude          (first run asks you to log in)
EOF
printf '%s' "$C_OFF"

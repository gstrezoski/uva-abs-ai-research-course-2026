<#
.SYNOPSIS
    Installs everything needed for the researchers course on Windows 10/11.

.DESCRIPTION
    Downloads and installs Git, Python 3.12, VS Code and Claude Code, then creates a Python
    virtual environment with the course libraries (numpy, pandas, scrapy, etc.). Each lab folder
    gets an AGENTS.md and a copy of permissions.md, which must sit next to this script.
    Safe to run twice. Anything already installed is skipped.

.USAGE
    Open PowerShell (a normal window, not "Run as administrator") and run:

        powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1

    Optional parameters:
        -ProjectDir  Where to put the course folder and venv (default: ~\research-course)
        -InstallerDir  Folder for downloaded .exe installers (default: .\installers).
                       Files already there are reused, so you can pre-load a USB stick.
        -SkipVSCode  Skip the VS Code install
#>

[CmdletBinding()]
param(
    [string]$ProjectDir = (Join-Path $HOME 'research-course'),
    [string]$InstallerDir = (Join-Path ($(if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path })) 'installers'),
    [switch]$SkipVSCode
)

$ErrorActionPreference = 'Stop'

# Python packages for the course. Pinned loosely so pip picks wheels for 3.12.
$PipPackages = @(
    'numpy', 'pandas', 'scipy', 'matplotlib', 'seaborn', 'scikit-learn',
    'jupyterlab', 'ipykernel',
    'requests', 'beautifulsoup4', 'lxml', 'scrapy',   # scraping labs
    'anthropic',                                      # Claude API
    'python-dotenv'
)

# One folder per lab, each with the project structure from the lecture.
# Edit the names here when the lab titles are final.
$Labs = @('lab0-intro', 'lab1-scraping', 'lab2-privacy-ethics', 'lab3')

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    $msg" -ForegroundColor Green }
function Write-Warn2($msg){ Write-Host "    $msg" -ForegroundColor Yellow }

function Update-SessionPath {
    # Pick up PATH changes made by installers without opening a new window.
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user    = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user;$HOME\.local\bin"
}

function Test-Command($name) {
    [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Get-Python312Exe {
    # Look for the interpreter by path. Calling `py -3.12` is unreliable: a
    # leftover py launcher writes errors to stderr, which is fatal here.
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "$env:ProgramFiles\Python312\python.exe"
    )
    $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}

function Get-Installer($fileName, $url) {
    # Reuse a file already in $InstallerDir (handy for USB sticks / offline
    # labs), otherwise download it.
    New-Item -ItemType Directory -Force -Path $InstallerDir | Out-Null
    $dest = Join-Path $InstallerDir $fileName
    if ((Test-Path $dest) -and (Get-Item $dest).Length -gt 1MB) {
        Write-Ok "Using local installer $fileName"
        return $dest
    }
    Write-Host "    Downloading $fileName..."
    $ProgressPreference = 'SilentlyContinue'   # progress bar makes downloads much slower
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
    return $dest
}

function Install-Exe($label, $isInstalled, $fileName, $url, $installerArgs) {
    if (& $isInstalled) {
        Write-Ok "$label already installed"
        return
    }
    $file = Get-Installer $fileName $url
    Write-Host "    Installing $label (approve the Windows prompt if one appears)..."
    $proc = Start-Process -FilePath $file -ArgumentList $installerArgs -Wait -PassThru
    # 3010 means success, reboot recommended.
    if ($proc.ExitCode -notin 0, 3010) {
        throw "$label installer failed (exit code $($proc.ExitCode))"
    }
    Update-SessionPath
    Write-Ok "$label installed"
}

function Get-GitInstallerUrl {
    # Latest 64-bit Git for Windows installer; falls back to a pinned version
    # if the GitHub API is rate limited.
    try {
        $rel = Invoke-RestMethod 'https://api.github.com/repos/git-for-windows/git/releases/latest' -UseBasicParsing
        $asset = $rel.assets | Where-Object { $_.name -match '^Git-[\d\.]+-64-bit\.exe$' } | Select-Object -First 1
        if ($asset) { return @{ Name = $asset.name; Url = $asset.browser_download_url } }
    } catch { }
    return @{
        Name = 'Git-2.47.1-64-bit.exe'
        Url  = 'https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.exe'
    }
}

# ---------------------------------------------------------------- preflight
Write-Step 'Checking prerequisites'

if ([Environment]::OSVersion.Platform -ne 'Win32NT') {
    throw 'This script is for Windows only.'
}
Write-Ok "Installers are cached in $InstallerDir"

# ---------------------------------------------------------------- system tools
Write-Step 'Installing Git (Claude Code needs it on Windows)'
$git = Get-GitInstallerUrl
Install-Exe 'Git for Windows' { Test-Command git } $git.Name $git.Url `
    '/VERYSILENT /NORESTART /NOAUTOUPDATE /SP-'

Write-Step 'Installing Python 3.12'
Install-Exe 'Python 3.12' {
    [bool](Get-Python312Exe)
} 'python-3.12.10-amd64.exe' 'https://www.python.org/ftp/python/3.12.10/python-3.12.10-amd64.exe' `
    '/quiet InstallAllUsers=0 PrependPath=1 Include_launcher=1 Include_test=0'

if (-not $SkipVSCode) {
    Write-Step 'Installing Visual Studio Code'
    Install-Exe 'VS Code' {
        (Test-Command code) -or (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe")
    } 'VSCodeUserSetup-x64.exe' 'https://update.code.visualstudio.com/latest/win32-x64-user/stable' `
        '/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addtopath'
}

Update-SessionPath

# ---------------------------------------------------------------- claude code
Write-Step 'Installing Claude Code'
if (Test-Command claude) {
    Write-Ok "Claude Code already installed ($(claude --version))"
} else {
    Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
    Update-SessionPath
    if (Test-Command claude) {
        Write-Ok "Claude Code installed ($(claude --version))"
    } else {
        Write-Warn2 'Installed, but "claude" is not on PATH yet. Open a new PowerShell window after this script finishes.'
    }
}

# ---------------------------------------------------------------- python env
Write-Step "Creating project folder at $ProjectDir"
New-Item -ItemType Directory -Force -Path $ProjectDir | Out-Null

# Call the 3.12 interpreter directly so another Python on PATH can't interfere.
$python312 = Get-Python312Exe
if (-not $python312) { throw 'Python 3.12 was not found after installing. Open a new PowerShell window and run this script again.' }
$venvDir = Join-Path $ProjectDir '.venv'
$venvPython = Join-Path $venvDir 'Scripts\python.exe'

if (-not (Test-Path $venvPython)) {
    Write-Step 'Creating virtual environment'
    & $python312 -m venv $venvDir
    if ($LASTEXITCODE -ne 0) { throw 'Failed to create the virtual environment.' }
    Write-Ok '.venv created'
} else {
    Write-Ok '.venv already exists'
}

Write-Step 'Installing Python packages (this takes a few minutes)'
& $venvPython -m pip install --upgrade pip
& $venvPython -m pip install @PipPackages
if ($LASTEXITCODE -ne 0) { throw 'pip install failed. See the error above.' }
Write-Ok 'Packages installed'

# Register the venv as a Jupyter kernel so notebooks can find it.
& $venvPython -m ipykernel install --user --name research-course --display-name 'Python (research-course)' | Out-Null

# Write requirements.txt so the environment can be rebuilt later.
& $venvPython -m pip freeze | Set-Content -Encoding utf8 (Join-Path $ProjectDir 'requirements.txt')

# ---------------------------------------------------------------- lab folders
Write-Step 'Creating lab folders'
$agentsTemplate = @'
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
'@

# The same permissions.md goes into every lab folder. It lives next to this script.
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$permissionsSource = Join-Path $scriptDir 'permissions.md'
if (-not (Test-Path $permissionsSource)) {
    Write-Warn2 "permissions.md not found next to this script ($scriptDir). Lab folders will be created without it."
    Write-Warn2 'Download the whole repository, not just this file, and run the script again.'
}

foreach ($lab in $Labs) {
    $labDir = Join-Path $ProjectDir $lab
    foreach ($sub in 'data\raw', 'notes', 'scripts', 'outputs') {
        New-Item -ItemType Directory -Force -Path (Join-Path $labDir $sub) | Out-Null
    }
    $agents = Join-Path $labDir 'AGENTS.md'
    if (-not (Test-Path $agents)) {
        $agentsTemplate.Replace('{LAB}', $lab) | Set-Content -Encoding utf8 $agents
    }
    $permissions = Join-Path $labDir 'permissions.md'
    if ((Test-Path $permissionsSource) -and -not (Test-Path $permissions)) {
        Copy-Item $permissionsSource $permissions
    }
    Write-Ok $lab
}

# ---------------------------------------------------------------- vs code extensions
if (-not $SkipVSCode -and (Test-Command code)) {
    Write-Step 'Installing VS Code extensions'
    # `code` prints a Node deprecation warning to stderr. Under 'Stop' that
    # becomes a fatal error in Windows PowerShell 5.1, so relax it here and
    # judge success by the exit code instead.
    $ErrorActionPreference = 'Continue'
    foreach ($ext in 'ms-python.python', 'ms-toolsai.jupyter', 'anthropic.claude-code') {
        code --install-extension $ext --force 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Ok $ext }
        else { Write-Warn2 "$ext failed to install. Add it later from the VS Code Extensions panel." }
    }
    $ErrorActionPreference = 'Stop'
}

# ---------------------------------------------------------------- verify
Write-Step 'Verifying'
$check = @'
import numpy, pandas, scipy, matplotlib, sklearn, scrapy, requests, bs4, anthropic
print("Python libraries OK. numpy", numpy.__version__, "| pandas", pandas.__version__)
'@
# Run from a file: Windows PowerShell 5.1 mangles quotes passed to `python -c`.
$checkFile = Join-Path $env:TEMP 'course_check.py'
Set-Content -Path $checkFile -Value $check -Encoding ascii
& $venvPython $checkFile
$checkExit = $LASTEXITCODE
Remove-Item $checkFile -ErrorAction SilentlyContinue
if ($checkExit -ne 0) { throw 'A library failed to import.' }

foreach ($tool in 'git', 'claude', 'code') {
    if (Test-Command $tool) { Write-Ok "$tool found" }
    else { Write-Warn2 "$tool not found on PATH yet (open a new PowerShell window)" }
}

# ---------------------------------------------------------------- done
Write-Host @"

Setup finished.

Next steps:
  1. Close this window and open a new PowerShell.
  2. cd $ProjectDir
  3. .\.venv\Scripts\Activate.ps1
  4. cd lab0-intro   (each lab folder has data, notes, scripts, outputs, AGENTS.md and permissions.md)
  5. claude          (first run asks you to log in)

If Activate.ps1 is blocked, run once:
  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
"@ -ForegroundColor Green

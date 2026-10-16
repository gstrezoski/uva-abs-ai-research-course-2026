<#
.SYNOPSIS
    Undoes everything setup-windows.ps1 installed, so you can test it again.

.DESCRIPTION
    Removes the research-course folder (venv, labs, requirements.txt), the
    Jupyter kernel, Claude Code, VS Code, Python 3.12 and Git for Windows.

    This is destructive. It asks for confirmation unless you pass -Force.
    Lab files in the project folder are deleted, so copy out anything you
    want to keep first.

.USAGE
        powershell -ExecutionPolicy Bypass -File .\teardown-windows.ps1

    Optional parameters:
        -ProjectDir           Folder to delete (default: ~\research-course)
        -InstallerDir         Downloaded installers (default: .\installers)
        -RemoveInstallers     Also delete the cached installers
        -IncludeClaudeConfig  Also delete ~\.claude and ~\.claude.json (login, settings, memory)
        -IncludeVSCodeData    Also delete VS Code settings and extensions
        -KeepGit              Leave Git installed
        -Force                Do not ask for confirmation
#>

[CmdletBinding()]
param(
    [string]$ProjectDir = (Join-Path $HOME 'research-course'),
    [string]$InstallerDir = (Join-Path ($(if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path })) 'installers'),
    [switch]$RemoveInstallers,
    [switch]$IncludeClaudeConfig,
    [switch]$IncludeVSCodeData,
    [switch]$KeepGit,
    [switch]$Force
)

# Keep going when one step fails, and report at the end.
$ErrorActionPreference = 'Continue'
$failures = New-Object System.Collections.Generic.List[string]

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "    $msg" -ForegroundColor DarkGray }
function Write-Warn2($msg){ Write-Host "    $msg" -ForegroundColor Yellow }

function Get-UninstallEntry($namePattern) {
    $roots = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
             'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
             'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    Get-ItemProperty $roots -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match $namePattern }
}

function Remove-PathItem($path, $label) {
    if (Test-Path $path) {
        Remove-Item -Recurse -Force $path -ErrorAction SilentlyContinue
        if (Test-Path $path) {
            Write-Warn2 "Could not fully delete $label ($path). Close programs using it and retry."
            $failures.Add($label)
        } else {
            Write-Ok "Deleted $label"
        }
    } else {
        Write-Skip "$label not found"
    }
}

function Remove-UserPathEntry($entry) {
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not $user) { return }
    $parts = $user -split ';' | Where-Object { $_ -and ($_.TrimEnd('\') -ne $entry.TrimEnd('\')) }
    $new = $parts -join ';'
    if ($new -ne $user) {
        [Environment]::SetEnvironmentVariable('Path', $new, 'User')
        Write-Ok "Removed $entry from your PATH"
    }
}

function Invoke-Uninstaller($label, $exe, $exeArgs) {
    Write-Host "    Uninstalling $label (approve the Windows prompt if one appears)..."
    try {
        $p = Start-Process -FilePath $exe -ArgumentList $exeArgs -Wait -PassThru
        if ($p.ExitCode -in 0, 3010) { Write-Ok "$label removed" }
        else { Write-Warn2 "$label uninstaller exited with code $($p.ExitCode)"; $failures.Add($label) }
    } catch {
        Write-Warn2 "$label uninstall failed: $($_.Exception.Message)"
        $failures.Add($label)
    }
}

# ---------------------------------------------------------------- confirm
Write-Host 'This will delete:' -ForegroundColor Yellow
Write-Host "  - $ProjectDir (venv, all lab folders and their files)"
Write-Host '  - Jupyter kernel "research-course"'
Write-Host '  - Claude Code (program only)'
Write-Host '  - Visual Studio Code (program only)'
Write-Host '  - Python 3.12'
if (-not $KeepGit)          { Write-Host '  - Git for Windows' }
if ($RemoveInstallers)      { Write-Host "  - Cached installers in $InstallerDir" }
if ($IncludeClaudeConfig)   { Write-Host '  - Claude Code login and settings (~\.claude, ~\.claude.json)' }
if ($IncludeVSCodeData)     { Write-Host '  - VS Code settings and extensions' }

if (-not $Force) {
    $answer = Read-Host "`nType YES to continue"
    if ($answer -cne 'YES') { Write-Host 'Cancelled.'; return }
}

# ---------------------------------------------------------------- stop processes
Write-Step 'Stopping running programs'
foreach ($name in 'Code', 'claude', 'jupyter-lab', 'jupyter-notebook') {
    Get-Process -Name $name -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
# Any python running from the course venv would lock its files.
Get-Process -Name python, pythonw -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -and $_.Path -like "$ProjectDir*" } |
    Stop-Process -Force -ErrorAction SilentlyContinue
Write-Ok 'Done'

# ---------------------------------------------------------------- project + kernel
Write-Step 'Removing project folder and Jupyter kernel'
Remove-PathItem $ProjectDir 'project folder'
Remove-PathItem (Join-Path $env:APPDATA 'jupyter\kernels\research-course') 'Jupyter kernel'

# ---------------------------------------------------------------- claude code
Write-Step 'Removing Claude Code'
Remove-PathItem (Join-Path $HOME '.local\bin\claude.exe') 'claude.exe'
Remove-PathItem (Join-Path $HOME '.local\share\claude') 'Claude Code program files'
Remove-UserPathEntry (Join-Path $HOME '.local\bin')
if ($IncludeClaudeConfig) {
    Remove-PathItem (Join-Path $HOME '.claude') '~\.claude'
    Remove-PathItem (Join-Path $HOME '.claude.json') '~\.claude.json'
} else {
    Write-Skip 'Keeping Claude login and settings (use -IncludeClaudeConfig to delete)'
}

# ---------------------------------------------------------------- vs code
Write-Step 'Removing Visual Studio Code'
$vsDir = Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code'
$vsUninstaller = Join-Path $vsDir 'unins000.exe'
if (Test-Path $vsUninstaller) {
    Invoke-Uninstaller 'VS Code' $vsUninstaller '/VERYSILENT /NORESTART'
} else {
    Write-Skip 'VS Code (user install) not found'
}
if ($IncludeVSCodeData) {
    Remove-PathItem (Join-Path $env:APPDATA 'Code') 'VS Code settings'
    Remove-PathItem (Join-Path $HOME '.vscode') 'VS Code extensions'
} else {
    Write-Skip 'Keeping VS Code settings and extensions (use -IncludeVSCodeData to delete)'
}

# ---------------------------------------------------------------- python
Write-Step 'Removing Python 3.12'
$pyEntries = Get-UninstallEntry '^Python 3\.12\.\d+ \(64-bit\)$'
if ($pyEntries) {
    foreach ($e in $pyEntries) {
        if ($e.QuietUninstallString) {
            Invoke-Uninstaller $e.DisplayName 'cmd.exe' "/c $($e.QuietUninstallString)"
        } elseif ($e.UninstallString) {
            Invoke-Uninstaller $e.DisplayName 'cmd.exe' "/c $($e.UninstallString) /quiet"
        }
    }
} else {
    # Fall back to the cached installer, which can uninstall itself.
    $pyExe = Join-Path $InstallerDir 'python-3.12.10-amd64.exe'
    if (Test-Path $pyExe) { Invoke-Uninstaller 'Python 3.12' $pyExe '/uninstall /quiet' }
    else { Write-Skip 'Python 3.12 not found' }
}

# ---------------------------------------------------------------- git
if ($KeepGit) {
    Write-Step 'Keeping Git (-KeepGit)'
} else {
    Write-Step 'Removing Git for Windows'
    $gitEntry = Get-UninstallEntry '^Git( version [\d\.]+)?$' | Select-Object -First 1
    $gitUninstaller = 'C:\Program Files\Git\unins000.exe'
    if ($gitEntry -and $gitEntry.UninstallString) {
        $gitUninstaller = $gitEntry.UninstallString.Trim('"')
    }
    if (Test-Path $gitUninstaller) {
        Invoke-Uninstaller 'Git for Windows' $gitUninstaller '/VERYSILENT /NORESTART'
    } else {
        Write-Skip 'Git for Windows not found'
    }
}

# ---------------------------------------------------------------- installers
if ($RemoveInstallers) {
    Write-Step 'Removing cached installers'
    Remove-PathItem $InstallerDir 'installers folder'
}

# ---------------------------------------------------------------- summary
Write-Host ''
if ($failures.Count -eq 0) {
    Write-Host 'Teardown finished. Open a new PowerShell window before running setup-windows.ps1 again.' -ForegroundColor Green
} else {
    Write-Host 'Teardown finished with problems:' -ForegroundColor Yellow
    $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host 'Fix those by hand, then open a new PowerShell window.' -ForegroundColor Yellow
}

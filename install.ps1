# Install the Feynman diagram drawing skill into every agent found on this machine.
#
#   irm https://raw.githubusercontent.com/ammelsayed/feynman_diagram_drawing_skills/main/install.ps1 | iex
#
# or, from a clone:
#
#   .\install.ps1              # install
#   .\install.ps1 -DryRun      # show what would happen
#   .\install.ps1 -Uninstall   # remove
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
$Repo = 'https://github.com/ammelsayed/feynman_diagram_drawing_skills.git'
$Skill = 'feynman-diagram'
$Marker = '.feynman-diagram-installer'

# Agent skill directories. Only agents whose parent directory exists are touched,
# except the universal target, which is always valid.
$Targets = @(
    @{ Label = 'Claude Code';               Dir = Join-Path $HOME '.claude\skills';      Universal = $false },
    @{ Label = 'Codex';                     Dir = Join-Path $HOME '.codex\skills';       Universal = $false },
    @{ Label = 'OpenCode';                  Dir = Join-Path $HOME '.config\opencode\skills'; Universal = $false },
    @{ Label = 'Cursor';                    Dir = Join-Path $HOME '.cursor\skills';      Universal = $false },
    @{ Label = 'zcode';                     Dir = Join-Path $HOME '.zcode\skills';       Universal = $false },
    @{ Label = 'DSH';                       Dir = Join-Path $HOME '.dsh\skills';         Universal = $false },
    @{ Label = 'WorkBuddy';                 Dir = Join-Path $HOME '.workbuddy\skills';   Universal = $false },
    @{ Label = 'Agent Skills (universal)';  Dir = Join-Path $HOME '.agents\skills';      Universal = $true }
)

$Temp = $null
$Src = $null

function Write-Step {
    param([scriptblock]$Action, [string]$Description)
    if ($DryRun) { Write-Host "  [dry-run] $Description" }
    else { & $Action }
}

try {
    # Uninstall needs no source: handle it before any clone.
    if ($Uninstall) {
        Write-Host 'Uninstalling Feynman diagram drawing skills'
        foreach ($t in $Targets) {
            $path = Join-Path $t.Dir $Skill
            if (Test-Path $path) {
                if (Test-Path (Join-Path $path $Marker)) {
                    Write-Step { Remove-Item $path -Recurse -Force } "rm -rf $path"
                    Write-Host "  removed    $($t.Label)  $Skill"
                } else {
                    Write-Host "  kept       $($t.Label)  $Skill (not installed by this installer)"
                }
            }
        }
        return
    }

    # Resolve source. In a piped `irm ... | iex` invocation $PSScriptRoot is
    # empty — never pass it to Join-Path.
    $Local = $null
    if ($PSScriptRoot) {
        $candidate = Join-Path $PSScriptRoot "skills\$Skill\SKILL.md"
        if (Test-Path $candidate) { $Local = $candidate }
    }
    if ($Local) {
        $Src = Join-Path $PSScriptRoot 'skills'
    } else {
        $Temp = Join-Path ([System.IO.Path]::GetTempPath()) ("fds-" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $Temp -Force | Out-Null
        Write-Host "Fetching skills from $Repo ..."
        git clone --depth 1 --quiet $Repo (Join-Path $Temp 'repo')
        $Src = Join-Path $Temp 'repo\skills'
    }

    # Stage everything first so a failed copy cannot damage a live install.
    $Stage = Join-Path ([System.IO.Path]::GetTempPath()) ("stage-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $Stage -Force | Out-Null
    Copy-Item (Join-Path $Src $Skill) (Join-Path $Stage $Skill) -Recurse -Force
    Set-Content -Path (Join-Path $Stage $Skill $Marker) -Value 'Installed by feynman_diagram_drawing_skills/install.ps1'

    $installed = 0
    foreach ($t in $Targets) {
        $parent = Split-Path $t.Dir -Parent
        if (-not $t.Universal -and -not (Test-Path $parent)) { continue }

        Write-Step { New-Item -ItemType Directory -Path $t.Dir -Force | Out-Null } "mkdir $($t.Dir)"
        $dest = Join-Path $t.Dir $Skill
        $backup = $null
        if (Test-Path $dest) {
            if (-not (Test-Path (Join-Path $dest $Marker))) {
                Write-Host "  skipped    $($t.Label)  $Skill (existing data not managed by this installer)"
                continue
            }
            $backup = Join-Path ([System.IO.Path]::GetTempPath()) ("backup-" + [guid]::NewGuid().ToString('N'))
            Move-Item $dest $backup -Force
        }
        try {
            Write-Step {
                Copy-Item (Join-Path $Stage $Skill) $dest -Recurse -Force
            } "copy $Skill -> $dest"
        } catch {
            if ($backup) { Move-Item $backup $dest -Force }
            Write-Error "Failed to install $($t.Label)/$Skill; previous version restored."
            throw
        }
        Write-Host "  installed  $($t.Label)  ->  $dest"
        $installed++
    }

    if ($installed -eq 0) {
        Write-Host 'No supported agent found. Create one of these directories and re-run:'
        foreach ($t in $Targets) { Write-Host "  $($t.Dir)" }
        exit 1
    }

    Write-Host ''
    Write-Host "Done. $installed skill installs. Restart the agent, or run its reload command."
}
finally {
    if ($Stage -and (Test-Path $Stage)) { Remove-Item $Stage -Recurse -Force -ErrorAction SilentlyContinue }
    if ($Temp -and (Test-Path $Temp)) { Remove-Item $Temp -Recurse -Force -ErrorAction SilentlyContinue }
}

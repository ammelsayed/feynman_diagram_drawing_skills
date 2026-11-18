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

$Targets = @(
    @{ Label = 'Claude Code';               Dir = Join-Path $HOME '.claude\skills';           Universal = $false },
    @{ Label = 'Codex';                     Dir = Join-Path $HOME '.codex\skills';            Universal = $false },
    @{ Label = 'OpenCode';                  Dir = Join-Path $HOME '.config\opencode\skills';  Universal = $false },
    @{ Label = 'Cursor';                    Dir = Join-Path $HOME '.cursor\skills';           Universal = $false },
    @{ Label = 'zcode';                     Dir = Join-Path $HOME '.zcode\skills';            Universal = $false },
    @{ Label = 'DSH';                       Dir = Join-Path $HOME '.dsh\skills';              Universal = $false },
    @{ Label = 'WorkBuddy';                 Dir = Join-Path $HOME '.workbuddy\skills';        Universal = $false },
    @{ Label = 'Agent Skills (universal)';  Dir = Join-Path $HOME '.agents\skills';           Universal = $true }
)

$Work = Join-Path ([System.IO.Path]::GetTempPath()) ("fds-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $Work -Force | Out-Null

function Test-Managed {
    param([string]$Path)
    if (Test-Path (Join-Path $Path $Marker)) { return $true }
    $skillMd = Join-Path $Path 'SKILL.md'
    if ((Test-Path $skillMd) -and (Select-String -Path $skillMd -Pattern 'name:\s*feynman-diagram' -Quiet)) {
        return $true   # legacy marker-less install of this skill
    }
    return $false
}

try {
    # Uninstall before any source fetch; serialize with install via a lock file.
    $lockPath = Join-Path $HOME '.feynman_skills.lock'
    $lock = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    try {
        if ($Uninstall) {
            Write-Host 'Uninstalling Feynman diagram drawing skills'
            foreach ($t in $Targets) {
                $path = Join-Path $t.Dir $Skill
                if (Test-Path $path) {
                    if (Test-Managed $path) {
                        if (-not $DryRun) { Remove-Item $path -Recurse -Force }
                        Write-Host "  removed    $($t.Label)  $Skill"
                    } else {
                        Write-Host "  kept       $($t.Label)  $Skill (unmanaged content)"
                    }
                }
            }
            return
        }

        # Source: only trust a real script file next to skills/; piped invocations
        # have empty $PSScriptRoot and must fetch the repository.
        $Src = $null
        if ($PSScriptRoot) {
            $candidate = Join-Path $PSScriptRoot "skills\$Skill\SKILL.md"
            if (Test-Path $candidate) { $Src = Join-Path $PSScriptRoot 'skills' }
        }
        if (-not $Src) {
            New-Item -ItemType Directory -Path (Join-Path $Work 'repo') -Force | Out-Null
            Write-Host "Fetching skills from $Repo ..."
            git clone --depth 1 --quiet $Repo (Join-Path $Work 'repo')
            $Src = Join-Path $Work 'repo\skills'
        }

        # Stage the whole set. No live directory is touched during staging.
        $Stage = Join-Path $Work 'stage'
        New-Item -ItemType Directory -Path $Stage -Force | Out-Null
        Copy-Item (Join-Path $Src $Skill) (Join-Path $Stage $Skill) -Recurse -Force
        Set-Content -Path (Join-Path $Stage $Skill $Marker) -Value 'Installed by feynman_diagram_drawing_skills/install.ps1'

        $installed = 0
        foreach ($t in $Targets) {
            $parent = Split-Path $t.Dir -Parent
            if (-not $t.Universal -and -not (Test-Path $parent)) { continue }
            if (-not $DryRun) { New-Item -ItemType Directory -Path $t.Dir -Force | Out-Null }
            $dest = Join-Path $t.Dir $Skill
            $backup = $null
            if (Test-Path $dest) {
                if (-not (Test-Managed $dest)) {
                    Write-Host "  skipped    $($t.Label)  $Skill (unmanaged content)"
                    continue
                }
                if (-not $DryRun) {
                    $backup = Join-Path $Work ("backup-$installed")
                    Move-Item $dest $backup -Force   # atomic rename, no gap
                }
            }
            if ($DryRun) {
                Write-Host "  [dry-run] copy $Skill -> $dest"
            } else {
                try {
                    Copy-Item (Join-Path $Stage $Skill) $dest -Recurse -Force -ErrorAction Stop
                    if ($backup) { Remove-Item $backup -Recurse -Force }
                } catch {
                    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
                    if ($backup) { Move-Item $backup $dest -Force }
                    Write-Error "Failed to install $($t.Label)/$Skill; previous state restored."
                    throw
                }
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
        if ($lock) { $lock.Dispose() }
    }
}
finally {
    if (Test-Path $Work) { Remove-Item $Work -Recurse -Force -ErrorAction SilentlyContinue }
}

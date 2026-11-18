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
param([switch]$DryRun, [switch]$Uninstall)

$ErrorActionPreference = 'Stop'
$Repo = 'https://github.com/ammelsayed/feynman_diagram_drawing_skills.git'
$Skill = 'feynman-diagram'
$Marker = '.feynman-diagram-installer'

$Targets = @(
    @{ Label='Claude Code'; Dir=(Join-Path $HOME '.claude\skills'); Universal=$false },
    @{ Label='Codex'; Dir=(Join-Path $HOME '.codex\skills'); Universal=$false },
    @{ Label='OpenCode'; Dir=(Join-Path $HOME '.config\opencode\skills'); Universal=$false },
    @{ Label='Cursor'; Dir=(Join-Path $HOME '.cursor\skills'); Universal=$false },
    @{ Label='zcode'; Dir=(Join-Path $HOME '.zcode\skills'); Universal=$false },
    @{ Label='DSH'; Dir=(Join-Path $HOME '.dsh\skills'); Universal=$false },
    @{ Label='WorkBuddy'; Dir=(Join-Path $HOME '.workbuddy\skills'); Universal=$false },
    @{ Label='Agent Skills (universal)'; Dir=(Join-Path $HOME '.agents\skills'); Universal=$true }
)

function Test-OurSkill {
    param([string]$Path)
    $md = Join-Path $Path 'SKILL.md'
    if (Test-Path $md) {
        if (Select-String -Path $md -Pattern '^name:\s*feynman-diagram\s*$' -Quiet) { return $true }
    }
    return $false
}

$Work = Join-Path ([System.IO.Path]::GetTempPath()) ("fds-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $Work -Force | Out-Null
$Lock = $null

try {
    # Serialize with a blocking, retrying lock so overlapping runs wait rather
    # than fail. Skipped entirely for dry runs (no mutations).
    if (-not $DryRun) {
        $lockPath = Join-Path $Work 'install.lock'
        for ($i = 0; $i -lt 100; $i++) {
            try {
                $Lock = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate,
                    [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
                break
            } catch {
                if ($i -eq 99) { throw }
                Start-Sleep -Milliseconds 100
            }
        }
    }

    # Uninstall needs no source.
    if ($Uninstall) {
        Write-Host 'Uninstalling Feynman diagram drawing skills'
        foreach ($t in $Targets) {
            $path = Join-Path $t.Dir $Skill
            if (Test-Path $path) {
                if ((Test-Path (Join-Path $path $Marker)) -or (Test-OurSkill $path)) {
                    if (-not $DryRun) { Remove-Item $path -Recurse -Force }
                    Write-Host "  removed    $($t.Label)  $Skill"
                } else {
                    Write-Host "  kept       $($t.Label)  $Skill (unmanaged content)"
                }
            }
        }
        return
    }

    # Source: only a real script file next to skills/; piped invocation ($PSScriptRoot
    # empty) fetches the repo. Bare .\install.ps1 resolves against the current dir.
    $Src = $null
    if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "skills\$Skill\SKILL.md"))) {
        $Src = Join-Path $PSScriptRoot 'skills'
    } elseif (-not $PSScriptRoot -and $MyInvocation.MyCommand.Path -and
              (Test-Path (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "skills\$Skill\SKILL.md"))) {
        $Src = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) 'skills'
    }
    if (-not $Src) {
        $repoDir = Join-Path $Work 'repo'
        New-Item -ItemType Directory -Path $repoDir -Force | Out-Null
        Write-Host "Fetching skills from $Repo ..."
        git clone --depth 1 --quiet $Repo $repoDir
        $Src = Join-Path $repoDir 'skills'
    }

    # Stage first; validate before touching live directories.
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
        if (Test-Path $dest) {
            if ((Test-Path (Join-Path $dest $Marker)) -or (Test-OurSkill $dest)) {
                Write-Host "  kept      $($t.Label)  $Skill (already installed; uninstall first to replace)"
                continue
            }
            Write-Host "  skipped   $($t.Label)  $Skill (unmanaged content)"
            continue
        }
        if ($DryRun) {
            Write-Host "  [dry-run] copy $Skill -> $dest"
        } else {
            try {
                Copy-Item (Join-Path $Stage $Skill) $dest -Recurse -Force -ErrorAction Stop
            } catch {
                if (Test-Path $dest) { Remove-Item $dest -Recurse -Force -ErrorAction SilentlyContinue }
                Write-Error "Failed to install $($t.Label)/$Skill."
                throw
            }
        }
        Write-Host "  installed  $($t.Label)  ->  $dest"
        $installed++
    }
    if ($installed -eq 0 -and -not $DryRun) {
        Write-Host 'No new installs. Agents already have the skill, or none were found.'
    }
    Write-Host ''
    Write-Host "Done. $installed new skill installs. Restart the agent, or run its reload command."
}
finally {
    if ($Lock) { $Lock.Dispose() }
    if (Test-Path $Work) { Remove-Item $Work -Recurse -Force -ErrorAction SilentlyContinue }
}

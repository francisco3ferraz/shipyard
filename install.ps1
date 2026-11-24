# Links the workflow into your user-level Claude Code config. Safe to re-run.
# Links, not copies, so /retrospective and /add-language edit this repo directly.
param([string]$ClaudeDir = (Join-Path $HOME '.claude'))

$ErrorActionPreference = 'Stop'
$src = Join-Path $PSScriptRoot 'claude'
$settingsPath = Join-Path $ClaudeDir 'settings.json'
$memoryPath = Join-Path $ClaudeDir 'CLAUDE.md'
$utf8 = New-Object Text.UTF8Encoding($false)

function Set-Link($link, $target) {
    $item = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -eq 'Junction' -and $item.Target -contains $target) { return }
    if ($item) { throw "$link already exists and is not a link to $target. Move it aside and re-run." }
    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
}

$backup = Join-Path $ClaudeDir ('backups\workflow-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force $backup | Out-Null
foreach ($f in $settingsPath, $memoryPath) {
    if (Test-Path $f) { Copy-Item $f $backup }
}

Set-Link (Join-Path $ClaudeDir 'workflow') $src
New-Item -ItemType Directory -Force (Join-Path $ClaudeDir 'skills') | Out-Null
# Drop links to skills this repo no longer has, so renames don't leave dead skills behind.
foreach ($link in Get-ChildItem (Join-Path $ClaudeDir 'skills') | Where-Object { $_.LinkType -eq 'Junction' }) {
    $target = [string]$link.Target
    if ($target.StartsWith($src) -and -not (Test-Path -LiteralPath $target)) { cmd /c rmdir "$($link.FullName)" }
}
foreach ($skill in Get-ChildItem -Directory (Join-Path $src 'skills')) {
    Set-Link (Join-Path $ClaudeDir "skills\$($skill.Name)") $skill.FullName
}
Set-Link (Join-Path $ClaudeDir 'agents') (Join-Path $src 'agents')

# The import sits between markers so a re-run replaces it instead of appending twice.
$begin = '<!-- workflow:begin -->'
$end = '<!-- workflow:end -->'
$block = "$begin`n@~/.claude/workflow/CLAUDE.md`n$end"
$memory = if (Test-Path $memoryPath) { [IO.File]::ReadAllText($memoryPath) } else { '' }
$pattern = [regex]::Escape($begin) + '[\s\S]*?' + [regex]::Escape($end)
if ($memory -match $pattern) {
    $memory = [regex]::Replace($memory, $pattern, { param($m) $block })
} else {
    $memory = $memory.TrimEnd() + "`n`n" + $block + "`n"
}
[IO.File]::WriteAllText($memoryPath, $memory.TrimStart(), $utf8)

$settings = if (Test-Path $settingsPath) { [IO.File]::ReadAllText($settingsPath) | ConvertFrom-Json } else { New-Object PSObject }
function Set-Prop($obj, $name, $value) {
    if ($obj.PSObject.Properties[$name]) { $obj.$name = $value } else { $obj | Add-Member -NotePropertyName $name -NotePropertyValue $value }
}

# New dependencies need your approval.
$askRules = @(
    'Bash(npm install:*)', 'Bash(npm i:*)', 'Bash(pnpm add:*)', 'Bash(yarn add:*)', 'Bash(bun add:*)',
    'Bash(pip install:*)', 'Bash(uv add:*)', 'Bash(uv pip install:*)', 'Bash(poetry add:*)',
    'Bash(cargo add:*)', 'Bash(go get:*)', 'Bash(dotnet add:*)',
    'Edit(**/package.json)', 'Edit(**/pyproject.toml)', 'Edit(**/requirements*.txt)',
    'Edit(**/go.mod)', 'Edit(**/Cargo.toml)', 'Edit(**/*.csproj)'
)
if (-not $settings.PSObject.Properties['permissions']) { Set-Prop $settings 'permissions' (New-Object PSObject) }
$existingAsk = @($settings.permissions.ask | Where-Object { $_ })
Set-Prop $settings.permissions 'ask' @($existingAsk + ($askRules | Where-Object { $existingAsk -notcontains $_ }))

# Pushing stays yours. The hook also covers PowerShell and chained commands the deny rules miss.
$denyRules = @('Bash(git push:*)', 'Bash(gh pr create:*)', 'Bash(gh pr merge:*)', 'Bash(npm publish:*)')
$existingDeny = @($settings.permissions.deny | Where-Object { $_ })
Set-Prop $settings.permissions 'deny' @($existingDeny + ($denyRules | Where-Object { $existingDeny -notcontains $_ }))

function New-Hook($matcher, $script) {
    $path = (Join-Path $ClaudeDir "workflow\hooks\$script") -replace '\\', '/'
    [pscustomobject]@{
        matcher = $matcher
        hooks   = @([pscustomobject]@{ type = 'command'; command = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$path`"" })
    }
}
if (-not $settings.PSObject.Properties['hooks']) { Set-Prop $settings 'hooks' (New-Object PSObject) }
$others = @($settings.hooks.PreToolUse | Where-Object { $_ -and -not ($_.hooks.command -match '(guard|no-push)\.ps1') })
Set-Prop $settings.hooks 'PreToolUse' @($others + (New-Hook 'Write|Edit|MultiEdit' 'guard.ps1') + (New-Hook 'Bash|PowerShell' 'no-push.ps1'))

[IO.File]::WriteAllText($settingsPath, (ConvertTo-Json -InputObject $settings -Depth 20), $utf8)

Write-Output "Linked into $ClaudeDir. Backup in $backup. Restart Claude Code."

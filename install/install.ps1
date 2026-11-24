# Links Shipyard into your user-level Claude Code config. Safe to re-run.
# Links, not copies, so /retrospective edits this repo directly.
param([string]$ClaudeDir = (Join-Path $HOME '.claude'))

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$settingsPath = Join-Path $ClaudeDir 'settings.json'
$memoryPath = Join-Path $ClaudeDir 'CLAUDE.md'
$utf8 = New-Object Text.UTF8Encoding($false)

function Set-Link($link, $target) {
    $item = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -eq 'Junction' -and $item.Target -contains $target) { return }
    if ($item) { throw "$link already exists and is not a link to $target. Move it aside and re-run." }
    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
}

$backup = Join-Path $ClaudeDir ('backups\shipyard-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force $backup | Out-Null
foreach ($f in $settingsPath, $memoryPath) {
    if (Test-Path $f) { Copy-Item $f $backup }
}

New-Item -ItemType Directory -Force (Join-Path $ClaudeDir 'skills') | Out-Null
# Drop links into this repo whose target is gone, so renames and moves don't leave dead links.
foreach ($link in Get-ChildItem $ClaudeDir, (Join-Path $ClaudeDir 'skills') | Where-Object { $_.LinkType -eq 'Junction' }) {
    $target = [string]$link.Target
    if ($target.StartsWith($root, 'OrdinalIgnoreCase') -and -not (Test-Path -LiteralPath $target)) { cmd /c rmdir "$($link.FullName)" }
}
Set-Link (Join-Path $ClaudeDir 'shipyard') $root
foreach ($skill in Get-ChildItem -Directory (Join-Path $root 'skills')) {
    Set-Link (Join-Path $ClaudeDir "skills\$($skill.Name)") $skill.FullName
}
Set-Link (Join-Path $ClaudeDir 'agents') (Join-Path $root 'agents')

# The import sits between markers so a re-run replaces it instead of appending twice.
# Older installs used workflow markers, so match both and write the shipyard ones.
$block = "<!-- shipyard:begin -->`n@~/.claude/shipyard/rules/CLAUDE.md`n<!-- shipyard:end -->"
$memory = if (Test-Path $memoryPath) { [IO.File]::ReadAllText($memoryPath) } else { '' }
$pattern = '<!-- (shipyard|workflow):begin -->[\s\S]*?<!-- (shipyard|workflow):end -->'
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

# Dependency installs ask first. Pushing is denied, and the no-push hook catches what deny rules miss.
$rules = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'permissions.json')) | ConvertFrom-Json
if (-not $settings.PSObject.Properties['permissions']) { Set-Prop $settings 'permissions' (New-Object PSObject) }
foreach ($kind in 'ask', 'deny') {
    $existing = @($settings.permissions.$kind | Where-Object { $_ })
    Set-Prop $settings.permissions $kind @($existing + ($rules.$kind | Where-Object { $existing -notcontains $_ }))
}

function New-Hook($matcher, $script) {
    $path = (Join-Path $ClaudeDir "shipyard\hooks\$script") -replace '\\', '/'
    [pscustomobject]@{
        matcher = $matcher
        hooks   = @([pscustomobject]@{ type = 'command'; command = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$path`"" })
    }
}
if (-not $settings.PSObject.Properties['hooks']) { Set-Prop $settings 'hooks' (New-Object PSObject) }
$others = @($settings.hooks.PreToolUse | Where-Object { $_ -and -not ($_.hooks.command -match '(guard|no-push)\.(ps1|sh)') })
Set-Prop $settings.hooks 'PreToolUse' @($others + (New-Hook 'Write|Edit|MultiEdit' 'guard.ps1') + (New-Hook 'Bash|PowerShell' 'no-push.ps1'))

[IO.File]::WriteAllText($settingsPath, (ConvertTo-Json -InputObject $settings -Depth 20), $utf8)

Write-Output "Shipyard linked into $ClaudeDir. Backup in $backup. Restart Claude Code."

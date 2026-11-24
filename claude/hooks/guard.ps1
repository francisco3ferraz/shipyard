# PreToolUse hook. Blocks new code that skips tests or swallows errors.
# Exit 2 sends stderr back to Claude and cancels the edit.
# A line containing "guard-ok: <reason>" is allowed, so real exceptions must state their why.
# Rules live in guard.patterns, shared with guard.sh.

$ErrorActionPreference = 'Stop'

$payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
$tool = $payload.tool_name
$in = $payload.tool_input
$path = [string]$in.file_path

# Prose quotes these patterns legitimately, and the rule and case files hold them on purpose.
if ($path -match '\.(md|mdx|txt|rst|patterns)$|\.cases\.json$') { exit 0 }

$old = ''
$new = ''
switch ($tool) {
    'Write' {
        $new = [string]$in.content
        if (Test-Path -LiteralPath $path) { $old = [IO.File]::ReadAllText($path) }
    }
    'Edit' {
        $old = [string]$in.old_string
        $new = [string]$in.new_string
    }
    'MultiEdit' {
        $old = ($in.edits | ForEach-Object { $_.old_string }) -join "`n"
        $new = ($in.edits | ForEach-Object { $_.new_string }) -join "`n"
    }
    default { exit 0 }
}

# Only judge lines this edit adds, so existing code can still be edited around.
$oldLines = [Collections.Generic.HashSet[string]]::new([string[]]($old -split "`r?`n"))
$added = ($new -split "`r?`n" | Where-Object { -not $oldLines.Contains($_) -and $_ -notmatch 'guard-ok:' }) -join "`n"
if (-not $added.Trim()) { exit 0 }

$rules = Get-Content (Join-Path $PSScriptRoot 'guard.patterns') | Where-Object { $_ -and -not $_.StartsWith('#') }
$hits = foreach ($rule in $rules) {
    $label, $pattern = $rule -split "`t", 2
    if ($added -match $pattern) { "- ${label}: $($Matches[0].Trim())" }
}
if (-not $hits) { exit 0 }

[Console]::Error.WriteLine(@"
Blocked: this edit to $path
$($hits -join "`n")

Errors must fail loudly and failing tests must be fixed, not skipped.
Fix the code instead. If this really is right, put "guard-ok: <reason>" on that line and tell the user why.
"@)
exit 2

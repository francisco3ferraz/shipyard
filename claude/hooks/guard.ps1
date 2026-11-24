# PreToolUse hook. Blocks new code that skips tests or swallows errors.
# Exit 2 sends stderr back to Claude and cancels the edit.
# A line containing "guard-ok: <reason>" is allowed, so real exceptions must state their why.

$ErrorActionPreference = 'Stop'

$payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
$tool = $payload.tool_name
$in = $payload.tool_input
$path = [string]$in.file_path

# Prose files quote these patterns legitimately.
if ($path -match '\.(md|mdx|txt|rst)$') { exit 0 }

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

$rules = [ordered]@{
    'skips or focuses a test'           = '\b(it|test|describe|context)\.(skip|only|todo)\(|(?<![\w.])(xit|xtest|xdescribe|fdescribe)\(|@pytest\.mark\.(skip|xfail)|pytest\.skip\(|@unittest\.skip|@(Disabled|Ignore)\b|#\[ignore\]|\bt\.Skip(f|Now)?\('
    'has an empty catch'                = 'catch\s*(\([^)]*\))?\s*\{\s*\}'
    'has a bare except'                 = '\bexcept\s*:'
    'swallows an exception with pass'   = '\bexcept\b[^\n:]*:\s*(pass|\.\.\.)\s*(\n|$)'
    'swallows a promise rejection'      = '\.catch\(\s*\(?\s*\w*\s*\)?\s*=>\s*(\{\s*\}|null|undefined)\s*\)'
    'returns a fallback from a catch'   = 'catch\s*(\([^)]*\))?\s*\{\s*return\s*(null|undefined|\[\]|\{\}|false|''''|"")?\s*;?\s*\}'
}

$hits = foreach ($rule in $rules.GetEnumerator()) {
    if ($added -match $rule.Value) { "- $($rule.Key): $($Matches[0].Trim())" }
}
if (-not $hits) { exit 0 }

[Console]::Error.WriteLine(@"
Blocked: this edit to $path
$($hits -join "`n")

Errors must fail loudly and failing tests must be fixed, not skipped.
Fix the code instead. If this really is right, put "guard-ok: <reason>" on that line and tell the user why.
"@)
exit 2

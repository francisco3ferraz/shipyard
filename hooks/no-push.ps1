# PreToolUse hook for Bash and PowerShell. Blocks anything that sends work to a remote.
# Exit 2 sends stderr back to Claude and cancels the command. You push yourself.
# Rules live in no-push.patterns, shared with no-push.sh.

$ErrorActionPreference = 'Stop'

$payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
$command = [string]$payload.tool_input.command

$rules = Get-Content (Join-Path $PSScriptRoot 'no-push.patterns') | Where-Object { $_ -and -not $_.StartsWith('#') }
foreach ($rule in $rules) {
    $label, $pattern = $rule -split "`t", 2
    if ($command -match $pattern) {
        [Console]::Error.WriteLine("Blocked: this command $label (``$($Matches[0])``). Only the user pushes or publishes. Tell them it's ready.")
        exit 2
    }
}
exit 0

# PreToolUse hook for Bash and PowerShell. Blocks anything that sends work to a remote.
# Exit 2 sends stderr back to Claude and cancels the command. You push yourself.

$ErrorActionPreference = 'Stop'

$payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
$command = [string]$payload.tool_input.command

$remote = @(
    '\bgit(\s+-\S+(\s+[^-\s]\S*)?)*\s+push\b'
    '\bgh\s+(pr\s+(create|merge)|release\s+create|repo\s+(create|sync))\b'
    '\b(npm|pnpm|yarn|bun|cargo|poetry)\s+publish\b'
    '\b(docker|podman)\s+push\b'
    '\btwine\s+upload\b'
    '\bnuget\s+push\b'
) -join '|'

if ($command -notmatch $remote) { exit 0 }

[Console]::Error.WriteLine("Blocked: ``$($Matches[0])`` sends work to a remote. Only the user pushes or publishes. Tell them it's ready.")
exit 2

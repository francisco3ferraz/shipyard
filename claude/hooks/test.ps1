# Runs both hooks against the shared cases. Exit 0 means every case behaved as expected.

$script:failed = 0

function Test-Hook($script, $casesFile, $toPayload) {
    $cases = Get-Content -Raw (Join-Path $PSScriptRoot $casesFile) | ConvertFrom-Json
    $passed = 0
    foreach ($c in $cases) {
        & $toPayload $c | ConvertTo-Json -Compress | powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot $script) 2>$null | Out-Null
        if (($LASTEXITCODE -eq 2) -eq $c.blocked) { $passed++; continue }
        $script:failed++
        Write-Output "FAIL ${script}: $($c | ConvertTo-Json -Compress) got exit $LASTEXITCODE"
    }
    Write-Output "${script}: $passed/$($cases.Count) passed"
}

Test-Hook 'guard.ps1' 'guard.cases.json' {
    param($c)
    $old = if ($c.old) { $c.old } else { 'x' }
    @{ tool_name = 'Edit'; tool_input = @{ file_path = $c.file; old_string = $old; new_string = $c.new } }
}
Test-Hook 'no-push.ps1' 'no-push.cases.json' {
    param($c)
    @{ tool_name = 'Bash'; tool_input = @{ command = $c.command } }
}
exit [int]($script:failed -gt 0)

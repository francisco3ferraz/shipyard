# Runs no-push.ps1 against sample commands. Exit 0 means every case behaved as expected.
$hook = Join-Path $PSScriptRoot 'no-push.ps1'

$cases = @(
    @{ blocked = $true;  command = 'git push' }
    @{ blocked = $true;  command = 'git push origin main --force' }
    @{ blocked = $true;  command = 'git -C ../app push' }
    @{ blocked = $true;  command = 'git add . && git commit -m "x" && git push' }
    @{ blocked = $true;  command = 'gh pr create --fill' }
    @{ blocked = $true;  command = 'gh pr merge 12' }
    @{ blocked = $true;  command = 'npm publish' }
    @{ blocked = $true;  command = 'docker push app:latest' }
    @{ blocked = $false; command = 'git status' }
    @{ blocked = $false; command = 'git commit -m "Prepare push of invoices"' }
    @{ blocked = $false; command = 'git stash push -m wip' }
    @{ blocked = $false; command = 'gh pr view 12' }
    @{ blocked = $false; command = 'git log origin/main..HEAD' }
)

$failed = 0
foreach ($c in $cases) {
    $json = @{ tool_name = 'Bash'; tool_input = @{ command = $c.command } } | ConvertTo-Json -Compress
    $json | powershell -NoProfile -ExecutionPolicy Bypass -File $hook 2>$null | Out-Null
    if (($LASTEXITCODE -eq 2) -ne $c.blocked) {
        $failed++
        Write-Output "FAIL '$($c.command)': expected blocked=$($c.blocked), got exit $LASTEXITCODE"
    }
}
Write-Output "$($cases.Count - $failed)/$($cases.Count) passed"
exit [int]($failed -gt 0)

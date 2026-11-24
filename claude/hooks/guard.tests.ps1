# Runs guard.ps1 against sample edits. Exit 0 means every case behaved as expected.
$guard = Join-Path $PSScriptRoot 'guard.ps1'

$cases = @(
    @{ name = 'js empty catch';        blocked = $true;  file = 'a.ts'; new = "try { run() } catch (e) {}" }
    @{ name = 'js catch returns null'; blocked = $true;  file = 'a.ts'; new = "try { return run() } catch { return null; }" }
    @{ name = 'promise swallow';       blocked = $true;  file = 'a.ts'; new = "load().catch(() => {})" }
    @{ name = 'it.skip';               blocked = $true;  file = 'a.test.ts'; new = "it.skip('adds', () => {})" }
    @{ name = 'xdescribe';             blocked = $true;  file = 'a.test.js'; new = "xdescribe('cart', () => {})" }
    @{ name = 'python bare except';    blocked = $true;  file = 'a.py'; new = "try:`n    run()`nexcept:`n    raise" }
    @{ name = 'python except pass';    blocked = $true;  file = 'a.py'; new = "try:`n    run()`nexcept ValueError:`n    pass" }
    @{ name = 'pytest skip';           blocked = $true;  file = 'test_a.py'; new = "@pytest.mark.skip`ndef test_a(): ..." }
    @{ name = 'go t.Skip';             blocked = $true;  file = 'a_test.go'; new = 't.Skip("flaky")' }
    @{ name = 'specific rethrow';      blocked = $false; file = 'a.ts'; new = "try { run() } catch (e) { throw new LoadError(id, e) }" }
    @{ name = 'python handled except'; blocked = $false; file = 'a.py'; new = "except KeyError:`n    return DEFAULTS[name]" }
    @{ name = 'model.fit';             blocked = $false; file = 'a.py'; new = "model.fit(x, y)" }
    @{ name = 'guard-ok escape';       blocked = $false; file = 'a.ts'; new = "} catch {} // guard-ok: best-effort cache warmup" }
    @{ name = 'markdown ignored';      blocked = $false; file = 'notes.md'; new = "catch (e) {}" }
    @{ name = 'pre-existing line';     blocked = $false; file = 'a.ts'; old = "catch (e) {}"; new = "catch (e) {}`nfoo()" }
)

$failed = 0
foreach ($c in $cases) {
    $old = if ($c.old) { $c.old } else { 'x' }
    $json = @{ tool_name = 'Edit'; tool_input = @{ file_path = $c.file; old_string = $old; new_string = $c.new } } | ConvertTo-Json -Compress
    $json | powershell -NoProfile -ExecutionPolicy Bypass -File $guard 2>$null | Out-Null
    $wasBlocked = $LASTEXITCODE -eq 2
    if ($wasBlocked -ne $c.blocked) {
        $failed++
        Write-Output "FAIL $($c.name): expected blocked=$($c.blocked), got exit $LASTEXITCODE"
    }
}
Write-Output "$($cases.Count - $failed)/$($cases.Count) passed"
exit [int]($failed -gt 0)

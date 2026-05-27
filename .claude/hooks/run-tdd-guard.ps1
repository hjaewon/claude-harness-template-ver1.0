$ErrorActionPreference = "Stop"

$payload = [Console]::In.ReadToEnd()
$bash = (Get-Command bash -ErrorAction SilentlyContinue).Source

if (-not $bash) {
    $gitBash = "C:\Program Files\Git\bin\bash.exe"
    if (Test-Path -LiteralPath $gitBash) {
        $bash = $gitBash
    }
}

if (-not $bash) {
    Write-Error "TDD Guard requires bash. Install Git for Windows or add bash to PATH."
    exit 1
}

$payload | & $bash ".claude/hooks/tdd-guard.sh"
exit $LASTEXITCODE

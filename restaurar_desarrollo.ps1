Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Restaurando entorno para DESARROLLO LOCAL..." -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$utf8NoBom = New-Object System.Text.UTF8Encoding $false

# 1. Restaurar host local en net_work.dart (activar 127.0.0.1 y comentar lwadersoft.site)
$networkFile = "$PSScriptRoot\frontend\lib\core\network\net_work.dart"
if (Test-Path $networkFile) {
    $netContent = [System.IO.File]::ReadAllText($networkFile)
    $netContent = $netContent -replace '(?m)^\s*//\s*final\s+String\s+host\s*=\s*["'']http://127\.0\.0\.1:8000["''];', 'final String host = "http://127.0.0.1:8000";'
    $netContent = $netContent -replace '(?m)^\s*final\s+String\s+host\s*=\s*["'']https://lwadersoft\.site["''];', '// final String host = "https://lwadersoft.site";'
    [System.IO.File]::WriteAllText($networkFile, $netContent, $utf8NoBom)
    Write-Host "[OK] net_work.dart -> Host local activado (http://127.0.0.1:8000)" -ForegroundColor Green
} else {
    Write-Host "[ERROR] No se encontro net_work.dart" -ForegroundColor Red
}

# 2. Restaurar botones de prueba en login_screen.dart (descomentar _buildQuickLoginRoles())
$loginFile = "$PSScriptRoot\frontend\lib\modules\auth\screens\login_screen.dart"
if (Test-Path $loginFile) {
    $loginContent = [System.IO.File]::ReadAllText($loginFile)
    $loginContent = $loginContent -replace '(?m)^(\s*)//\s*_buildQuickLoginRoles\(\),', '$1_buildQuickLoginRoles(),'
    [System.IO.File]::WriteAllText($loginFile, $loginContent, $utf8NoBom)
    Write-Host "[OK] login_screen.dart -> Botones de prueba activados (_buildQuickLoginRoles)" -ForegroundColor Green
} else {
    Write-Host "[ERROR] No se encontro login_screen.dart" -ForegroundColor Red
}

Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "Listo: Modo de desarrollo local activo." -ForegroundColor Green

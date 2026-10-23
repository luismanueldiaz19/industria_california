param(
    [switch]$RestoreAfterBuild = $false
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Preparando entorno para PRODUCCION..." -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$utf8NoBom = New-Object System.Text.UTF8Encoding $false

# 1. Configurar net_work.dart para producción (descomentar lwadersoft.site y comentar 127.0.0.1)
$networkFile = "$PSScriptRoot\frontend\lib\core\network\net_work.dart"
if (Test-Path $networkFile) {
    $netContent = [System.IO.File]::ReadAllText($networkFile)
    $netContent = $netContent -replace '(?m)^\s*final\s+String\s+host\s*=\s*["'']http://127\.0\.0\.1:8000["''];', '// final String host = "http://127.0.0.1:8000";'
    $netContent = $netContent -replace '(?m)^\s*//\s*final\s+String\s+host\s*=\s*["'']https://lwadersoft\.site["''];', 'final String host = "https://lwadersoft.site";'
    [System.IO.File]::WriteAllText($networkFile, $netContent, $utf8NoBom)
    Write-Host "[OK] net_work.dart -> Host de produccion activado (https://lwadersoft.site)" -ForegroundColor Green
} else {
    Write-Host "[ADVERTENCIA] No se encontro net_work.dart en la ruta esperada." -ForegroundColor Yellow
}

# 2. Configurar login_screen.dart para producción (comentar _buildQuickLoginRoles())
$loginFile = "$PSScriptRoot\frontend\lib\modules\auth\screens\login_screen.dart"
if (Test-Path $loginFile) {
    $loginContent = [System.IO.File]::ReadAllText($loginFile)
    $loginContent = $loginContent -replace '(?m)^(\s*)(?!//)(\s*)_buildQuickLoginRoles\(\),', '$1// _buildQuickLoginRoles(),'
    [System.IO.File]::WriteAllText($loginFile, $loginContent, $utf8NoBom)
    Write-Host "[OK] login_screen.dart -> Botones de prueba comentados (_buildQuickLoginRoles)" -ForegroundColor Green
} else {
    Write-Host "[ADVERTENCIA] No se encontro login_screen.dart en la ruta esperada." -ForegroundColor Yellow
}

Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "Iniciando compilacion de Flutter Web..." -ForegroundColor Cyan
# comando para hacer la compilacion y hacer el push:
# powershell -ExecutionPolicy Bypass -File .\compilar_web.ps1

# 3. Navegar, limpiar y compilar Flutter Web
Push-Location "$PSScriptRoot\frontend"

Write-Host "Ejecutando flutter clean..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "Advertencia al ejecutar flutter clean, continuando..." -ForegroundColor DarkYellow
}

Write-Host "Ejecutando flutter pub get..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al obtener dependencias de Flutter." -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host "Compilando Flutter Web en modo Release..." -ForegroundColor Cyan
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error en la compilacion de Flutter Web." -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

Write-Host "compilacion completada. Copiando archivos a Laravel..." -ForegroundColor Cyan

# Rutas
$buildWebDir = "$PSScriptRoot\frontend\build\web"
$publicDir = "$PSScriptRoot\backend\public"
$bladeViewPath = "$PSScriptRoot\backend\resources\views\app.blade.php"

# 2. Asegurar que las carpetas existen
if (-not (Test-Path $publicDir)) {
    New-Item -ItemType Directory -Path $publicDir -Force | Out-Null
}

# 3. Limpiar carpetas de compilaciones previas para evitar acumulación
$foldersToClean = @("assets", "canvaskit", "icons", "images")
foreach ($folder in $foldersToClean) {
    $targetFolder = Join-Path $publicDir $folder
    if (Test-Path $targetFolder) {
        Remove-Item -Recurse -Force $targetFolder
    }
}

# 4. Copiar todos los archivos de build/web a backend/public
Copy-Item -Path "$buildWebDir\*" -Destination $publicDir -Recurse -Force

# 5. Copiar index.html a app.blade.php y hacer que Laravel maneje el base href dinámicamente
if (Test-Path "$buildWebDir\index.html") {
    $htmlContent = Get-Content -Path "$buildWebDir\index.html" -Raw
    # Reemplazamos la ruta estática de Flutter por el asset dinámico de Laravel
    $htmlContent = $htmlContent -replace '<base href="/">', '<base href="{{ asset(''/'') }}">'
    
    # Agregar un token de versión para evitar el caché del navegador al actualizar
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $htmlContent = $htmlContent -replace 'src="flutter_bootstrap.js"', "src=`"flutter_bootstrap.js?v=$timestamp`""
    
    Set-Content -Path $bladeViewPath -Value $htmlContent -Force
    Write-Host "Se actualizo app.blade.php con el nuevo index.html (y base href dinamico, sin cache)." -ForegroundColor Green
}

# 6. Borrar index.html del public de Laravel para evitar conflictos con las rutas amigables de Laravel
$publicIndexHtml = Join-Path $publicDir "index.html"
if (Test-Path $publicIndexHtml) {
    Remove-Item -Path $publicIndexHtml -Force
}

Write-Host "¡Proceso terminado con éxito! Listo para hacer git add, commit y push en produccion." -ForegroundColor Green

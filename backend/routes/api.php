<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Pdf\PdfViewerController;
// Modulo Ledhouse
use App\Http\Controllers\Api\LedhouseEstadoResultadoController;
use App\Http\Controllers\Api\LedhouseCxpController;
use App\Http\Controllers\Api\LedhouseCxcController;
use App\Http\Controllers\Api\LedhouseCuentaCatalogoController;
use App\Http\Controllers\Api\LedhouseClienteController;
use App\Http\Controllers\Api\LedhouseProveedorController;
// Módulo Inventario
use App\Http\Controllers\Api\InventarioCategoriaController;
use App\Http\Controllers\Api\InventarioProductoController;
use App\Http\Controllers\Api\InventarioMovimientoController;
// Módulo Logística/Ventas
use App\Http\Controllers\Api\RutaController;
use App\Http\Controllers\Api\PedidoController;

// =========================================================
// RUTA PÚBLICA DE DOCUMENTOS SEGUROS CON TOKEN (COMPATIBLE CON APACHE)
// =========================================================
Route::get('d/{token}', [PdfViewerController::class, 'ver'])->name('api.pdf.view');

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::prefix('v1')->group(function () {

    // Ruta de token también bajo v1
    Route::get('d/{token}', [PdfViewerController::class, 'ver']);

    // Rutas Públicas
    Route::post('login', [AuthController::class, 'login']);

    // Rutas Públicas (Módulo Ledhouse / Industria California - PDFs)
    foreach (['industria-california', 'ledhouse'] as $prefix) {
        Route::prefix($prefix)->group(function () use ($prefix) {
            Route::get('/estado-resultado/matriz-pdf', [LedhouseEstadoResultadoController::class, 'generateMatrizPdf']);
            Route::get('/estado-resultado/pdf', [LedhouseEstadoResultadoController::class, 'generatePdf']);
            
            $genPdf = Route::get('cxc/reporte-general-pdf', [LedhouseCxcController::class, 'reporteGeneralPdf'])->middleware('signed');
            $agrPdf = Route::get('cxc/reporte-agrupado-pdf', [LedhouseCxcController::class, 'reporteAgrupadoPdf'])->middleware('signed');
            Route::get('cxc/reporte-pdf/{cliente_id}', [LedhouseCxcController::class, 'reportePdf']);
            Route::get('cxc/alertas-pdf', [LedhouseCxcController::class, 'reporteAlertasPdf']);
            $venPdf = Route::get('cxc/vendedor/mis-cxc-pdf', [LedhouseCxcController::class, 'exportMisCxcPdf'])->middleware('signed');

            if ($prefix === 'industria-california') {
                $genPdf->name('cxc.general.pdf');
                $agrPdf->name('cxc.agrupado.pdf');
                $venPdf->name('cxc.vendedor.pdf');
            } else {
                $genPdf->name('cxc.general.pdf.legacy');
                $agrPdf->name('cxc.agrupado.pdf.legacy');
                $venPdf->name('cxc.vendedor.pdf.legacy');
            }
        });
    }

    // Rutas Protegidas
    Route::middleware('auth:sanctum')->group(function () {

        Route::post('register', [AuthController::class, 'register']);
        Route::post('logout', [AuthController::class, 'logout']);
        Route::post('perfil/actualizar', [AuthController::class, 'updateProfile']);
        Route::apiResource('users', UserController::class);

        Route::get('/file', function (Request $request) {
            $path = $request->query('path');
            if (!$path) abort(404);
            $fullPath = storage_path('app/public/' . $path);
            if (!file_exists($fullPath)) abort(404);
            return response()->file($fullPath);
        });

        // ── MÓDULO INDUSTRIA CALIFORNIA ───────────────────────
        foreach (['industria-california', 'ledhouse'] as $prefix) {
            Route::prefix($prefix)->group(function () {
                Route::get('/estado-resultado/matriz', [LedhouseEstadoResultadoController::class, 'matriz']);
                Route::get('/estado-resultado/matriz-pdf-url', [LedhouseEstadoResultadoController::class, 'getMatrizPdfUrl']);
                Route::get('/estado-resultado/pdf-url', [LedhouseEstadoResultadoController::class, 'getEstadoResultadoPdfUrl']);
                Route::get('/estado-resultado', [LedhouseEstadoResultadoController::class, 'index']);
                Route::get('/estado-resultado/summary', [LedhouseEstadoResultadoController::class, 'summary']);
                Route::post('/estado-resultado', [LedhouseEstadoResultadoController::class, 'store']);
                Route::put('/estado-resultado/{id}', [LedhouseEstadoResultadoController::class, 'update']);
                Route::delete('/estado-resultado/{id}', [LedhouseEstadoResultadoController::class, 'destroy']);
                Route::post('/estado-resultado/import', [LedhouseEstadoResultadoController::class, 'import']);

                // CXP
                Route::apiResource('cxp', LedhouseCxpController::class);

                // CXC
                Route::get('cxc/reporte-general-pdf-url', [LedhouseCxcController::class, 'getReporteGeneralPdfUrl']);
                Route::get('cxc/reporte-agrupado-pdf-url', [LedhouseCxcController::class, 'getReporteAgrupadoPdfUrl']);
                Route::get('cxc/reporte-pdf-url/{cliente_id}', [LedhouseCxcController::class, 'getReporteClientePdfUrl']);
                Route::get('cxc/alertas-pdf-url', [LedhouseCxcController::class, 'getReporteAlertasPdfUrl']);

                // Rutas para el vendedor
                Route::get('cxc/vendedor/mis-cxc', [LedhouseCxcController::class, 'getMisCxcPaginated']);
                Route::get('cxc/vendedor/mis-cxc-pdf-url', [LedhouseCxcController::class, 'getMisCxcPdfUrl']);
                
                Route::get('cxc/grouped', [LedhouseCxcController::class, 'groupedByCliente']);
                Route::post('cxc/import-by-cliente/{cliente_id}', [LedhouseCxcController::class, 'importByCliente']);
                // Sync masivo (Fase 1 preview + Fase 2 confirm)
                Route::post('cxc/sync-preview', [LedhouseCxcController::class, 'syncPreview']);
                Route::post('cxc/sync-confirm', [LedhouseCxcController::class, 'syncConfirm']);
                // Alertas del Vendedor
                Route::get('cxc/alertas', [LedhouseCxcController::class, 'getAlertas']);
                Route::post('cxc/{cxc}/alerta', [LedhouseCxcController::class, 'addAlerta']);
                Route::patch('cxc/alertas/{alerta}/resolver', [LedhouseCxcController::class, 'resolverAlerta']);
                Route::delete('cxc/alertas/{alerta}', [LedhouseCxcController::class, 'destroyAlerta']);
                // Evidencias (archivos PDF/JPG)
                Route::post('cxc/{cxc}/evidencia', [LedhouseCxcController::class, 'uploadEvidencia']);
                Route::get('cxc/{cxc}/evidencias', [LedhouseCxcController::class, 'getEvidencias']);
                Route::apiResource('cxc', LedhouseCxcController::class);
                Route::post('cxc/{cxc}/soporte', [LedhouseCxcController::class, 'addSoporte']);
                Route::get('cxc/{cxc}/soporte', [LedhouseCxcController::class, 'getSoportes']);

                // Cuentas de Catalogo
                Route::post('cuentas-catalogo/import', [LedhouseCuentaCatalogoController::class, 'import']);
                Route::apiResource('cuentas-catalogo', LedhouseCuentaCatalogoController::class);

                // Clientes
                Route::post('clientes/import', [LedhouseClienteController::class, 'import']);
                Route::apiResource('clientes', LedhouseClienteController::class);

                // Proveedores
                Route::apiResource('proveedores', LedhouseProveedorController::class);

                // ── MÓDULO INVENTARIO ─────────────────────────────────
                // Categorías
                Route::apiResource('inventario/categorias', InventarioCategoriaController::class)->except(['show']);

                // Productos
                Route::get('inventario/productos-pdf-url', [InventarioProductoController::class, 'getInventarioPdfUrl']);
                Route::post('inventario/productos/import', [InventarioProductoController::class, 'import']);
                Route::post('inventario/productos/{id}/imagen', [InventarioProductoController::class, 'uploadImagen']);
                Route::delete('inventario/productos/{id}/imagen', [InventarioProductoController::class, 'deleteImagen']);
                Route::apiResource('inventario/productos', InventarioProductoController::class);

                // Movimientos de inventario
                Route::get('inventario/movimientos-pdf-url', [InventarioMovimientoController::class, 'getMovimientoPdfUrl']);
                Route::apiResource('inventario/movimientos', InventarioMovimientoController::class)->only(['index', 'store']);

                // ── MÓDULO LOGÍSTICA / PEDIDOS ────────────────────────
                Route::apiResource('rutas', RutaController::class)->except(['show']);
                Route::patch('pedidos/{pedido}/estado', [PedidoController::class, 'changeStatus']);
                Route::apiResource('pedidos', PedidoController::class)->except(['show', 'destroy']);
            });
        }
    });
});

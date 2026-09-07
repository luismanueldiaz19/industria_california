<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\UserController;
// Modulo Ledhouse
use App\Http\Controllers\Api\LedhouseEstadoResultadoController;
use App\Http\Controllers\Api\LedhouseCxpController;
use App\Http\Controllers\Api\LedhouseCxcController;
use App\Http\Controllers\Api\LedhouseCuentaCatalogoController;
use App\Http\Controllers\Api\LedhouseClienteController;
use App\Http\Controllers\Api\LedhouseProveedorController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::prefix('v1')->group(function () {

    // Rutas Públicas
    Route::post('login', [AuthController::class, 'login']);

    // Rutas Públicas (Módulo Ledhouse - PDFs)
    Route::prefix('ledhouse')->group(function () {
        Route::get('/estado-resultado/matriz-pdf', [LedhouseEstadoResultadoController::class, 'generateMatrizPdf']);
        Route::get('/estado-resultado/pdf', [LedhouseEstadoResultadoController::class, 'generatePdf']);
        Route::get('cxc/reporte-general-pdf', [LedhouseCxcController::class, 'reporteGeneralPdf']);
        Route::get('cxc/reporte-agrupado-pdf', [LedhouseCxcController::class, 'reporteAgrupadoPdf']);
        Route::get('cxc/reporte-pdf/{cliente_id}', [LedhouseCxcController::class, 'reportePdf']);
        Route::get('cxc/alertas-pdf', [LedhouseCxcController::class, 'reporteAlertasPdf']);
    });

    // Rutas Protegidas
    Route::middleware('auth:sanctum')->group(function () {
        
        Route::post('register', [AuthController::class, 'register']);
        Route::post('logout', [AuthController::class, 'logout']);
        Route::apiResource('users', UserController::class);

        Route::get('/file', function (Request $request) {
            $path = $request->query('path');
            if (!$path) abort(404);
            $fullPath = storage_path('app/public/' . $path);
            if (!file_exists($fullPath)) abort(404);
            return response()->file($fullPath);
        });

        // ── MÓDULO LED-HOUSE ───────────────────────────────────────────────
        Route::prefix('ledhouse')->group(function () {
            Route::get('/estado-resultado/matriz', [LedhouseEstadoResultadoController::class, 'matriz']);
            Route::get('/estado-resultado', [LedhouseEstadoResultadoController::class, 'index']);
            Route::get('/estado-resultado/summary', [LedhouseEstadoResultadoController::class, 'summary']);
            Route::post('/estado-resultado', [LedhouseEstadoResultadoController::class, 'store']);
            Route::put('/estado-resultado/{id}', [LedhouseEstadoResultadoController::class, 'update']);
            Route::delete('/estado-resultado/{id}', [LedhouseEstadoResultadoController::class, 'destroy']);
            Route::post('/estado-resultado/import', [LedhouseEstadoResultadoController::class, 'import']);

            // CXP
            Route::apiResource('cxp', LedhouseCxpController::class);

            // CXC
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
        });
    });
});

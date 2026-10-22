<?php

use App\Modules\CuentasPorCobrar\Http\Controllers\CuentaPorCobrarController;
use App\Modules\CuentasPorCobrar\Http\Controllers\CxcCuarentenaController;
use Illuminate\Support\Facades\Route;
use App\Modules\Alerta\Http\Controllers\AlertaController;
Route::middleware('auth:sanctum')->group(function () {
    // Resumen y Métricas
    Route::get('cxc/resumen', [CuentaPorCobrarController::class, 'resumen']);

    // Vista Vendedor
    Route::get('vendedor/mis-cxc', [CuentaPorCobrarController::class, 'misCxc']);
    Route::get('cxc/vendedor/mis-cxc', [CuentaPorCobrarController::class, 'misCxc']);
    Route::get('vendedor/mis-cxc-pdf-url', [CuentaPorCobrarController::class, 'misCxcPdfUrl']);
    Route::get('cxc/vendedor/mis-cxc-pdf-url', [CuentaPorCobrarController::class, 'misCxcPdfUrl']);
    Route::get('vendedor/mis-cxc-pdf', [CuentaPorCobrarController::class, 'exportMisCxcPdf']);
    Route::get('cxc/vendedor/mis-cxc-pdf', [CuentaPorCobrarController::class, 'exportMisCxcPdf']);

    // Agrupado por Cliente
    Route::get('cxc/grouped', [CuentaPorCobrarController::class, 'grouped']);

    // Auditoría
    Route::get('cxc/auditoria', [CuentaPorCobrarController::class, 'auditoria']);

    // Sincronización Masiva
    Route::post('cxc/sync-preview', [CuentaPorCobrarController::class, 'syncPreview']);
    Route::post('cxc/sync-confirm', [CuentaPorCobrarController::class, 'syncConfirm']);

    // Importación por Cliente
    Route::post('cxc/import-by-cliente/{cliente_id}', [CuentaPorCobrarController::class, 'importByCliente']);

    // Alertas (comentadas para probar módulo Alerta V2 puro)
    // Route::get('cxc/alertas', [CuentaPorCobrarController::class, 'alertasIndex']);
    // Route::patch('cxc/alertas/{alerta}/resolver', [CuentaPorCobrarController::class, 'alertaResolver']);
    // Route::patch('cxc/alertas/{alerta}/tipo', [CuentaPorCobrarController::class, 'alertaUpdateTipo']);
    // Route::delete('cxc/alertas/{alerta}', [CuentaPorCobrarController::class, 'alertaDestroy']);
    // Route::post('cxc/{cxc}/alerta', [CuentaPorCobrarController::class, 'alertaStore']);

    // Cuarentena (Notas de Crédito / Débito pendientes) - solo admin
    Route::get('cxc/cuarentena/resumen', [CxcCuarentenaController::class, 'resumen']);
    Route::get('cxc/cuarentena', [CxcCuarentenaController::class, 'index']);
    Route::post('cxc/cuarentena/masivo', [CxcCuarentenaController::class, 'enviarMasivo']);
    Route::get('cxc/cuarentena/{cuarentena}', [CxcCuarentenaController::class, 'show'])->whereNumber('cuarentena');
    Route::patch('cxc/cuarentena/{cuarentena}/aplicar', [CxcCuarentenaController::class, 'aplicar'])->whereNumber('cuarentena');
    Route::patch('cxc/cuarentena/{cuarentena}/anular', [CxcCuarentenaController::class, 'anular'])->whereNumber('cuarentena');
    Route::post('cxc/{cxc}/cuarentena', [CxcCuarentenaController::class, 'enviar'])->whereNumber('cxc');

    // Soportes
    Route::get('cxc/{cxc}/soporte', [CuentaPorCobrarController::class, 'soportesIndex']);
    Route::post('cxc/{cxc}/soporte', [CuentaPorCobrarController::class, 'soporteStore']);

    // Evidencias (Mapeadas a AlertaController)
    Route::get('cxc/{cxc}/evidencias', [AlertaController::class, 'getEvidencias']);
    Route::post('cxc/{cxc}/evidencia', [AlertaController::class, 'uploadEvidencia']);

    // CRUD Base
    Route::apiResource('cxc', CuentaPorCobrarController::class);
});

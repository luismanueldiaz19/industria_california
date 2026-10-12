<?php

use App\Modules\CuentasPorCobrar\Http\Controllers\CuentaPorCobrarController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->group(function () {
    // Resumen y Métricas
    Route::get('cxc/resumen', [CuentaPorCobrarController::class, 'resumen']);

    // Vista Vendedor
    Route::get('cxc/vendedor/mis-cxc', [CuentaPorCobrarController::class, 'misCxc']);

    // Agrupado por Cliente
    Route::get('cxc/grouped', [CuentaPorCobrarController::class, 'grouped']);

    // Auditoría
    Route::get('cxc/auditoria', [CuentaPorCobrarController::class, 'auditoria']);

    // Sincronización Masiva
    Route::post('cxc/sync-preview', [CuentaPorCobrarController::class, 'syncPreview']);
    Route::post('cxc/sync-confirm', [CuentaPorCobrarController::class, 'syncConfirm']);

    // Importación por Cliente
    Route::post('cxc/import-by-cliente/{cliente_id}', [CuentaPorCobrarController::class, 'importByCliente']);

    // Alertas
    Route::get('cxc/alertas', [CuentaPorCobrarController::class, 'alertasIndex']);
    Route::patch('cxc/alertas/{alerta}/resolver', [CuentaPorCobrarController::class, 'alertaResolver']);
    Route::patch('cxc/alertas/{alerta}/tipo', [CuentaPorCobrarController::class, 'alertaUpdateTipo']);
    Route::delete('cxc/alertas/{alerta}', [CuentaPorCobrarController::class, 'alertaDestroy']);
    Route::post('cxc/{cxc}/alerta', [CuentaPorCobrarController::class, 'alertaStore']);

    // Soportes
    Route::get('cxc/{cxc}/soporte', [CuentaPorCobrarController::class, 'soportesIndex']);
    Route::post('cxc/{cxc}/soporte', [CuentaPorCobrarController::class, 'soporteStore']);

    // Evidencias
    Route::get('cxc/{cxc}/evidencias', [CuentaPorCobrarController::class, 'evidenciasIndex']);
    Route::post('cxc/{cxc}/evidencia', [CuentaPorCobrarController::class, 'evidenciaStore']);

    // CRUD Base
    Route::apiResource('cxc', CuentaPorCobrarController::class);
});

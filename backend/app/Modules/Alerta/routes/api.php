<?php

use App\Modules\Alerta\Http\Controllers\AlertaController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->group(function () {
    // Métricas y Resumen
    Route::get('alertas/resumen', [AlertaController::class, 'resumen']);

    // Reportes PDF y URL Segura
    Route::get('alertas/pdf-url', [AlertaController::class, 'pdfUrl']);
    Route::get('alertas/pdf', [AlertaController::class, 'reportePdf']);

    // Operaciones de Resolución y Concepto
    Route::patch('alertas/{alerta}/resolver', [AlertaController::class, 'resolver']);
    Route::patch('alertas/{alerta}/tipo', [AlertaController::class, 'updateTipo']);

    // Evidencias (Subir y Listar)
    Route::post('alertas/evidencia', [AlertaController::class, 'uploadEvidencia']);
    Route::post('alertas/{cxc}/evidencia', [AlertaController::class, 'uploadEvidencia']);
    Route::get('alertas/{cxc}/evidencias', [AlertaController::class, 'getEvidencias']);

    // CRUD Base
    Route::apiResource('alertas', AlertaController::class);
});

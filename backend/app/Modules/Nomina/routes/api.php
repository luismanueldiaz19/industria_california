<?php

use App\Modules\Nomina\Http\Controllers\NominaConceptoController;
use App\Modules\Nomina\Http\Controllers\NominaController;
use App\Modules\Nomina\Http\Controllers\NominaEmpleadoRecurrenteController;
use Illuminate\Support\Facades\Route;

// Conceptos de Nómina (Catálogo de Ingresos y Deducciones)
Route::apiResource('nomina-conceptos', NominaConceptoController::class)->parameters([
    'nomina-conceptos' => 'nominaConcepto'
]);

// Préstamos y deducciones recurrentes por empleado
Route::apiResource('nomina-recurrentes', NominaEmpleadoRecurrenteController::class)->parameters([
    'nomina-recurrentes' => 'recurrente'
]);

// Acciones específicas de Nómina registradas ANTES del apiResource
Route::get('nominas/resumen', [NominaController::class, 'resumen']);
Route::get('nominas/escalas-isr', [NominaController::class, 'escalasIsr']);
Route::get('nominas/token-reporte', function (\Illuminate\Http\Request $request) {
    $tipo = $request->query('tipo', 'nomina_general');
    $nominaId = $request->query('nomina_id');
    $detalleId = $request->query('detalle_id');
    $modo = $request->query('modo', 'blade');

    $params = [
        'nomina_id' => $nominaId ? (int)$nominaId : null,
        'detalle_id' => $detalleId ? (int)$detalleId : null,
        'modo' => $modo,
    ];

    $url = \App\Services\PdfSecurityService::generarUrl($tipo, $params, auth()->id(), 60);
    return response()->json(['url' => $url]);
});

Route::get('nominas/{nomina}/reportes-urls', function (\App\Modules\Nomina\Models\Nomina $nomina) {
    return response()->json([
        'volantes_web'   => \App\Services\PdfSecurityService::generarUrl('nomina_volantes', ['nomina_id' => $nomina->id, 'modo' => 'blade'], auth()->id(), 60),
        'volantes_pdf'   => \App\Services\PdfSecurityService::generarUrl('nomina_volantes', ['nomina_id' => $nomina->id, 'modo' => 'pdf'], auth()->id(), 60),
        'general_web'    => \App\Services\PdfSecurityService::generarUrl('nomina_general', ['nomina_id' => $nomina->id, 'modo' => 'blade'], auth()->id(), 60),
        'general_pdf'    => \App\Services\PdfSecurityService::generarUrl('nomina_general', ['nomina_id' => $nomina->id, 'modo' => 'pdf'], auth()->id(), 60),
        'general_excel'  => \App\Services\PdfSecurityService::generarUrl('nomina_general', ['nomina_id' => $nomina->id, 'modo' => 'excel'], auth()->id(), 60),
    ]);
});
Route::post('nominas/{nomina}/calcular', [NominaController::class, 'calcular']);
Route::post('nominas/{nomina}/aprobar', [NominaController::class, 'aprobar']);
Route::post('nominas/{nomina}/pagar', [NominaController::class, 'pagar']);
Route::post('nominas/{nomina}/anular', [NominaController::class, 'anular']);

// CRUD Base de Nóminas
Route::apiResource('nominas', NominaController::class);


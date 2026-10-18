<?php

use App\Modules\CamionVictual\Http\Controllers\CamionVictualController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->group(function () {
    Route::get('camiones-victuales/monto-minimo', [CamionVictualController::class, 'montoMinimo']);
    Route::get('camiones-victuales/pedidos-disponibles', [CamionVictualController::class, 'pedidosDisponibles']);
    Route::get('camiones-victuales/viajes/historial', [CamionVictualController::class, 'historialViajes']);
    Route::get('camiones-victuales/viajes/{viajeId}', [CamionVictualController::class, 'detalleViaje']);
    Route::post('camiones-victuales/{camionVictual}/pedidos', [CamionVictualController::class, 'agregarPedido']);
    Route::delete('camiones-victuales/{camionVictual}/pedidos/{pedidoId}', [CamionVictualController::class, 'quitarPedido']);
    Route::patch('camiones-victuales/{camionVictual}/reordenar', [CamionVictualController::class, 'reordenar']);
    Route::patch('camiones-victuales/{camionVictual}/pedidos/{pedidoId}/entrega', [CamionVictualController::class, 'actualizarEntrega']);
    Route::patch('camiones-victuales/{camionVictual}/en-ruta', [CamionVictualController::class, 'ponerEnRuta']);
    Route::post('camiones-victuales/{camionVictual}/cerrar-liquidacion', [CamionVictualController::class, 'cerrarConLiquidacion']);
    Route::patch('camiones-victuales/{camionVictual}/cerrar', [CamionVictualController::class, 'cerrar']);
    Route::patch('camiones-victuales/{camionVictual}/vaciar', [CamionVictualController::class, 'vaciar']);
    Route::get('camiones-victuales/{id}/pdf-url', [CamionVictualController::class, 'getConducePdfUrl']);
    Route::apiResource('camiones-victuales', CamionVictualController::class)->parameters([
        'camiones-victuales' => 'camionVictual',
    ]);
});

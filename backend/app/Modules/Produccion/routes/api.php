<?php

use App\Modules\Produccion\Http\Controllers\OrdenProduccionController;
use App\Modules\Produccion\Http\Controllers\ProduccionAgrupadaController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->group(function () {
    // Producción Agrupada
    Route::get('produccion/agrupada/producto', [ProduccionAgrupadaController::class, 'porProducto']);
    Route::get('produccion/agrupada/pedido', [ProduccionAgrupadaController::class, 'porPedido']);
    Route::get('produccion/agrupada/cliente', [ProduccionAgrupadaController::class, 'porCliente']);
    Route::get('produccion/agrupada/fecha', [ProduccionAgrupadaController::class, 'porFecha']);
    Route::post('produccion/agrupada/marcar-listo', [ProduccionAgrupadaController::class, 'marcarListoAgrupadoProducto']);
    Route::get('produccion-agrupada/pdf-url', [ProduccionAgrupadaController::class, 'getPdfUrl']);
    Route::get('produccion/agrupada/pdf-url', [ProduccionAgrupadaController::class, 'getPdfUrl']);

    // Órdenes de Producción
    Route::get('produccion', [OrdenProduccionController::class, 'index']);
    Route::get('produccion/por-pedido/{pedidoId}', [OrdenProduccionController::class, 'porPedidoId']);
    Route::post('produccion/generar-desde-pedido/{pedidoId}', [OrdenProduccionController::class, 'generarDesdePedido']);
    Route::get('produccion/{id}', [OrdenProduccionController::class, 'show']);
    Route::patch('produccion/detalles/{detalleId}/listo', [OrdenProduccionController::class, 'marcarDetalleListo']);
});

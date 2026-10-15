<?php

use App\Modules\Pedido\Http\Controllers\PedidoController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->group(function () {
    // Asignación y Optimización de Rutas
    Route::post('pedidos/assign-ruta', [PedidoController::class, 'assignRuta']);
    Route::post('pedidos/optimize-route', [PedidoController::class, 'optimizeDayRoute']);

    // Operaciones de Estado y Facturación
    Route::patch('pedidos/{pedido}/estado', [PedidoController::class, 'changeStatus']);
    Route::patch('pedidos/{pedido}/num-factura', [PedidoController::class, 'updateNumFactura']);
    Route::patch('pedidos/{pedido}/informacion', [PedidoController::class, 'updateInformacion']);

    // URLs de Reportes PDF
    Route::get('pedidos-pdf-url', [PedidoController::class, 'getGeneralPdfUrl']);
    Route::get('pedidos/pdf-url', [PedidoController::class, 'getGeneralPdfUrl']);
    Route::get('pedidos/{id}/pdf-url', [PedidoController::class, 'getPdfUrl']);

    // Reportes de Vendedores
    Route::get('pedidos/reporte-vendedores', [PedidoController::class, 'reporteVendedores']);
    Route::get('pedidos-vendedores-pdf-url', [PedidoController::class, 'getReporteVendedoresPdfUrl']);
    Route::get('pedidos/reporte-vendedores/pdf-url', [PedidoController::class, 'getReporteVendedoresPdfUrl']);

    // CRUD Base
    Route::apiResource('pedidos', PedidoController::class);
});

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
    Route::post('pedidos/{pedido}/facturar-vigente', [PedidoController::class, 'facturarVigente']);

    // Gestión de Items del Pedido (Solo Admin)
    Route::put('pedidos/{pedido}/items', [PedidoController::class, 'updateItems']);
    Route::patch('pedidos/{pedido}/items/{detalle}', [PedidoController::class, 'updateItem']);
    Route::delete('pedidos/{pedido}/items/{detalle}', [PedidoController::class, 'deleteItem']);

    // Reporte de Productos Facturados Pendientes de Entrega por Vendedor (Rutas Estáticas de Mayor Prioridad)
    Route::get('pedidos/productos-pendientes-entrega/pdf-url', [PedidoController::class, 'getProductosPendientesEntregaPdfUrl']);
    Route::get('pedidos/productos-pendientes-entrega', [PedidoController::class, 'reporteProductosPendientesEntrega']);
    Route::get('pedidos-productos-pendientes-pdf-url', [PedidoController::class, 'getProductosPendientesEntregaPdfUrl']);

    // URLs de Reportes PDF Generales
    Route::get('pedidos-pdf-url', [PedidoController::class, 'getGeneralPdfUrl']);
    Route::get('pedidos/pdf-url', [PedidoController::class, 'getGeneralPdfUrl']);

    // Reportes de Vendedores
    Route::get('pedidos/reporte-vendedores/pdf-url', [PedidoController::class, 'getReporteVendedoresPdfUrl']);
    Route::get('pedidos/reporte-vendedores', [PedidoController::class, 'reporteVendedores']);
    Route::get('pedidos-vendedores-pdf-url', [PedidoController::class, 'getReporteVendedoresPdfUrl']);

    // URLs de Reportes PDF Individuales (Con Parámetro Numérico)
    Route::get('pedidos/{id}/pdf-url', [PedidoController::class, 'getPdfUrl'])->whereNumber('id');

    // CRUD Base
    Route::apiResource('pedidos', PedidoController::class);
});

<?php

use Illuminate\Support\Facades\Route;
use App\Modules\Producto\Http\Controllers\ProductoController;

use App\Modules\Producto\Http\Controllers\CategoriaController;

Route::prefix('api/v1')->middleware('auth:sanctum')->group(function () {
    Route::post('categorias/{categoria}/productos/import', [CategoriaController::class, 'importProductos']);
    Route::post('categorias/{categoria}/imagen', [CategoriaController::class, 'uploadImagen']);
    Route::apiResource('categorias', CategoriaController::class);
    Route::apiResource('productos', ProductoController::class);
});

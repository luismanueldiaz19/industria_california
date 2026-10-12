<?php

use Illuminate\Support\Facades\Route;
use App\Modules\Cliente\Http\Controllers\ClienteController;

Route::middleware('auth:sanctum')->group(function () {
    // Importación Excel
    Route::post('cliente/import', [ClienteController::class, 'import']);
    Route::post('clientes/import', [ClienteController::class, 'import']);

    // CRUD completo (soporta tanto /cliente como /clientes)
    Route::apiResource('cliente', ClienteController::class);
    Route::apiResource('clientes', ClienteController::class);
});

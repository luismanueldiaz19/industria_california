<?php

use App\Modules\Empleado\Http\Controllers\EmpleadoController;
use Illuminate\Support\Facades\Route;

// Sub-rutas específicas registradas ANTES del apiResource
Route::get('empleados/resumen', [EmpleadoController::class, 'resumen']);
Route::get('empleados/activos-para-nomina', [EmpleadoController::class, 'activosParaNomina']);

// CRUD Base
Route::apiResource('empleados', EmpleadoController::class);


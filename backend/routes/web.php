<?php

use Illuminate\Support\Facades\Route;
// =========================================================
// RUTA PARA EL FRONTEND (FLUTTER WEB)
// =========================================================
// Esta ruta atrapa todo lo demás que no sea la API o los PDFs
// y carga la aplicación web de Flutter. Flutter se encarga
// internamente del resto de las rutas en el navegador.
Route::get('/{any?}', function () {
    return view('app');
})->where('any', '.*');

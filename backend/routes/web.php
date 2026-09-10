<?php

use App\Http\Controllers\Pdf\PdfViewerController;

// =========================================================
// RUTA SEGURA DE VISUALIZACIÓN DE DOCUMENTOS (TOKEN OPACO)
// =========================================================
Route::get('/d/{token}', [PdfViewerController::class, 'ver'])->name('pdf.view');

// =========================================================
// RUTA PARA EL FRONTEND (FLUTTER WEB)
// =========================================================
// Esta ruta atrapa todo lo demás que no sea la API o los PDFs
// y carga la aplicación web de Flutter. Flutter se encarga
// internamente del resto de las rutas en el navegador.
Route::get('/{any?}', function () {
    return view('app');
})->where('any', '.*');

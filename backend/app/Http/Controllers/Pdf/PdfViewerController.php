<?php

namespace App\Http\Controllers\Pdf;

use App\Http\Controllers\Controller;
use App\Services\PdfSecurityService;
use Illuminate\Http\Request;

class PdfViewerController extends Controller
{
    /**
     * Muestra el documento PDF en el navegador mediante su token opaco.
     * Si el token no existe o expiró, aborta con 404 Not Found.
     */
    public function ver(Request $request, string $token)
    {
        return PdfSecurityService::renderizarPdf($token);
    }
}

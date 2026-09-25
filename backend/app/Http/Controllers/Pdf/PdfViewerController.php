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
        try {
            return PdfSecurityService::renderizarPdf($token);
        } catch (\Throwable $e) {
            // DEBUG TEMPORAL — quitar después de identificar el error
            return response('<pre style="background:#1e1e1e;color:#ff6b6b;padding:20px;font-size:13px;">'
                . '<b>ERROR:</b> ' . htmlspecialchars($e->getMessage()) . "\n\n"
                . '<b>Archivo:</b> ' . htmlspecialchars($e->getFile()) . ':' . $e->getLine() . "\n\n"
                . '<b>Trace:</b>' . "\n" . htmlspecialchars($e->getTraceAsString())
                . '</pre>', 200, ['Content-Type' => 'text/html']);
        }
    }
}

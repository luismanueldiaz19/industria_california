<?php

namespace App\Modules\ChequeFuturista\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\ChequeFuturista\Http\Requests\StoreChequeFuturistaRequest;
use App\Modules\ChequeFuturista\Http\Requests\StoreDocumentoChequeRequest;
use App\Modules\ChequeFuturista\Http\Requests\UpdateChequeFuturistaRequest;
use App\Modules\ChequeFuturista\Http\Resources\ChequeFuturistaResource;
use App\Modules\ChequeFuturista\Models\ChequeFuturista;
use App\Modules\ChequeFuturista\Models\DocumentoCheque;
use App\Modules\ChequeFuturista\Services\ChequeFuturistaService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Services\PdfSecurityService;

class ChequeFuturistaController extends Controller
{
    public function __construct(
        private readonly ChequeFuturistaService $service
    ) {}

    // ── CRUD Cheques ──────────────────────────────────────────

    public function index(Request $request): JsonResponse
    {
        $cheques = $this->service->obtenerListadoFiltrado($request->all(), Auth::id());
        return response()->json($cheques);
    }

    public function getPdfUrl(Request $request): JsonResponse
    {
        $params = $request->all();
        $params['id_vendedor'] = Auth::id(); // Asegurar que sea el vendedor actual
        $url = PdfSecurityService::generarUrl('cheques_futuristas_general', $params, Auth::id(), 30);
        return response()->json(['url' => $url]);
    }

    public function store(StoreChequeFuturistaRequest $request): JsonResponse {
        try {
            $cheque = $this->service->crear($request->validated(), Auth::user());
            $cheque->load(['cliente:id,nombre', 'vendedor:id,name', 'creador:id,name']);
            return response()->json(new ChequeFuturistaResource($cheque), 201);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function show(ChequeFuturista $chequeFuturista): JsonResponse {
        $chequeFuturista->load(['cliente:id,nombre', 'vendedor:id,name', 'creador:id,name', 'documentos']);
        return response()->json(new ChequeFuturistaResource($chequeFuturista));
    }

    public function update(UpdateChequeFuturistaRequest $request, ChequeFuturista $chequeFuturista): JsonResponse {
        try {
            $cheque = $this->service->actualizar($chequeFuturista, $request->validated());
            return response()->json(new ChequeFuturistaResource($cheque));
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function destroy(ChequeFuturista $chequeFuturista): JsonResponse
    {
        try {
            $this->service->eliminar($chequeFuturista);
            return response()->json(null, 204);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function resumen(): JsonResponse
    {
        return response()->json($this->service->resumen());
    }

    // ── Sub-recurso: Documentos ───────────────────────────────

    public function documentosIndex(ChequeFuturista $chequeFuturista): JsonResponse
    {
        return response()->json($chequeFuturista->documentos()->orderByDesc('id')->get());
    }

    public function documentosStore(StoreDocumentoChequeRequest $request, ChequeFuturista $chequeFuturista): JsonResponse
    {
        try {
            $documento = $this->service->subirDocumento(
                $chequeFuturista,
                $request->file('archivo'),
                Auth::user()
            );
            return response()->json($documento, 201);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function documentosDestroy(ChequeFuturista $chequeFuturista, DocumentoCheque $documento): JsonResponse
    {
        try {
            $this->service->eliminarDocumento($documento);
            return response()->json(null, 204);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }
}
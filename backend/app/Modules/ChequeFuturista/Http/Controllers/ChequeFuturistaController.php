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

    /** Listado global para gestión contable (sin restricción por vendedor). */
    public function indexAdmin(Request $request): JsonResponse
    {
        $cheques = $this->service->obtenerListadoAdmin($request->all());
        return response()->json($cheques);
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
        if (!Auth::user()->hasRole('admin')) {
            return response()->json(['message' => 'Solo el administrador puede eliminar cheques.'], 403);
        }

        try {
            $this->service->eliminar($chequeFuturista);
            return response()->json(['message' => 'Cheque eliminado correctamente.']);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function resumen(): JsonResponse
    {
        return response()->json($this->service->resumen());
    }

    public function reporteVendedores(Request $request): JsonResponse
    {
        return response()->json($this->service->reporteVendedores($request->all()));
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

    /** Elimina una imagen/evidencia del cheque. Solo administradores. */
    public function documentosDestroy(ChequeFuturista $chequeFuturista, DocumentoCheque $documento): JsonResponse
    {
        if (!Auth::user()->hasRole('admin')) {
            return response()->json(['message' => 'Solo el administrador puede eliminar evidencias.'], 403);
        }

        if ((int) $documento->cheque_futurista_id !== (int) $chequeFuturista->id) {
            return response()->json(['message' => 'El documento no pertenece a este cheque.'], 404);
        }

        try {
            $this->service->eliminarDocumento($documento);
            return response()->json(['message' => 'Evidencia eliminada correctamente.']);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function getPdfUrl(Request $request): JsonResponse
    {
        $params = $request->only(['fecha_inicio', 'fecha_fin', 'buscar', 'estado', 'id_vendedor', 'atrasados']);
        
        if (!Auth::user()->hasRole('admin')) {
            $params['id_vendedor'] = Auth::id();
        }
        
        $url = PdfSecurityService::generarUrl('cheques_futuristas_general', $params, Auth::id(), 30);
        
        return response()->json(['url' => $url]);
    }
}
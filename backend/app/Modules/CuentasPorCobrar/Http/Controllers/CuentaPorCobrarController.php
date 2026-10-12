<?php

namespace App\Modules\CuentasPorCobrar\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\CuentasPorCobrar\Http\Requests\ResolverCxcAlertaRequest;
use App\Modules\CuentasPorCobrar\Http\Requests\StoreCuentaPorCobrarRequest;
use App\Modules\CuentasPorCobrar\Http\Requests\StoreCxcAlertaRequest;
use App\Modules\CuentasPorCobrar\Http\Requests\StoreCxcSoporteRequest;
use App\Modules\CuentasPorCobrar\Http\Requests\UpdateCuentaPorCobrarRequest;
use App\Modules\CuentasPorCobrar\Http\Requests\UploadCxcEvidenciaRequest;
use App\Modules\CuentasPorCobrar\Http\Resources\CuentaPorCobrarResource;
use App\Modules\CuentasPorCobrar\Http\Resources\CxcAlertaResource;
use App\Modules\CuentasPorCobrar\Http\Resources\CxcEvidenciaResource;
use App\Modules\CuentasPorCobrar\Http\Resources\CxcSoporteResource;
use App\Modules\CuentasPorCobrar\Services\CuentaPorCobrarService;
use Exception;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CuentaPorCobrarController extends Controller
{
    public function __construct(
        private readonly CuentaPorCobrarService $service
    ) {}

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $filters = $request->all();

        // Si es vendedor, forzar su vendedor_id
        if ($user && $user->hasRole('vendedor')) {
            $filters['vendedor_id'] = $user->id;
        }

        $result = $this->service->listar($filters, $request->per_page ?? null);

        if ($result instanceof LengthAwarePaginator) {
            return response()->json([
                'data'         => CuentaPorCobrarResource::collection($result->items()),
                'current_page' => $result->currentPage(),
                'last_page'    => $result->lastPage(),
                'per_page'     => $result->perPage(),
                'total'        => $result->total(),
            ]);
        }

        return response()->json(CuentaPorCobrarResource::collection($result));
    }

    public function store(StoreCuentaPorCobrarRequest $request): JsonResponse
    {
        try {
            $record = $this->service->crear($request->validated());
            return response()->json(new CuentaPorCobrarResource($record), 201);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function show(int $id): JsonResponse
    {
        try {
            $record = $this->service->obtener($id);
            return response()->json(new CuentaPorCobrarResource($record));
        } catch (Exception $e) {
            return response()->json(['message' => 'Cuenta por cobrar no encontrada.'], 404);
        }
    }

    public function update(UpdateCuentaPorCobrarRequest $request, int $id): JsonResponse
    {
        try {
            $record = $this->service->actualizar($id, $request->validated());
            return response()->json(new CuentaPorCobrarResource($record));
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function destroy(int $id): JsonResponse
    {
        try {
            $this->service->eliminar($id);
            return response()->json(null, 204);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function resumen(): JsonResponse
    {
        return response()->json($this->service->resumen());
    }

    public function misCxc(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user || !$user->hasRole('vendedor')) {
            return response()->json(['error' => 'No autorizado'], 403);
        }

        $result = $this->service->misCxc($user->id, $request->all(), $request->per_page ?? 20);
        $paginator = $result['paginator'];

        return response()->json([
            'current_page'     => $paginator->currentPage(),
            'data'             => CuentaPorCobrarResource::collection($paginator->items()),
            'first_page_url'   => $paginator->url(1),
            'from'             => $paginator->firstItem(),
            'last_page'        => $paginator->lastPage(),
            'last_page_url'    => $paginator->url($paginator->lastPage()),
            'next_page_url'    => $paginator->nextPageUrl(),
            'path'             => $paginator->path(),
            'per_page'         => $paginator->perPage(),
            'prev_page_url'    => $paginator->previousPageUrl(),
            'to'               => $paginator->lastItem(),
            'total'            => $paginator->total(),
            'totales_globales' => $result['totales_globales'],
        ]);
    }

    public function grouped(Request $request): JsonResponse
    {
        $clientes = $this->service->agrupadoPorCliente($request->all());
        return response()->json($clientes);
    }

    // ─────────────────────────────────────────────────────────────
    // Alertas
    // ─────────────────────────────────────────────────────────────

    public function alertasIndex(Request $request): JsonResponse
    {
        $alertas = $this->service->listarAlertas($request->all(), $request->user());

        if ($alertas instanceof LengthAwarePaginator) {
            return response()->json([
                'data'         => CxcAlertaResource::collection($alertas->items()),
                'current_page' => $alertas->currentPage(),
                'last_page'    => $alertas->lastPage(),
                'per_page'     => $alertas->perPage(),
                'total'        => $alertas->total(),
            ]);
        }

        return response()->json(CxcAlertaResource::collection($alertas));
    }

    public function alertaStore(StoreCxcAlertaRequest $request, int $id): JsonResponse
    {
        try {
            $alerta = $this->service->agregarAlerta($id, $request->validated(), $request->user());
            return response()->json(new CxcAlertaResource($alerta), 201);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function alertaResolver(ResolverCxcAlertaRequest $request, int $alertaId): JsonResponse
    {
        try {
            $alerta = $this->service->resolverAlerta($alertaId, $request->validated(), $request->user());
            return response()->json(new CxcAlertaResource($alerta));
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function alertaDestroy(Request $request, int $alertaId): JsonResponse
    {
        try {
            $this->service->eliminarAlerta($alertaId, $request->user());
            return response()->json(['message' => 'Alerta y documentos eliminados exitosamente.']);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function alertaUpdateTipo(Request $request, int $alertaId): JsonResponse
    {
        $validated = $request->validate([
            'tipo' => 'required|string|max:50',
        ]);
        try {
            $alerta = $this->service->updateTipoAlerta($alertaId, $validated['tipo']);
            return response()->json(new CxcAlertaResource($alerta));
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    // ─────────────────────────────────────────────────────────────
    // Soportes
    // ─────────────────────────────────────────────────────────────

    public function soportesIndex(int $id): JsonResponse
    {
        $soportes = $this->service->listarSoportes($id);
        return response()->json(CxcSoporteResource::collection($soportes));
    }

    public function soporteStore(StoreCxcSoporteRequest $request, int $id): JsonResponse
    {
        try {
            $soporte = $this->service->agregarSoporte($id, $request->validated());
            return response()->json(new CxcSoporteResource($soporte), 201);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    // ─────────────────────────────────────────────────────────────
    // Evidencias
    // ─────────────────────────────────────────────────────────────

    public function evidenciasIndex(int $id): JsonResponse
    {
        $evidencias = $this->service->listarEvidencias($id);
        return response()->json(CxcEvidenciaResource::collection($evidencias));
    }

    public function evidenciaStore(UploadCxcEvidenciaRequest $request, int $id): JsonResponse
    {
        try {
            $evidencia = $this->service->subirEvidencia(
                $id,
                $request->file('file'),
                $request->alerta_id,
                $request->user()
            );
            return response()->json(new CxcEvidenciaResource($evidencia), 201);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    // ─────────────────────────────────────────────────────────────
    // Auditoría
    // ─────────────────────────────────────────────────────────────

    public function auditoria(Request $request): JsonResponse
    {
        try {
            $resultado = $this->service->auditoria($request->user());
            return response()->json($resultado);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 403);
        }
    }

    // ─────────────────────────────────────────────────────────────
    // Sync & Importación Masiva
    // ─────────────────────────────────────────────────────────────

    public function syncPreview(Request $request): JsonResponse
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls,csv',
        ]);

        try {
            $preview = $this->service->syncPreview($request->file('file'));
            return response()->json($preview);
        } catch (Exception $e) {
            return response()->json(['message' => 'Error al analizar el archivo: ' . $e->getMessage()], 500);
        }
    }

    public function syncConfirm(Request $request): JsonResponse
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls,csv',
        ]);

        try {
            $resultado = $this->service->syncConfirm($request->file('file'));
            return response()->json($resultado);
        } catch (Exception $e) {
            return response()->json(['message' => 'Error durante la sincronización: ' . $e->getMessage()], 500);
        }
    }

    public function importByCliente(Request $request, int $clienteId): JsonResponse
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls,csv',
        ]);

        try {
            $resultado = $this->service->importByCliente($clienteId, $request->file('file'));
            return response()->json($resultado);
        } catch (Exception $e) {
            return response()->json(['message' => 'Error al importar: ' . $e->getMessage()], 500);
        }
    }
}

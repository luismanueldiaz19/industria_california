<?php

namespace App\Modules\Alerta\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Alerta\Http\Requests\ResolverAlertaRequest;
use App\Modules\Alerta\Http\Requests\StoreAlertaRequest;
use App\Modules\Alerta\Http\Requests\UpdateTipoAlertaRequest;
use App\Modules\Alerta\Models\Alerta;
use App\Modules\Alerta\Services\AlertaService;
use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AlertaController extends Controller
{
    public function __construct(
        private readonly AlertaService $service
    ) {}

    public function index(Request $request): JsonResponse
    {
        $alertas = $this->service->listar($request->all(), $request->user());
        return response()->json($alertas);
    }

    public function resumen(Request $request): JsonResponse
    {
        $resumen = $this->service->resumen($request->user());
        return response()->json($resumen);
    }

    public function store(StoreAlertaRequest $request): JsonResponse
    {
        try {
            $alerta = $this->service->crear($request->validated(), $request->user());
            return response()->json($alerta, 201);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function show(Alerta $alerta): JsonResponse
    {
        return response()->json(
            $alerta->load(['cxc.cliente', 'vendedor:id,name', 'revisador:id,name', 'evidencias'])
        );
    }

    public function resolver(ResolverAlertaRequest $request, int $alertaId): JsonResponse
    {
        try {
            $alerta = $this->service->resolver($alertaId, $request->validated(), $request->user());
            return response()->json($alerta);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function updateTipo(UpdateTipoAlertaRequest $request, int $alertaId): JsonResponse
    {
        try {
            $alerta = $this->service->actualizarTipo($alertaId, $request->validated('tipo'));
            return response()->json($alerta);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function destroy(Request $request, int $alertaId): JsonResponse
    {
        try {
            $this->service->eliminar($alertaId, $request->user());
            return response()->json(['message' => 'Alerta eliminada correctamente.']);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function pdfUrl(Request $request): JsonResponse
    {
        $url = $this->service->obtenerPdfUrl($request->all(), $request->user());
        return response()->json(['url' => $url]);
    }

    public function reportePdf(Request $request)
    {
        return $this->service->generarPdf($request->all(), $request->user());
    }

    public function uploadEvidencia(Request $request, ?int $cxc = null): JsonResponse
    {
        $request->validate([
            'file'      => 'required|file|mimes:pdf,jpg,jpeg,png|max:10240',
            'cxc_id'    => 'nullable|integer',
            'alerta_id' => 'nullable|integer',
        ]);

        $cxcId = $cxc ?? $request->input('cxc_id') ?? $request->input('ledhouse_cxc_id');
        if (!$cxcId) {
            return response()->json(['message' => 'El id de la cuenta por cobrar es obligatorio.'], 422);
        }

        try {
            $alertaId = $request->filled('alerta_id') ? (int) $request->input('alerta_id') : null;
            $evidencia = $this->service->subirEvidencia(
                (int) $cxcId,
                $request->file('file'),
                $request->user(),
                $alertaId
            );

            return response()->json($evidencia, 201);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function getEvidencias(int $cxc): JsonResponse
    {
        $evidencias = $this->service->listarEvidencias($cxc);
        return response()->json($evidencias);
    }
}

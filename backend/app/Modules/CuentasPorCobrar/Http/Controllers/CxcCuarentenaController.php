<?php

namespace App\Modules\CuentasPorCobrar\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\CuentasPorCobrar\Http\Requests\EnviarCuarentenaRequest;
use App\Modules\CuentasPorCobrar\Http\Requests\ResolverCuarentenaRequest;
use App\Modules\CuentasPorCobrar\Services\CxcCuarentenaService;
use Exception;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CxcCuarentenaController extends Controller
{
    public function __construct(
        private readonly CxcCuarentenaService $service
    ) {}

    private function soloAdmin(Request $request): ?JsonResponse
    {
        if (!$request->user()?->hasRole('admin')) {
            return response()->json(['message' => 'Solo un administrador puede gestionar la cuarentena de CXC.'], 403);
        }
        return null;
    }

    public function index(Request $request): JsonResponse
    {
        if ($r = $this->soloAdmin($request)) return $r;

        $result = $this->service->listar($request->all());

        return response()->json([
            'data'         => $result->items(),
            'current_page' => $result->currentPage(),
            'last_page'    => $result->lastPage(),
            'per_page'     => $result->perPage(),
            'total'        => $result->total(),
        ]);
    }

    public function show(Request $request, int $cuarentena): JsonResponse
    {
        if ($r = $this->soloAdmin($request)) return $r;

        try {
            return response()->json($this->service->obtener($cuarentena));
        } catch (ModelNotFoundException) {
            return response()->json(['message' => 'Registro de cuarentena no encontrado.'], 404);
        }
    }

    public function resumen(Request $request): JsonResponse
    {
        if ($r = $this->soloAdmin($request)) return $r;

        return response()->json($this->service->resumen());
    }

    public function enviar(EnviarCuarentenaRequest $request, int $cxc): JsonResponse
    {
        try {
            $registro = $this->service->enviar($cxc, $request->validated(), $request->user());
            return response()->json([
                'message' => "Documento {$registro->documento} enviado a cuarentena.",
                'data'    => $registro,
            ], 201);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function enviarMasivo(EnviarCuarentenaRequest $request): JsonResponse
    {
        try {
            $datos     = $request->validated();
            $registros = $this->service->enviarMasivo($datos['ids'], $datos, $request->user());
            return response()->json([
                'message' => count($registros) . ' documento(s) enviados a cuarentena.',
                'data'    => $registros,
            ], 201);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function aplicar(ResolverCuarentenaRequest $request, int $cuarentena): JsonResponse
    {
        try {
            $registro = $this->service->aplicar($cuarentena, $request->validated(), $request->user());
            return response()->json($registro);
        } catch (ModelNotFoundException) {
            return response()->json(['message' => 'Registro de cuarentena no encontrado.'], 404);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function anular(ResolverCuarentenaRequest $request, int $cuarentena): JsonResponse
    {
        try {
            $registro = $this->service->anular($cuarentena, $request->validated(), $request->user());
            return response()->json($registro);
        } catch (ModelNotFoundException) {
            return response()->json(['message' => 'Registro de cuarentena no encontrado.'], 404);
        } catch (Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }
}

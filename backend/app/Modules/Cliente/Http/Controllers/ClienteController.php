<?php

namespace App\Modules\Cliente\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Cliente\Http\Requests\StoreClienteRequest;
use App\Modules\Cliente\Http\Requests\UpdateClienteRequest;
use App\Modules\Cliente\Http\Resources\ClienteResource;
use App\Modules\Cliente\Services\ClienteService;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ClienteController extends Controller
{
    protected ClienteService $clienteService;

    public function __construct(ClienteService $clienteService)
    {
        $this->clienteService = $clienteService;
    }

    public function index(Request $request)
    {
        $clientes = $this->clienteService->getAllClientes();

        if ($clientes instanceof LengthAwarePaginator) {
            return response()->json([
                'data'         => ClienteResource::collection($clientes->items()),
                'current_page' => $clientes->currentPage(),
                'last_page'    => $clientes->lastPage(),
                'per_page'     => $clientes->perPage(),
                'total'        => $clientes->total(),
            ]);
        }

        return response()->json(ClienteResource::collection($clientes));
    }

    public function store(StoreClienteRequest $request): JsonResponse
    {
        $cliente = $this->clienteService->createCliente($request->validated());
        return response()->json(new ClienteResource($cliente), 201);
    }

    public function show($id): JsonResponse
    {
        $cliente = $this->clienteService->getClienteById($id);
        return response()->json(new ClienteResource($cliente));
    }

    public function update(UpdateClienteRequest $request, $id): JsonResponse
    {
        $cliente = $this->clienteService->updateCliente($id, $request->validated());
        return response()->json(new ClienteResource($cliente));
    }

    public function destroy($id): JsonResponse
    {
        $this->clienteService->deleteCliente($id);
        return response()->json(null, 204);
    }

    public function import(Request $request): JsonResponse
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls,csv',
        ]);

        try {
            $resultado = $this->clienteService->importClientes($request->file('file'));
            return response()->json($resultado);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error al importar: ' . $e->getMessage(),
            ], 500);
        }
    }
}

<?php

// app/Modules/Pedido/Http/Controllers/PedidoController.php
namespace App\Modules\Pedido\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Pedido\Http\Requests\StorePedidoRequest;
use App\Modules\Pedido\Http\Resources\PedidoResource;
use App\Modules\Pedido\Services\PedidoService;
use Illuminate\Http\JsonResponse;

class PedidoController extends Controller
{
    public function __construct(
        private readonly PedidoService $pedidoService,
    ) {}

    public function store(StorePedidoRequest $request): JsonResponse
    {
        $pedido = $this->pedidoService->crear(
            $request->validated(),
            $request->user(),
        );

        return (new PedidoResource($pedido))
            ->response()
            ->setStatusCode($pedido->wasRecentlyCreated ? 201 : 200);
    }
}
<?php

namespace App\Modules\Producto\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Producto\Http\Requests\StoreProductoRequest;
use App\Modules\Producto\Http\Requests\UpdateProductoRequest;
use App\Modules\Producto\Http\Resources\ProductoResource;
use App\Modules\Producto\Services\ProductoService;
use Illuminate\Http\JsonResponse;

class ProductoController extends Controller
{
    protected $productoService;

    public function __construct(ProductoService $productoService)
    {
        $this->productoService = $productoService;
    }

    public function index()
    {
        $productos = $this->productoService->getAllProductos();
        return ProductoResource::collection($productos);
    }

    public function store(StoreProductoRequest $request): JsonResponse
    {
        $producto = $this->productoService->createProducto($request->validated());
        return response()->json(new ProductoResource($producto), 201);
    }

    public function show($id): JsonResponse
    {
        $producto = $this->productoService->getProductoById($id);
        return response()->json(new ProductoResource($producto));
    }

    public function update(UpdateProductoRequest $request, $id): JsonResponse
    {
        $producto = $this->productoService->updateProducto($id, $request->validated());
        return response()->json(new ProductoResource($producto));
    }

    public function destroy($id): JsonResponse
    {
        $this->productoService->deleteProducto($id);
        return response()->json(null, 204);
    }
}

<?php

namespace App\Modules\Producto\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Producto\Http\Requests\StoreProductoRequest;
use App\Modules\Producto\Http\Requests\UpdateProductoRequest;
use App\Modules\Producto\Http\Resources\ProductoResource;
use App\Modules\Producto\Services\ProductoService;
use App\Services\PdfSecurityService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

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

    /**
     * Genera URL segura (token) para PDF de inventario.
     */
    public function getInventarioPdfUrl(Request $request)
    {
        $params = [];
        foreach (['search', 'categoria_id', 'estado_stock', 'order_by', 'order_dir', 'solo_negativos'] as $key) {
            if ($request->filled($key)) {
                $params[$key] = $request->input($key);
            }
        }

        $url = PdfSecurityService::generarUrl(
            'inventario_productos',
            $params,
            $request->user()->id,
            30
        );

        return response()->json(['url' => $url]);
    }
}

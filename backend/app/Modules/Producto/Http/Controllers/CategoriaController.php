<?php

namespace App\Modules\Producto\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Producto\Http\Requests\StoreCategoriaRequest;
use App\Modules\Producto\Http\Requests\UpdateCategoriaRequest;
use App\Modules\Producto\Http\Resources\CategoriaResource;
use App\Modules\Producto\Services\CategoriaService;
use Illuminate\Http\JsonResponse;

class CategoriaController extends Controller
{
    protected $categoriaService;

    public function __construct(CategoriaService $categoriaService)
    {
        $this->categoriaService = $categoriaService;
    }

    public function index(): JsonResponse
    {
        $categorias = $this->categoriaService->getAllCategorias();
        return response()->json(CategoriaResource::collection($categorias));
    }

    public function store(StoreCategoriaRequest $request): JsonResponse
    {
        $categoria = $this->categoriaService->createCategoria($request->validated());
        return response()->json(new CategoriaResource($categoria), 201);
    }

    public function show($id): JsonResponse
    {
        $categoria = $this->categoriaService->getCategoriaById($id);
        return response()->json(new CategoriaResource($categoria));
    }

    public function update(UpdateCategoriaRequest $request, $id): JsonResponse
    {
        $categoria = $this->categoriaService->updateCategoria($id, $request->validated());
        return response()->json(new CategoriaResource($categoria));
    }

    public function destroy($id): JsonResponse
    {
        $this->categoriaService->deleteCategoria($id);
        return response()->json(null, 204);
    }

    public function uploadImagen(\Illuminate\Http\Request $request, $id): JsonResponse
    {
        $request->validate([
            'imagen' => 'required|image|mimes:jpeg,png,jpg,webp|max:4096',
        ]);

        $categoria = $this->categoriaService->getCategoriaById($id);
        
        if ($request->hasFile('imagen')) {
            if ($categoria->imagen_path) {
                \Illuminate\Support\Facades\Storage::disk('public')->delete($categoria->imagen_path);
            }
            $path = $request->file('imagen')->store('categorias', 'public');
            $this->categoriaService->updateCategoria($id, ['imagen_path' => $path]);
            $categoria = $this->categoriaService->getCategoriaById($id);
        }

        return response()->json(new CategoriaResource($categoria));
    }

    public function importProductos(\Illuminate\Http\Request $request, $id): JsonResponse
    {
        $request->validate([
            'file' => 'required|mimes:xlsx,xls,csv|max:10240',
        ]);

        $categoria = $this->categoriaService->getCategoriaById($id);

        if (!$categoria) {
            return response()->json(['message' => 'Categoría no encontrada'], 404);
        }

        try {
            \Maatwebsite\Excel\Facades\Excel::import(
                new \App\Modules\Producto\Imports\ProductosCategoriaImport($id),
                $request->file('file')
            );

            return response()->json(['message' => 'Productos importados exitosamente']);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error("Error importando productos: " . $e->getMessage());
            return response()->json(['message' => 'Error al importar archivo', 'error' => $e->getMessage()], 500);
        }
    }
}

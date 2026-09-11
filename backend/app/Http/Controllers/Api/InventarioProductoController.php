<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\InventarioProducto;
use App\Services\PdfSecurityService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Intervention\Image\Facades\Image;

class InventarioProductoController extends Controller
{
    /**
     * Listar productos con paginación, búsqueda y filtros.
     * Todos los usuarios autenticados pueden ver el inventario.
     */
    public function index(Request $request)
    {
        $query = InventarioProducto::with('categoria');

        // Búsqueda por código o nombre
        if ($request->filled('search')) {
            $search = strtoupper(trim($request->input('search')));
            $query->where(function ($q) use ($search) {
                $q->where('codigo', 'LIKE', "%{$search}%")
                  ->orWhere('nombre', 'LIKE', "%{$search}%");
            });
        }

        // Filtro por categoría
        if ($request->filled('categoria_id')) {
            $query->where('categoria_id', $request->input('categoria_id'));
        }

        // Filtro de estado: disponible (stock > 0), agotado (stock = 0), negativo (stock < 0)
        if ($request->filled('estado_stock')) {
            match ($request->input('estado_stock')) {
                'disponible' => $query->where('stock', '>', 0),
                'agotado'    => $query->where('stock', '=', 0),
                'alerta'     => $query->whereColumn('stock', '<=', 'stock_minimo')->where('stock', '>', 0),
                'negativo'   => $query->where('stock', '<', 0),
                default      => null,
            };
        }

        // Filtro especial: solo negativos
        if ($request->boolean('solo_negativos')) {
            $query->where('stock', '<', 0);
        }

        // Solo activos por defecto
        if (!$request->boolean('incluir_inactivos')) {
            $query->where('activo', true);
        }

        // Ordenamiento
        $orderBy    = in_array($request->input('order_by'), ['nombre', 'codigo', 'stock', 'costo', 'venta', 'created_at'])
            ? $request->input('order_by')
            : 'nombre';
        $orderDir   = $request->input('order_dir', 'asc') === 'desc' ? 'desc' : 'asc';
        $query->orderBy($orderBy, $orderDir);

        // Paginación
        $perPage = (int) $request->input('per_page', 24);
        $perPage = min(max($perPage, 6), 100); // Entre 6 y 100

        $productos = $query->paginate($perPage);

        // Agregar URL de imagen y estado de stock a cada producto
        $productos->getCollection()->transform(function ($producto) {
            $producto->imagen_url = $producto->imagen_producto
                ? url("api/v1/file?path={$producto->imagen_producto}")
                : null;
            $producto->estado_stock = $producto->estado_stock; // accesor
            return $producto;
        });

        return response()->json($productos);
    }

    /**
     * Crear un nuevo producto (solo admin).
     */
    public function store(Request $request)
    {
        if (!$request->user()->hasRole('admin')) {
            return response()->json(['message' => 'No tienes permiso para crear productos.'], 403);
        }

        $validated = $request->validate([
            'codigo'       => 'required|string|max:60|unique:inventario_productos,codigo',
            'nombre'       => 'required|string|max:255',
            'unidad'       => 'required|in:UNIDAD,LIBRA,KG,OTRO',
            'costo'        => 'required|numeric|min:0',
            'venta'        => 'required|numeric|min:0',
            'stock'        => 'nullable|numeric',
            'stock_maximo' => 'nullable|numeric',
            'stock_minimo' => 'nullable|numeric',
            'categoria_id' => 'nullable|exists:inventario_categorias,id',
            'activo'       => 'boolean',
            // La imagen se sube por endpoint separado (POST /{id}/imagen)
        ]);

        $validated['stock'] = $validated['stock'] ?? 0;

        $producto = InventarioProducto::create($validated);

        return response()->json($producto->load('categoria'), 201);
    }

    /**
     * Ver detalle de un producto.
     */
    public function show(string $id)
    {
        $producto = InventarioProducto::with('categoria')->findOrFail($id);
        $producto->imagen_url = $producto->imagen_producto
            ? url("api/v1/file?path={$producto->imagen_producto}")
            : null;
        $producto->estado_stock = $producto->estado_stock;
        return response()->json($producto);
    }

    /**
     * Actualizar producto (solo admin).
     */
    public function update(Request $request, string $id)
    {
        if (!$request->user()->hasRole('admin')) {
            return response()->json(['message' => 'No tienes permiso para editar productos.'], 403);
        }

        $producto = InventarioProducto::findOrFail($id);

        $validated = $request->validate([
            'codigo'       => "required|string|max:60|unique:inventario_productos,codigo,{$id}",
            'nombre'       => 'required|string|max:255',
            'unidad'       => 'required|in:UNIDAD,LIBRA,KG,OTRO',
            'costo'        => 'required|numeric|min:0',
            'venta'        => 'required|numeric|min:0',
            'stock'        => 'nullable|numeric',
            'stock_maximo' => 'nullable|numeric',
            'stock_minimo' => 'nullable|numeric',
            'categoria_id' => 'nullable|exists:inventario_categorias,id',
            'activo'       => 'boolean',
        ]);

        $producto->update($validated);

        $producto->imagen_url = $producto->imagen_producto
            ? url("api/v1/file?path={$producto->imagen_producto}")
            : null;

        return response()->json($producto->load('categoria'));
    }

    /**
     * Subir o reemplazar imagen del producto.
     * Comprime a JPEG 80% calidad, máx 800x800px — óptimo para listas masivas.
     */
    public function uploadImagen(Request $request, string $id)
    {
        if (!$request->user()->hasRole('admin')) {
            return response()->json(['message' => 'No tienes permiso.'], 403);
        }

        $request->validate([
            // Máx 1.5MB en subida; el procesamiento la reducirá a ~100-300KB
            'imagen' => 'required|image|max:1536|mimes:jpeg,jpg,png,webp',
        ]);

        $producto = InventarioProducto::findOrFail($id);

        // Eliminar imagen anterior si existe
        if ($producto->imagen_producto && Storage::disk('public')->exists($producto->imagen_producto)) {
            Storage::disk('public')->delete($producto->imagen_producto);
        }

        // Comprimir y guardar como JPEG
        // Si Intervention Image no está disponible, guarda directamente
        $file     = $request->file('imagen');
        $filename = 'inventario-productos/' . $producto->codigo . '_' . time() . '.jpg';

        if (class_exists(\Intervention\Image\Facades\Image::class)) {
            $img = \Intervention\Image\Facades\Image::make($file)
                ->fit(800, 800, function ($constraint) {
                    $constraint->upsize();
                })
                ->encode('jpg', 80);
            Storage::disk('public')->put($filename, $img->__toString());
        } else {
            // Fallback: guardar sin comprimir si Intervention no está instalada
            $filename = $file->store('inventario-productos', 'public');
        }

        $producto->update(['imagen_producto' => $filename]);

        return response()->json([
            'imagen_producto' => $filename,
            'imagen_url'      => url("api/v1/file?path={$filename}"),
        ]);
    }

    /**
     * Eliminar imagen del producto (solo admin).
     */
    public function deleteImagen(Request $request, string $id)
    {
        if (!$request->user()->hasRole('admin')) {
            return response()->json(['message' => 'No tienes permiso.'], 403);
        }

        $producto = InventarioProducto::findOrFail($id);

        if ($producto->imagen_producto && Storage::disk('public')->exists($producto->imagen_producto)) {
            Storage::disk('public')->delete($producto->imagen_producto);
        }

        $producto->update(['imagen_producto' => null]);

        return response()->json(['message' => 'Imagen eliminada.']);
    }

    /**
     * Eliminar producto (solo admin).
     */
    public function destroy(Request $request, string $id)
    {
        if (!$request->user()->hasRole('admin')) {
            return response()->json(['message' => 'No tienes permiso para eliminar productos.'], 403);
        }

        $producto = InventarioProducto::findOrFail($id);

        // Limpiar imagen si existe
        if ($producto->imagen_producto && Storage::disk('public')->exists($producto->imagen_producto)) {
            Storage::disk('public')->delete($producto->imagen_producto);
        }

        $producto->delete();

        return response()->json(null, 204);
    }

    /**
     * Importación masiva desde Excel/CSV.
     * Columnas esperadas: codigo, nombre, unidad, costo, venta, stock, stock_maximo, stock_minimo, categoria
     */
    public function import(Request $request)
    {
        if (!$request->user()->hasRole('admin')) {
            return response()->json(['message' => 'No tienes permiso para importar productos.'], 403);
        }

        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls,csv',
        ]);

        try {
            $spreadsheet = \PhpOffice\PhpSpreadsheet\IOFactory::load($request->file('file')->getPathname());
            $rows        = $spreadsheet->getActiveSheet()->toArray();

            // La primera fila es encabezado
            array_shift($rows);

            $imported = 0;
            $errors   = [];

            foreach ($rows as $index => $row) {
                $rowNum  = $index + 2;
                $codigo  = isset($row[0]) ? strtoupper(trim((string) $row[0])) : null;
                $nombre  = isset($row[1]) ? strtoupper(trim((string) $row[1])) : null;
                $unidad  = isset($row[2]) ? strtoupper(trim((string) $row[2])) : 'UNIDAD';
                $costo   = isset($row[3]) && is_numeric($row[3]) ? (float) $row[3] : 0;
                $venta   = isset($row[4]) && is_numeric($row[4]) ? (float) $row[4] : 0;
                $stock   = isset($row[5]) && is_numeric($row[5]) ? (float) $row[5] : 0;
                $stockMax = isset($row[6]) && is_numeric($row[6]) ? (float) $row[6] : null;
                $stockMin = isset($row[7]) && is_numeric($row[7]) ? (float) $row[7] : null;
                $categoriaNombre = isset($row[8]) ? strtoupper(trim((string) $row[8])) : null;

                if (!$codigo || !$nombre) {
                    $errors[] = "Fila {$rowNum}: código o nombre vacío, omitida.";
                    continue;
                }

                if (!in_array($unidad, ['UNIDAD', 'LIBRA', 'KG', 'OTRO'])) {
                    $unidad = 'UNIDAD';
                }

                // Buscar o ignorar categoría
                $categoriaId = null;
                if ($categoriaNombre) {
                    $cat = \App\Models\InventarioCategoria::where('nombre', $categoriaNombre)->first();
                    $categoriaId = $cat?->id;
                }

                InventarioProducto::updateOrCreate(
                    ['codigo' => $codigo],
                    [
                        'nombre'       => $nombre,
                        'unidad'       => $unidad,
                        'costo'        => $costo,
                        'venta'        => $venta,
                        'stock'        => $stock,
                        'stock_maximo' => $stockMax,
                        'stock_minimo' => $stockMin,
                        'categoria_id' => $categoriaId,
                        'activo'       => true,
                    ]
                );
                $imported++;
            }

            return response()->json([
                'message' => "Importación completa. {$imported} productos procesados.",
                'errores' => $errors,
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Error al importar: ' . $e->getMessage()], 500);
        }
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

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pedido;
use App\Models\PedidoDetalle;
use App\Models\InventarioProducto;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class PedidoController extends Controller
{
    public function index(Request $request)
    {
        $query = Pedido::with([
            'cliente:id,nombre',
            'ruta:id,nombre',
            'vendedor:id,name',
            'facturador:id,name',
            'detalles.producto:id,codigo,nombre,imagen_producto,unidad'
        ]);

        if ($request->filled('cliente_id')) {
            $query->where('cliente_id', $request->input('cliente_id'));
        }
        if ($request->filled('ruta_id')) {
            $query->where('ruta_id', $request->input('ruta_id'));
        }
        if ($request->filled('estado')) {
            $query->where('estado', $request->input('estado'));
        }
        if ($request->filled('start_date')) {
            $query->whereDate('created_at', '>=', $request->input('start_date'));
        }
        if ($request->filled('end_date')) {
            $query->whereDate('created_at', '<=', $request->input('end_date'));
        }

        // Vendedor can only see their own orders unless they are admin
        if (!Auth::user()->hasRole('admin')) {
            $query->where('vendedor_id', Auth::id());
        }

        $query->orderBy('created_at', 'desc');

        $perPage = min(max((int) $request->input('per_page', 30), 5), 100);
        return response()->json($query->paginate($perPage));
    }

    public function store(Request $request)
    {
        $request->validate([
            'cliente_id' => 'required|exists:ledhouse_clientes,id',
            'ruta_id' => 'nullable|exists:rutas,id',
            'comentario' => 'nullable|string',
            'estado' => 'required|in:borrador,enviado',
            'detalles' => 'required|array|min:1',
            'detalles.*.producto_id' => 'required|exists:inventario_productos,id',
            'detalles.*.cantidad' => 'required|numeric|min:0.01',
            'detalles.*.precio_unitario' => 'required|numeric|min:0',
            'detalles.*.observacion' => 'nullable|string',
        ]);

        try {
            DB::beginTransaction();

            $total = 0;
            $detallesToInsert = [];

            foreach ($request->detalles as $detalle) {
                $producto = InventarioProducto::findOrFail($detalle['producto_id']);
                $precioEnviado = (float) $detalle['precio_unitario'];
                $precioBase = (float) $producto->venta;

                // Validate ±20% constraint
                if ($precioBase > 0) {
                    $minPrice = $precioBase * 0.8;
                    $maxPrice = $precioBase * 1.2;
                    
                    if ($precioEnviado < $minPrice || $precioEnviado > $maxPrice) {
                        return response()->json([
                            'message' => "El precio del producto {$producto->nombre} ({$precioEnviado}) excede el límite del 20% sobre el precio base ({$precioBase})."
                        ], 422);
                    }
                }

                $subtotal = $precioEnviado * $detalle['cantidad'];
                $total += $subtotal;

                $detallesToInsert[] = [
                    'producto_id' => $producto->id,
                    'cantidad' => $detalle['cantidad'],
                    'precio_unitario' => $precioEnviado,
                    'subtotal' => $subtotal,
                    'observacion' => $detalle['observacion'] ?? null,
                ];
            }

            $pedido = Pedido::create([
                'cliente_id' => $request->cliente_id,
                'ruta_id' => $request->ruta_id,
                'vendedor_id' => Auth::id(),
                'estado' => $request->estado,
                'comentario' => $request->comentario,
                'total' => $total,
            ]);

            foreach ($detallesToInsert as $det) {
                $det['pedido_id'] = $pedido->id;
                PedidoDetalle::create($det);
            }

            DB::commit();
            return response()->json($pedido->load('detalles'), 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Error al crear pedido', 'error' => $e->getMessage()], 500);
        }
    }

    public function update(Request $request, Pedido $pedido)
    {
        // Only draft orders can be completely updated by the vendor
        if ($pedido->estado !== 'borrador' && !Auth::user()->hasRole('admin')) {
            return response()->json(['message' => 'No puedes editar un pedido que ya no es borrador.'], 403);
        }

        $request->validate([
            'cliente_id' => 'required|exists:ledhouse_clientes,id',
            'ruta_id' => 'nullable|exists:rutas,id',
            'comentario' => 'nullable|string',
            'estado' => 'required|in:borrador,enviado',
            'detalles' => 'required|array|min:1',
            'detalles.*.producto_id' => 'required|exists:inventario_productos,id',
            'detalles.*.cantidad' => 'required|numeric|min:0.01',
            'detalles.*.precio_unitario' => 'required|numeric|min:0',
            'detalles.*.observacion' => 'nullable|string',
        ]);

        try {
            DB::beginTransaction();

            $total = 0;
            $pedido->detalles()->delete(); // Clear old ones to easily sync

            foreach ($request->detalles as $detalle) {
                $producto = InventarioProducto::findOrFail($detalle['producto_id']);
                $precioEnviado = (float) $detalle['precio_unitario'];
                $precioBase = (float) $producto->venta;

                if ($precioBase > 0) {
                    $minPrice = $precioBase * 0.8;
                    $maxPrice = $precioBase * 1.2;
                    if ($precioEnviado < $minPrice || $precioEnviado > $maxPrice) {
                        return response()->json([
                            'message' => "El precio del producto {$producto->nombre} ({$precioEnviado}) excede el límite del 20% sobre el precio base ({$precioBase})."
                        ], 422);
                    }
                }

                $subtotal = $precioEnviado * $detalle['cantidad'];
                $total += $subtotal;

                PedidoDetalle::create([
                    'pedido_id' => $pedido->id,
                    'producto_id' => $producto->id,
                    'cantidad' => $detalle['cantidad'],
                    'precio_unitario' => $precioEnviado,
                    'subtotal' => $subtotal,
                    'observacion' => $detalle['observacion'] ?? null,
                ]);
            }

            $pedido->update([
                'cliente_id' => $request->cliente_id,
                'ruta_id' => $request->ruta_id,
                'estado' => $request->estado,
                'comentario' => $request->comentario,
                'total' => $total,
            ]);

            DB::commit();
            return response()->json($pedido->load('detalles'));
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Error al actualizar pedido', 'error' => $e->getMessage()], 500);
        }
    }

    public function changeStatus(Request $request, Pedido $pedido)
    {
        $request->validate([
            'estado' => 'required|in:borrador,enviado,facturado,cancelado'
        ]);

        $nuevoEstado = $request->estado;
        
        // Vendedores can only change from borrador to enviado
        if (!Auth::user()->hasRole('admin')) {
            if ($nuevoEstado === 'facturado' || $nuevoEstado === 'cancelado') {
                return response()->json(['message' => 'No autorizado para facturar o cancelar.'], 403);
            }
        }

        if ($nuevoEstado === 'facturado' || $nuevoEstado === 'cancelado') {
            $pedido->facturador_id = Auth::id();
        }

        $pedido->estado = $nuevoEstado;
        $pedido->save();

        return response()->json($pedido);
    }
}

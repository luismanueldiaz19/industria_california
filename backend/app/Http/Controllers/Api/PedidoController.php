<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pedido;
use App\Models\PedidoDetalle;
use App\Models\InventarioProducto;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use App\Services\PdfSecurityService;

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
        } else {
            // If admin and they provided a vendedor_id filter, apply it
            if ($request->filled('vendedor_id')) {
                $query->where('vendedor_id', $request->input('vendedor_id'));
            }
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
            'latitud' => 'nullable|numeric',
            'longitud' => 'nullable|numeric',
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
                'latitud' => $request->latitud,
                'longitud' => $request->longitud,
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
            'latitud' => 'nullable|numeric',
            'longitud' => 'nullable|numeric',
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
                'latitud' => $request->latitud,
                'longitud' => $request->longitud,
            ]);

            DB::commit();
            return response()->json($pedido->load('detalles'));
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Error al actualizar pedido', 'error' => $e->getMessage()], 500);
        }
    }

    public function destroy(Pedido $pedido)
    {
        if (!Auth::user()->hasRole('admin')) {
            return response()->json(['message' => 'No autorizado para eliminar pedidos.'], 403);
        }

        $pedido->delete();
        return response()->json(['message' => 'Pedido eliminado correctamente.']);
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
    public function getGeneralPdfUrl(Request $request)
    {
        $params = $request->only(['cliente_id', 'ruta_id', 'estado', 'start_date', 'end_date']);
        if (!Auth::user()->hasRole('admin')) {
            $params['vendedor_id'] = Auth::id();
        }
        $url = PdfSecurityService::generarUrl('pedidos_general', $params, Auth::id(), 30);
        return response()->json(['url' => $url]);
    }

    public function getPdfUrl($id)
    {
        $pedido = Pedido::findOrFail($id);
        if (!Auth::user()->hasRole('admin') && $pedido->vendedor_id !== Auth::id()) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $url = PdfSecurityService::generarUrl('pedido', ['id' => $id], Auth::id(), 30);
        
        return response()->json(['url' => $url]);
    }

    public function generatePdf($id)
    {
        $pedido = Pedido::with([
            'cliente:id,nombre,direccion,telefono,rnc', 
            'ruta:id,nombre', 
            'vendedor:id,name', 
            'detalles.producto:id,codigo,nombre,unidad'
        ])->findOrFail($id);

        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('pdf.pedido_factura', compact('pedido'));
        return $pdf->stream("pedido_{$pedido->id}.pdf");
    }

    public function assignRuta(Request $request)
    {
        if (!Auth::user()->hasRole('admin')) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $request->validate([
            'pedido_ids' => 'required|array|min:1',
            'pedido_ids.*' => 'exists:pedidos,id',
            'ruta_id' => 'required|exists:rutas,id',
        ]);

        Pedido::whereIn('id', $request->pedido_ids)->update(['ruta_id' => $request->ruta_id]);

        return response()->json(['message' => 'Pedidos asignados a la ruta correctamente.']);
    }

    public function optimizeDayRoute(Request $request)
    {
        $request->validate([
            'ruta_id' => 'required|exists:rutas,id',
            'date' => 'nullable|date',
            'origin_lat' => 'required|numeric',
            'origin_lng' => 'required|numeric'
        ]);

        $date = $request->input('date', date('Y-m-d'));
        
        $pedidos = Pedido::with(['cliente:id,nombre,direccion,latitud,longitud', 'ruta:id,nombre'])
            ->where('ruta_id', $request->ruta_id)
            ->whereDate('created_at', $date)
            ->get();
            
        if ($pedidos->isEmpty()) {
            return response()->json([]);
        }

        // Greedy TSP using Haversine
        $origin = ['lat' => (float) $request->origin_lat, 'lng' => (float) $request->origin_lng];
        $unvisited = $pedidos->toArray();
        $ordered = [];

        $currentPos = $origin;

        while(count($unvisited) > 0) {
            $nearestIndex = -1;
            $minDist = PHP_FLOAT_MAX;

            foreach($unvisited as $index => $pedido) {
                // Fallback to client location if pedido location is missing
                $lat = $pedido['latitud'] ?? $pedido['cliente']['latitud'] ?? null;
                $lng = $pedido['longitud'] ?? $pedido['cliente']['longitud'] ?? null;

                if ($lat === null || $lng === null) {
                    $dist = PHP_FLOAT_MAX - 1; // Send to end of route
                } else {
                    $dist = $this->haversineGreatCircleDistance(
                        $currentPos['lat'], $currentPos['lng'], 
                        (float)$lat, (float)$lng
                    );
                }

                if ($dist < $minDist) {
                    $minDist = $dist;
                    $nearestIndex = $index;
                }
            }

            $nearest = $unvisited[$nearestIndex];
            $ordered[] = $nearest;
            
            $nearestLat = $nearest['latitud'] ?? $nearest['cliente']['latitud'] ?? null;
            $nearestLng = $nearest['longitud'] ?? $nearest['cliente']['longitud'] ?? null;
            if ($nearestLat !== null && $nearestLng !== null) {
                $currentPos = ['lat' => (float)$nearestLat, 'lng' => (float)$nearestLng];
            }
            
            unset($unvisited[$nearestIndex]);
            $unvisited = array_values($unvisited);
        }

        return response()->json($ordered);
    }

    private function haversineGreatCircleDistance($latitudeFrom, $longitudeFrom, $latitudeTo, $longitudeTo, $earthRadius = 6371000)
    {
        $latFrom = deg2rad($latitudeFrom);
        $lonFrom = deg2rad($longitudeFrom);
        $latTo = deg2rad($latitudeTo);
        $lonTo = deg2rad($longitudeTo);

        $latDelta = $latTo - $latFrom;
        $lonDelta = $lonTo - $lonFrom;

        $angle = 2 * asin(sqrt(pow(sin($latDelta / 2), 2) +
            cos($latFrom) * cos($latTo) * pow(sin($lonDelta / 2), 2)));
        
        return $angle * $earthRadius;
    }
}

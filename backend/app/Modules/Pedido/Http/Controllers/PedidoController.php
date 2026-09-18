<?php

namespace App\Modules\Pedido\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Pedido\Models\Pedido;
use App\Modules\Pedido\Http\Requests\StorePedidoRequest;
use App\Modules\Pedido\Services\PedidoService;
use App\Services\PdfSecurityService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class PedidoController extends Controller
{
    public function __construct(
        private readonly PedidoService $pedidoService
    ) {}

    public function index(Request $request)
    {
        $query = Pedido::with([
            'cliente:id,nombre',
            'ruta:id,nombre',
            'vendedor:id,name',
            'facturador:id,name',
            'detalles.producto:id,codigo,descripcion,imagen_producto,unidad,medidas,capacidad'
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
        if ($request->filled('start_date') || $request->filled('end_date')) {
            if ($request->filled('start_date')) {
                $query->whereDate('created_at', '>=', $request->input('start_date'));
            }
            if ($request->filled('end_date')) {
                $query->whereDate('created_at', '<=', $request->input('end_date'));
            }
        } else {
            $query->where(function ($q) {
                $q->whereDate('created_at', now()->toDateString())
                  ->orWhereIn('estado', ['borrador', 'enviado']);
            });
        }

        if ($request->input('has_faltantes') == '1' || $request->input('has_faltantes') == 'true') {
            $query->whereHas('detalles', function ($q) {
                $q->where('cantidad_en_produccion', '>', 0);
            });
        }

        if (!Auth::user()->hasRole('admin')) {
            $query->where('vendedor_id', Auth::id());
        } else {
            if ($request->filled('vendedor_id')) {
                $query->where('vendedor_id', $request->input('vendedor_id'));
            }
        }

        $query->orderBy('created_at', 'desc');

        $perPage = min(max((int) $request->input('per_page', 30), 5), 100);
        return response()->json($query->paginate($perPage));
    }

    public function store(StorePedidoRequest $request)
    {
        $vendedor = Auth::user();
        $datos = $request->validated();
        $pedido = $this->pedidoService->crear($datos, $vendedor);

        return response()->json($pedido->load('detalles'), 201);
    }

    public function update(StorePedidoRequest $request, Pedido $pedido)
    {
        if ($pedido->estado->value !== 'borrador' && !Auth::user()->hasRole('admin')) {
            return response()->json(['message' => 'No puedes editar un pedido que ya no es borrador.'], 403);
        }

        $datos = $request->validated();
        $pedidoActualizado = $this->pedidoService->actualizar($pedido, $datos);

        return response()->json($pedidoActualizado);
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
        
        if (!Auth::user()->hasRole('admin')) {
            if ($nuevoEstado === 'facturado' || $nuevoEstado === 'cancelado') {
                return response()->json(['message' => 'No autorizado para facturar o cancelar.'], 403);
            }
        }

        $pedido = $this->pedidoService->cambiarEstado($pedido, $nuevoEstado, Auth::user());

        return response()->json($pedido);
    }

    public function getGeneralPdfUrl(Request $request)
    {
        $params = $request->only(['cliente_id', 'ruta_id', 'vendedor_id', 'estado', 'start_date', 'end_date']);
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
            'detalles.producto:id,codigo,descripcion,unidad,medidas,capacidad'
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

        $origin = ['lat' => (float) $request->origin_lat, 'lng' => (float) $request->origin_lng];
        $unvisited = $pedidos->toArray();
        $ordered = [];

        $currentPos = $origin;

        while(count($unvisited) > 0) {
            $nearestIndex = -1;
            $minDist = PHP_FLOAT_MAX;

            foreach($unvisited as $index => $pedido) {
                $lat = $pedido['latitud'] ?? $pedido['cliente']['latitud'] ?? null;
                $lng = $pedido['longitud'] ?? $pedido['cliente']['longitud'] ?? null;

                if ($lat === null || $lng === null) {
                    $dist = PHP_FLOAT_MAX - 1;
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

    public function reporteVendedores(Request $request)
    {
        $startDate = $request->input('start_date');
        $endDate   = $request->input('end_date');
        $search    = $request->input('search');
        $mesFmt    = $this->_mesFmtExpr('pedidos.created_at');

        $scope = Pedido::query()
            ->with('vendedor:id,name')
            ->when($startDate, fn($q) => $q->whereDate('pedidos.created_at', '>=', $startDate))
            ->when($endDate,   fn($q) => $q->whereDate('pedidos.created_at', '<=', $endDate))
            ->when($search, fn($q) =>
                $q->whereHas('vendedor', fn($vq) =>
                    $vq->whereRaw('LOWER(name) LIKE ?', ['%' . mb_strtolower($search) . '%'])
                )
            )
            ->when(!Auth::user()->hasRole('admin'), fn($q) =>
                $q->where('vendedor_id', Auth::id())
            );

        $perPage = min(max((int) $request->input('per_page', 10), 3), 50);

        $paginated = (clone $scope)
            ->select(
                'vendedor_id',
                DB::raw('COUNT(id) as total_pedidos'),
                DB::raw('SUM(total) as total_monto'),
                DB::raw("SUM(CASE WHEN estado = 'borrador'  THEN 1 ELSE 0 END) as borrador"),
                DB::raw("SUM(CASE WHEN estado = 'enviado'   THEN 1 ELSE 0 END) as enviado"),
                DB::raw("SUM(CASE WHEN estado = 'facturado' THEN 1 ELSE 0 END) as facturado"),
                DB::raw("SUM(CASE WHEN estado = 'cancelado' THEN 1 ELSE 0 END) as cancelado")
            )
            ->groupBy('vendedor_id')
            ->orderByDesc('total_monto')
            ->with('vendedor:id,name')
            ->paginate($perPage);

        $paginated->getCollection()->transform(function ($item) use ($scope) {
            $item->vendedor_nombre = $item->vendedor?->name ?? 'Sin asignar';
            
            $faltante = (clone $scope)
                ->where('pedidos.vendedor_id', $item->vendedor_id)
                ->join('pedido_detalles', 'pedidos.id', '=', 'pedido_detalles.pedido_id')
                ->sum(\DB::raw('pedido_detalles.cantidad_en_produccion * pedido_detalles.precio_unitario'));

            $item->total_faltante = (float)$faltante;
            $item->total_real = $item->total_monto - (float)$faltante;

            unset($item->vendedor);
            return $item;
        });

        $graficoMeses = (clone $scope)
            ->selectRaw("{$mesFmt} as mes, COUNT(id) as total_pedidos, SUM(total) as total_monto")
            ->groupBy('mes')
            ->orderBy('mes')
            ->get()
            ->map(fn($row) => [
                'mes'           => $row->mes,
                'mes_label'     => \Carbon\Carbon::parse($row->mes . '-01')->translatedFormat('M Y'),
                'total_pedidos' => (int)   $row->total_pedidos,
                'total_monto'   => (float) $row->total_monto,
            ]);

        $graficoVendedoresMeses = Pedido::query()
            ->join('users as v', 'pedidos.vendedor_id', '=', 'v.id')
            ->when($startDate, fn($q) => $q->whereDate('pedidos.created_at', '>=', $startDate))
            ->when($endDate,   fn($q) => $q->whereDate('pedidos.created_at', '<=', $endDate))
            ->when($search, fn($q) =>
                $q->whereRaw('LOWER(v.name) LIKE ?', ['%' . mb_strtolower($search) . '%'])
            )
            ->when(!Auth::user()->hasRole('admin'), fn($q) =>
                $q->where('pedidos.vendedor_id', Auth::id())
            )
            ->selectRaw("v.name as vendedor_nombre, {$mesFmt} as mes, COUNT(pedidos.id) as total_pedidos, SUM(pedidos.total) as total_monto")
            ->groupBy('v.name', 'mes')
            ->orderBy('mes')
            ->get();

        $resumen = (clone $scope)
            ->selectRaw('COUNT(id) as total_pedidos, SUM(total) as total_monto, COUNT(DISTINCT vendedor_id) as total_vendedores')
            ->first();

        $totalFaltanteGeneral = (clone $scope)
            ->join('pedido_detalles', 'pedidos.id', '=', 'pedido_detalles.pedido_id')
            ->sum(\DB::raw('pedido_detalles.cantidad_en_produccion * pedido_detalles.precio_unitario'));

        return response()->json([
            'vendedores'               => $paginated,
            'grafico_meses'            => $graficoMeses,
            'grafico_vendedores_meses' => $graficoVendedoresMeses,
            'resumen' => [
                'total_pedidos'    => (int)   ($resumen->total_pedidos    ?? 0),
                'total_monto'      => (float) ($resumen->total_monto      ?? 0),
                'total_faltante'   => (float) $totalFaltanteGeneral,
                'total_real'       => (float) (($resumen->total_monto ?? 0) - $totalFaltanteGeneral),
                'total_vendedores' => (int)   ($resumen->total_vendedores ?? 0),
            ],
        ]);
    }

    public function getReporteVendedoresPdfUrl(Request $request)
    {
        $params = $request->only(['start_date', 'end_date', 'search']);
        if (!Auth::user()->hasRole('admin')) {
            $params['vendedor_id'] = Auth::id();
        }
        $url = PdfSecurityService::generarUrl('pedidos_vendedores', $params, Auth::id(), 30);
        return response()->json(['url' => $url]);
    }

    private function _mesFmtExpr(string $columna): string
    {
        return match (DB::getDriverName()) {
            'sqlite' => "strftime('%Y-%m', {$columna})",
            'pgsql'  => "TO_CHAR({$columna}, 'YYYY-MM')",
            default  => "DATE_FORMAT({$columna}, '%Y-%m')",
        };
    }
}
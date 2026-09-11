<?php

namespace App\Services;

use App\Models\PdfToken;
use App\Models\LedhouseCxc;
use App\Models\LedhouseCliente;
use App\Models\LedhouseCxcAlerta;
use App\Models\LedhouseEstadoResultado;
use App\Models\InventarioProducto;
use App\Models\InventarioMovimiento;
use App\Models\User;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;

class PdfSecurityService
{
    /**
     * Genera un token aleatorio y retorna la URL pública /d/{token}
     */
    public static function generarUrl(string $tipo, array $parametros = [], ?int $userId = null, int $minutos = 30): string
    {
        $token = Str::random(40);

        PdfToken::create([
            'token'      => $token,
            'tipo'       => $tipo,
            'parametros' => $parametros,
            'user_id'    => $userId,
            'expires_at' => now()->addMinutes($minutos),
        ]);

        return url("/api/d/{$token}");
    }

    /**
     * Resuelve el token, valida su expiración y genera la respuesta PDF en streaming.
     */
    public static function renderizarPdf(string $token): Response
    {
        $pdfToken = PdfToken::where('token', $token)->first();

        if (!$pdfToken || !$pdfToken->isValid()) {
            abort(404, 'El enlace del documento no es válido o ha expirado.');
        }

        $params = $pdfToken->parametros ?? [];

        switch ($pdfToken->tipo) {
            case 'cxc_general':
                $cxcs = LedhouseCxc::with('cliente')->orderBy('fecha_vencimiento', 'asc')->get();
                $pdf  = Pdf::loadView('pdf.cxc_general', ['cxcs' => $cxcs]);
                $filename = 'Reporte_General_CXC.pdf';
                break;

            case 'cxc_agrupado':
                $clientes = LedhouseCliente::withSum('cxcs as total_facturado', 'monto_factura')
                    ->withSum('cxcs as total_pendiente', 'monto_pendiente')
                    ->get()
                    ->filter(fn($c) => $c->total_pendiente > 0);
                $pdf = Pdf::loadView('pdf.cxc_agrupado', ['clientes' => $clientes]);
                $filename = 'Reporte_Agrupado_CXC.pdf';
                break;

            case 'cxc_vendedor':
                $vendedorId = $params['vendedor_id'] ?? null;
                $user = $vendedorId ? User::find($vendedorId) : null;
                $query = LedhouseCxc::with(['cliente']);
                if ($user) {
                    $query->where('vendedor_id', $user->id);
                }
                if (!empty($params['search'])) {
                    $search = $params['search'];
                    $query->where(function($q) use ($search) {
                        $q->where('documento', 'like', "%{$search}%")
                          ->orWhereHas('cliente', fn($q2) => $q2->where('nombre', 'like', "%{$search}%"));
                    });
                }
                $isVencidos = !empty($params['vencidos']) && $params['vencidos'] == '1';
                if ($isVencidos) {
                    $query->where('monto_pendiente', '>', 0)
                          ->where('estado', '!=', 'pagado')
                          ->whereDate('fecha_vencimiento', '<', now()->format('Y-m-d'));
                }
                $cxcs = $query->orderBy('fecha_vencimiento', 'asc')->get();
                $pdf = Pdf::loadView('pdf.cxc_vendedor', [
                    'cxcs' => $cxcs,
                    'vendedor' => $user,
                    'isVencidos' => $isVencidos,
                    'search' => $params['search'] ?? null,
                ]);
                $filename = 'Reporte_Mis_CXC.pdf';
                break;

            case 'cxc_cliente':
                $clienteId = $params['cliente_id'] ?? null;
                $cliente = LedhouseCliente::findOrFail($clienteId);
                $cxcs = LedhouseCxc::where('cliente_id', $clienteId)->get();
                $pdf = Pdf::loadView('pdf.example_temp_url', [
                    'cliente'  => $cliente,
                    'cxcs'     => $cxcs,
                    'imageUrl' => null,
                ]);
                $filename = "Reporte_CXC_{$cliente->nombre}.pdf";
                break;

            case 'cxc_alertas':
                $estado = $params['estado'] ?? 'todas';
                $query = LedhouseCxcAlerta::with(['cxc.cliente', 'vendedor']);
                if ($estado !== 'todas') {
                    $query->where('estado_alerta', $estado);
                }
                if (!empty($params['vendedor_id'])) {
                    $query->where('vendedor_id', $params['vendedor_id']);
                }
                $alertas = $query->orderBy('created_at', 'desc')->get();
                $totalInformado = $alertas->where('estado_alerta', 'pendiente')->sum('monto_informado');
                $cxcQuery = LedhouseCxc::where('monto_pendiente', '>', 0);
                if (!empty($params['vendedor_id'])) {
                    $cxcQuery->where('vendedor_id', $params['vendedor_id']);
                }
                $totalPendiente = $cxcQuery->sum('monto_pendiente');
                $montoReal = $totalPendiente - $totalInformado;

                $pdf = Pdf::loadView('pdf.alertas_vendedores', [
                    'alertas'        => $alertas,
                    'totalInformado' => $totalInformado,
                    'totalPendiente' => $totalPendiente,
                    'montoReal'      => $montoReal,
                    'estado'         => $estado,
                ])->setPaper('a4', 'landscape');
                $filename = 'Reporte_Alertas_' . date('Ymd_His') . '.pdf';
                break;

            case 'matriz':
                $year = $params['year'] ?? date('Y');
                $mesesFiltrados = !empty($params['meses']) ? explode(',', $params['meses']) : [];
                $controller = app(\App\Http\Controllers\Api\LedhouseEstadoResultadoController::class);
                $fakeReq = new \Illuminate\Http\Request(['year' => $year, 'meses' => $params['meses'] ?? null]);
                $matrizResponse = $controller->matriz($fakeReq);
                $data = $matrizResponse->getData(true);
                $resultado = $data['matriz'] ?? [];
                $maximos = $data['maximos'] ?? [];
                $mesesVisibles = 12;
                if (!empty($mesesFiltrados)) {
                    $mesesVisibles = max($mesesFiltrados);
                } else {
                    $maxMonth = 1;
                    foreach ($resultado as $seccion) {
                        foreach ($seccion['cuentas'] as $cuenta) {
                            foreach ($cuenta['meses'] as $m => $monto) {
                                if ($monto != 0 && $m > $maxMonth) {
                                    $maxMonth = $m;
                                }
                            }
                        }
                    }
                    $mesesVisibles = $maxMonth;
                }
                $pdf = Pdf::loadView('reports.ledhouse_matriz', [
                    'matriz'         => $resultado,
                    'maximos'        => $maximos,
                    'year'           => $year,
                    'mesesVisibles'  => $mesesVisibles,
                    'mesesFiltrados' => $mesesFiltrados
                ])->setPaper('a4', 'landscape');
                $filename = "Matriz_Cuentas_{$year}.pdf";
                break;

            case 'estado_resultado':
                $query = LedhouseEstadoResultado::join('cuenta_catalogo_ledhouse', 'ledhouse_estado_resultado.codigo_cuenta', '=', 'cuenta_catalogo_ledhouse.codigo')
                    ->select('ledhouse_estado_resultado.*', 'cuenta_catalogo_ledhouse.origen as modulo', 'cuenta_catalogo_ledhouse.descripcion as descripcion_de_cuenta');
                if (!empty($params['start_date']) && !empty($params['end_date'])) {
                    $query->whereBetween('ledhouse_estado_resultado.fecha', [$params['start_date'], $params['end_date']]);
                } elseif (!empty($params['start_date'])) {
                    $query->where('ledhouse_estado_resultado.fecha', '>=', $params['start_date']);
                } elseif (!empty($params['end_date'])) {
                    $query->where('ledhouse_estado_resultado.fecha', '<=', $params['end_date']);
                }
                if (!empty($params['modulo']) && $params['modulo'] !== 'TODOS') {
                    $query->where('cuenta_catalogo_ledhouse.origen', $params['modulo']);
                }
                if (!empty($params['codigo_cuenta'])) {
                    $query->where('ledhouse_estado_resultado.codigo_cuenta', 'like', '%' . $params['codigo_cuenta'] . '%');
                }
                if (!empty($params['ids'])) {
                    $ids = array_filter(explode(',', $params['ids']), 'is_numeric');
                    if (count($ids) > 0) {
                        $query->whereIn('ledhouse_estado_resultado.id', $ids);
                    }
                }
                $query->orderByRaw("CASE WHEN UPPER(cuenta_catalogo_ledhouse.origen) = 'VENTAS' THEN 1 WHEN UPPER(cuenta_catalogo_ledhouse.origen) = 'COSTOS' THEN 2 WHEN UPPER(cuenta_catalogo_ledhouse.origen) = 'GASTOS' THEN 3 ELSE 4 END")
                      ->orderBy('ledhouse_estado_resultado.fecha', 'desc');

                $registros = $query->get();
                $ventas = $registros->where('modulo', 'VENTAS')->sum('monto');
                $costos = $registros->where('modulo', 'COSTOS')->sum('monto');
                $gastos = $registros->where('modulo', 'GASTOS')->sum('monto');
                $utilidad = $ventas - $costos - $gastos;
                $fakeReq = new \Illuminate\Http\Request($params);

                $pdf = Pdf::loadView('reports.ledhouse_estado_resultado', [
                    'registros' => $registros,
                    'ventas'    => $ventas,
                    'costos'    => $costos,
                    'gastos'    => $gastos,
                    'utilidad'  => $utilidad,
                    'request'   => $fakeReq,
                ]);
                $filename = 'Estado_Resultado.pdf';
                break;

            case 'inventario_productos':
                $query = InventarioProducto::with('categoria')->where('activo', true);
                if (!empty($params['search'])) {
                    $s = strtoupper($params['search']);
                    $query->where(fn($q) => $q->where('codigo', 'LIKE', "%{$s}%")->orWhere('nombre', 'LIKE', "%{$s}%"));
                }
                if (!empty($params['categoria_id'])) {
                    $query->where('categoria_id', $params['categoria_id']);
                }
                if (!empty($params['estado_stock'])) {
                    match($params['estado_stock']) {
                        'disponible' => $query->where('stock', '>', 0),
                        'agotado'    => $query->where('stock', '=', 0),
                        'negativo'   => $query->where('stock', '<', 0),
                        'alerta'     => $query->whereColumn('stock', '<=', 'stock_minimo')->where('stock', '>', 0),
                        default      => null,
                    };
                }
                if (!empty($params['solo_negativos'])) {
                    $query->where('stock', '<', 0);
                }
                $orderBy  = in_array($params['order_by'] ?? '', ['nombre','codigo','stock','costo','venta']) ? $params['order_by'] : 'nombre';
                $orderDir = ($params['order_dir'] ?? 'asc') === 'desc' ? 'desc' : 'asc';
                $productos = $query->orderBy($orderBy, $orderDir)->get();
                $pdf = Pdf::loadView('pdf.inventario_productos', ['productos' => $productos]);
                $filename = 'Inventario_Productos_' . date('Ymd') . '.pdf';
                break;

            case 'inventario_movimientos':
                $query = InventarioMovimiento::with(['producto:id,codigo,nombre,unidad', 'user:id,name,username']);
                if (!empty($params['producto_id'])) {
                    $query->where('producto_id', $params['producto_id']);
                }
                if (!empty($params['tipo'])) {
                    $query->where('tipo', strtoupper($params['tipo']));
                }
                if (!empty($params['start_date'])) {
                    $query->whereDate('created_at', '>=', $params['start_date']);
                }
                if (!empty($params['end_date'])) {
                    $query->whereDate('created_at', '<=', $params['end_date']);
                }
                if (!empty($params['user_id'])) {
                    $query->where('user_id', $params['user_id']);
                }
                $resumenQuery = clone $query;
                $resumen = $resumenQuery->select('tipo', \Illuminate\Support\Facades\DB::raw('SUM(cantidad) as total_cantidad'))
                    ->groupBy('tipo')
                    ->pluck('total_cantidad', 'tipo');

                $movimientos = $query->orderBy('created_at', 'desc')->get();
                $pdf = Pdf::loadView('pdf.inventario_movimientos', [
                    'movimientos' => $movimientos,
                    'resumen' => $resumen
                ])->setPaper('a4', 'landscape');
                $filename = 'Movimientos_Inventario_' . date('Ymd') . '.pdf';
                break;

            default:
                abort(404, 'Tipo de documento no soportado.');
        }

        $headers = [
            'Content-Type'           => 'application/pdf',
            'Content-Disposition'    => 'inline; filename="' . $filename . '"',
            'Cache-Control'          => 'private, no-cache, no-store, must-revalidate',
            'Pragma'                 => 'no-cache',
            'Expires'                => '0',
            'X-Content-Type-Options' => 'nosniff',
        ];

        return response($pdf->output(), 200, $headers);
    }
}

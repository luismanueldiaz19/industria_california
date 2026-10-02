<?php

namespace App\Services;

use App\Models\PdfToken;
use App\Models\LedhouseCxc;
use App\Models\LedhouseCliente;
use App\Models\LedhouseCxcAlerta;
use App\Models\LedhouseEstadoResultado;
use App\Modules\Producto\Models\Producto as ModuleProducto;
use App\Models\InventarioProducto;
use App\Models\InventarioMovimiento;
use App\Models\Pedido;
use App\Models\User;
use App\Modules\Vehiculo\Models\VehiculoMantenimiento;
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

        return route('pdf.view', $token);
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
                $query = LedhouseCxc::with('cliente');
                if (!empty($params['search'])) {
                    $rawSearch = trim($params['search']);
                    $search = \App\Helpers\TextNormalizer::normalize($rawSearch);
                    $query->where(function($q) use ($search) {
                        $q->whereRaw('LOWER(documento) LIKE ?', ["%{$search}%"])
                          ->orWhereHas('cliente', function($q2) use ($search) {
                              $q2->whereRaw('LOWER(nombre) LIKE ?', ["%{$search}%"])
                                 ->orWhereRaw('LOWER(documento) LIKE ?', ["%{$search}%"]);
                          });
                    });
                }

                $isVencidos = !empty($params['vencidos']) && $params['vencidos'] == '1';
                if ($isVencidos) {
                    $query->where('monto_pendiente', '>', 0)
                          ->where('estado', '!=', 'pagado')
                          ->whereDate('fecha_vencimiento', '<', now()->format('Y-m-d'));
                }

                if (!empty($params['estado']) && $params['estado'] !== 'Todos' && $params['estado'] !== 'Todos los Estados') {
                    $query->where('estado', $params['estado']);
                } else {
                    $query->where('estado', '!=', 'pagado');
                }

                if (!empty($params['vendedor_id'])) {
                    $query->where('vendedor_id', $params['vendedor_id']);
                }

                if (!empty($params['con_visita']) && $params['con_visita'] == '1') {
                    $query->whereHas('soportes', function ($q) {
                        $q->whereNotNull('fecha_visita');
                    });
                }

                if (!empty($params['start_date']) && !empty($params['end_date'])) {
                    $query->whereBetween('fecha_factura', [$params['start_date'], $params['end_date']]);
                }

                $cxcs = $query->orderBy('fecha_vencimiento', 'asc')->get();
                $vendedorNombre = null;
                if (!empty($params['vendedor_id'])) {
                    $vendedor = User::find($params['vendedor_id']);
                    if ($vendedor) {
                        $vendedorNombre = $vendedor->name;
                    }
                }
                $pdf  = Pdf::loadView('pdf.cxc_general', [
                    'cxcs' => $cxcs,
                    'search' => $params['search'] ?? null,
                    'isVencidos' => $isVencidos,
                    'estado' => $params['estado'] ?? null,
                    'vendedorNombre' => $vendedorNombre,
                ]);
                $filename = 'Reporte_General_CXC.pdf';
                break;

            case 'cxc_agrupado':
                $queryCxc = function ($q) use ($params) {
                    if (!empty($params['estado']) && $params['estado'] !== 'Todos' && $params['estado'] !== 'Todos los Estados') {
                        $q->where('estado', $params['estado']);
                    } else {
                        $q->where('estado', '!=', 'pagado');
                    }
                    if (!empty($params['vendedor_id'])) {
                        $q->where('vendedor_id', $params['vendedor_id']);
                    }
                    if (!empty($params['vencidos']) && $params['vencidos'] == '1') {
                        $q->where('monto_pendiente', '>', 0)
                          ->whereDate('fecha_vencimiento', '<', now()->format('Y-m-d'));
                    }
                    if (!empty($params['con_visita']) && $params['con_visita'] == '1') {
                        $q->whereHas('soportes', function ($q2) {
                            $q2->whereNotNull('fecha_visita');
                        });
                    }
                    if (!empty($params['start_date']) && !empty($params['end_date'])) {
                        $q->whereBetween('fecha_factura', [$params['start_date'], $params['end_date']]);
                    }
                    if (!empty($params['search'])) {
                        $rawSearch = trim($params['search']);
                        $search = \App\Helpers\TextNormalizer::normalize($rawSearch);
                        $q->where(function($q2) use ($search) {
                            $q2->whereRaw('LOWER(documento) LIKE ?', ["%{$search}%"])
                               ->orWhereHas('cliente', function($q3) use ($search) {
                                   $q3->whereRaw('LOWER(nombre) LIKE ?', ["%{$search}%"])
                                      ->orWhereRaw('LOWER(documento) LIKE ?', ["%{$search}%"]);
                               });
                        });
                    }
                };

                $clientes = LedhouseCliente::whereHas('cxcs', $queryCxc)
                    ->withSum(['cxcs as total_facturado' => $queryCxc], 'monto_factura')
                    ->withSum(['cxcs as total_pendiente' => $queryCxc], 'monto_pendiente')
                    ->get()
                    ->filter(fn($c) => $c->total_pendiente > 0);
                
                $vendedorNombre = null;
                if (!empty($params['vendedor_id'])) {
                    $vendedor = User::find($params['vendedor_id']);
                    if ($vendedor) {
                        $vendedorNombre = $vendedor->name;
                    }
                }
                
                $pdf = Pdf::loadView('pdf.cxc_agrupado', [
                    'clientes' => $clientes,
                    'search' => $params['search'] ?? null,
                    'vendedorNombre' => $vendedorNombre,
                    'isVencidos' => !empty($params['vencidos']) && $params['vencidos'] == '1',
                ]);
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
                $userGenerador = $pdfToken->user ? $pdfToken->user->name : 'Sistema';
                $pdf = Pdf::loadView('pdf.example_temp_url', [
                    'cliente'  => $cliente,
                    'cxcs'     => $cxcs,
                    'imageUrl' => null,
                    'usuario'  => $userGenerador,
                ]);
                $filename = 'Reporte_CXC_' . preg_replace('/[^A-Za-z0-9\-]/', '_', $cliente->nombre) . '_' . date('Ymd_Hi') . '.pdf';
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
                $query = ModuleProducto::with('categoria')->where('activo', true);
                if (!empty($params['search'])) {
                    $search = $params['search'];
                    $query->where(function($q) use ($search) {
                        $operator = \DB::connection()->getDriverName() === 'pgsql' ? 'ilike' : 'like';
                        $q->whereRaw("CONCAT_WS(' ', descripcion, medidas, capacidad, NULLIF(UPPER(unidad), 'UNIDAD')) $operator ?", ['%' . $search . '%'])
                          ->orWhere('codigo', $operator, '%' . $search . '%');
                    });
                }
                if (!empty($params['categoria_id'])) {
                    $query->where('category_id', $params['categoria_id']);
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
                if (!empty($params['solo_negativos']) && $params['solo_negativos'] == 'true') {
                    $query->where('stock', '<=', 0);
                }
                
                $orderByMap = [
                    'nombre' => 'descripcion',
                    'venta'  => 'precio',
                    'codigo' => 'codigo',
                    'stock'  => 'stock',
                    'costo'  => 'costo'
                ];
                
                $requestOrder = $params['order_by'] ?? 'nombre';
                $orderBy = $orderByMap[$requestOrder] ?? 'descripcion';
                $orderDir = ($params['order_dir'] ?? 'asc') === 'desc' ? 'desc' : 'asc';
                
                $productos = $query->orderBy($orderBy, $orderDir)->get();
                $pdf = Pdf::loadView('pdf.inventario_productos', ['productos' => $productos]);
                $filename = 'Inventario_Productos_' . date('Ymd') . '.pdf';
                break;

            case 'inventario_movimientos':
                $query = InventarioMovimiento::with(['producto:id,codigo,descripcion,unidad', 'user:id,name,username']);
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

            case 'cheques_futuristas_general':
                return app(\App\Modules\ChequeFuturista\Services\ChequeFuturistaPdfService::class)->renderizarPdf($pdfToken->tipo, $params);

            case 'pedidos_general':
            case 'pedido':
            case 'pedidos_vendedores':
                return app(\App\Modules\Pedido\Services\PedidoPdfService::class)->renderizarPdf($pdfToken->tipo, $params);

            case 'mantenimientos_flota':
                $query = VehiculoMantenimiento::with(['vehiculo:id,ficha,placa', 'reportador:id,name']);

                if (!empty($params['estado']) && $params['estado'] !== 'todos' && $params['estado'] !== 'Todos') {
                    $query->where('estado', strtolower(str_replace(' ', '_', $params['estado'])));
                }
                if (!empty($params['tipo']) && $params['tipo'] !== 'todos' && $params['tipo'] !== 'Todos') {
                    $query->where('tipo', strtolower($params['tipo']));
                }
                if (!empty($params['vehiculo_ficha']) && $params['vehiculo_ficha'] !== 'todos' && $params['vehiculo_ficha'] !== 'Todos') {
                    $query->whereHas('vehiculo', function ($q) use ($params) {
                        $q->where('ficha', $params['vehiculo_ficha']);
                    });
                }
                if (!empty($params['fecha_inicio'])) {
                    $query->where('fecha_reporte', '>=', $params['fecha_inicio']);
                }
                if (!empty($params['fecha_fin'])) {
                    $query->where('fecha_reporte', '<=', $params['fecha_fin']);
                }

                $mantenimientos = $query->orderBy('fecha_reporte', 'desc')->get();
                $totalCosto = $mantenimientos->sum('costo');

                $pdf = Pdf::loadView('pdf.mantenimientos_flota', [
                    'mantenimientos' => $mantenimientos,
                    'totalCosto'     => $totalCosto,
                    'filtros'        => $params
                ]);
                $filename = 'mantenimientos_flota.pdf';
                break;

            case 'gastos_flota':
                $query = \App\Models\VehiculoGasto::with(['vehiculo:id,ficha,placa', 'registrador:id,name']);

                if (!empty($params['tipo_gasto']) && $params['tipo_gasto'] !== 'todos' && $params['tipo_gasto'] !== 'Todos') {
                    $query->where('tipo_gasto', strtolower($params['tipo_gasto']));
                }
                if (!empty($params['vehiculo_ficha']) && $params['vehiculo_ficha'] !== 'todos' && $params['vehiculo_ficha'] !== 'Todos') {
                    $query->whereHas('vehiculo', function ($q) use ($params) {
                        $q->where('ficha', $params['vehiculo_ficha']);
                    });
                }
                if (!empty($params['fecha_inicio'])) {
                    $query->where('fecha_gasto', '>=', $params['fecha_inicio']);
                }
                if (!empty($params['fecha_fin'])) {
                    $query->where('fecha_gasto', '<=', $params['fecha_fin']);
                }

                $gastos = $query->orderBy('fecha_gasto', 'desc')->get();
                $totalMonto = $gastos->sum('monto_total');

                $pdf = Pdf::loadView('pdf.gastos_flota', [
                    'gastos'     => $gastos,
                    'totalMonto' => $totalMonto,
                    'filtros'    => $params
                ]);
                $filename = 'gastos_flota.pdf';
                break;

            case 'gastos_estadisticas_flota':
                $year = $params['year'] ?? date('Y');
                $gastos = \App\Models\VehiculoGasto::with('vehiculo:id,ficha')
                    ->whereYear('fecha_gasto', $year)
                    ->get();

                $porVehiculo = [];
                $porTipo = [];
                $totalYear = 0.0;

                foreach ($gastos as $g) {
                    $mes = (int) $g->fecha_gasto->format('n');
                    $monto = (float) $g->monto_total;
                    $totalYear += $monto;

                    $ficha = $g->vehiculo ? $g->vehiculo->ficha : 'Sin Vehículo';
                    if (!isset($porVehiculo[$ficha])) {
                        $porVehiculo[$ficha] = array_fill(1, 12, 0.0);
                    }
                    $porVehiculo[$ficha][$mes] += $monto;

                    $tipo = ucfirst(strtolower($g->tipo_gasto ?? 'Sin tipo'));
                    if (!isset($porTipo[$tipo])) {
                        $porTipo[$tipo] = array_fill(1, 12, 0.0);
                    }
                    $porTipo[$tipo][$mes] += $monto;
                }

                ksort($porVehiculo);
                ksort($porTipo);

                $pdf = Pdf::loadView('pdf.gastos_estadisticas_flota', [
                    'year' => $year,
                    'totalYear' => $totalYear,
                    'porVehiculo' => $porVehiculo,
                    'porTipo' => $porTipo,
                ])->setPaper('a4', 'landscape'); // we will use landscape since it has 14 columns
                $filename = "gastos_estadisticas_{$year}.pdf";
                break;

            case 'choferes':
                $choferes = \App\Models\Chofer::with('user:id,name,email,username')->get();
                $pdf = Pdf::loadView('pdf.choferes', compact('choferes'));
                $filename = 'reporte_choferes.pdf';
                break;

            case 'produccion_agrupada':
                $tipo = $params['tipo'] ?? 'producto';
                $search = $params['search'] ?? null;
                $repo = app(\App\Modules\Produccion\Repositories\Contracts\ProduccionRepositoryInterface::class);
                
                // Get maximum possible items for PDF (e.g. 500)
                $perPage = 500;
                
                switch ($tipo) {
                    case 'pedido':
                        $resultados = $repo->getAgrupadoPorPedido($perPage, $search);
                        break;
                    case 'cliente':
                        $resultados = $repo->getAgrupadoPorCliente($perPage, $search);
                        break;
                    case 'fecha':
                        $resultados = $repo->getAgrupadoPorFecha($perPage, $search);
                        break;
                    case 'producto':
                    default:
                        $resultados = $repo->getAgrupadoPorProducto($perPage, $search);
                        $tipo = 'producto';
                        break;
                }
                
                $pdf = Pdf::loadView('pdf.produccion_agrupada', [
                    'resultados' => $resultados->items(),
                    'tipo' => $tipo,
                    'search' => $search
                ]);
                $filename = 'Produccion_Agrupada_' . ucfirst($tipo) . '_' . date('Ymd_His') . '.pdf';
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

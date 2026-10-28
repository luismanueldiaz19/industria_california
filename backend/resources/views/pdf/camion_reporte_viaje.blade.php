<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Viaje - Camión #{{ $camion->id }}</title>
    <style>
        @page { margin: 28px 32px; }
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            font-size: 10px;
            color: #1e293b;
            margin: 0;
            padding: 0;
            line-height: 1.35;
        }

        .info-card {
            width: 100%;
            background-color: #f8fafc;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            padding: 10px 14px;
            margin-bottom: 14px;
        }

        .info-table {
            width: 100%;
            border-collapse: collapse;
        }
        .info-table td {
            padding: 3px 6px;
            vertical-align: top;
            font-size: 10px;
        }
        .info-label {
            font-weight: bold;
            color: #475569;
            width: 110px;
            text-transform: uppercase;
            font-size: 8.5px;
            letter-spacing: 0.3px;
        }
        .info-val {
            color: #0f172a;
            font-weight: 500;
        }

        .section-header {
            font-size: 11.5px;
            font-weight: bold;
            color: #0f172a;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-top: 14px;
            margin-bottom: 6px;
            padding-bottom: 3px;
            border-bottom: 1.5px solid #0f172a;
        }

        /* Resumen Financiero Gerencial */
        .kpi-table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 6px 0;
            margin-bottom: 14px;
        }
        .kpi-box {
            background-color: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            padding: 8px 10px;
            text-align: center;
        }
        .kpi-title {
            font-size: 8.5px;
            font-weight: bold;
            text-transform: uppercase;
            color: #64748b;
            margin-bottom: 3px;
        }
        .kpi-value {
            font-size: 14px;
            font-weight: bold;
            color: #0f172a;
        }
        .kpi-box.green {
            background-color: #f0fdf4;
            border-color: #bbf7d0;
        }
        .kpi-box.green .kpi-value { color: #15803d; }
        .kpi-box.red {
            background-color: #fef2f2;
            border-color: #fecaca;
        }
        .kpi-box.red .kpi-value { color: #b91c1c; }
        .kpi-box.blue {
            background-color: #eff6ff;
            border-color: #bfdbfe;
        }
        .kpi-box.blue .kpi-value { color: #1d4ed8; }

        /* Tablas de Datos */
        table.data-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 12px;
            font-size: 9.5px;
        }
        table.data-table th, table.data-table td {
            border: 1px solid #cbd5e1;
            padding: 5px 6px;
            text-align: left;
        }
        table.data-table th {
            background-color: #1e293b;
            color: #ffffff;
            font-weight: bold;
            font-size: 8.5px;
            text-transform: uppercase;
            letter-spacing: 0.3px;
        }
        table.data-table tr:nth-child(even) td {
            background-color: #f8fafc;
        }
        table.data-table td.text-center { text-align: center; }
        table.data-table td.text-right { text-align: right; }

        .total-row {
            background-color: #f1f5f9 !important;
            font-weight: bold;
            font-size: 10px;
        }

        .badge {
            display: inline-block;
            padding: 1.5px 5px;
            font-size: 8px;
            font-weight: bold;
            border-radius: 3px;
            text-transform: uppercase;
        }
        .badge-pendiente { background-color: #fef3c7; color: #92400e; }
        .badge-encurso   { background-color: #eff6ff; color: #1e40af; }
        .badge-entregado { background-color: #dcfce7; color: #166534; }
        .badge-fallido   { background-color: #fee2e2; color: #991b1b; }

        /* Observaciones */
        .notes-box {
            background-color: #fffbeb;
            border: 1px solid #fde68a;
            border-radius: 5px;
            padding: 8px 10px;
            margin-bottom: 14px;
            font-size: 9.5px;
            color: #92400e;
        }

        /* Firmas */
        .signatures-table {
            width: 100%;
            margin-top: 35px;
            border-collapse: collapse;
        }
        .signatures-table td {
            width: 33.33%;
            text-align: center;
            vertical-align: bottom;
            padding: 0 14px;
        }
        .signature-line {
            border-top: 1.5px solid #475569;
            padding-top: 5px;
            font-weight: bold;
            font-size: 9.5px;
            color: #1e293b;
        }
        .signature-role {
            font-size: 8.5px;
            color: #64748b;
            text-transform: uppercase;
        }
    </style>
</head>
<body>

    <x-pdf-header 
        title="REPORTE DE VIAJE" 
        subtitle="Control Operativo, Financiero y de Liquidación" 
    />

    @php
        $choferNombre = $camion->chofer?->user?->name ?? $viaje?->chofer?->user?->name ?? 'No asignado';
        $choferLicencia = $camion->chofer?->numero_licencia ?? $viaje?->chofer?->numero_licencia ?? 'N/D';
        $vendedorNombre = $camion->vendedor?->name ?? 'No asignado';
        $vehiculoFicha = $camion->vehiculo?->ficha ?? $viaje?->vehiculo?->ficha ?? 'N/D';
        $vehiculoDesc = trim(($camion->vehiculo?->marca ?? $viaje?->vehiculo?->marca ?? '') . ' ' . ($camion->vehiculo?->modelo ?? $viaje?->vehiculo?->modelo ?? ''));
        $vehiculoPlaca = $camion->vehiculo?->placa ?? $viaje?->vehiculo?->placa ?? 'N/D';

        $cantAyudantes = $viaje?->cant_ayudantes ?? 0;
        $nombresAyudantes = $viaje?->nombres_ayudantes ?? null;
        $comentarios = $viaje?->comentarios ?? $camion->notas ?? null;

        $gastos = $viaje?->gastos ?? collect();
        $totalGastos = (float) ($viaje?->total_gastos ?? 0);
        if ($totalGastos <= 0 && count($gastos) > 0) {
            $totalGastos = $gastos->sum('monto_total');
        }

        $totalFacturado = (float) ($viaje?->total_facturado > 0 ? $viaje->total_facturado : $camion->monto_total);
        $margenNeto = $totalFacturado - $totalGastos;
        $porcentajeRendimiento = $totalFacturado > 0 ? ($margenNeto / $totalFacturado) * 100 : 0;

        $pedidosReporte = collect();
        if ($viaje && $viaje->pedidos && $viaje->pedidos->count() > 0) {
            foreach ($viaje->pedidos as $vp) {
                $p = $vp->pedido;
                $pedidosReporte->push((object) [
                    'orden_viaje'    => $vp->orden_viaje,
                    'num_factura'    => $p?->num_factura ?? ('FAC-' . $vp->pedido_id),
                    'id'             => $vp->pedido_id,
                    'cliente_nombre' => $p?->cliente?->nombre ?? 'Cliente sin nombre',
                    'cliente_doc'    => $p?->cliente?->documento,
                    'direccion'      => $p?->cliente?->direccion ?? $p?->direccion_entrega ?? 'Dirección no especificada',
                    'estado_entrega' => strtolower($vp->estado_entrega?->value ?? (string) $vp->estado_entrega),
                    'total'          => (float) ($vp->total_pedido > 0 ? $vp->total_pedido : ($p?->total ?? 0)),
                ]);
            }
        } elseif ($camion && $camion->pedidos) {
            foreach ($camion->pedidos as $p) {
                $pedidosReporte->push((object) [
                    'orden_viaje'    => $p->pivot->orden_viaje ?? '-',
                    'num_factura'    => $p->num_factura ?? ('FAC-' . $p->id),
                    'id'             => $p->id,
                    'cliente_nombre' => $p->cliente?->nombre ?? 'Cliente sin nombre',
                    'cliente_doc'    => $p->cliente?->documento,
                    'direccion'      => $p->cliente?->direccion ?? $p->direccion_entrega ?? 'Dirección no especificada',
                    'estado_entrega' => strtolower($p->pivot->estado_entrega ?? 'pendiente'),
                    'total'          => (float) $p->total,
                ]);
            }
        }
        $totalPedidos = $pedidosReporte->count();
    @endphp

    <!-- Datos Generales del Despacho / Camión -->
    <div class="info-card">
        <table class="info-table">
            <tr>
                <td class="info-label">Camión / Unidad:</td>
                <td class="info-val"><strong>{{ $camion->nombre }}</strong> (Slot #{{ $camion->slot_numero }})</td>
                <td class="info-label">Fecha Emisión:</td>
                <td class="info-val">{{ now()->format('d/m/Y h:i A') }}</td>
            </tr>
            <tr>
                <td class="info-label">Conductor Real:</td>
                <td class="info-val"><strong>{{ $choferNombre }}</strong> (Lic: {{ $choferLicencia }})</td>
                <td class="info-label">Vehículo Físico:</td>
                <td class="info-val">Ficha <strong>{{ $vehiculoFicha }}</strong> &bull; {{ $vehiculoDesc }} (Placa: {{ $vehiculoPlaca }})</td>
            </tr>
            <tr>
                <td class="info-label">Vendedor:</td>
                <td class="info-val">{{ $vendedorNombre }}</td>
                <td class="info-label">Estado de Flota:</td>
                <td class="info-val"><strong>{{ strtoupper($camion->estado?->value ?? (string) $camion->estado) }}</strong></td>
            </tr>
            <tr>
                <td class="info-label">Ayudantes:</td>
                <td class="info-val">
                    @if($cantAyudantes > 0 || !empty($nombresAyudantes))
                        <strong>{{ $cantAyudantes }} ayudante(s)</strong> &bull; {{ $nombresAyudantes ?? 'Nombres no detallados' }}
                    @else
                        Sin ayudantes registrados
                    @endif
                </td>
                <td class="info-label">Fecha Salida:</td>
                <td class="info-val">{{ $viaje?->fecha_salida ? $viaje->fecha_salida->format('d/m/Y h:i A') : 'En preparación' }}</td>
            </tr>
        </table>
    </div>

    <!-- Observaciones o Notas de Salida si existen -->
    @if(!empty($comentarios))
        <div class="notes-box">
            <strong>OBSERVACIONES / NOTAS DEL VIAJE:</strong> {{ $comentarios }}
        </div>
    @endif

    <!-- Resumen Financiero Gerencial (KPIs) -->
    <table class="kpi-table">
        <tr>
            <td style="width: 25%;">
                <div class="kpi-box blue">
                    <div class="kpi-title">Facturación Total</div>
                    <div class="kpi-value">RD$ {{ number_format($totalFacturado, 2) }}</div>
                </div>
            </td>
            <td style="width: 25%;">
                <div class="kpi-box">
                    <div class="kpi-title">Cant. Pedidos / Facturas</div>
                    <div class="kpi-value">{{ $totalPedidos }}</div>
                </div>
            </td>
            <td style="width: 25%;">
                <div class="kpi-box red">
                    <div class="kpi-title">Gastos Presupuestados</div>
                    <div class="kpi-value">RD$ {{ number_format($totalGastos, 2) }}</div>
                </div>
            </td>
            <td style="width: 25%;">
                <div class="kpi-box green">
                    <div class="kpi-title">Margen Neto Estimado</div>
                    <div class="kpi-value">RD$ {{ number_format($margenNeto, 2) }}</div>
                </div>
            </td>
        </tr>
    </table>

    <!-- Sección 1: Desglose de Gastos del Viaje -->
    <div class="section-header">1. DESGLOSE DE GASTOS OPERATIVOS DEL VIAJE</div>
    <table class="data-table">
        <thead>
            <tr>
                <th style="width: 28px;" class="text-center">#</th>
                <th style="width: 130px;">TIPO DE GASTO</th>
                <th>CONCEPTO / ESTACIÓN / DETALLE</th>
                <th style="width: 100px;">COMPROBANTE / NIF</th>
                <th style="width: 90px;" class="text-right">MONTO (RD$)</th>
            </tr>
        </thead>
        <tbody>
            @forelse($gastos as $idx => $g)
                <tr>
                    <td class="text-center">{{ $idx + 1 }}</td>
                    <td><strong>{{ strtoupper($g->tipo_gasto ?? 'OTRO') }}</strong></td>
                    <td>{{ $g->concepto ?? 'Gasto operativo de viaje' }}</td>
                    <td>{{ $g->comprobante ?? '-' }}</td>
                    <td class="text-right" style="color: #b91c1c; font-weight: bold;">
                        RD$ {{ number_format($g->monto_total, 2) }}
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="5" class="text-center" style="color: #64748b; font-style: italic;">
                        No se registraron gastos operativos para este despacho.
                    </td>
                </tr>
            @endforelse
        </tbody>
        @if(count($gastos) > 0)
            <tfoot>
                <tr class="total-row">
                    <td colspan="4" class="text-right">TOTAL GASTOS DE VIAJE:</td>
                    <td class="text-right" style="color: #b91c1c; font-size: 11px;">
                        RD$ {{ number_format($totalGastos, 2) }}
                    </td>
                </tr>
            </tfoot>
        @endif
    </table>

    <!-- Sección 2: Pedidos / Facturas Asignadas al Camión -->
    <div class="section-header">2. FACTURAS Y PEDIDOS CARGADOS AL CAMIÓN</div>
    <table class="data-table">
        <thead>
            <tr>
                <th style="width: 24px;" class="text-center">ORD</th>
                <th style="width: 75px;" class="text-center">FACTURA #</th>
                <th style="width: 60px;" class="text-center">PEDIDO #</th>
                <th>CLIENTE / RAZÓN SOCIAL</th>
                <th>DIRECCIÓN DE ENTREGA</th>
                <th style="width: 75px;" class="text-center">ESTADO</th>
                <th style="width: 85px;" class="text-right">MONTO (RD$)</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($pedidosReporte as $pedido)
                @php
                    $estadoEntrega = $pedido->estado_entrega;
                    $badgeClass = match($estadoEntrega) {
                        'entregado' => 'badge-entregado',
                        'en_curso'  => 'badge-encurso',
                        'fallido'   => 'badge-fallido',
                        default     => 'badge-pendiente',
                    };
                    $labelEntrega = match($estadoEntrega) {
                        'entregado' => 'Entregado',
                        'en_curso'  => 'En curso',
                        'fallido'   => 'Fallido',
                        default     => 'Pendiente',
                    };
                @endphp
                <tr>
                    <td class="text-center"><strong>{{ $pedido->orden_viaje }}</strong></td>
                    <td class="text-center" style="font-weight: bold; color: #1e40af;">
                        {{ $pedido->num_factura }}
                    </td>
                    <td class="text-center">#{{ $pedido->id }}</td>
                    <td>
                        <strong>{{ $pedido->cliente_nombre }}</strong>
                        @if(!empty($pedido->cliente_doc))
                            <br><span style="font-size: 8px; color: #64748b;">Doc: {{ $pedido->cliente_doc }}</span>
                        @endif
                    </td>
                    <td>{{ $pedido->direccion }}</td>
                    <td class="text-center">
                        <span class="badge {{ $badgeClass }}">{{ $labelEntrega }}</span>
                    </td>
                    <td class="text-right" style="font-weight: bold;">
                        RD$ {{ number_format($pedido->total, 2) }}
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="7" class="text-center" style="color: #64748b;">
                        No hay pedidos asignados a este camión o viaje.
                    </td>
                </tr>
            @endforelse
        </tbody>
        @if($totalPedidos > 0)
            <tfoot>
                <tr class="total-row">
                    <td colspan="6" class="text-right">MONTO TOTAL FACTURADO ({{ $totalPedidos }} PEDIDOS):</td>
                    <td class="text-right" style="color: #15803d; font-size: 11px;">
                        RD$ {{ number_format($totalFacturado, 2) }}
                    </td>
                </tr>
            </tfoot>
        @endif
    </table>

    <!-- Bloque de Firmas -->
    <table class="signatures-table">
        <tr>
            <td>
                <div class="signature-line">{{ $choferNombre }}</div>
                <div class="signature-role">Firma del Conductor</div>
            </td>
            <td>
                <div class="signature-line">{{ $vendedorNombre }}</div>
                <div class="signature-role">Despacho / Vendedor</div>
            </td>
            <td>
                <div class="signature-line">Gerencia / Logística</div>
                <div class="signature-role">Aprobado y Liquidado</div>
            </td>
        </tr>
    </table>

</body>
</html>


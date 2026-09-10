<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporte General CXC</title>
    <style>
        @page { margin: 40px; }
        body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; font-size: 14px; color: #333; margin: 0; padding: 0; }

        table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 12px; }
        table, th, td { border: 1px solid #ddd; }
        th, td { padding: 6px; text-align: left; }
        th { background-color: #f4f4f4; }
    </style>
</head>
<body>
    <x-pdf-header title="Estado de Cuentas (CXC)" subtitle="Reporte: Todos los Documentos" />

    <table>
        <thead>
            <tr>
                <th>Cliente</th>
                <th>Documento</th>
                <th>F. Factura</th>
                <th>F. Vencimiento</th>
                <th style="text-align: right;">Facturado</th>
                <th style="text-align: right;">Pagado</th>
                <th style="text-align: right;">Pendiente</th>
                <th style="text-align: center;">Estado</th>
            </tr>
        </thead>
        <tbody>
            @php
                $totalFacturado = 0;
                $totalPagado = 0;
                $totalPendiente = 0;
            @endphp
            @forelse($cxcs as $cxc)
                @php
                    $totalFacturado += $cxc->monto_factura;
                    $totalPagado += $cxc->monto_pagado;
                    $totalPendiente += $cxc->monto_pendiente;
                    $fechaFactura = !empty($cxc->fecha_factura) ? \Carbon\Carbon::parse($cxc->fecha_factura)->format('d/m/Y') : '-';
                    $fechaVencimientoObj = !empty($cxc->fecha_vencimiento) ? \Carbon\Carbon::parse($cxc->fecha_vencimiento) : null;
                    $fechaVencimiento = $fechaVencimientoObj ? $fechaVencimientoObj->format('d/m/Y') : '-';
                    $estaVencido = $fechaVencimientoObj && $fechaVencimientoObj->isPast() && strtolower($cxc->estado) !== 'pagado';
                    $diasVencido = $estaVencido ? abs(floor(now()->diffInDays($fechaVencimientoObj))) : 0;
                @endphp
                <tr>
                    <td>{{ $cxc->cliente->nombre ?? 'N/A' }}</td>
                    <td style="font-weight: 600;">{{ $cxc->documento }}</td>
                    <td>{{ $fechaFactura }}</td>
                    <td style="{{ $estaVencido ? 'color: #ea4335; font-weight: bold;' : '' }}">
                        {{ $fechaVencimiento }}
                    </td>
                    <td style="text-align: right;">${{ number_format($cxc->monto_factura, 2) }}</td>
                    <td style="text-align: right;">${{ number_format($cxc->monto_pagado, 2) }}</td>
                    <td style="text-align: right; color: #d93025; font-weight: bold;">${{ number_format($cxc->monto_pendiente, 2) }}</td>
                    <td style="text-align: center;">
                        @if(strtolower($cxc->estado) === 'pagado')
                            <span style="color: #1e8e3e; font-weight: bold;">Pagado</span>
                        @elseif($estaVencido)
                            <span style="color: #ea4335; font-weight: bold;">Vencido ({{ $diasVencido }}d)</span>
                        @else
                            <span style="color: #fbbc05; font-weight: bold;">Pendiente</span>
                        @endif
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="8" style="text-align: center; padding: 20px;">No hay cuentas por cobrar registradas.</td>
                </tr>
            @endforelse
            <tr style="background-color: #f8f9fa; font-weight: bold; font-size: 13px;">
                <td colspan="4" style="text-align: right; color: #555;">TOTALES GENERALES:</td>
                <td style="text-align: right;">${{ number_format($totalFacturado, 2) }}</td>
                <td style="text-align: right;">${{ number_format($totalPagado, 2) }}</td>
                <td style="text-align: right; color: #d93025;">${{ number_format($totalPendiente, 2) }}</td>
                <td></td>
            </tr>
        </tbody>
    </table>
</body>
</html>

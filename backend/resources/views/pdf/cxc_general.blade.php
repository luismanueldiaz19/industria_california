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
                <th>Factura</th>
                <th>Facturado</th>
                <th>Pagado</th>
                <th>Deuda Pendiente</th>
                <th>Vencimiento</th>
                <th>Estado</th>
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
                    $fechaVencimiento = \Carbon\Carbon::parse($cxc->fecha_vencimiento);
                    $estaVencido = $fechaVencimiento->isPast() && strtolower($cxc->estado) !== 'pagado';
                    $diasVencido = $estaVencido ? abs(floor(now()->diffInDays($fechaVencimiento))) : 0;
                @endphp
                <tr>
                    <td>{{ $cxc->cliente->nombre ?? 'N/A' }}</td>
                    <td>{{ $cxc->documento }}</td>
                    <td>${{ number_format($cxc->monto_factura, 2) }}</td>
                    <td>${{ number_format($cxc->monto_pagado, 2) }}</td>
                    <td style="color: #d93025; font-weight: bold;">${{ number_format($cxc->monto_pendiente, 2) }}</td>
                    <td>{{ $fechaVencimiento->format('Y-m-d') }}</td>
                    <td>
                        @if(strtolower($cxc->estado) === 'pagado')
                            <span style="color: #1e8e3e; font-weight: bold;">Pagado</span>
                        @elseif($estaVencido)
                            <span style="color: #ea4335; font-weight: bold;">{{ $diasVencido }} días vencidos</span>
                        @else
                            <span style="color: #fbbc05; font-weight: bold;">Pendiente</span>
                        @endif
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="7" style="text-align: center; padding: 20px;">No hay cuentas por cobrar registradas.</td>
                </tr>
            @endforelse
            <tr style="background-color: #f8f9fa; font-weight: bold; font-size: 13px;">
                <td colspan="2" style="text-align: right; color: #555;">TOTALES:</td>
                <td>${{ number_format($totalFacturado, 2) }}</td>
                <td>${{ number_format($totalPagado, 2) }}</td>
                <td style="color: #d93025;">${{ number_format($totalPendiente, 2) }}</td>
                <td colspan="2"></td>
            </tr>
        </tbody>
    </table>
</body>
</html>

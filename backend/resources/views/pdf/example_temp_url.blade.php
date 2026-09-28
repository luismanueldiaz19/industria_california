<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporte CXC - {{ $cliente->nombre ?? 'Cliente' }}</title>
    <style>
        /* Márgenes de página normales (sin footer fijo) */
        @page {
            margin: 40px;
        }

        /* Estilos generales para DOMPDF */
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            font-size: 14px;
            color: #333;
            margin: 0;
            padding: 0;
        }

        /* Utilidad para saltos de página (Page Breaks) */
        .page-break {
            page-break-after: always;
        }

        .info-section {
            background-color: #eef2ff;
            border-left: 4px solid #4f46e5;
            padding: 15px;
            margin-bottom: 20px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        table, th, td {
            border: 1px solid #ddd;
        }
        th, td {
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f4f4f4;
        }
    </style>
</head>
<body>

    <x-pdf-header title="Reporte Completo de CXC" subtitle="Cliente: {{ $cliente->nombre ?? 'N/A' }}" usuario="{{ $usuario ?? '' }}" />

    @php
        $totalFacturado = 0;
        $totalPagado = 0;
        $totalPendiente = 0;
        $totalVencido = 0;
        
        foreach($cxcs as $cxc) {
            $totalFacturado += $cxc->monto_factura;
            $totalPagado += $cxc->monto_pagado;
            $totalPendiente += $cxc->monto_pendiente;
            
            $fechaVencimiento = \Carbon\Carbon::parse($cxc->fecha_vencimiento);
            $estaVencido = $fechaVencimiento->isPast() && strtolower($cxc->estado) !== 'pagado';
            
            if ($estaVencido) {
                $totalVencido += $cxc->monto_pendiente;
            }
        }
    @endphp

    <div style="margin-bottom: 20px;">
        <h3 style="margin: 0 0 5px 0; color: #1a1a2e; text-transform: uppercase;">{{ $cliente->nombre ?? 'Cliente Desconocido' }}</h3>
        <p style="margin: 0; font-size: 12px; color: #475569;">
            @if(!empty($cliente->documento)) <strong>Doc:</strong> {{ $cliente->documento }} &nbsp;|&nbsp; @endif
            @if(!empty($cliente->whatsapp)) <strong>WhatsApp:</strong> {{ $cliente->whatsapp }} &nbsp;|&nbsp; @endif
            @if(!empty($cliente->dias_credito)) <strong>Días:</strong> {{ $cliente->dias_credito }} &nbsp;|&nbsp; @endif
            @if(!empty($cliente->direccion)) <strong>Dirección:</strong> {{ $cliente->direccion }} @endif
        </p>
    </div>

    <!-- ========================================== -->
    <!-- TABLA DE DATOS (CXC)                       -->
    <!-- ========================================== -->
    <table>
        <thead>
            <tr>
                <th>Documento / Factura</th>
                <th>Facturado</th>
                <th>Pagado</th>
                <th>Deuda Pendiente</th>
                <th>Vencimiento</th>
                <th>Estado</th>
            </tr>
        </thead>
        <tbody>
            @forelse($cxcs as $cxc)
                @php
                    $fechaVencimiento = \Carbon\Carbon::parse($cxc->fecha_vencimiento);
                    $estaVencido = $fechaVencimiento->isPast() && strtolower($cxc->estado) !== 'pagado';
                    $diasVencido = $estaVencido ? abs(floor(now()->diffInDays($fechaVencimiento))) : 0;
                @endphp
                <tr>
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
                    <td colspan="6" style="text-align: center; padding: 20px;">No hay cuentas por cobrar registradas para este cliente.</td>
                </tr>
            @endforelse
            
        </tbody>
    </table>

    <div style="margin-top: 20px; page-break-inside: avoid;">
        <div style="border: 1px solid #e2e8f0; border-radius: 6px; padding: 12px; background-color: #f8fafc;">
            <table style="width: 100%; border: none; margin: 0;">
                <tr style="border: none;">
                    <td style="border: none; text-align: center; border-right: 1px solid #e2e8f0;">
                        <span style="font-size: 10px; color: #64748b; font-weight: bold;">TOTAL FACTURADO</span><br>
                        <span style="font-size: 14px; color: #0f172a; font-weight: bold;">${{ number_format($totalFacturado, 2) }}</span>
                    </td>
                    <td style="border: none; text-align: center; border-right: 1px solid #e2e8f0;">
                        <span style="font-size: 10px; color: #64748b; font-weight: bold;">DEUDA PENDIENTE</span><br>
                        <span style="font-size: 14px; color: #d97706; font-weight: bold;">${{ number_format($totalPendiente, 2) }}</span>
                    </td>
                    <td style="border: none; text-align: center;">
                        <span style="font-size: 10px; color: #64748b; font-weight: bold;">TOTAL VENCIDO</span><br>
                        <span style="font-size: 14px; color: #dc2626; font-weight: bold;">${{ number_format($totalVencido, 2) }}</span>
                    </td>
                </tr>
            </table>
        </div>
    </div>

</body>
</html>

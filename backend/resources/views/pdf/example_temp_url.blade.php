<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporte PDF con URLs Temporales</title>
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

    <x-pdf-header title="Reporte Completo de CXC" subtitle="Demo" />

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
                    
                    // Determinar estado y días vencidos
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
            
            <!-- Fila de Totales -->
            <tr style="background-color: #f8f9fa; font-weight: bold; font-size: 15px;">
                <td style="text-align: right; color: #555;">TOTALES:</td>
                <td>${{ number_format($totalFacturado, 2) }}</td>
                <td>${{ number_format($totalPagado, 2) }}</td>
                <td style="color: #d93025;">${{ number_format($totalPendiente, 2) }}</td>
                <td colspan="2"></td>
            </tr>
        </tbody>
    </table>

    <!-- ========================================== -->
    <!-- DEMOSTRACIÓN DE URL TEMPORAL (OPCIONAL)    -->
    <!-- ========================================== -->
    @if(isset($imageUrl))
    <div style="page-break-before: always; margin-top: 30px;">
        <h4 style="color: #4f46e5;">Anexos / Documentos de Soporte (URL Temporal)</h4>
        <p style="font-size: 11px; color: #666;">
            Esta imagen ha sido cargada usando una <strong>URL temporal segura</strong> firmada desde tu bucket en S3/Disco local.
        </p>
        <div class="image-container">
            <img src="{{ $imageUrl }}" alt="Soporte Adjunto">
        </div>
    </div>
    @endif

</body>
</html>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporte de CXC - Vendedor</title>
    <style>
        @page { margin: 40px; }
        body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; font-size: 14px; color: #333; margin: 0; padding: 0; }

        table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 12px; }
        table, th, td { border: 1px solid #ddd; }
        th, td { padding: 6px; text-align: left; }
        th { background-color: #f4f4f4; }

        .text-right { text-align: right; }
        .text-center { text-align: center; }
        .total-row { font-weight: bold; background-color: #f8f9fa; font-size: 13px; }
        .text-danger { color: #d93025; font-weight: bold; }
        .filters { font-size: 11px; color: #555; margin-bottom: 15px; margin-top: -10px; }
    </style>
</head>
<body>

    <x-pdf-header title="ESTADO DE CUENTAS (CXC)" subtitle="Reporte: Vendedor - {{ $vendedor->name ?? 'N/A' }}" />

    <div class="filters">
        @if($search)
            <strong>Búsqueda:</strong> {{ $search }}<br>
        @endif
        @if($isVencidos)
            <strong>Filtro:</strong> Solo documentos vencidos<br>
        @endif
    </div>

    <table>
        <thead>
            <tr>
                <th>Documento</th>
                <th>Cliente</th>
                <th>F. Factura</th>
                <th>F. Vencimiento</th>
                <th class="text-right">Monto Factura</th>
                <th class="text-right">Monto Pendiente</th>
            </tr>
        </thead>
        <tbody>
            @php
                $totalFactura = 0;
                $totalPendiente = 0;
            @endphp
            @forelse($cxcs as $cxc)
                @php
                    $totalFactura += $cxc->monto_factura;
                    $totalPendiente += $cxc->monto_pendiente;
                    $isPastDue = $cxc->monto_pendiente > 0 && \Carbon\Carbon::parse($cxc->fecha_vencimiento)->isPast();
                @endphp
                <tr>
                    <td>{{ $cxc->documento }}</td>
                    <td>{{ optional($cxc->cliente)->nombre ?? 'Desconocido' }}</td>
                    <td>{{ \Carbon\Carbon::parse($cxc->fecha_factura)->format('d/m/Y') }}</td>
                    <td class="{{ $isPastDue ? 'text-danger' : '' }}">
                        {{ \Carbon\Carbon::parse($cxc->fecha_vencimiento)->format('d/m/Y') }}
                    </td>
                    <td class="text-right">${{ number_format($cxc->monto_factura, 2) }}</td>
                    <td class="text-right {{ $isPastDue ? 'text-danger' : '' }}">${{ number_format($cxc->monto_pendiente, 2) }}</td>
                </tr>
            @empty
                <tr>
                    <td colspan="6" class="text-center" style="padding: 20px;">No se encontraron registros.</td>
                </tr>
            @endforelse
        </tbody>
        @if($cxcs->count() > 0)
        <tfoot>
            <tr class="total-row">
                <td colspan="4" class="text-right" style="color: #555;">TOTALES GENERALES:</td>
                <td class="text-right">${{ number_format($totalFactura, 2) }}</td>
                <td class="text-right text-danger">${{ number_format($totalPendiente, 2) }}</td>
            </tr>
        </tfoot>
        @endif
    </table>

</body>
</html>

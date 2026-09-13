<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporte Agrupado CXC</title>
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
    <x-pdf-header title="Estado de Cuentas (CXC)" subtitle="Reporte: Agrupado por Cliente" />
    
    <div style="margin-bottom: 15px; font-size: 12px; color: #555;">
        @if(isset($vendedorNombre) && $vendedorNombre)
            <span><strong>Vendedor:</strong> {{ $vendedorNombre }}</span> &nbsp;|&nbsp;
        @endif
        @if(isset($search) && $search)
            <span><strong>Búsqueda:</strong> {{ $search }}</span> &nbsp;|&nbsp;
        @endif
        @if(isset($isVencidos) && $isVencidos)
            <span><strong>Filtro:</strong> Solo Vencidos</span>
        @endif
    </div>

    <table>
        <thead>
            <tr>
                <th>Cliente</th>
                <th>Total Facturado</th>
                <th>Total Pagado</th>
                <th>Deuda Pendiente</th>
            </tr>
        </thead>
        <tbody>
            @php
                $granFacturado = 0;
                $granPagado = 0;
                $granPendiente = 0;
            @endphp
            @forelse($clientes as $cliente)
                @php
                    $facturado = $cliente->total_facturado ?? 0;
                    $pendiente = $cliente->total_pendiente ?? 0;
                    $pagado = $facturado - $pendiente;
                    
                    $granFacturado += $facturado;
                    $granPagado += $pagado;
                    $granPendiente += $pendiente;
                @endphp
                <tr>
                    <td>{{ $cliente->nombre ?? 'N/A' }}</td>
                    <td>${{ number_format($facturado, 2) }}</td>
                    <td>${{ number_format($pagado, 2) }}</td>
                    <td style="color: #d93025; font-weight: bold;">${{ number_format($pendiente, 2) }}</td>
                </tr>
            @empty
                <tr>
                    <td colspan="4" style="text-align: center; padding: 20px;">No hay clientes registrados con deudas.</td>
                </tr>
            @endforelse
            <tr style="background-color: #f8f9fa; font-weight: bold; font-size: 13px;">
                <td style="text-align: right; color: #555;">TOTALES GENERALES:</td>
                <td>${{ number_format($granFacturado, 2) }}</td>
                <td>${{ number_format($granPagado, 2) }}</td>
                <td style="color: #d93025;">${{ number_format($granPendiente, 2) }}</td>
            </tr>
        </tbody>
    </table>
</body>
</html>

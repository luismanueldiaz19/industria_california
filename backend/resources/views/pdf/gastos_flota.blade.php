<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporte de Gastos y Combustible</title>
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
    @include('components.pdf-header', [
        'title' => 'Flota Vehicular', 
        'subtitle' => 'Reporte de Gastos y Combustible'
    ])
    
    <div style="margin-bottom: 15px; font-size: 12px; color: #555;">
        @if(isset($filtros['vehiculo_ficha']) && $filtros['vehiculo_ficha'] !== 'todos' && $filtros['vehiculo_ficha'] !== 'Todos')
            <span><strong>Vehículo Ficha:</strong> {{ $filtros['vehiculo_ficha'] }}</span> &nbsp;|&nbsp;
        @endif
        @if(isset($filtros['tipo_gasto']) && $filtros['tipo_gasto'] !== 'todos' && $filtros['tipo_gasto'] !== 'Todos')
            <span><strong>Tipo:</strong> {{ ucfirst($filtros['tipo_gasto']) }}</span> &nbsp;|&nbsp;
        @endif
        @if(isset($filtros['fecha_inicio']))
            <span><strong>Desde:</strong> {{ \Carbon\Carbon::parse($filtros['fecha_inicio'])->format('d/m/Y') }}</span> &nbsp;|&nbsp;
        @endif
        @if(isset($filtros['fecha_fin']))
            <span><strong>Hasta:</strong> {{ \Carbon\Carbon::parse($filtros['fecha_fin'])->format('d/m/Y') }}</span>
        @endif
    </div>

    <table>
        <thead>
            <tr>
                <th>Vehículo</th>
                <th>Tipo Gasto</th>
                <th>Concepto</th>
                <th>Fecha</th>
                <th>Registrador</th>
                <th style="text-align: right;">Monto Total</th>
            </tr>
        </thead>
        <tbody>
            @forelse($gastos as $gasto)
                <tr>
                    <td style="font-weight: 600;">{{ $gasto->vehiculo->ficha ?? 'S/N' }} ({{ $gasto->vehiculo->placa ?? 'S/N' }})</td>
                    <td>{{ $gasto->tipo_gasto ? ucfirst($gasto->tipo_gasto) : 'N/A' }}</td>
                    <td>{{ Str::limit($gasto->concepto, 120) }}</td>
                    <td>{{ $gasto->fecha_gasto ? \Carbon\Carbon::parse($gasto->fecha_gasto)->format('d/m/Y') : 'N/A' }}</td>
                    <td>{{ $gasto->registrador->name ?? 'N/A' }}</td>
                    <td style="text-align: right;">${{ number_format($gasto->monto_total, 2) }}</td>
                </tr>
            @empty
                <tr>
                    <td colspan="6" style="text-align: center; padding: 20px;">No hay gastos registrados con los filtros aplicados.</td>
                </tr>
            @endforelse
            <tr style="background-color: #f8f9fa; font-weight: bold; font-size: 13px;">
                <td colspan="5" style="text-align: right; color: #555;">COSTO TOTAL:</td>
                <td style="text-align: right; color: #1e8e3e;">${{ number_format($totalMonto ?? 0, 2) }}</td>
            </tr>
        </tbody>
    </table>
</body>
</html>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporte de Mantenimientos y Averías</title>
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
        'subtitle' => 'Reporte de Mantenimientos y Averías'
    ])
    
    <div style="margin-bottom: 15px; font-size: 12px; color: #555;">
        @if(isset($filtros['vehiculo_ficha']) && $filtros['vehiculo_ficha'] !== 'todos' && $filtros['vehiculo_ficha'] !== 'Todos')
            <span><strong>Vehículo Ficha:</strong> {{ $filtros['vehiculo_ficha'] }}</span> &nbsp;|&nbsp;
        @endif
        @if(isset($filtros['tipo']) && $filtros['tipo'] !== 'todos' && $filtros['tipo'] !== 'Todos')
            <span><strong>Tipo:</strong> {{ ucfirst($filtros['tipo']) }}</span> &nbsp;|&nbsp;
        @endif
        @if(isset($filtros['estado']) && $filtros['estado'] !== 'todos' && $filtros['estado'] !== 'Todos')
            <span><strong>Estado:</strong> {{ ucfirst(str_replace('_', ' ', $filtros['estado'])) }}</span> &nbsp;|&nbsp;
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
                <th>Tipo</th>
                <th>Estado</th>
                <th>F. Reporte</th>
                <th>Descripción</th>
                <th>Reportador</th>
                <th style="text-align: right;">Costo</th>
            </tr>
        </thead>
        <tbody>
            @forelse($mantenimientos as $mant)
                <tr>
                    <td style="font-weight: 600;">{{ $mant->vehiculo->ficha ?? 'S/N' }} ({{ $mant->vehiculo->placa ?? 'S/N' }})</td>
                    <td>{{ ucfirst($mant->tipo->value) }}</td>
                    <td style="text-align: center;">
                        @if($mant->estado->value === 'resuelto')
                            <span style="color: #1e8e3e; font-weight: bold;">Resuelto</span>
                        @elseif($mant->estado->value === 'en_proceso')
                            <span style="color: #fbbc05; font-weight: bold;">En Proceso</span>
                        @else
                            <span style="color: #ea4335; font-weight: bold;">Pendiente</span>
                        @endif
                    </td>
                    <td>{{ $mant->fecha_reporte ? \Carbon\Carbon::parse($mant->fecha_reporte)->format('d/m/Y') : 'N/A' }}</td>
                    <td>{{ Str::limit($mant->descripcion, 120) }}</td>
                    <td>{{ $mant->reportador->name ?? 'N/A' }}</td>
                    <td style="text-align: right;">${{ number_format($mant->costo, 2) }}</td>
                </tr>
            @empty
                <tr>
                    <td colspan="7" style="text-align: center; padding: 20px;">No hay mantenimientos registrados con los filtros aplicados.</td>
                </tr>
            @endforelse
            <tr style="background-color: #f8f9fa; font-weight: bold; font-size: 13px;">
                <td colspan="6" style="text-align: right; color: #555;">COSTO TOTAL:</td>
                <td style="text-align: right; color: #1e8e3e;">${{ number_format($totalCosto ?? 0, 2) }}</td>
            </tr>
        </tbody>
    </table>
</body>
</html>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Choferes</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            color: #333;
            font-size: 11px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 6px;
            text-align: left;
        }
        th {
            background-color: #2C2F33;
            color: white;
            font-size: 11px;
            font-weight: bold;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .text-center {
            text-align: center;
        }
        .status-activo { color: green; font-weight: bold; }
        .status-inactivo { color: red; font-weight: bold; }
        .status-vacaciones { color: orange; font-weight: bold; }
    </style>
</head>
<body>

    @include('components.pdf-header')

    <h2 class="text-center" style="margin-top:10px; margin-bottom: 20px;">Reporte de Choferes</h2>

    <table>
        <thead>
            <tr>
                <th>Nombre</th>
                <th>Usuario</th>
                <th>Email</th>
                <th>Licencia</th>
                <th>Tipo</th>
                <th>Vencimiento</th>
                <th>Emergencia</th>
                <th>Estado</th>
            </tr>
        </thead>
        <tbody>
            @foreach($choferes as $chofer)
                <tr>
                    <td>{{ $chofer->user->name ?? 'N/A' }}</td>
                    <td>{{ $chofer->user->username ?? 'N/A' }}</td>
                    <td>{{ $chofer->user->email ?? 'N/A' }}</td>
                    <td>{{ $chofer->numero_licencia ?? 'N/A' }}</td>
                    <td>{{ $chofer->tipo_licencia ?? 'N/A' }}</td>
                    <td>{{ $chofer->vencimiento_licencia ? \Carbon\Carbon::parse($chofer->vencimiento_licencia)->format('d/m/Y') : 'N/A' }}</td>
                    <td>{{ $chofer->contacto_emergencia ?? 'N/A' }}</td>
                    <td>
                        @php
                            $statusClass = 'status-inactivo';
                            if ($chofer->estado === 'activo') $statusClass = 'status-activo';
                            if ($chofer->estado === 'vacaciones') $statusClass = 'status-vacaciones';
                        @endphp
                        <span class="{{ $statusClass }}">{{ strtoupper($chofer->estado) }}</span>
                    </td>
                </tr>
            @endforeach
        </tbody>
    </table>

</body>
</html>

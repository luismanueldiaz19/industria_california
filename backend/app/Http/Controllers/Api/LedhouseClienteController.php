<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\LedhouseCliente;

class LedhouseClienteController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = LedhouseCliente::query();

        if ($request->has('search') && trim($request->input('search')) !== '') {
            $rawSearch = trim($request->input('search'));
            // Use the backend normalizer equivalent to the frontend one
            $search = \App\Helpers\TextNormalizer::normalize($rawSearch);
            // Also extract just digits in case they are searching for a phone number with dashes
            $digitsOnly = \App\Helpers\TextNormalizer::onlyDigits($rawSearch);

            $query->where(function ($q) use ($search, $digitsOnly) {
                // MySQL's utf8mb4_unicode_ci is already case/accent insensitive, 
                // but we use the normalized search just to be safe.
                $q->whereRaw('LOWER(nombre) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(id_cliente_externo) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(documento) LIKE ?', ["%{$search}%"]);
                  
                if (!empty($digitsOnly)) {
                    // Try to match digits only (e.g. if they typed "809-555" we search "%809555%")
                    // But also search the raw string just in case the db has formatting.
                    $q->orWhereRaw("REPLACE(REPLACE(REPLACE(whatsapp, '-', ''), ' ', ''), '+', '') LIKE ?", ["%{$digitsOnly}%"])
                      ->orWhereRaw('LOWER(whatsapp) LIKE ?', ["%{$search}%"]);
                } else {
                    $q->orWhereRaw('LOWER(whatsapp) LIKE ?', ["%{$search}%"]);
                }
            });
        }

        $sort = $request->input('sort', 'recent');
        if ($sort === 'name_asc') {
            $query->orderBy('nombre', 'asc');
        } elseif ($sort === 'name_desc') {
            $query->orderBy('nombre', 'desc');
        } else {
            $query->orderBy('id', 'desc');
        }

        if ($request->boolean('paginate')) {
            $perPage = $request->input('per_page', 20);
            return response()->json($query->paginate($perPage));
        }

        return response()->json($query->get());
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'id_cliente_externo' => 'required|string|unique:ledhouse_clientes,id_cliente_externo',
            'nombre' => 'required|string',
            'whatsapp' => 'nullable|string',
            'direccion' => 'nullable|string',
            'tipo_documento' => 'nullable|string|in:Cédula,RNC',
            'documento' => 'nullable|string',
            'limite_credito' => 'nullable|numeric',
            'dias_credito' => 'nullable|integer',
            'latitud' => 'nullable|numeric',
            'longitud' => 'nullable|numeric',
        ]);

        $cliente = LedhouseCliente::create($validated);

        return response()->json($cliente, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $cliente = LedhouseCliente::findOrFail($id);
        return response()->json($cliente);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $cliente = LedhouseCliente::findOrFail($id);

        $validated = $request->validate([
            'id_cliente_externo' => 'required|string|unique:ledhouse_clientes,id_cliente_externo,' . $id,
            'nombre' => 'required|string',
            'whatsapp' => 'nullable|string',
            'direccion' => 'nullable|string',
            'tipo_documento' => 'nullable|string|in:Cédula,RNC',
            'documento' => 'nullable|string',
            'limite_credito' => 'nullable|numeric',
            'dias_credito' => 'nullable|integer',
            'latitud' => 'nullable|numeric',
            'longitud' => 'nullable|numeric',
        ]);

        $cliente->update($validated);

        return response()->json($cliente);
    }

    /**
     * Import records from Excel
     * Omite clientes duplicados (mismo id_cliente_externo o mismo nombre).
     */
    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls,csv'
        ]);

        $file = $request->file('file');

        try {
            $spreadsheet = \PhpOffice\PhpSpreadsheet\IOFactory::load($file->getPathname());
            $worksheet = $spreadsheet->getActiveSheet();
            $rows = $worksheet->toArray();

            // Assuming first row is header
            $header = array_shift($rows);

            $importedCount  = 0;
            $skippedCount   = 0;
            $skippedDetails = [];

            foreach ($rows as $index => $row) {
                $id_cliente_externo = isset($row[0]) ? trim((string)$row[0]) : null;
                $nombre             = isset($row[1]) ? trim((string)$row[1]) : null;
                $whatsapp           = isset($row[2]) ? trim((string)$row[2]) : null;
                $direccion          = isset($row[3]) ? trim((string)$row[3]) : null;
                $limite_credito     = isset($row[4]) ? trim((string)$row[4]) : null;
                $dias_credito       = isset($row[5]) ? trim((string)$row[5]) : null;
                $tipo_documento     = isset($row[6]) ? trim((string)$row[6]) : null;
                $documento          = isset($row[7]) ? trim((string)$row[7]) : null;

                // Campos opcionales vacíos => null
                $whatsapp  = ($whatsapp  !== '') ? $whatsapp  : null;
                $direccion = ($direccion !== '') ? $direccion : null;
                $documento = ($documento !== '') ? $documento : null;

                if ($tipo_documento !== '') {
                    $lower_tipo = strtolower($tipo_documento);
                    if ($lower_tipo === 'cedula' || $lower_tipo === 'cédula') {
                        $tipo_documento = 'Cédula';
                    } elseif ($lower_tipo === 'rnc') {
                        $tipo_documento = 'RNC';
                    } else {
                        $tipo_documento = null;
                    }
                } else {
                    $tipo_documento = null;
                }

                $limite_credito = ($limite_credito !== '' && is_numeric($limite_credito)) ? (float)$limite_credito : 0;
                $dias_credito   = ($dias_credito   !== '' && is_numeric($dias_credito))   ? (int)$dias_credito   : 0;

                // Omitir filas sin datos obligatorios
                if (!$id_cliente_externo || !$nombre) {
                    continue;
                }

                // Verificar si ya existe un cliente con el mismo id_cliente_externo O el mismo nombre
                $existe = LedhouseCliente::where('id_cliente_externo', $id_cliente_externo)
                    ->orWhereRaw('LOWER(nombre) = ?', [strtolower($nombre)])
                    ->first();

                if ($existe) {
                    // Cliente duplicado: omitir y registrar detalle
                    $skippedCount++;
                    $razon = ($existe->id_cliente_externo === $id_cliente_externo)
                        ? 'ID externo duplicado'
                        : 'Nombre duplicado';
                    $skippedDetails[] = [
                        'fila'               => $index + 2, // +2 porque se quitó la cabecera y Excel es base 1
                        'id_cliente_externo' => $id_cliente_externo,
                        'nombre'             => $nombre,
                        'razon'              => $razon,
                    ];
                    continue;
                }

                // Crear nuevo cliente
                LedhouseCliente::create([
                    'id_cliente_externo' => $id_cliente_externo,
                    'nombre'             => $nombre,
                    'whatsapp'           => $whatsapp,
                    'direccion'          => $direccion,
                    'tipo_documento'     => $tipo_documento,
                    'documento'          => $documento,
                    'limite_credito'     => $limite_credito,
                    'dias_credito'       => $dias_credito,
                ]);

                $importedCount++;
            }

            return response()->json([
                'message'          => "Importación completada. $importedCount creados, $skippedCount omitidos por duplicado.",
                'creados'          => $importedCount,
                'omitidos'         => $skippedCount,
                'omitidos_detalle' => $skippedDetails,
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Error al importar: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $cliente = LedhouseCliente::findOrFail($id);
        $cliente->delete();

        return response()->json(null, 204);
    }
}

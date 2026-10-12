<?php

namespace App\Modules\Cliente\Imports;

use App\Modules\Cliente\Models\Cliente;
use PhpOffice\PhpSpreadsheet\IOFactory;

class ClientesImport
{
    public function import($file): array
    {
        $spreadsheet = IOFactory::load($file->getPathname());
        $worksheet = $spreadsheet->getActiveSheet();
        $rows = $worksheet->toArray();

        // Asumimos primera fila cabecera
        array_shift($rows);

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
            $existe = Cliente::where('id_cliente_externo', $id_cliente_externo)
                ->orWhereRaw('LOWER(nombre) = ?', [strtolower($nombre)])
                ->first();

            if ($existe) {
                $skippedCount++;
                $razon = ($existe->id_cliente_externo === $id_cliente_externo)
                    ? 'ID externo duplicado'
                    : 'Nombre duplicado';
                $skippedDetails[] = [
                    'fila'               => $index + 2,
                    'id_cliente_externo' => $id_cliente_externo,
                    'nombre'             => $nombre,
                    'razon'              => $razon,
                ];
                continue;
            }

            // Crear nuevo cliente
            Cliente::create([
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

        return [
            'message'          => "Importación completada. $importedCount creados, $skippedCount omitidos por duplicado.",
            'creados'          => $importedCount,
            'omitidos'         => $skippedCount,
            'omitidos_detalle' => $skippedDetails,
        ];
    }
}

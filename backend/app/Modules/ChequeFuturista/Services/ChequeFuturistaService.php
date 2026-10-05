<?php

namespace App\Modules\ChequeFuturista\Services;

use App\Models\User;
use App\Modules\ChequeFuturista\Enums\EstadoCheque;
use App\Modules\ChequeFuturista\Enums\TipoArchivoDocumento;
use App\Modules\ChequeFuturista\Models\ChequeFuturista;
use App\Modules\ChequeFuturista\Models\DocumentoCheque;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use App\Helpers\TextNormalizer;

class ChequeFuturistaService
{
    // ── CRUD Cheques ──────────────────────────────────────────

    public function obtenerListadoFiltrado(array $filtros, int $idVendedor)
    {
        $query = ChequeFuturista::query()
            ->with(['cliente:id,nombre', 'vendedor:id,name', 'creador:id,name']);

        // 1. Filtrar por el vendedor logueado
        $query->where('id_vendedor', $idVendedor);

        // 2. Filtros
        if (!empty($filtros['buscar'])) {
            // Normalizar el texto de búsqueda (quita acentos, convierte a minúsculas, etc.)
            $buscar = TextNormalizer::normalize($filtros['buscar']);
            // Quitar espacios extra
            $buscar = preg_replace('/\s+/', ' ', $buscar);
            
            $query->where(function($q) use ($buscar) {
                $q->whereHas('cliente', function ($sub) use ($buscar) {
                    $sub->whereRaw('LOWER(nombre) LIKE ?', ['%' . $buscar . '%']);
                })->orWhereRaw('LOWER(num_cheque) LIKE ?', ['%' . $buscar . '%']);
            });
        }

        if (!empty($filtros['estado'])) {
            $query->where('estado', $filtros['estado']);
        }

        if (!empty($filtros['id_cliente'])) {
            $query->where('id_cliente', $filtros['id_cliente']);
        }

        // 3. Rango de Fechas, Atrasados o Regla por Defecto
        $atrasados = filter_var($filtros['atrasados'] ?? false, FILTER_VALIDATE_BOOLEAN);

        $tipoFecha = $filtros['tipo_fecha'] ?? 'creacion';
        $columnaFecha = $tipoFecha === 'deposito' ? 'fecha_deposito' : 'created_at';

        if ($atrasados) {
            $query->where('created_at', '<', now()->subDays(20));
        } elseif (!empty($filtros['fecha_inicio']) && !empty($filtros['fecha_fin'])) {
            $query->whereBetween($columnaFecha, [
                $filtros['fecha_inicio'] . ' 00:00:00', 
                $filtros['fecha_fin'] . ' 23:59:59'
            ]);
        } else {
            // Por defecto: todos los pendientes + cualquier estado pero solo del mes actual
            $query->where(function ($q) {
                $q->where('estado', EstadoCheque::Pendiente->value)
                  ->orWhere(function ($sub) {
                      $sub->whereMonth('created_at', now()->month)
                          ->whereYear('created_at', now()->year);
                  });
            });
        }

        $perPage = $filtros['per_page'] ?? 20;
        $montoTotal = (float) $query->sum('monto');
        $paginator = $query->orderByRaw('fecha_deposito IS NULL')->orderBy('fecha_deposito', 'asc')->paginate($perPage);

        $resultado = $paginator->toArray();
        $resultado['resumen_filtro'] = [
            'total_filas' => $paginator->total(),
            'monto_total' => $montoTotal,
        ];

        return $resultado;
    }

    /**
     * Listado global para gestión contable/administrativa.
     * Igual que obtenerListadoFiltrado pero sin restricción por vendedor.
     * Incluye filtro opcional por id_vendedor para buscar por vendedor específico.
     */
    public function obtenerListadoAdmin(array $filtros): array
    {
        $query = ChequeFuturista::query()
            ->with(['cliente:id,nombre', 'vendedor:id,name', 'creador:id,name']);

        // 1. Filtros de búsqueda
        if (!empty($filtros['buscar'])) {
            $buscar = TextNormalizer::normalize($filtros['buscar']);
            $buscar = preg_replace('/\s+/', ' ', $buscar);

            $query->where(function ($q) use ($buscar) {
                $q->whereHas('cliente', function ($sub) use ($buscar) {
                    $sub->whereRaw('LOWER(nombre) LIKE ?', ['%' . $buscar . '%']);
                })->orWhereRaw('LOWER(num_cheque) LIKE ?', ['%' . $buscar . '%']);
            });
        }

        if (!empty($filtros['estado'])) {
            $query->where('estado', $filtros['estado']);
        }

        if (!empty($filtros['id_cliente'])) {
            $query->where('id_cliente', $filtros['id_cliente']);
        }

        // Filtro opcional por vendedor (para admin que quiera ver solo uno)
        if (!empty($filtros['id_vendedor'])) {
            $query->where('id_vendedor', $filtros['id_vendedor']);
        }

        // 2. Rango de Fechas, Atrasados o Regla por Defecto
        $atrasados = filter_var($filtros['atrasados'] ?? false, FILTER_VALIDATE_BOOLEAN);

        $tipoFecha = $filtros['tipo_fecha'] ?? 'creacion';
        $columnaFecha = $tipoFecha === 'deposito' ? 'fecha_deposito' : 'created_at';

        if ($atrasados) {
            $query->where('created_at', '<', now()->subDays(20));
        } elseif (!empty($filtros['fecha_inicio']) && !empty($filtros['fecha_fin'])) {
            $query->whereBetween($columnaFecha, [
                $filtros['fecha_inicio'] . ' 00:00:00',
                $filtros['fecha_fin'] . ' 23:59:59',
            ]);
        } else {
            $query->where(function ($q) {
                $q->where('estado', EstadoCheque::Pendiente->value)
                  ->orWhere(function ($sub) {
                      $sub->whereMonth('created_at', now()->month)
                          ->whereYear('created_at', now()->year);
                  });
            });
        }

        $perPage    = $filtros['per_page'] ?? 20;
        $montoTotal = (float) $query->sum('monto');
        $paginator  = $query->orderByRaw('fecha_deposito IS NULL')->orderBy('fecha_deposito', 'asc')->paginate($perPage);

        $resultado = $paginator->toArray();
        $resultado['resumen_filtro'] = [
            'total_filas' => $paginator->total(),
            'monto_total' => $montoTotal,
        ];

        return $resultado;
    }

    public function crear(array $datos, User $responsable): ChequeFuturista
    {
        $datos['created_by'] = $responsable->id;
        $datos['estado']     = $datos['estado'] ?? EstadoCheque::Pendiente->value;

        return ChequeFuturista::create($datos);
    }

    public function actualizar(ChequeFuturista $cheque, array $datos): ChequeFuturista
    {
        if (isset($datos['estado'])) {
            $nuevo = EstadoCheque::from($datos['estado']);
            $datos['estado'] = $nuevo;
        }

        $cheque->update($datos);
        return $cheque->fresh(['cliente', 'vendedor', 'creador']);
    }

    public function eliminar(ChequeFuturista $cheque): void
    {
        if ($cheque->documentos()->count() > 0) {
            throw new \Exception('No se puede eliminar el cheque. Tiene documentos asociados. Elimínelos primero.');
        }
        $cheque->delete();
    }

    public function resumen(): array
    {
        // Ejecuta una sola consulta agrupada en PostgreSQL
        $totales = ChequeFuturista::select('estado', DB::raw('count(*) as cantidad'))
            ->groupBy('estado')
            ->pluck('cantidad', 'estado')
            ->toArray();

        return [
            'total'      => array_sum($totales),
            'pendiente'  => $totales[EstadoCheque::Pendiente->value] ?? 0,
            'depositado' => $totales[EstadoCheque::Depositado->value] ?? 0,
            'cancelado'  => $totales[EstadoCheque::Cancelado->value] ?? 0,
            'vencido'    => $totales[EstadoCheque::Vencido->value] ?? 0,
        ];
    }

    // ── CRUD Documentos ───────────────────────────────────────

    public function subirDocumento(
        ChequeFuturista $cheque,
        UploadedFile    $archivo,
        User            $responsable
    ): DocumentoCheque {
        $extension = strtolower($archivo->getClientOriginalExtension());
        $ruta = $archivo->store("cheques/{$cheque->id}", 'public');

        return DocumentoCheque::create([
            'cheque_futurista_id' => $cheque->id,
            'nombre_archivo'      => $archivo->getClientOriginalName(),
            'ruta_archivo'        => $ruta,
            'tipo_archivo'        => TipoArchivoDocumento::from($extension),
            'created_by'          => $responsable->id,
        ]);
    }

    public function eliminarDocumento(DocumentoCheque $documento): void
    {
        $ruta = $documento->ruta_archivo;
        
        if ($documento->delete()) {
            Storage::disk('public')->delete($ruta);
        }
    }
}
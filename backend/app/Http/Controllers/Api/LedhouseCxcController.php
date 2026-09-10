<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LedhouseCxc;
use App\Models\LedhouseCxcSoporte;
use App\Models\LedhouseCxcAlerta;
use App\Models\LedhouseCxcEvidencia;
use App\Models\LedhouseCliente;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;

class LedhouseCxcController extends Controller
{
    // ─────────────────────────────────────────────────────────────
    // CRUD Básico
    // ─────────────────────────────────────────────────────────────

    // ─────────────────────────────────────────────────────────────
    // Endpoint Independiente para el Vendedor (Paginado y Filtrado)
    // ─────────────────────────────────────────────────────────────

    public function getMisCxcPaginated(Request $request)
    {
        $user = $request->user();
        if (!$user || !$user->hasRole('vendedor')) {
            return response()->json(['error' => 'No autorizado'], 403);
        }

        $query = LedhouseCxc::with(['cliente'])
            ->withCount(['alertas as alertas_pendientes' => function ($q) {
                $q->where('estado_alerta', 'pendiente');
            }])
            ->where('vendedor_id', $user->id);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('documento', 'like', "%{$search}%")
                  ->orWhereHas('cliente', function($q2) use ($search) {
                      $q2->where('nombre', 'like', "%{$search}%");
                  });
            });
        }

        if ($request->filled('vencidos') && $request->vencidos == '1') {
            $query->where('monto_pendiente', '>', 0)
                  ->where('estado', '!=', 'pagado')
                  ->whereDate('fecha_vencimiento', '<', now()->format('Y-m-d'));
        }

        if ($request->filled('con_alerta') && $request->con_alerta == '1') {
            $query->whereHas('alertas');
        }

        return response()->json($query->orderBy('fecha_vencimiento', 'asc')->paginate($request->per_page ?? 20));
    }

    public function getMisCxcPdfUrl(Request $request)
    {
        $user = $request->user();
        if (!$user || !$user->hasRole('vendedor')) {
            return response()->json(['error' => 'No autorizado'], 403);
        }

        $url = \Illuminate\Support\Facades\URL::temporarySignedRoute(
            'cxc.vendedor.pdf', 
            now()->addMinutes(15), 
            [
                'vendedor_id' => $user->id,
                'search' => $request->search,
                'vencidos' => $request->vencidos,
            ]
        );

        return response()->json(['url' => $url]);
    }

    public function exportMisCxcPdf(Request $request)
    {
        if (!$request->hasValidSignature()) {
            abort(401, 'URL inválida o expirada.');
        }

        $vendedorId = $request->vendedor_id;
        $user = \App\Models\User::findOrFail($vendedorId);

        $query = LedhouseCxc::with(['cliente'])
            ->where('vendedor_id', $user->id);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('documento', 'like', "%{$search}%")
                  ->orWhereHas('cliente', function($q2) use ($search) {
                      $q2->where('nombre', 'like', "%{$search}%");
                  });
            });
        }

        $isVencidos = false;
        if ($request->filled('vencidos') && $request->vencidos == '1') {
            $isVencidos = true;
            $query->where('monto_pendiente', '>', 0)
                  ->where('estado', '!=', 'pagado')
                  ->whereDate('fecha_vencimiento', '<', now()->format('Y-m-d'));
        }

        $cxcs = $query->orderBy('fecha_vencimiento', 'asc')->get();

        $pdf = Pdf::loadView('pdf.cxc_vendedor', [
            'cxcs' => $cxcs,
            'vendedor' => $user,
            'isVencidos' => $isVencidos,
            'search' => $request->search
        ]);

        return $pdf->stream("Reporte_Mis_CXC.pdf");
    }

    public function index(Request $request)
    {
        $query = LedhouseCxc::with(['cliente', 'vendedor'])
            ->withCount('soportes as total_intervenciones')
            ->withMax('soportes as ultima_fecha_visita', 'fecha_visita')
            ->withCount(['alertas as alertas_pendientes' => function ($q) {
                $q->where('estado_alerta', 'pendiente');
            }]);

        // Si el usuario es vendedor, filtrar solo sus CXC
        $user = $request->user();
        if ($user && $user->hasRole('vendedor')) {
            $query->where('vendedor_id', $user->id);
        }

        // Filtro opcional por vendedor (para contabilidad)
        if ($request->has('vendedor_id')) {
            $query->where('vendedor_id', $request->vendedor_id);
        }

        return response()->json($query->orderBy('created_at', 'desc')->get());
    }

    public function groupedByCliente()
    {
        $clientes = \App\Models\LedhouseCliente::withSum('cxcs as total_facturado', 'monto_factura')
            ->withSum('cxcs as total_pendiente', 'monto_pendiente')
            ->get();
        return response()->json($clientes);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'documento'        => 'required|string|max:255',
            'cliente_id'       => 'required|exists:ledhouse_clientes,id',
            'vendedor_id'      => 'nullable|exists:users,id',
            'monto_factura'    => 'nullable|numeric|min:0',
            'monto_pagado'     => 'nullable|numeric|min:0',
            'fecha_factura'    => 'nullable|date',
            'fecha_vencimiento'=> 'required|date',
            'estado'           => 'nullable|string|in:pendiente,pagado,cancelado',
        ]);

        $pagado   = $validated['monto_pagado'] ?? 0;
        $pendiente = $validated['monto_factura'] - $pagado;

        $cxc = LedhouseCxc::create(array_merge($validated, [
            'monto_pagado'   => $pagado,
            'monto_pendiente'=> $pendiente,
            'estado'         => $validated['estado'] ?? 'pendiente',
        ]));

        return response()->json($cxc, 201);
    }

    public function show(LedhouseCxc $cxc)
    {
        $cxc->load(['soportes', 'alertas.vendedor', 'alertas.evidencias', 'evidencias.subidoPor', 'cliente', 'vendedor']);
        return response()->json($cxc);
    }

    public function update(Request $request, LedhouseCxc $cxc)
    {
        $validated = $request->validate([
            'documento'        => 'sometimes|string|max:255',
            'cliente_id'       => 'sometimes|exists:ledhouse_clientes,id',
            'vendedor_id'      => 'nullable|exists:users,id',
            'monto_factura'    => 'nullable|numeric|min:0',
            'monto_pagado'     => 'sometimes|numeric|min:0',
            'fecha_factura'    => 'sometimes|nullable|date',
            'fecha_vencimiento'=> 'sometimes|date',
            'estado'           => 'sometimes|string|in:pendiente,pagado,cancelado',
        ]);

        if (isset($validated['monto_factura']) || isset($validated['monto_pagado'])) {
            $factura  = $validated['monto_factura'] ?? $cxc->monto_factura;
            $pagado   = $validated['monto_pagado'] ?? $cxc->monto_pagado;
            $validated['monto_pendiente'] = $factura - $pagado;
        }

        $cxc->update($validated);
        return response()->json($cxc);
    }

    public function destroy(LedhouseCxc $cxc)
    {
        $cxc->delete();
        return response()->json(null, 204);
    }

    // ─────────────────────────────────────────────────────────────
    // PDF Reports
    // ─────────────────────────────────────────────────────────────

    public function reportePdf($cliente_id)
    {
        $cliente = LedhouseCliente::findOrFail($cliente_id);
        $cxcs    = LedhouseCxc::where('cliente_id', $cliente_id)->get();

        $pdf = Pdf::loadView('pdf.example_temp_url', [
            'cliente'  => $cliente,
            'cxcs'     => $cxcs,
            'imageUrl' => null,
        ]);

        return $pdf->stream("Reporte_CXC_{$cliente->nombre}.pdf");
    }

    public function getReporteGeneralPdfUrl(Request $request)
    {
        $url = \Illuminate\Support\Facades\URL::temporarySignedRoute(
            'cxc.general.pdf', 
            now()->addMinutes(15)
        );
        return response()->json(['url' => $url]);
    }

    public function getReporteAgrupadoPdfUrl(Request $request)
    {
        $url = \Illuminate\Support\Facades\URL::temporarySignedRoute(
            'cxc.agrupado.pdf', 
            now()->addMinutes(15)
        );
        return response()->json(['url' => $url]);
    }

    public function reporteGeneralPdf(Request $request)
    {
        if (!$request->hasValidSignature()) {
            abort(401, 'URL inválida o expirada.');
        }

        $cxcs = LedhouseCxc::with('cliente')->orderBy('fecha_vencimiento', 'asc')->get();
        $pdf  = Pdf::loadView('pdf.cxc_general', ['cxcs' => $cxcs]);
        return $pdf->stream("Reporte_General_CXC.pdf");
    }

    public function reporteAgrupadoPdf(Request $request)
    {
        if (!$request->hasValidSignature()) {
            abort(401, 'URL inválida o expirada.');
        }

        $clientes = LedhouseCliente::withSum('cxcs as total_facturado', 'monto_factura')
            ->withSum('cxcs as total_pendiente', 'monto_pendiente')
            ->get()
            ->filter(fn($c) => $c->total_pendiente > 0);

        $pdf = Pdf::loadView('pdf.cxc_agrupado', ['clientes' => $clientes]);
        return $pdf->stream("Reporte_Agrupado_CXC.pdf");
    }

    // ─────────────────────────────────────────────────────────────
    // Sync Masivo (Preview + Confirm) — SAFE MODE
    // ─────────────────────────────────────────────────────────────

    /**
     * Fase 1: Analiza el Excel sin escribir en la BD.
     * Retorna un preview con errores, nuevos y actualizaciones.
     */
    public function syncPreview(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls,csv',
            'vendedor_id' => 'nullable|exists:users,id',
        ]);

        $vendedor   = $request->user();
        if ($request->has('vendedor_id') && $vendedor->hasRole('admin')) {
            $vendedor = \App\Models\User::find($request->vendedor_id);
            if (!$vendedor) {
                return response()->json(['message' => 'Vendedor no encontrado'], 404);
            }
        }
        $file       = $request->file('file');
        $spreadsheet = \PhpOffice\PhpSpreadsheet\IOFactory::load($file->getPathname());
        $rows        = $spreadsheet->getActiveSheet()->toArray();
        array_shift($rows); // Ignorar encabezado

        $errores       = [];
        $nuevos        = [];
        $actualizaciones = [];

        foreach ($rows as $index => $row) {
            $fila = $index + 2; // +2 por encabezado y 0-index
            $id_ext   = isset($row[0]) ? trim((string)$row[0]) : null;
            $documento = isset($row[1]) ? trim((string)$row[1]) : null;
            $monto    = isset($row[2]) ? trim((string)$row[2]) : null;
            $fecha    = isset($row[3]) ? trim((string)$row[3]) : null;

            if (empty($id_ext) || empty($documento)) {
                $errores[] = ['fila' => $fila, 'razon' => 'ID externo o documento vacío'];
                continue;
            }

            // Buscar cliente
            $cliente = LedhouseCliente::where('id_cliente_externo', $id_ext)->first();
            if (!$cliente) {
                $errores[] = [
                    'fila'  => $fila,
                    'id_ext'=> $id_ext,
                    'razon' => "Cliente con ID externo '{$id_ext}' no encontrado en el sistema.",
                ];
                continue;
            }

            // Buscar si el documento ya existe para este cliente
            $cxcExistente = LedhouseCxc::where('documento', $documento)
                ->where('cliente_id', $cliente->id)
                ->first();

            $item = [
                'fila'          => $fila,
                'id_ext'        => $id_ext,
                'cliente_nombre'=> $cliente->nombre,
                'cliente_id'    => $cliente->id,
                'documento'     => $documento,
                'monto_pendiente'=> (float)$monto,
                'fecha_factura' => $fecha,
            ];

            if ($cxcExistente) {
                $item['cxc_id'] = $cxcExistente->id;
                $item['monto_anterior'] = $cxcExistente->monto_pendiente;
                $actualizaciones[] = $item;
            } else {
                $nuevos[] = $item;
            }
        }

        return response()->json([
            'resumen' => [
                'total_filas'    => count($rows),
                'errores'        => count($errores),
                'nuevos'         => count($nuevos),
                'actualizaciones'=> count($actualizaciones),
            ],
            'errores'        => $errores,
            'nuevos'         => $nuevos,
            'actualizaciones'=> $actualizaciones,
        ]);
    }

    /**
     * Fase 2: Ejecuta la sincronización en una transacción atómica.
     * Si algo falla, hace rollback total.
     */
    public function syncConfirm(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls,csv',
            'vendedor_id' => 'nullable|exists:users,id',
        ]);

        $vendedor    = $request->user();
        if ($request->has('vendedor_id') && $vendedor->hasRole('admin')) {
            $vendedor = \App\Models\User::find($request->vendedor_id);
            if (!$vendedor) {
                return response()->json(['message' => 'Vendedor no encontrado'], 404);
            }
        }
        $file        = $request->file('file');
        $spreadsheet = \PhpOffice\PhpSpreadsheet\IOFactory::load($file->getPathname());
        $rows        = $spreadsheet->getActiveSheet()->toArray();
        array_shift($rows);

        $creados     = 0;
        $actualizados = 0;
        $omitidos    = 0;
        $errores     = [];

        try {
            DB::transaction(function () use ($rows, $vendedor, &$creados, &$actualizados, &$omitidos, &$errores) {
                foreach ($rows as $index => $row) {
                    $fila     = $index + 2;
                    $id_ext   = isset($row[0]) ? trim((string)$row[0]) : null;
                    $documento = isset($row[1]) ? trim((string)$row[1]) : null;
                    $monto    = isset($row[2]) ? trim((string)$row[2]) : null;
                    $fecha    = isset($row[3]) ? trim((string)$row[3]) : null;

                    if (empty($id_ext) || empty($documento)) {
                        $omitidos++;
                        continue;
                    }

                    $cliente = LedhouseCliente::where('id_cliente_externo', $id_ext)->first();
                    if (!$cliente) {
                        $errores[] = ['fila' => $fila, 'id_ext' => $id_ext, 'razon' => 'Cliente no encontrado'];
                        $omitidos++;
                        continue;
                    }

                    $monto = is_numeric($monto) ? (float)$monto : 0;
                    $estado = $monto <= 0 ? 'pagado' : 'pendiente';

                    try {
                        $fechaObj           = Carbon::parse($fecha);
                        $fecha_factura_db   = $fechaObj->format('Y-m-d');
                        $dias_credito       = $cliente->dias_credito ?? 0;
                        $fecha_vencimiento  = $fechaObj->copy()->addDays($dias_credito)->format('Y-m-d');
                    } catch (\Exception $e) {
                        $fecha_factura_db  = now()->format('Y-m-d');
                        $fecha_vencimiento = now()->format('Y-m-d');
                    }

                    $existing = LedhouseCxc::where('documento', $documento)
                        ->where('cliente_id', $cliente->id)
                        ->first();

                    if ($existing) {
                        $existing->update([
                            'monto_pendiente'  => $monto,
                            'fecha_factura'    => $fecha_factura_db,
                            'fecha_vencimiento'=> $fecha_vencimiento,
                            'estado'           => $estado,
                            'vendedor_id'      => $vendedor->id,
                        ]);
                        $actualizados++;
                    } else {
                        LedhouseCxc::create([
                            'documento'        => $documento,
                            'cliente_id'       => $cliente->id,
                            'vendedor_id'      => $vendedor->id,
                            'monto_factura'    => $monto,
                            'monto_pagado'     => 0,
                            'monto_pendiente'  => $monto,
                            'fecha_factura'    => $fecha_factura_db,
                            'fecha_vencimiento'=> $fecha_vencimiento,
                            'estado'           => $estado,
                        ]);
                        $creados++;
                    }
                }
            });

            return response()->json([
                'message'      => "Sincronización completada exitosamente.",
                'creados'      => $creados,
                'actualizados' => $actualizados,
                'omitidos'     => $omitidos,
                'errores'      => $errores,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Error durante la sincronización. Se realizó rollback. Detalle: ' . $e->getMessage(),
            ], 500);
        }
    }

    // ─────────────────────────────────────────────────────────────
    // Alertas del Vendedor
    // ─────────────────────────────────────────────────────────────

    /**
     * Lista todas las alertas (para contabilidad) o filtradas por vendedor.
     */
    public function getAlertas(Request $request)
    {
        $query = LedhouseCxcAlerta::with(['cxc.cliente', 'cxc.evidencias', 'vendedor', 'evidencias', 'revisador'])
            ->orderBy('created_at', 'desc');

        $user = $request->user();
        if ($user && $user->hasRole('vendedor')) {
            $query->where('vendedor_id', $user->id)
                  ->where('estado_alerta', '!=', 'procesada');
        }

        if ($request->has('estado')) {
            $query->where('estado_alerta', $request->estado);
        }

        return response()->json($query->get());
    }

    /**
     * Genera un reporte en PDF de las alertas (con filtros).
     */
    public function reporteAlertasPdf(Request $request)
    {
        $query = LedhouseCxcAlerta::with(['cxc.cliente', 'vendedor'])
            ->orderBy('created_at', 'desc');

        $user = $request->user();
        if ($user && $user->hasRole('vendedor')) {
            $query->where('vendedor_id', $user->id);
        } elseif ($request->has('vendedor_id')) {
            $query->where('vendedor_id', $request->vendedor_id);
        }

        if ($request->has('estado')) {
            $query->where('estado_alerta', $request->estado);
        }

        if ($request->has('cliente_id')) {
            $query->whereHas('cxc', function ($q) use ($request) {
                $q->where('cliente_id', $request->cliente_id);
            });
        }

        if ($request->has('tipo')) {
            $query->where('tipo', $request->tipo);
        }

        $alertas = $query->get();

        $totalInformado = $alertas->sum('monto_informado');
        
        $cxcQuery = \App\Models\LedhouseCxc::query();
        if ($user && $user->hasRole('vendedor')) {
            $cxcQuery->where('vendedor_id', $user->id);
        } elseif ($request->has('vendedor_id')) {
            $cxcQuery->where('vendedor_id', $request->vendedor_id);
        }
        if ($request->has('cliente_id')) {
            $cxcQuery->where('cliente_id', $request->cliente_id);
        }
        
        $totalPendiente = $cxcQuery->sum('monto_pendiente');
        
        $montoReal = $totalPendiente - $totalInformado;

        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('pdf.alertas_vendedores', [
            'alertas' => $alertas,
            'totalInformado' => $totalInformado,
            'totalPendiente' => $totalPendiente,
            'montoReal' => $montoReal,
            'estado' => $request->estado ?? 'todas',
        ])->setPaper('a4', 'landscape');

        return $pdf->stream('Reporte_Alertas_' . date('Ymd_His') . '.pdf');
    }

    /**
     * El vendedor agrega una alerta a uno de sus CXC.
     */
    public function addAlerta(Request $request, LedhouseCxc $cxc)
    {
        $user = $request->user();

        // Verificar que el CXC pertenece al vendedor (o es admin/contabilidad)
        if ($user->hasRole('vendedor') && $cxc->vendedor_id !== $user->id) {
            return response()->json(['error' => 'No tienes permiso para alertar este documento.'], 403);
        }

        $validated = $request->validate([
            'tipo'            => 'required|string|max:50',
            'monto_informado' => 'nullable|numeric|min:0',
            'nota'            => 'required|string|max:1000',
        ]);

        $alerta = LedhouseCxcAlerta::create([
            'ledhouse_cxc_id' => $cxc->id,
            'vendedor_id'     => $user->id,
            'tipo'            => $validated['tipo'],
            'monto_informado' => $validated['monto_informado'] ?? null,
            'nota'            => $validated['nota'],
            'estado_alerta'   => 'pendiente',
        ]);

        return response()->json($alerta->load('vendedor'), 201);
    }

    /**
     * Contabilidad procesa/resuelve una alerta.
     */
    public function resolverAlerta(Request $request, LedhouseCxcAlerta $alerta)
    {
        $validated = $request->validate([
            'estado_alerta' => 'required|in:revisada,procesada',
            // Si contabilidad quiere actualizar el CXC al mismo tiempo:
            'actualizar_cxc'   => 'nullable|boolean',
            'monto_pagado'     => 'nullable|numeric|min:0',
            'estado_cxc'       => 'nullable|in:pendiente,pagado,cancelado',
        ]);

        $user = $request->user();

        $alerta->update([
            'estado_alerta'  => $validated['estado_alerta'],
            'revisada_por'   => $user->id,
            'fecha_revision' => now(),
        ]);

        // Actualizar el CXC si se solicita
        if (!empty($validated['actualizar_cxc'])) {
            $cxc = $alerta->cxc;
            $updates = [];

            if (isset($validated['monto_pagado'])) {
                $updates['monto_pagado']   = $validated['monto_pagado'];
                $updates['monto_pendiente'] = $cxc->monto_factura - $validated['monto_pagado'];
            }
            if (isset($validated['estado_cxc'])) {
                $updates['estado'] = $validated['estado_cxc'];
            }

            if (!empty($updates)) {
                $cxc->update($updates);
            }
        }

        return response()->json($alerta->load(['vendedor', 'revisador']));
    }

    /**
     * Eliminar una alerta.
     */
    public function destroyAlerta(Request $request, LedhouseCxcAlerta $alerta)
    {
        $user = $request->user();

        // Validar permisos (solo contabilidad/admin o el propio vendedor pueden borrarla)
        if ($user->hasRole('vendedor') && $alerta->vendedor_id !== $user->id) {
            return response()->json(['error' => 'No tienes permiso para eliminar esta alerta.'], 403);
        }

        // Buscar evidencias asociadas directamente a la alerta, 
        // o asociadas al documento CXC pero sin alerta_id
        $evidencias = \App\Models\LedhouseCxcEvidencia::where('alerta_id', $alerta->id)
            ->orWhere(function($query) use ($alerta) {
                $query->where('ledhouse_cxc_id', $alerta->ledhouse_cxc_id)
                      ->whereNull('alerta_id');
            })->get();

        // Eliminar archivos físicos del disco 'public'
        foreach ($evidencias as $ev) {
            if (\Illuminate\Support\Facades\Storage::disk('public')->exists($ev->ruta_archivo)) {
                \Illuminate\Support\Facades\Storage::disk('public')->delete($ev->ruta_archivo);
            }
            $ev->delete();
        }

        $alerta->delete();

        return response()->json(['message' => 'Alerta y documentos eliminados exitosamente.']);
    }

    // ─────────────────────────────────────────────────────────────
    // Evidencias (Archivos PDF/JPG)
    // ─────────────────────────────────────────────────────────────

    /**
     * Sube un archivo de evidencia asociado a una alerta o un CXC.
     */
    public function uploadEvidencia(Request $request, LedhouseCxc $cxc)
    {
        $request->validate([
            'file'      => 'required|file|mimes:pdf,jpg,jpeg,png|max:10240',
            'alerta_id' => 'nullable|exists:ledhouse_cxc_alertas,id',
        ]);

        $user = $request->user();
        $file = $request->file('file');
        $ext  = strtolower($file->getClientOriginalExtension());

        $path = $file->store("cxc-evidencias/{$cxc->id}", 'public');

        $evidencia = LedhouseCxcEvidencia::create([
            'ledhouse_cxc_id' => $cxc->id,
            'alerta_id'       => $request->alerta_id ?? null,
            'subido_por'      => $user->id,
            'nombre_archivo'  => $file->getClientOriginalName(),
            'ruta_archivo'    => $path,
            'tipo_archivo'    => $ext,
        ]);

        return response()->json($evidencia->load('subidoPor'), 201);
    }

    /**
     * Lista las evidencias de un CXC.
     */
    public function getEvidencias(LedhouseCxc $cxc)
    {
        return response()->json(
            $cxc->evidencias()->with('subidoPor')->orderBy('created_at', 'desc')->get()
        );
    }

    // ─────────────────────────────────────────────────────────────
    // Soportes (existentes — para contabilidad)
    // ─────────────────────────────────────────────────────────────

    public function getSoportes(LedhouseCxc $cxc)
    {
        return response()->json($cxc->soportes()->orderBy('fecha', 'desc')->get());
    }

    public function addSoporte(Request $request, LedhouseCxc $cxc)
    {
        $validated = $request->validate([
            'nota'        => 'required|string',
            'fecha'       => 'required|date',
            'fecha_visita'=> 'nullable|date',
        ]);

        $soporte = $cxc->soportes()->create($validated);
        return response()->json($soporte, 201);
    }

    // ─────────────────────────────────────────────────────────────
    // Importación por cliente (legacy — se mantiene)
    // ─────────────────────────────────────────────────────────────

    public function importByCliente(Request $request, $cliente_id)
    {
        $request->validate(['file' => 'required|file|mimes:xlsx,xls,csv']);

        $file = $request->file('file');

        try {
            $spreadsheet = \PhpOffice\PhpSpreadsheet\IOFactory::load($file->getPathname());
            $rows        = $spreadsheet->getActiveSheet()->toArray();
            array_shift($rows);

            $importedCount = 0;
            $cliente       = LedhouseCliente::find($cliente_id);
            $dias_credito  = $cliente ? ($cliente->dias_credito ?? 0) : 0;

            foreach ($rows as $row) {
                $documento     = isset($row[0]) ? trim((string)$row[0]) : null;
                $monto         = isset($row[1]) ? trim((string)$row[1]) : null;
                $fecha_factura = isset($row[2]) ? trim((string)$row[2]) : null;
                $monto_factura = isset($row[3]) ? trim((string)$row[3]) : null;

                if ($documento && $monto !== null && $fecha_factura) {
                    $monto         = (float)$monto;
                    $monto_factura = ($monto_factura !== '' && is_numeric($monto_factura)) ? (float)$monto_factura : null;
                    $estado        = $monto <= 0 ? 'pagado' : 'pendiente';

                    try {
                        $fechaObj             = Carbon::parse($fecha_factura);
                        $fecha_factura_db     = $fechaObj->format('Y-m-d');
                        $fecha_vencimiento_db = $fechaObj->copy()->addDays($dias_credito)->format('Y-m-d');
                    } catch (\Exception $e) {
                        $fecha_factura_db     = $fecha_factura;
                        $fecha_vencimiento_db = $fecha_factura;
                    }

                    LedhouseCxc::updateOrCreate(
                        ['documento' => $documento, 'cliente_id' => $cliente_id],
                        [
                            'monto_pendiente'  => $monto,
                            'monto_factura'    => $monto_factura,
                            'fecha_factura'    => $fecha_factura_db,
                            'fecha_vencimiento'=> $fecha_vencimiento_db,
                            'estado'           => $estado,
                            'monto_pagado'     => $estado === 'pagado' ? ($monto_factura ?? 0) : 0,
                        ]
                    );
                    $importedCount++;
                }
            }

            return response()->json(['message' => "Importado exitosamente. $importedCount registros procesados."]);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Error al importar: ' . $e->getMessage()], 500);
        }
    }
}

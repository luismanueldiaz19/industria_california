<?php

namespace App\Modules\CamionVictual\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\CamionVictual\Enums\EstadoEntrega;
use App\Modules\CamionVictual\Models\CamionVictual;
use App\Modules\CamionVictual\Http\Requests\StoreCamionVictualRequest;
use App\Modules\CamionVictual\Services\CamionVictualService;
use App\Services\PdfSecurityService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CamionVictualController extends Controller
{
    public function __construct(
        private readonly CamionVictualService $service
    ) {}

    /**
     * Listar camiones victuales.
     * - Vendedor: ve todos los camiones activos (para poder llenarlos).
     * - Admin/Logística: ve todos con filtros.
     */
    public function index(Request $request): JsonResponse
    {
        $user = Auth::user();

        $query = CamionVictual::with([
            'chofer.user:id,name',
            'vendedor:id,name',
        ]);

        // Si es vendedor y no es admin, solo ve sus camiones
        if ($user && $user->hasRole('vendedor') && !$user->hasRole('admin')) {
            $query->where('vendedor_id', $user->id);
        }

        if ($request->filled('chofer_id')) {
            $query->where('chofer_id', $request->chofer_id);
        }

        if ($request->filled('estado') && $request->estado !== 'todos') {
            $query->where('estado', $request->estado);
        }

        if ($request->boolean('with_pedidos')) {
            $query->with(['pedidos' => function ($q) {
                $q->with('cliente:id,nombre')
                  ->orderByPivot('orden_viaje', 'asc');
            }]);
        }

        return response()->json($query->orderBy('chofer_id')->orderBy('slot_numero')->get());
    }

    /**
     * Crear un nuevo camión victual para un chofer.
     */
    public function store(StoreCamionVictualRequest $request): JsonResponse
    {
        try {
            $camion = $this->service->crear($request->validated(), Auth::user());
            return response()->json($camion->load('chofer.user', 'vendedor'), 201);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Actualizar un camión victual.
     */
    public function update(Request $request, CamionVictual $camionVictual): JsonResponse
    {
        $datos = $request->validate([
            'nombre'      => 'nullable|string|max:255',
            'notas'       => 'nullable|string',
            'chofer_id'   => 'nullable|exists:choferes,id',
            'vendedor_id' => 'nullable|exists:users,id',
            'estado'      => 'nullable|in:vacio,armando,listo,en_ruta,cerrado',
            'minimo_salida' => 'nullable|numeric|min:0',
        ]);

        try {
            $camion = $this->service->actualizar($camionVictual, $datos);
            return response()->json($camion->refresh()->load('chofer.user', 'vendedor'), 200);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Eliminar un camión victual.
     */
    public function destroy(CamionVictual $camionVictual): JsonResponse
    {
        try {
            $this->service->eliminar($camionVictual);
            return response()->json(null, 204);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Ver un camión con todos sus pedidos ordenados por orden_viaje.
     */
    public function show(CamionVictual $camionVictual): JsonResponse
    {
        return response()->json(
            $camionVictual->load([
                'chofer.user:id,name',
                'vendedor:id,name',
                'pedidos' => function ($q) {
                    $q->with('cliente:id,nombre,direccion')
                      ->orderByPivot('orden_viaje', 'asc');
                },
            ])
        );
    }

    /**
     * Agregar un pedido al camión.
     * Solo el vendedor o admin pueden hacerlo.
     * Solo pedidos en estado 'facturado' y sin camión activo.
     */
    public function agregarPedido(Request $request, CamionVictual $camionVictual): JsonResponse
    {
        $request->validate([
            'pedido_id' => 'required|exists:pedidos,id',
        ]);

        try {
            $camion = $this->service->agregarPedido($camionVictual, $request->pedido_id, Auth::user());
            return response()->json($camion);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Quitar un pedido del camión.
     */
    public function quitarPedido(CamionVictual $camionVictual, int $pedidoId): JsonResponse
    {
        try {
            $camion = $this->service->quitarPedido($camionVictual, $pedidoId);
            return response()->json($camion);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Reordenar los pedidos del camión (drag & drop del vendedor).
     * Body: [{ "pedido_id": 5, "orden_viaje": 1 }, { "pedido_id": 8, "orden_viaje": 2 }, ...]
     */
    public function reordenar(Request $request, CamionVictual $camionVictual): JsonResponse
    {
        $request->validate([
            'orden'              => 'required|array|min:1',
            'orden.*.pedido_id'  => 'required|integer',
            'orden.*.orden_viaje' => 'required|integer|min:1',
        ]);

        try {
            $camion = $this->service->reordenarPedidos($camionVictual, $request->orden);
            return response()->json($camion);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Logística actualiza el estado de entrega de un pedido individual.
     * Ej: marcar como en_curso, entregado o fallido.
     */
    public function actualizarEntrega(Request $request, CamionVictual $camionVictual, int $pedidoId): JsonResponse
    {
        $request->validate([
            'estado_entrega'     => 'required|in:en_curso,entregado,fallido',
            'comentario_entrega' => 'nullable|string|max:500',
        ]);

        try {
            $camion = $this->service->actualizarEstadoEntrega(
                $camionVictual,
                $pedidoId,
                EstadoEntrega::from($request->estado_entrega),
                $request->comentario_entrega
            );
            return response()->json($camion);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Logística pone el camión en_ruta.
     */
    public function ponerEnRuta(CamionVictual $camionVictual): JsonResponse
    {
        try {
            $camion = $this->service->ponerEnRuta($camionVictual);
            return response()->json($camion);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Logística cierra el camión manualmente.
     */
    public function cerrar(CamionVictual $camionVictual): JsonResponse
    {
        try {
            $camion = $this->service->cerrar($camionVictual, Auth::user());
            return response()->json($camion);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Devuelve el monto mínimo configurado.
     * Usado por el frontend para mostrar el progress bar.
     */
    public function montoMinimo(): JsonResponse
    {
        return response()->json([
            'monto_minimo' => $this->service->getMontoMinimo(),
        ]);
    }

    /**
     * Listar pedidos facturados disponibles para agregar a un camión.
     * Excluye los que ya están en algún camión activo.
     */
    public function pedidosDisponibles(Request $request): JsonResponse
    {
        $vendedorId = Auth::user()->hasRole('admin')
            ? $request->input('vendedor_id')
            : Auth::id();

        $pedidosEnCamionesActivos = \DB::table('camion_victual_pedido')
            ->join('camiones_victuales', 'camiones_victuales.id', '=', 'camion_victual_pedido.camion_victual_id')
            ->whereIn('camiones_victuales.estado', ['armando', 'listo', 'en_ruta'])
            ->pluck('camion_victual_pedido.pedido_id');

        $query = \App\Modules\Pedido\Models\Pedido::with('cliente:id,nombre')
            ->where('estado', 'facturado')
            ->whereNotIn('id', $pedidosEnCamionesActivos);

        if ($vendedorId) {
            $query->where('vendedor_id', $vendedorId);
        }

        if ($request->filled('search')) {
            $query->whereHas('cliente', fn($q) =>
                $q->where('nombre', 'like', '%' . $request->search . '%')
            );
        }

        return response()->json($query->orderBy('created_at', 'desc')->get());
    }

    /**
     * Generar URL para PDF del conduce del camión.
     */
    public function getConducePdfUrl($id)
    {
        $url = PdfSecurityService::generarUrl('camion_conduce', ['id' => $id], Auth::id(), 30);
        return response()->json(['url' => $url]);
    }
}

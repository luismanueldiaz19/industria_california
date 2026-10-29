<?php

namespace App\Modules\Empleado\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Empleado\Http\Requests\StoreEmpleadoRequest;
use App\Modules\Empleado\Http\Requests\UpdateEmpleadoRequest;
use App\Modules\Empleado\Models\Empleado;
use App\Modules\Empleado\Services\EmpleadoService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class EmpleadoController extends Controller
{
    public function __construct(
        private readonly EmpleadoService $service
    ) {}

    public function index(Request $request): JsonResponse
    {
        $query = Empleado::query()->with('creador:id,name');

        if ($request->filled('estado')) {
            $query->where('estado', $request->query('estado'));
        }

        if ($request->filled('departamento')) {
            $query->where('departamento', $request->query('departamento'));
        }

        if ($request->filled('search')) {
            $search = '%' . trim($request->query('search')) . '%';
            $query->where(function ($q) use ($search) {
                $q->where('nombres', 'ILIKE', $search)
                  ->orWhere('apellidos', 'ILIKE', $search)
                  ->orWhere('cedula', 'ILIKE', $search)
                  ->orWhere('ocupacion', 'ILIKE', $search);
            });
        }

        $empleados = $query->orderBy('nombres')->orderBy('apellidos')->get();
        return response()->json($empleados);
    }

    public function store(StoreEmpleadoRequest $request): JsonResponse
    {
        try {
            $empleado = $this->service->crear($request->validated(), Auth::user());
            return response()->json($empleado, 201);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function show(Empleado $empleado): JsonResponse
    {
        return response()->json($empleado->load('creador:id,name'));
    }

    public function update(UpdateEmpleadoRequest $request, Empleado $empleado): JsonResponse
    {
        try {
            $actualizado = $this->service->actualizar($empleado, $request->validated());
            return response()->json($actualizado, 200);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Regla de negocio: Los colaboradores no se eliminan para resguardar la integridad
     * laboral, fiscal y contable histórica de las nóminas. En su lugar se inactivan.
     */
    public function destroy(Empleado $empleado): JsonResponse
    {
        return response()->json([
            'message' => 'Los empleados no pueden ser eliminados para preservar el historial contable y de nómina. Cambie su estado a Inactivo.'
        ], 403);
    }

    public function resumen(): JsonResponse
    {
        return response()->json($this->service->resumen());
    }

    public function activosParaNomina(): JsonResponse
    {
        return response()->json($this->service->getActivosParaNomina());
    }
}


<?php

namespace App\Modules\Produccion\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Modules\Produccion\Repositories\Contracts\ProduccionRepositoryInterface;

class ProduccionAgrupadaController extends Controller
{
    public function __construct(
        private readonly ProduccionRepositoryInterface $produccionRepository
    ) {}

    public function porProducto(Request $request)
    {
        $perPage = min(max((int) $request->input('per_page', 30), 5), 100);
        $search = $request->input('search');

        $resultados = $this->produccionRepository->getAgrupadoPorProducto($perPage, $search);

        return response()->json($resultados);
    }

    public function porPedido(Request $request)
    {
        $perPage = min(max((int) $request->input('per_page', 30), 5), 100);
        $search = $request->input('search');

        $resultados = $this->produccionRepository->getAgrupadoPorPedido($perPage, $search);

        return response()->json($resultados);
    }

    public function porCliente(Request $request)
    {
        $perPage = min(max((int) $request->input('per_page', 30), 5), 100);
        $search = $request->input('search');

        $resultados = $this->produccionRepository->getAgrupadoPorCliente($perPage, $search);

        return response()->json($resultados);
    }

    public function porFecha(Request $request)
    {
        $perPage = min(max((int) $request->input('per_page', 30), 5), 100);
        $search = $request->input('search');
        
        $resultados = $this->produccionRepository->getAgrupadoPorFecha($perPage, $search);

        return response()->json($resultados);
    }
}

<?php

namespace App\Modules\Cliente\Repositories;

use App\Modules\Cliente\Models\Cliente;
use App\Modules\Cliente\Repositories\Contracts\ClienteRepositoryInterface;
use App\Helpers\TextNormalizer;

class ClienteRepository implements ClienteRepositoryInterface
{
    public function all()
    {
        $query = Cliente::query();

        if (request()->has('search') && trim(request()->input('search')) !== '') {
            $rawSearch = trim(request()->input('search'));
            $search = TextNormalizer::normalize($rawSearch);
            $digitsOnly = TextNormalizer::onlyDigits($rawSearch);

            $query->where(function ($q) use ($search, $digitsOnly) {
                $q->whereRaw('LOWER(nombre) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(id_cliente_externo) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(documento) LIKE ?', ["%{$search}%"]);

                if (!empty($digitsOnly)) {
                    $q->orWhereRaw("REPLACE(REPLACE(REPLACE(whatsapp, '-', ''), ' ', ''), '+', '') LIKE ?", ["%{$digitsOnly}%"])
                      ->orWhereRaw('LOWER(whatsapp) LIKE ?', ["%{$search}%"]);
                } else {
                    $q->orWhereRaw('LOWER(whatsapp) LIKE ?', ["%{$search}%"]);
                }
            });
        }

        $sort = request()->input('sort', 'recent');
        if ($sort === 'name_asc') {
            $query->orderBy('nombre', 'asc');
        } elseif ($sort === 'name_desc') {
            $query->orderBy('nombre', 'desc');
        } else {
            $query->orderBy('id', 'desc');
        }

        if (request()->boolean('paginate')) {
            $perPage = (int) request()->input('per_page', 350);
            return $query->paginate($perPage);
        }

        return $query->get();
    }

    public function find($id)
    {
        return Cliente::findOrFail($id);
    }

    public function create(array $data)
    {
        return Cliente::create($data);
    }

    public function update($id, array $data)
    {
        $cliente = $this->find($id);
        $cliente->update($data);
        return $cliente->fresh();
    }

    public function delete($id)
    {
        $cliente = $this->find($id);
        return $cliente->delete();
    }
}

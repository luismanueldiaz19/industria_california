<?php

namespace App\Modules\Cliente\Services;

use App\Modules\Cliente\Repositories\Contracts\ClienteRepositoryInterface;
use App\Modules\Cliente\Imports\ClientesImport;

class ClienteService
{
    protected ClienteRepositoryInterface $clienteRepository;

    public function __construct(ClienteRepositoryInterface $clienteRepository)
    {
        $this->clienteRepository = $clienteRepository;
    }

    public function getAllClientes()
    {
        return $this->clienteRepository->all();
    }

    public function getClienteById($id)
    {
        return $this->clienteRepository->find($id);
    }

    public function createCliente(array $data)
    {
        return $this->clienteRepository->create($data);
    }

    public function updateCliente($id, array $data)
    {
        return $this->clienteRepository->update($id, $data);
    }

    public function deleteCliente($id)
    {
        return $this->clienteRepository->delete($id);
    }

    public function importClientes($file): array
    {
        $importer = new ClientesImport();
        return $importer->import($file);
    }
}

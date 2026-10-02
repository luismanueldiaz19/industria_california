<?php

namespace App\Modules\ChequeFuturista\Policies;

use App\Modules\ChequeFuturista\Models\ChequeFuturista;
use App\Modules\ChequeFuturista\Models\DocumentoCheque;
use App\Models\User;

class ChequeFuturistaPolicy
{
    /**
     * Retorna true en todos los metodos mientras no se definan
     * los permisos especificos (ver_cheques, crear_cheques, etc.).
     * Cuando esten creados, reemplazar cada 'return true' por
     * el $user->can('permiso_correspondiente').
     */

    public function viewAny(User $user): bool
    {
        // TODO: return $user->can('ver_cheques');
        return true;
    }

    public function view(User $user, ChequeFuturista $cheque): bool
    {
        // TODO: return $user->can('ver_cheques');
        return true;
    }

    public function create(User $user): bool
    {
        // TODO: return $user->can('crear_cheques');
        return true;
    }

    public function update(User $user, ChequeFuturista $cheque): bool
    {
        // TODO: return $user->can('editar_cheques');
        return true;
    }

    public function delete(User $user, ChequeFuturista $cheque): bool
    {
        // TODO: return $user->can('eliminar_cheques');
        return true;
    }

    // ── Sub-recurso Documentos ────────────────────────────────

    public function subirDocumento(User $user, ChequeFuturista $cheque): bool
    {
        // TODO: return $user->can('crear_cheques');
        return true;
    }

    public function eliminarDocumento(User $user, DocumentoCheque $documento): bool
    {
        // TODO: return $user->can('eliminar_cheques');
        return true;
    }
}
<?php

namespace App\Modules\ChequeFuturista\Models;

use App\Models\LedhouseCliente;
use App\Models\User;
use App\Modules\ChequeFuturista\Enums\EstadoCheque;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class ChequeFuturista extends Model
{
    use HasFactory;

    protected $table = 'cheques_futuristas';

    protected $fillable = [
        'id_cliente',
        'id_vendedor',
        'num_cheque',
        'num_pedido',
        'monto',
        'estado',
        'comentario',
        'created_by',
    ];

    protected $casts = [
        'estado' => EstadoCheque::class,
    ];

    // ── Relaciones ────────────────────────────────────────────

    public function cliente(): BelongsTo
    {
        return $this->belongsTo(LedhouseCliente::class, 'id_cliente');
    }

    public function vendedor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'id_vendedor');
    }

    public function creador(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function documentos(): HasMany
    {
        return $this->hasMany(DocumentoCheque::class, 'cheque_futurista_id');
    }

    // ── Helpers ───────────────────────────────────────────────

    public function estaPendiente(): bool
    {
        return $this->estado === EstadoCheque::Pendiente;
    }
}
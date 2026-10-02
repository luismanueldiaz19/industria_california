<?php

namespace App\Modules\ChequeFuturista\Models;

use App\Modules\ChequeFuturista\Enums\TipoArchivoDocumento;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class DocumentoCheque extends Model
{
    use HasFactory;

    protected $table = 'documento_cheques';

    protected $fillable = [
        'cheque_futurista_id',
        'nombre_archivo',
        'ruta_archivo',
        'tipo_archivo',
        'created_by',
    ];

    protected $casts = [
        'tipo_archivo' => TipoArchivoDocumento::class,
    ];

    // ── Relaciones ────────────────────────────────────────────

    public function cheque(): BelongsTo
    {
        return $this->belongsTo(ChequeFuturista::class, 'cheque_futurista_id');
    }

    public function subidoPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
<?php

namespace App\Modules\CuentasPorCobrar\Models;

use App\Models\User;
use App\Modules\CuentasPorCobrar\Enums\TipoEvidenciaCxc;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class CxcEvidencia extends Model
{
    use HasFactory;

    protected $table = 'ledhouse_cxc_evidencias';

    protected $fillable = [
        'ledhouse_cxc_id',
        'alerta_id',
        'subido_por',
        'nombre_archivo',
        'ruta_archivo',
        'tipo_archivo',
    ];

    protected $casts = [
        'tipo_archivo' => TipoEvidenciaCxc::class,
    ];

    protected $appends = [
        'url',
    ];

    public function cxc(): BelongsTo
    {
        return $this->belongsTo(CuentaPorCobrar::class, 'ledhouse_cxc_id');
    }

    public function alerta(): BelongsTo
    {
        return $this->belongsTo(CxcAlerta::class, 'alerta_id');
    }

    public function subidoPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'subido_por');
    }

    public function getUrlAttribute(): ?string
    {
        if (!$this->ruta_archivo) {
            return null;
        }

        return Storage::disk('public')->url($this->ruta_archivo);
    }
}

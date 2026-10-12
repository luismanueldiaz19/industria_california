<?php

namespace App\Modules\CuentasPorCobrar\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CxcSoporte extends Model
{
    use HasFactory;

    protected $table = 'ledhouse_cxc_soportes';

    protected $fillable = [
        'ledhouse_cxc_id',
        'nota',
        'fecha',
        'fecha_visita',
    ];

    protected $casts = [
        'fecha'        => 'date',
        'fecha_visita' => 'date',
    ];

    public function cxc(): BelongsTo
    {
        return $this->belongsTo(CuentaPorCobrar::class, 'ledhouse_cxc_id');
    }
}

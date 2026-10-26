<?php

namespace App\Modules\CamionVictual\Models;

use App\Models\Chofer;
use App\Models\User;
use App\Modules\CamionVictual\Enums\EstadoViaje;
use App\Modules\Vehiculo\Models\Vehiculo;
use App\Modules\Vehiculo\Models\VehiculoGasto;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CamionViaje extends Model
{
    protected $table = 'camion_victual_viajes';

    protected $fillable = [
        'codigo',
        'camion_victual_id',
        'chofer_id',
        'vendedor_id',
        'vehiculo_id',
        'fecha_salida',
        'fecha_cierre',
        'cerrado_por',
        'total_facturado',
        'total_gastos',
        'cant_ayudantes',
        'nombres_ayudantes',
        'comentarios',
        'estado',
    ];

    protected $casts = [
        'estado'          => EstadoViaje::class,
        'fecha_salida'    => 'datetime',
        'fecha_cierre'    => 'datetime',
        'total_facturado' => 'decimal:2',
        'total_gastos'    => 'decimal:2',
        'cant_ayudantes'  => 'integer',
    ];

    protected $appends = ['margen_neto', 'porcentaje_gastos'];

    public function getMargenNetoAttribute(): float
    {
        return round((float) $this->total_facturado - (float) $this->total_gastos, 2);
    }

    public function getPorcentajeGastosAttribute(): float
    {
        $facturado = (float) $this->total_facturado;
        if ($facturado <= 0) {
            return 0.0;
        }
        return round(((float) $this->total_gastos / $facturado) * 100, 2);
    }

    // ─── Relaciones ───────────────────────────────────────────────

    public function camionVictual(): BelongsTo
    {
        return $this->belongsTo(CamionVictual::class, 'camion_victual_id');
    }

    public function chofer(): BelongsTo
    {
        return $this->belongsTo(Chofer::class, 'chofer_id');
    }

    public function vendedor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'vendedor_id');
    }

    public function vehiculo(): BelongsTo
    {
        return $this->belongsTo(Vehiculo::class, 'vehiculo_id');
    }

    public function cerradoPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'cerrado_por');
    }

    public function pedidos(): HasMany
    {
        return $this->hasMany(CamionViajePedido::class, 'viaje_id')->orderBy('orden_viaje', 'asc');
    }

    public function gastos(): HasMany
    {
        return $this->hasMany(VehiculoGasto::class, 'viaje_id')->orderBy('id', 'asc');
    }

    /**
     * Genera el siguiente código correlativo único para un viaje (ej: VJ-0001, VJ-0005).
     * Evita colisiones cuando hay viajes eliminados, saltos de numeración o concurrencia.
     */
    public static function generarSiguienteCodigo(): string
    {
        // 1. Tomar el número más alto entre los últimos registros creados
        $ultimosCodigos = static::where('codigo', 'like', 'VJ-%')
            ->orderBy('id', 'desc')
            ->limit(100)
            ->pluck('codigo');

        $maxNumero = 0;
        foreach ($ultimosCodigos as $c) {
            if (preg_match('/VJ-(\d+)/i', $c, $m)) {
                $num = (int) $m[1];
                if ($num > $maxNumero) {
                    $maxNumero = $num;
                }
            }
        }

        // 2. Verificar también por longitud de código por si hay códigos mayores fuera de los últimos 100 IDs
        $viajePorLargo = static::where('codigo', 'like', 'VJ-%')
            ->orderByRaw('LENGTH(codigo) DESC, codigo DESC')
            ->first();

        if ($viajePorLargo && preg_match('/VJ-(\d+)/i', $viajePorLargo->codigo, $m)) {
            $num = (int) $m[1];
            if ($num > $maxNumero) {
                $maxNumero = $num;
            }
        }

        // 3. Tomar el mayor entre: el número más alto encontrado + 1, max(id) + 1, o count() + 1
        $maxId = (int) (static::max('id') ?? 0);
        $count = (int) (static::count() ?? 0);

        $siguienteNumero = max($maxNumero + 1, $maxId + 1, $count + 1);

        // 4. Bucle defensivo: si por alguna razón el código generado ya existe en BD, seguir incrementando
        do {
            $codigo = 'VJ-' . str_pad($siguienteNumero, 4, '0', STR_PAD_LEFT);
            $siguienteNumero++;
        } while (static::where('codigo', $codigo)->exists());

        return $codigo;
    }
}


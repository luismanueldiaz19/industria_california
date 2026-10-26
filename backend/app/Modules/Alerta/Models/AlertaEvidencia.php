<?php

namespace App\Modules\Alerta\Models;

use App\Models\User;
use App\Models\LedhouseCxc;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class AlertaEvidencia extends Model
{
    use HasFactory;

    protected $table = 'ledhouse_cxc_evidencias';

    protected $fillable = [
        'ledhouse_cxc_id',
        'alerta_id',
        'grupo_pago_id',
        'subido_por',
        'nombre_archivo',
        'ruta_archivo',
        'tipo_archivo',
    ];

    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function alerta(): BelongsTo
    {
        return $this->belongsTo(Alerta::class, 'alerta_id');
    }

    public function cxc(): BelongsTo
    {
        return $this->belongsTo(LedhouseCxc::class, 'ledhouse_cxc_id');
    }

    public function subidor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'subido_por');
    }

    public function isImage(): bool
    {
        return in_array(strtolower($this->tipo_archivo), ['jpg', 'jpeg', 'png', 'webp']);
    }

    public function isPdf(): bool
    {
        return strtolower($this->tipo_archivo) === 'pdf';
    }

    /**
     * Elimina el archivo físico SOLO si ya ningún registro de evidencia lo referencia.
     * Necesario porque en un pago agrupado varias evidencias comparten la misma ruta.
     * Debe llamarse DESPUÉS de borrar el/los registros de evidencia.
     */
    public static function borrarArchivoSiHuerfano(?string $ruta): void
    {
        if (!$ruta) {
            return;
        }

        $sigueEnUso = static::where('ruta_archivo', $ruta)->exists();

        if (!$sigueEnUso && Storage::disk('public')->exists($ruta)) {
            Storage::disk('public')->delete($ruta);
        }
    }
}

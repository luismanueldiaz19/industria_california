<?php

namespace App\Modules\Alerta\Models;

use App\Models\User;
use App\Models\LedhouseCxc;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AlertaEvidencia extends Model
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
}

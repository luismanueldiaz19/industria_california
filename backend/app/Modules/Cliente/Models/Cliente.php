<?php

namespace App\Modules\Cliente\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\LedhouseCxc;

class Cliente extends Model
{
    use HasFactory;

    protected $table = 'ledhouse_clientes';

    protected $fillable = [
        'id_cliente_externo',
        'nombre',
        'whatsapp',
        'direccion',
        'tipo_documento',
        'documento',
        'limite_credito',
        'dias_credito',
        'latitud',
        'longitud',
    ];

    protected $casts = [
        'limite_credito' => 'decimal:2',
        'dias_credito'   => 'integer',
        'latitud'        => 'decimal:8',
        'longitud'       => 'decimal:8',
    ];

    protected $appends = [
        'telefono',
        'rnc',
    ];

    /**
     * Accesor para compatibilidad con código que use 'telefono'
     */
    public function getTelefonoAttribute(): ?string
    {
        return $this->attributes['whatsapp'] ?? null;
    }

    /**
     * Accesor para compatibilidad con código que use 'rnc'
     */
    public function getRncAttribute(): ?string
    {
        return $this->attributes['documento'] ?? null;
    }

    /**
     * Relación con Cuentas por Cobrar
     */
    public function cxcs()
    {
        return $this->hasMany(LedhouseCxc::class, 'cliente_id');
    }
}

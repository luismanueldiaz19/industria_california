<?php

namespace App\Modules\CuentasPorCobrar\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UploadCxcEvidenciaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'file'      => 'required|file|mimes:pdf,jpg,jpeg,png|max:10240',
            'alerta_id' => 'nullable|exists:ledhouse_cxc_alertas,id',
        ];
    }

    public function messages(): array
    {
        return [
            'file.required' => 'Debe adjuntar un archivo (PDF, JPG, PNG).',
            'file.mimes'    => 'Formato no permitido. Solo se aceptan PDF, JPG y PNG.',
            'file.max'      => 'El archivo no puede exceder los 10MB.',
        ];
    }
}

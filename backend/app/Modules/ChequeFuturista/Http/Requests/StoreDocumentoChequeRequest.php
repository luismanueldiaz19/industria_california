<?php

namespace App\Modules\ChequeFuturista\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreDocumentoChequeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'archivo' => 'required|file|mimes:pdf,jpg,jpeg,png|max:10240',
        ];
    }

    public function messages(): array
    {
        return [
            'archivo.required' => 'El archivo es obligatorio.',
            'archivo.mimes'    => 'Solo se permiten archivos PDF, JPG, JPEG o PNG.',
            'archivo.max'      => 'El archivo no debe superar los 10 MB.',
        ];
    }
}

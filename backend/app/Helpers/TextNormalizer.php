<?php

namespace App\Helpers;

class TextNormalizer
{
    /**
     * Normaliza un texto (quita acentos, convierte a minúsculas y recorta espacios).
     */
    public static function normalize($text)
    {
        if (!$text) return '';

        $text = trim(mb_strtolower($text, 'UTF-8'));
        $text = str_replace(
            ['á', 'é', 'í', 'ó', 'ú', 'ñ'],
            ['a', 'e', 'i', 'o', 'u', 'n'],
            $text
        );
        
        return $text;
    }
    
    /**
     * Extrae solo los dígitos (útil para teléfonos o RNC).
     */
    public static function onlyDigits($text)
    {
        if (!$text) return '';
        return preg_replace('/[^0-9]/', '', $text);
    }
}

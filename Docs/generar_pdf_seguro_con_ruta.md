Actúa como un arquitecto de software y desarrollador backend senior especializado en Laravel y seguridad web.

Necesito implementar un flujo seguro para la generación y visualización de PDFs en el navegador, mitigando cualquier riesgo de acceso no autorizado, manipulación de URLs o ataques de enumeración (IDOR).

Por favor, diseña y escribe la solución completa bajo las siguientes especificaciones:

### 1. Requerimientos de Seguridad
* *URLs Firmadas y Temporales (Signed URLs):* La URL para visualizar el PDF debe generarse usando URL::temporarySignedRoute(), con una validez corta (ej. 15 a 30 minutos).
* *Imposibilidad de Modificación:* Si un usuario altera el ID del recurso o cualquier query parameter, el middleware signed de Laravel debe abortar con un error 403 Forbidden de inmediato.
* *Uso de UUID o Tokens Criptográficos:* No expongas IDs incrementales en la URL; utiliza UUIDs o un hash seguro para identificar el registro.
* *Protección contra Descargas Externas No Deseadas:* Configura los encabezados HTTP apropiados (Content-Type: application/pdf, Content-Disposition: inline) para forzar que el PDF se renderice directamente en el visor del navegador sin exponer la ruta física de almacenamiento en el servidor (storage/app/...).

### 2. Flujo Requerido
1. *Endpoint de Solicitud (API/Backend):*
   * Recibe la petición para solicitar el documento.
   * Valida permisos del usuario solicitante (Policies / Form Request).
   * Retorna una URL temporal firmada válida por poco tiempo.
2. *Endpoint de Descarga/Visualización:*
   * Protegido estrictamente por el middleware 'signed'.
   * Resuelve el modelo de forma segura.
   * Genera el PDF al vuelo (o lo lee del disco privado) y lo retorna en streaming inline.
   * Al expirar el tiempo, el enlace queda automáticamente inhabilitado.

### 3. Entregables de Código
Por favor, proporciona el código limpio y comentado para:
- Definición de rutas (routes/web.php o routes/api.php).
- Controlador que genera la URL firmada.
- Controlador que valida la firma y emite el PDF (Response::stream o streamDownload inline).
- Ejemplo de configuración si se usa una librería de PDF común (como barryvdh/laravel-dompdf o similar).
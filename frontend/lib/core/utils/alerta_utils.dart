class AlertaUtils {
  static const List<String> tiposDeAlerta = [
    'pago_recibido',
    'credito',
    'debito',
    'devolucion',
    'retencion',
    'diferencia',
    'mer_no_entregada',
    'cheque_futurista',
    'anular',
    'consulta',
    'informacion',
  ];

  static bool requiereMonto(String tipo) {
    // Todos excepto consulta requieren monto usualmente (según la lógica actual)
    return tipo != 'consulta';
  }

  static const List<String> formasDePago = [
    'Efectivo',
    'Transferencia',
    'Cheque',
    'Otro',
  ];

  static String getFormaPagoLabel(String forma) {
    switch (forma) {
      case 'Efectivo':
        return '💵 Efectivo';
      case 'Transferencia':
        return '🏦 Transferencia';
      case 'Cheque':
        return '📝 Cheque';
      case 'Otro':
      default:
        return '📌 Otro';
    }
  }

  static String getTipoLabel(String tipo) {
    switch (tipo) {
      case 'pago_recibido':
        return '💵 Pago Recibido';
      case 'credito':
        return '💳 Nota de credito';
      case 'debito':
        return '🧾 Nota de débito';
      case 'devolucion':
        return '↩️ Devolución';
      case 'retencion':
        return '✂️ Retención';
      case 'diferencia':
        return '⚖️ Diferencia de Precio';
      case 'mer_no_entregada':
        return '📦 Mercancía No Entregada';
      case 'cheque_futurista':
        return '🕰️ Cheque Futurista';
      case 'anular':
        return '❌ Anular Factura';
      case 'consulta':
        return '❓ Consulta';
      case 'informacion':
      default:
        return '📝 Información';
    }
  }
}

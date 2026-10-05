import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Paleta oscura compartida con el módulo de Pedidos.
class ChequeAdminColors {
  static const bar = Color(0xFF1A1C1E);
  static const card = Color(0xFF2C2F33);
  static const header = Color(0xFF23272A);
  static const red = Color(0xFFE31E24);
  static const blue = Color(0xFF2196F3);
}

/// Estados disponibles para un cheque futurista.
class ChequeEstadoInfo {
  final String value;
  final String label;
  final IconData icon;
  const ChequeEstadoInfo(this.value, this.label, this.icon);
}

/// Nivel de alerta calculado para un cheque.
enum ChequeAlerta { ninguna, registro, deposito }

class ChequeAdminUtils {
  /// Días desde el registro para alerta de seguimiento.
  static const diasAlertaRegistro = 20;

  /// Días después de la fecha de depósito para alerta crítica.
  static const diasAlertaDeposito = 15;

  static const estados = [
    ChequeEstadoInfo('pendiente', 'Pendiente', Icons.schedule),
    ChequeEstadoInfo('depositado', 'Depositado', Icons.check_circle),
    ChequeEstadoInfo('cancelado', 'Cancelado', Icons.cancel),
    ChequeEstadoInfo('vencido', 'Vencido', Icons.event_busy),
  ];

  static Color colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return const Color(0xFFFF9800);
      case 'depositado':
        return const Color(0xFF4CAF50);
      case 'cancelado':
        return const Color(0xFFE53935);
      case 'vencido':
        return const Color(0xFFAB47BC);
      default:
        return Colors.grey;
    }
  }

  static DateTime? parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  static int? diasDesde(String? raw) {
    final dt = parse(raw);
    if (dt == null) return null;
    final hoy = DateTime.now();
    return DateTime(hoy.year, hoy.month, hoy.day)
        .difference(DateTime(dt.year, dt.month, dt.day))
        .inDays;
  }

  /// Las alertas solo aplican a cheques pendientes.
  static ChequeAlerta alerta(String estado, String createdAt, String? fechaDeposito) {
    if (estado.toLowerCase() != 'pendiente') return ChequeAlerta.ninguna;
    final dDep = diasDesde(fechaDeposito);
    if (dDep != null && dDep > diasAlertaDeposito) return ChequeAlerta.deposito;
    final dReg = diasDesde(createdAt) ?? 0;
    if (dReg > diasAlertaRegistro) return ChequeAlerta.registro;
    return ChequeAlerta.ninguna;
  }

  static String fmt(String? raw, [String pattern = 'dd/MM/yyyy']) {
    final dt = parse(raw);
    return dt == null ? '—' : DateFormat(pattern).format(dt);
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/camion_victual.dart';

/// Tarjeta visual de un camión victual — Estilo CXC.
/// - Nombre del camión
/// - Estado con badge de color
/// - Chofer asignado
/// - Monto total vs monto mínimo (progress bar)
class CamionVictualCard extends StatelessWidget {
  final CamionVictual camion;
  final double montoMinimo;
  final VoidCallback onTap;

  const CamionVictualCard({
    super.key,
    required this.camion,
    required this.montoMinimo,
    required this.onTap,
  });

  Color get _estadoColor {
    switch (camion.estado) {
      case 'armando':
        return const Color(0xFFFB8C00); // Orange
      case 'listo':
        return const Color(0xFF2E7D32); // Green
      case 'en_ruta':
        return const Color(0xFF1976D2); // Blue
      case 'cerrado':
        return Colors.grey.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String get _estadoLabel {
    switch (camion.estado) {
      case 'armando':
        return 'ARMANDO';
      case 'listo':
        return 'LISTO';
      case 'en_ruta':
        return 'EN RUTA';
      case 'cerrado':
        return 'CERRADO';
      default:
        return camion.estado.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'es');
    final actualMinimo = (camion.minimoSalida > 5000)
        ? camion.minimoSalida
        : (montoMinimo > 0 ? montoMinimo : 500000.0);
    final progreso = actualMinimo > 0
        ? (camion.montoTotal / actualMinimo).clamp(0.0, 1.0)
        : 1.0;
    final falta = (actualMinimo - camion.montoTotal).clamp(0, double.infinity);
    final isCompletado = falta <= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Barra vertical de color
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: _estadoColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila 1: Nombre y Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          camion.nombre.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Colors.grey.shade800,
                            letterSpacing: 0.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _estadoColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _estadoLabel,
                          style: TextStyle(
                            color: _estadoColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Fila 2: Chofer
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          camion.choferNombre?.toUpperCase() ?? 'SIN CHOFER',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Fila 3: Montos y Pedidos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMontoItem(
                        'Cargado',
                        '\$${fmt.format(camion.montoTotal)}',
                        const Color(0xFF1976D2),
                      ),
                      _buildMontoItem(
                        'Pedidos',
                        '${camion.pedidos.length}',
                        Colors.grey.shade700,
                      ),
                      _buildMontoItem(
                        isCompletado ? 'Monto' : 'Falta',
                        isCompletado ? 'Alcanzado' : '\$${fmt.format(falta)}',
                        isCompletado
                            ? const Color(0xFF2E7D32)
                            : Colors.orange.shade700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Fila 4: Progress Bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progreso,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompletado
                                  ? const Color(0xFF4CAF50)
                                  : progreso > 0.6
                                  ? const Color(0xFFFDD835)
                                  : const Color(0xFFE53935),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Min: \$${fmt.format(actualMinimo)}',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMontoItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../camion_victual/models/camion_victual.dart';
import '../../../camion_victual/models/camion_viaje.dart';

/// Tarjeta unificada y compacta que muestra los datos operativos del viaje activo:
/// Vehículo físico real, Conductor, Ayudantes, Resumen de gastos con chips limpios
/// y Notas de despacho sin redundancia visual.
class DespachoViajeInfoCard extends StatelessWidget {
  final CamionVictual camion;
  final VoidCallback? onEditar;

  const DespachoViajeInfoCard({super.key, required this.camion, this.onEditar});

  IconData _getIconForTipo(String tipo) {
    final t = tipo.trim().toUpperCase();
    if (t.contains('COMBUSTIBLE')) return Icons.local_gas_station_outlined;
    if (t.contains('DIETA')) return Icons.restaurant_outlined;
    if (t.contains('PEAJE')) return Icons.toll_outlined;
    if (t.contains('MANTENIMIENTO') || t.contains('TALLER')) {
      return Icons.build_circle_outlined;
    }
    return Icons.receipt_long_outlined;
  }

  Color _getColorForTipo(String tipo) {
    final t = tipo.trim().toUpperCase();
    if (t.contains('COMBUSTIBLE')) return const Color(0xFFD97706);
    if (t.contains('DIETA')) return const Color(0xFF059669);
    if (t.contains('PEAJE')) return const Color(0xFF2563EB);
    return const Color(0xFF64748B);
  }

  String _formatChipLabel(CamionViajeGasto g) {
    final tipo = g.tipoGasto.trim();
    final tipoCap = tipo.isEmpty
        ? 'Gasto'
        : '${tipo[0].toUpperCase()}${tipo.substring(1).toLowerCase()}';
    final conc = g.concepto.trim();

    // Evitar redundancias como "Dieta: DIETA" o "Peaje: PEAJE"
    if (conc.isEmpty || conc.toUpperCase() == tipo.toUpperCase()) {
      return tipoCap;
    }

    return '$tipoCap ($conc)';
  }

  @override
  Widget build(BuildContext context) {
    final viaje = camion.viajeActivo;

    final vehiculoFicha = camion.vehiculoFicha ?? viaje?.vehiculoFicha;
    final vehiculoMarca = camion.vehiculoMarca ?? viaje?.vehiculoMarca ?? '';
    final vehiculoModelo = camion.vehiculoModelo ?? viaje?.vehiculoModelo ?? '';
    final vehiculoPlaca = camion.vehiculoPlaca ?? viaje?.vehiculoPlaca;
    final hasVehiculo = vehiculoFicha != null && vehiculoFicha.isNotEmpty;

    final hasAyudantes =
        viaje != null &&
        (viaje.cantAyudantes > 0 ||
            (viaje.nombresAyudantes != null &&
                viaje.nombresAyudantes!.trim().isNotEmpty));

    final hasGastos =
        viaje != null && (viaje.gastos.isNotEmpty || viaje.totalGastos > 0);

    final hasNotas =
        viaje != null &&
        viaje.comentarios != null &&
        viaje.comentarios!.trim().isNotEmpty;

    // Si no hay ningún dato de viaje ni vehículo físico asignado, no renderizamos nada
    if (!hasVehiculo && !hasAyudantes && !hasGastos && !hasNotas) {
      return const SizedBox.shrink();
    }

    final totalFacturado = camion.montoTotal;
    final totalGastos = viaje?.totalGastos ?? 0.0;
    final margenNeto = viaje?.margenNeto ?? (totalFacturado - totalGastos);
    final rendimiento = totalFacturado > 0
        ? ((margenNeto / totalFacturado) * 100).clamp(-999.0, 100.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fila 1: Asignaciones Operativas (Vehículo + Personal) ─────────
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Vehículo Físico
                    if (hasVehiculo)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_shipping,
                            size: 14,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              vehiculoFicha,
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            [
                              '$vehiculoMarca $vehiculoModelo'.trim(),
                              if (vehiculoPlaca != null &&
                                  vehiculoPlaca.isNotEmpty)
                                '($vehiculoPlaca)',
                            ].where((s) => s.isNotEmpty).join(' '),
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                    // Ayudantes
                    if (hasAyudantes)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.groups_outlined,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            [
                              if (viaje.cantAyudantes > 0)
                                '${viaje.cantAyudantes} ayudante(s)',
                              if (viaje.nombresAyudantes != null &&
                                  viaje.nombresAyudantes!.trim().isNotEmpty)
                                '(${viaje.nombresAyudantes!.trim()})',
                            ].join(' '),
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Botón Modificar / Preparar (solo visible antes de salir a ruta)
              if (onEditar != null &&
                  camion.estado != 'en_ruta' &&
                  camion.estado != 'cerrado')
                InkWell(
                  onTap: onEditar,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 11,
                          color: Color(0xFF2563EB),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Modificar',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // ── Fila 2: Resumen Presupuestario & Gastos de Salida ──────────────
          if (hasGastos) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI compactos de Salida
                  Row(
                    children: [
                      const Text(
                        'Gastos de Salida:',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.formatCurrency(totalGastos),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Margen Est.:',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.formatCurrency(margenNeto),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: margenNeto >= 0
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${rendimiento.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: margenNeto >= 0
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Chips limpios con icono y formato sin repeticiones
                  if (viaje.gastos.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: viaje.gastos.map((g) {
                        final chipColor = _getColorForTipo(g.tipoGasto);
                        final chipIcon = _getIconForTipo(g.tipoGasto);
                        final label = _formatChipLabel(g);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(chipIcon, size: 12, color: chipColor),
                              const SizedBox(width: 4),
                              Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                Formatters.formatCurrency(g.montoTotal),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: chipColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ── Fila 3: Observaciones o Notas de Salida ───────────────────────
          if (hasNotas) ...[
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1.5),
                    child: Icon(
                      Icons.comment_outlined,
                      size: 11,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      viaje.comentarios!.trim(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/compact_snack_bar.dart';
import '../../../core/widgets/general_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../../camion_victual/models/camion_victual.dart';
import '../../camion_victual/providers/camion_victual_provider.dart';
import '../widgets/chofer_pedido_card.dart';

class ChoferRutaScreen extends StatefulWidget {
  final VoidCallback? onIrALiquidar;

  const ChoferRutaScreen({super.key, this.onIrALiquidar});

  @override
  State<ChoferRutaScreen> createState() => _ChoferRutaScreenState();
}

class _ChoferRutaScreenState extends State<ChoferRutaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarRuta();
    });
  }

  Future<void> _cargarRuta() async {
    await context.read<CamionVictualProvider>().fetchCamiones();
  }

  Future<void> _abrirConduce(int camionId) async {
    try {
      final provider = context.read<CamionVictualProvider>();
      final urlStr = await provider.getConducePdfUrl(camionId);
      final url = Uri.parse(urlStr);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('No se pudo abrir el enlace');
      }
    } catch (e) {
      if (mounted) {
        CompactSnackBar.showError(context, 'Error al abrir Conduce: $e');
      }
    }
  }

  CamionVictual? _obtenerCamionActivo(List<CamionVictual> camiones) {
    if (camiones.isEmpty) return null;
    // Preferir el que esté en_ruta
    try {
      return camiones.firstWhere((c) => c.estado == 'en_ruta');
    } catch (_) {}
    // O listo
    try {
      return camiones.firstWhere((c) => c.estado == 'listo');
    } catch (_) {}
    return camiones.first;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final driverName = auth.name ?? auth.username ?? 'Chofer';

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Column(
        children: [
          GeneralHeader(
            title: 'Mi Despacho en Ruta',
            subtitle: 'Conductor: $driverName',
            icon: Icons.local_shipping,
            iconColor: Colors.blue.shade300,
            gradientColors: const [
              AppTheme.primaryBlue,
              AppTheme.secondaryBlue,
            ],
            actions: [
              HeaderButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Actualizar ruta',
                onTap: _cargarRuta,
              ),
            ],
          ),
          Expanded(
            child: Consumer<CamionVictualProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.camiones.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1976D2)),
                  );
                }

                final camion = _obtenerCamionActivo(provider.camiones);

                if (camion == null || camion.pedidos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.no_crash_outlined,
                              color: Color(0xFF64748B),
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No tienes despachos asignados',
                            style: TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Cuando administración cargue y despache tu camión a ruta, aquí verás la secuencia de clientes para entregar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _cargarRuta,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Actualizar Estado'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final pedidos = List<CamionPedido>.from(camion.pedidos)
                  ..sort((a, b) => a.ordenViaje.compareTo(b.ordenViaje));

                final int totalPedidos = pedidos.length;
                final int entregados = pedidos
                    .where((p) => p.estadoEntrega.toLowerCase() == 'entregado')
                    .length;
                final int fallidos = pedidos
                    .where((p) => p.estadoEntrega.toLowerCase() == 'fallido')
                    .length;
                final double progreso = totalPedidos > 0
                    ? (entregados / totalPedidos)
                    : 0.0;
                final bool todosProcesados =
                    (entregados + fallidos) == totalPedidos;

                return RefreshIndicator(
                  onRefresh: _cargarRuta,
                  color: const Color(0xFFE31E24),
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      // 1. TARJETA RESUMEN DEL CAMIÓN
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.local_shipping,
                                        color: Color(0xFF2563EB),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          camion.nombre,
                                          style: const TextStyle(
                                            color: Color(0xFF1E293B),
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          camion.vehiculoFicha != null
                                              ? 'Ficha: ${camion.vehiculoFicha} · Placa: ${camion.vehiculoPlaca ?? 'S/P'}'
                                              : 'Sin vehículo físico asignado',
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (camion.estado == 'en_ruta'
                                        ? const Color(0xFFEFF6FF)
                                        : const Color(0xFFFFF7ED)),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: (camion.estado == 'en_ruta'
                                          ? const Color(0xFFBFDBFE)
                                          : const Color(0xFFFED7AA)),
                                    ),
                                  ),
                                  child: Text(
                                    camion.estado.toUpperCase().replaceAll(
                                      '_',
                                      ' ',
                                    ),
                                    style: TextStyle(
                                      color: camion.estado == 'en_ruta'
                                          ? const Color(0xFF1D4ED8)
                                          : const Color(0xFFC2410C),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Color(0xFFF1F5F9), height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Carga Facturada',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      Formatters.formatCurrency(
                                        camion.montoTotal,
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF15803D),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFDC2626),
                                    backgroundColor: const Color(0xFFFEF2F2),
                                    side: const BorderSide(
                                      color: Color(0xFFFECACA),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.picture_as_pdf,
                                    color: Color(0xFFDC2626),
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Conduce PDF',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () => _abrirConduce(camion.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Entregas: $entregados / $totalPedidos ($fallidos fallidos)',
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${(progreso * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Color(0xFF15803D),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progreso,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF10B981),
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2. BOTÓN DE ACCESO RÁPIDO A LIQUIDACIÓN (SI TODOS PROCESADOS)
                      if (todosProcesados && widget.onIrALiquidar != null) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: widget.onIrALiquidar,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF059669), Color(0xFF10B981)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.payments,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '¡Ruta finalizada! Pasar a Liquidar',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // 3. TÍTULO DE LISTADO DE ENTREGAS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Secuencia de Entregas',
                            style: TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$totalPedidos pedidos',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 4. LISTADO DE PEDIDOS DEL CAMIÓN
                      ...pedidos.map(
                        (p) => ChoferPedidoCard(
                          pedido: p,
                          camionId: camion.id,
                          onCambiarEstado: (nuevoEstado, comentario) async {
                            final ok = await provider.actualizarEntrega(
                              camion.id,
                              p.id,
                              nuevoEstado,
                              comentarioEntrega: comentario,
                            );
                            if (context.mounted) {
                              if (ok) {
                                CompactSnackBar.showSuccess(
                                  context,
                                  nuevoEstado == 'entregado'
                                      ? 'Pedido marcado como ENTREGADO'
                                      : 'Pedido marcado como FALLIDO',
                                );
                              } else {
                                CompactSnackBar.showError(
                                  context,
                                  provider.error ??
                                      'Error al actualizar pedido',
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

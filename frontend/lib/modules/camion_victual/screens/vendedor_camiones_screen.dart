import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/general_header.dart';
import '../models/camion_victual.dart';
import '../providers/camion_victual_provider.dart';
import '../widgets/camion_victual_card.dart';
import 'camion_victual_detalle_screen.dart';

/// Pantalla principal del vendedor — estilo CXC (fondo claro, AppBar azul).
/// El vendedor NO puede crear camiones, solo gestionarlos.
class VendedorCamionesScreen extends StatefulWidget {
  const VendedorCamionesScreen({super.key});

  @override
  State<VendedorCamionesScreen> createState() => _VendedorCamionesScreenState();
}

class _VendedorCamionesScreenState extends State<VendedorCamionesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CamionVictualProvider>().fetchCamiones();
    });
  }

  Future<void> _refrescar() =>
      context.read<CamionVictualProvider>().fetchCamiones();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mis Camiones Victuales',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Consumer<CamionVictualProvider>(
              builder: (_, p, __) {
                final total = p.camiones.length;
                return total > 0
                    ? Text(
                        '$total camiones activos',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          HeaderButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Actualizar',
            onTap: _refrescar,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de estados (leyenda) ─────────────────────────────
          Material(
            color: Colors.white,
            elevation: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _estadoChip('Vacío', Colors.blueGrey),
                    const SizedBox(width: 6),
                    _estadoChip('Armando', const Color(0xFFFB8C00)),
                    const SizedBox(width: 6),
                    _estadoChip('Listo', const Color(0xFF2E7D32)),
                    const SizedBox(width: 6),
                    _estadoChip('En Ruta', const Color(0xFF1976D2)),
                    const SizedBox(width: 6),
                    _estadoChip('Cerrado', Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          // ── Contenido principal ────────────────────────────────────
          Expanded(
            child: Consumer<CamionVictualProvider>(
              builder: (_, provider, __) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade300,
                          size: 52,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          provider.error!,
                          style: TextStyle(color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _refrescar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                final camiones = provider.camiones;

                if (camiones.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refrescar,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.55,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_shipping_outlined,
                                  size: 72,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No hay camiones activos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black45,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Los camiones son creados en oficina.\nHaz pull-to-refresh para actualizar.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final vacios = camiones
                    .where((c) => c.estado == 'vacio')
                    .toList();
                final activos = camiones
                    .where((c) => c.estado == 'armando' || c.estado == 'listo')
                    .toList();
                final enRuta = camiones
                    .where((c) => c.estado == 'en_ruta')
                    .toList();
                final cerrados = camiones
                    .where((c) => c.estado == 'cerrado')
                    .toList();

                return RefreshIndicator(
                  onRefresh: _refrescar,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    children: [
                      if (vacios.isNotEmpty) ...[
                        _sectionLabel(
                          'Vacíos',
                          vacios.length,
                          Colors.blueGrey,
                        ),
                        const SizedBox(height: 6),
                        ...vacios.map(
                          (c) => CamionVictualCard(
                            camion: c,
                            montoMinimo: provider.montoMinimo,
                            onTap: () => _abrirDetalle(c),
                          ),
                        ),
                      ],
                      if (activos.isNotEmpty) ...[
                        if (vacios.isNotEmpty) const SizedBox(height: 8),
                        _sectionLabel(
                          'En preparación',
                          activos.length,
                          const Color(0xFFFB8C00),
                        ),
                        const SizedBox(height: 6),
                        ...activos.map(
                          (c) => CamionVictualCard(
                            camion: c,
                            montoMinimo: provider.montoMinimo,
                            onTap: () => _abrirDetalle(c),
                          ),
                        ),
                      ],
                      if (enRuta.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _sectionLabel(
                          'En Ruta',
                          enRuta.length,
                          const Color(0xFF1976D2),
                        ),
                        const SizedBox(height: 6),
                        ...enRuta.map(
                          (c) => CamionVictualCard(
                            camion: c,
                            montoMinimo: provider.montoMinimo,
                            onTap: () => _abrirDetalle(c),
                          ),
                        ),
                      ],
                      if (cerrados.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _sectionLabel(
                          'Cerrados',
                          cerrados.length,
                          Colors.grey.shade500,
                        ),
                        const SizedBox(height: 6),
                        ...cerrados.map(
                          (c) => CamionVictualCard(
                            camion: c,
                            montoMinimo: provider.montoMinimo,
                            onTap: () => _abrirDetalle(c),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ), // Expanded
        ], // Column children
      ), // Column (body)
      // Totales al pie — similar al footer de CXC
      bottomSheet: Consumer<CamionVictualProvider>(
        builder: (_, p, __) {
          if (p.camiones.isEmpty || p.isLoading) return const SizedBox.shrink();
          final totalMonto = p.camiones.fold<double>(
            0,
            (sum, c) => sum + c.montoTotal,
          );
          final listos = p.camiones.where((c) => c.estado == 'listo').length;
          final enRutaCount = p.camiones
              .where((c) => c.estado == 'en_ruta')
              .length;
          return _buildFooter(totalMonto, listos, enRutaCount);
        },
      ),
    );
  }

  /// Chip de leyenda de estado (Armando / Listo / En Ruta / Cerrado)
  Widget _estadoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(double total, int listos, int enRuta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _footerChip(
                'TOTAL CARGADO',
                '\$${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _footerChip(
                'LISTOS',
                '$listos camiones',
                const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _footerChip(
                'EN RUTA',
                '$enRuta camiones',
                const Color(0xFF1976D2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _abrirDetalle(CamionVictual camion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<CamionVictualProvider>(),
          child: CamionVictualDetalleScreen(camionId: camion.id),
        ),
      ),
    );
  }
}

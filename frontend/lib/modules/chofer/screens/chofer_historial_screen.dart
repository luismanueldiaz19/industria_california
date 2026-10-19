import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/general_header.dart';
import '../../camion_victual/models/camion_viaje.dart';
import '../../camion_victual/services/camion_victual_service.dart';

class ChoferHistorialScreen extends StatefulWidget {
  const ChoferHistorialScreen({super.key});

  @override
  State<ChoferHistorialScreen> createState() => _ChoferHistorialScreenState();
}

class _ChoferHistorialScreenState extends State<ChoferHistorialScreen> {
  final CamionVictualService _service = CamionVictualService();
  bool _isLoading = true;
  List<CamionViaje> _viajes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _service.getHistorialViajes(perPage: 30);
      final List data = res['data'] is List ? res['data'] : [];
      setState(() {
        _viajes = data.map((e) => CamionViaje.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Column(
        children: [
          GeneralHeader(
            title: 'Historial de Viajes',
            subtitle: 'Viajes completados y balances',
            icon: Icons.history,
            iconColor: Colors.tealAccent,
            gradientColors: const [
              AppTheme.primaryBlue,
              AppTheme.secondaryBlue,
            ],
            actions: [
              HeaderButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Actualizar',
                onTap: _cargarHistorial,
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1976D2)),
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFDC2626),
                          size: 36,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Error al cargar historial: $_error',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _cargarHistorial,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : _viajes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.history, color: Color(0xFFCBD5E1), size: 48),
                        SizedBox(height: 12),
                        Text(
                          'No tienes viajes liquidados anteriores',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarHistorial,
                    color: const Color(0xFF1976D2),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _viajes.length,
                      itemBuilder: (context, index) {
                        final v = _viajes[index];
                        return Card(
                          color: Colors.white,
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.route,
                                          color: Color(0xFF0D9488),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          v.codigo,
                                          style: const TextStyle(
                                            color: Color(0xFF1E293B),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: const Color(0xFF86EFAC),
                                        ),
                                      ),
                                      child: Text(
                                        v.estado.toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xFF15803D),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  v.fechaSalida != null
                                      ? 'Fecha: ${Formatters.dateShort(v.fechaSalida!)}'
                                      : 'Sin fecha registrada',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11,
                                  ),
                                ),
                                if (v.vehiculoFicha != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Vehículo: ${v.vehiculoFicha} (${v.vehiculoPlaca ?? 'S/P'})',
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                                const Divider(
                                  color: Color(0xFFF1F5F9),
                                  height: 14,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _miniItem(
                                      'Facturado',
                                      v.totalFacturado,
                                      const Color(0xFF1E293B),
                                    ),
                                    _miniItem(
                                      'Gastos',
                                      v.totalGastos,
                                      const Color(0xFFDC2626),
                                    ),
                                    _miniItem(
                                      'Margen Neto',
                                      v.margenNeto,
                                      const Color(0xFF15803D),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _miniItem(String label, double val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
        ),
        Text(
          Formatters.formatCurrency(val),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

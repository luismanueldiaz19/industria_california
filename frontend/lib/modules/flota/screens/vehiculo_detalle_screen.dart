import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehiculo.dart';
import '../providers/vehiculo_provider.dart';
import '../widgets/vehiculos/vehiculo_form_modal.dart';
import '../widgets/vehiculos/vehiculo_mantenimientos_tab.dart';

class VehiculoDetalleScreen extends StatelessWidget {
  final Vehiculo vehiculo;

  const VehiculoDetalleScreen({super.key, required this.vehiculo});

  @override
  Widget build(BuildContext context) {
    return Consumer<VehiculoProvider>(
      builder: (context, provider, child) {
        final currentVehiculo = provider.vehiculos.firstWhere(
          (v) => v.id == vehiculo.id,
          orElse: () => vehiculo,
        );

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: const Color(0xFF1A1C1E),
            appBar: AppBar(
              title: Text(
                'Vehículo: ${currentVehiculo.ficha}',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF2C2F33),
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Editar Vehículo',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          VehiculoFormModal(vehiculo: currentVehiculo),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              bottom: const TabBar(
                indicatorColor: Color(0xFFE31E24),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(text: 'INFORMACIÓN'),
                  Tab(text: 'MANTENIMIENTOS'),
                  Tab(text: 'GASTOS / ENERGÍA'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildInfoTab(currentVehiculo),
                _buildMantenimientosTab(currentVehiculo),
                _buildGastosTab(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(Vehiculo v) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Ficha:', v.ficha),
          _buildInfoRow('Placa:', v.placa ?? 'S/N'),
          _buildInfoRow(
            'Marca / Modelo:',
            '${v.marca ?? 'N/A'} ${v.modelo ?? ''}',
          ),
          if (v.anio != null) _buildInfoRow('Año:', v.anio.toString()),
          if (v.capacidadCarga != null)
            _buildInfoRow('Capacidad Carga:', '${v.capacidadCarga} kg'),
          _buildInfoRow('Energía:', v.tipoEnergia.toUpperCase()),
          _buildInfoRow(
            'Estado:',
            v.estado.toUpperCase().replaceAll('_', ' '),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Text(
            '$label ',
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMantenimientosTab(Vehiculo v) {
    return VehiculoMantenimientosTab(vehiculoId: v.id);
  }

  Widget _buildGastosTab() {
    return const Center(
      child: Text(
        'Historial de Gastos (Combustible / Carga Eléctrica)',
        style: TextStyle(color: Colors.white54, fontSize: 16),
      ),
    );
  }
}

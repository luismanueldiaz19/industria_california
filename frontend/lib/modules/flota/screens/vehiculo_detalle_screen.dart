import 'package:flutter/material.dart';
import '../providers/vehiculo_provider.dart';

class VehiculoDetalleScreen extends StatelessWidget {
  final VehiculoModel vehiculo;

  const VehiculoDetalleScreen({super.key, required this.vehiculo});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1C1E),
        appBar: AppBar(
          title: Text('Vehículo: ${vehiculo.ficha}', style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF2C2F33),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
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
            _buildInfoTab(),
            _buildMantenimientosTab(),
            _buildGastosTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Ficha:', vehiculo.ficha),
          _buildInfoRow('Placa:', vehiculo.placa),
          _buildInfoRow('Marca / Modelo:', '${vehiculo.marca} ${vehiculo.modelo}'),
          _buildInfoRow('Energía:', vehiculo.tipoEnergia.toUpperCase()),
          _buildInfoRow('Estado:', vehiculo.estado.toUpperCase().replaceAll('_', ' ')),
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
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMantenimientosTab() {
    return const Center(
      child: Text(
        'Historial de Mantenimientos y Averías',
        style: TextStyle(color: Colors.white54, fontSize: 16),
      ),
    );
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

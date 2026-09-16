import 'package:flutter/material.dart';
import '../../providers/vehiculo_provider.dart';

class VehiculoCard extends StatelessWidget {
  final VehiculoModel vehiculo;
  final VoidCallback onTap;

  const VehiculoCard({
    super.key,
    required this.vehiculo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isElectric = vehiculo.tipoEnergia == 'electrico';
    final Color statusColor = vehiculo.estado == 'disponible'
        ? Colors.green
        : vehiculo.estado == 'en_mantenimiento'
            ? Colors.orange
            : Colors.red;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2F33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vehiculo.ficha,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    vehiculo.estado.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isElectric ? Icons.electric_car : Icons.local_gas_station,
                  color: isElectric ? Colors.blueAccent : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${vehiculo.marca} ${vehiculo.modelo}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.pin_drop_outlined, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Placa: ${vehiculo.placa}',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

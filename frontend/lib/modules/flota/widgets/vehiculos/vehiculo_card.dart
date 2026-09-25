import 'package:flutter/material.dart';
import '../../models/vehiculo.dart';

class VehiculoCard extends StatelessWidget {
  final Vehiculo vehiculo;
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2F33),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                (vehiculo.capacidadCarga ?? 0) > 0 ? Icons.local_shipping : Icons.directions_car,
                color: Colors.white24,
                size: 24,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vehiculo.ficha,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              vehiculo.estado.toUpperCase().replaceAll('_', ' '),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isElectric ? Icons.electric_car : Icons.local_gas_station,
                        color: isElectric ? Colors.blueAccent : Colors.grey,
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${vehiculo.marca ?? 'Sin marca'} ${vehiculo.modelo ?? ''}',
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.pin_drop_outlined, color: Colors.grey, size: 11),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Placa: ${vehiculo.placa ?? 'S/N'}',
                          style: const TextStyle(color: Colors.white54, fontSize: 9),
                          overflow: TextOverflow.ellipsis,
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
}

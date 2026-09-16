import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/despacho_provider.dart';
import '../widgets/despachos/despacho_asignacion_modal.dart';

class DespachosScreen extends StatefulWidget {
  const DespachosScreen({super.key});

  @override
  State<DespachosScreen> createState() => _DespachosScreenState();
}

class _DespachosScreenState extends State<DespachosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DespachoProvider>().mockLoad();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C1E),
      appBar: AppBar(
        title: const Text('Despachos y Asignaciones', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2C2F33),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const DespachoAsignacionModal(),
              );
            },
            icon: const Icon(Icons.add, color: Colors.white, size: 16),
            label: const Text('Nuevo Despacho', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31E24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<DespachoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE31E24)));
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView.builder(
              itemCount: provider.despachos.length,
              itemBuilder: (context, index) {
                final despacho = provider.despachos[index];
                final inTransit = despacho.estado == 'en_transito';
                return Card(
                  color: const Color(0xFF2C2F33),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.local_shipping, color: inTransit ? Colors.blue : Colors.grey),
                    ),
                    title: Text('Vehículo: ${despacho.vehiculoFicha}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Chofer: ${despacho.choferNombre}\nSalida: ${despacho.fechaSalida}', style: const TextStyle(color: Colors.white54)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (inTransit ? Colors.blue : Colors.grey).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        despacho.estado.toUpperCase().replaceAll('_', ' '),
                        style: TextStyle(
                          color: inTransit ? Colors.blue : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mantenimiento_provider.dart';
import '../widgets/vehiculos/mantenimiento_form_modal.dart';

class MantenimientosScreen extends StatefulWidget {
  const MantenimientosScreen({super.key});

  @override
  State<MantenimientosScreen> createState() => _MantenimientosScreenState();
}

class _MantenimientosScreenState extends State<MantenimientosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MantenimientoProvider>().mockLoad();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C1E),
      appBar: AppBar(
        title: const Text('Mantenimientos y Averías', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2C2F33),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFE31E24)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const MantenimientoFormModal(),
              );
            },
          ),
        ],
      ),
      body: Consumer<MantenimientoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE31E24)));
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView.builder(
              itemCount: provider.mantenimientos.length,
              itemBuilder: (context, index) {
                final mant = provider.mantenimientos[index];
                return Card(
                  color: const Color(0xFF2C2F33),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.white10,
                      child: Icon(
                        mant.tipo == 'averia' ? Icons.warning_amber_rounded : Icons.build,
                        color: mant.tipo == 'averia' ? Colors.red : Colors.orange,
                      ),
                    ),
                    title: Text('Vehículo: ${mant.vehiculoFicha}', style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Fecha: ${mant.fecha} | Tipo: ${mant.tipo.toUpperCase()}', style: const TextStyle(color: Colors.white54)),
                    trailing: Text(
                      mant.estado.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(
                        color: mant.estado == 'resuelto' ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

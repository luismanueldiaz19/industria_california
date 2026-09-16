import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gasto_vehiculo_provider.dart';
import '../widgets/vehiculos/gasto_form_modal.dart';

class GastosVehiculosScreen extends StatefulWidget {
  const GastosVehiculosScreen({super.key});

  @override
  State<GastosVehiculosScreen> createState() => _GastosVehiculosScreenState();
}

class _GastosVehiculosScreenState extends State<GastosVehiculosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GastoVehiculoProvider>().mockLoad();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C1E),
      appBar: AppBar(
        title: const Text('Gastos de Vehículo y Combustible', style: TextStyle(color: Colors.white)),
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
                builder: (context) => const GastoFormModal(),
              );
            },
          ),
        ],
      ),
      body: Consumer<GastoVehiculoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE31E24)));
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView.builder(
              itemCount: provider.gastos.length,
              itemBuilder: (context, index) {
                final gasto = provider.gastos[index];
                return Card(
                  color: const Color(0xFF2C2F33),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.receipt_long, color: Colors.blueAccent),
                    ),
                    title: Text('Vehículo: ${gasto.vehiculoFicha} - \$${gasto.montoTotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Concepto: ${gasto.concepto}\nFecha: ${gasto.fecha}', style: const TextStyle(color: Colors.white54)),
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

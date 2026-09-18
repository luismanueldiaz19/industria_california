import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vehiculo_provider.dart';
import '../widgets/vehiculos/vehiculo_card.dart';
import '../widgets/flota_stat_card.dart';
import 'vehiculo_detalle_screen.dart';
import '../widgets/vehiculos/vehiculo_form_modal.dart';

class VehiculosScreen extends StatefulWidget {
  const VehiculosScreen({super.key});

  @override
  State<VehiculosScreen> createState() => _VehiculosScreenState();
}

class _VehiculosScreenState extends State<VehiculosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehiculoProvider>().mockLoad();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C1E),
      appBar: AppBar(
        title: const Text('Flota de Vehículos', style: TextStyle(color: Colors.white)),
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
                builder: (context) => const VehiculoFormModal(),
              );
            },
          ),
        ],
      ),
      body: Consumer<VehiculoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE31E24)));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1000;
              
              int crossAxisCount = 3;
              double aspectRatio = 1.3;
              
              if (isMobile) {
                crossAxisCount = 1;
                aspectRatio = 2.5; // Wider cards for 1 column
              } else if (isTablet) {
                crossAxisCount = 2;
                aspectRatio = 1.4;
              }

              return Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Row/Column
                    if (isMobile)
                      Column(
                        children: [
                          FlotaStatCard(
                            title: 'Disponibles',
                            value: provider.totalDisponibles.toString(),
                            icon: Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 12),
                          FlotaStatCard(
                            title: 'En Taller',
                            value: provider.totalMantenimiento.toString(),
                            icon: Icons.build_outlined,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          FlotaStatCard(
                            title: 'Inactivos',
                            value: provider.totalInactivos.toString(),
                            icon: Icons.cancel_outlined,
                            color: Colors.red,
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: FlotaStatCard(
                              title: 'Disponibles',
                              value: provider.totalDisponibles.toString(),
                              icon: Icons.check_circle_outline,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FlotaStatCard(
                              title: 'En Taller',
                              value: provider.totalMantenimiento.toString(),
                              icon: Icons.build_outlined,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FlotaStatCard(
                              title: 'Inactivos',
                              value: provider.totalInactivos.toString(),
                              icon: Icons.cancel_outlined,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    
                    SizedBox(height: isMobile ? 24 : 32),
                    
                    const Text(
                      'Inventario de Vehículos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: isMobile ? 12 : 16,
                          mainAxisSpacing: isMobile ? 12 : 16,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount: provider.vehiculos.length,
                        itemBuilder: (context, index) {
                          final vehiculo = provider.vehiculos[index];
                          return VehiculoCard(
                            vehiculo: vehiculo,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VehiculoDetalleScreen(vehiculo: vehiculo),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

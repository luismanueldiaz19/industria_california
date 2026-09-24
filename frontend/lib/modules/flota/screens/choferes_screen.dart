import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chofer_provider.dart';
import '../widgets/choferes/chofer_form_modal.dart';

class ChoferesScreen extends StatefulWidget {
  const ChoferesScreen({super.key});

  @override
  State<ChoferesScreen> createState() => _ChoferesScreenState();
}

class _ChoferesScreenState extends State<ChoferesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChoferProvider>().fetchChoferes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C1E),
      appBar: AppBar(
        title: const Text(
          'Gestión de Choferes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF232529),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<ChoferProvider>().fetchChoferes();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFE31E24)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const ChoferFormModal(),
              );
            },
          ),
        ],
      ),
      body: Consumer<ChoferProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE31E24)),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Text(
                'Error: ${provider.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFFE31E24),
            backgroundColor: const Color(0xFF232529),
            onRefresh: () async {
              await provider.fetchChoferes();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              child: ListView.builder(
                itemCount: provider.choferes.length,
                itemBuilder: (context, index) {
                  final chofer = provider.choferes[index];
                  final isActivo = chofer.estado == 'activo';
                  final isVacaciones = chofer.estado == 'vacaciones';

                  Color statusColor = Colors.grey;
                  if (isActivo) statusColor = const Color(0xFF4CAF50);
                  if (isVacaciones) statusColor = const Color(0xFFFF9800);

                  return GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => ChoferFormModal(chofer: chofer),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2F33),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: statusColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chofer.name ?? 'Sin Nombre',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Licencia: ${chofer.numeroLicencia ?? 'N/A'}${chofer.tipoLicencia != null ? ' (${chofer.tipoLicencia})' : ''}\n'
                                    'Vence: ${chofer.vencimientoLicencia != null ? chofer.vencimientoLicencia!.split('T').first : 'N/A'}\n'
                                    'Emergencia: ${chofer.contactoEmergencia ?? 'N/A'}\n'
                                    'Email: ${chofer.email ?? 'N/A'}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                chofer.estado.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

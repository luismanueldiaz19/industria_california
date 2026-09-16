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
      context.read<ChoferProvider>().mockLoad();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C1E),
      appBar: AppBar(
        title: const Text('Gestión de Choferes', style: TextStyle(color: Colors.white)),
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
                builder: (context) => const ChoferFormModal(),
              );
            },
          ),
        ],
      ),
      body: Consumer<ChoferProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE31E24)));
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView.builder(
              itemCount: provider.choferes.length,
              itemBuilder: (context, index) {
                final chofer = provider.choferes[index];
                final isActivo = chofer.estado == 'activo';
                return Card(
                  color: const Color(0xFF2C2F33),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.person, color: isActivo ? Colors.green : Colors.grey),
                    ),
                    title: Text(chofer.nombre, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Licencia: ${chofer.licencia}', style: const TextStyle(color: Colors.white54)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isActivo ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        chofer.estado.toUpperCase(),
                        style: TextStyle(
                          color: isActivo ? Colors.green : Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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

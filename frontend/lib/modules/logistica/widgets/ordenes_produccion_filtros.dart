import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/orden_produccion_provider.dart';

class OrdenesProduccionFiltros extends StatefulWidget {
  const OrdenesProduccionFiltros({super.key});

  @override
  State<OrdenesProduccionFiltros> createState() =>
      _OrdenesProduccionFiltrosState();
}

class _OrdenesProduccionFiltrosState extends State<OrdenesProduccionFiltros> {
  String _estadoFiltro = 'pendiente';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdenProduccionProvider>().setEstadoFiltro(_estadoFiltro);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2C2F33),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text(
            'Estado: ',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF23272A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _estadoFiltro.isEmpty ? null : _estadoFiltro,
                hint: const Text(
                  'Todos',
                  style: TextStyle(color: Colors.white70),
                ),
                dropdownColor: const Color(0xFF23272A),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Todos')),
                  DropdownMenuItem(
                    value: 'pendiente',
                    child: Text('Pendiente'),
                  ),
                  DropdownMenuItem(
                    value: 'en_proceso',
                    child: Text('En Proceso'),
                  ),
                  DropdownMenuItem(value: 'lista', child: Text('Lista')),
                ],
                onChanged: (val) {
                  setState(() {
                    _estadoFiltro = val ?? '';
                  });
                  context.read<OrdenProduccionProvider>().setEstadoFiltro(
                    _estadoFiltro,
                  );
                },
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              context.read<OrdenProduccionProvider>().fetchOrdenes(
                refresh: true,
              );
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

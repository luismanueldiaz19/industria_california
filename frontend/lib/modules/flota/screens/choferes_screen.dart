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
  String _searchQuery = '';

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
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFF2C2F33),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf,
              color: Colors.white70,
              size: 20,
            ),
            tooltip: 'Exportar PDF',
            onPressed: () {
              context.read<ChoferProvider>().generarPdf();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            onPressed: () {
              context.read<ChoferProvider>().fetchChoferes();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFE31E24), size: 20),
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

          final filteredChoferes = provider.choferes.where((c) {
            final query = _searchQuery.toLowerCase();
            return (c.name?.toLowerCase().contains(query) ?? false) ||
                (c.username?.toLowerCase().contains(query) ?? false) ||
                (c.numeroLicencia?.toLowerCase().contains(query) ?? false) ||
                (c.estado.toLowerCase().contains(query));
          }).toList();

          return Column(
            children: [
              Container(
                color: const Color(0xFF2C2F33),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText:
                          'Buscar por nombre, usuario, licencia o estado...',
                      hintStyle: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white54,
                        size: 16,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1C1E),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFFE31E24),
                  backgroundColor: const Color(0xFF232529),
                  onRefresh: () async {
                    await provider.fetchChoferes();
                  },
                  child: filteredChoferes.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(
                              child: Text(
                                'No se encontraron choferes.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Theme(
                              data: Theme.of(
                                context,
                              ).copyWith(dividerColor: Colors.white10),
                              child: DataTable(
                                border: TableBorder.all(color: Colors.white10),
                                headingRowHeight: 32,
                                dataRowMinHeight: 32,
                                dataRowMaxHeight: 32,
                                columnSpacing: 20,
                                showCheckboxColumn: false,
                                headingTextStyle: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                dataTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                                columns: const [
                                  DataColumn(label: Text('NOMBRE')),
                                  DataColumn(label: Text('USUARIO')),
                                  DataColumn(label: Text('LICENCIA')),
                                  DataColumn(label: Text('TIPO')),
                                  DataColumn(label: Text('VENCE')),
                                  DataColumn(label: Text('EMERGENCIA')),
                                  DataColumn(label: Text('ESTADO')),
                                ],
                                rows: filteredChoferes.map((chofer) {
                                  final isActivo = chofer.estado == 'activo';
                                  final isVacaciones =
                                      chofer.estado == 'vacaciones';

                                  Color statusColor = Colors.grey;
                                  if (isActivo)
                                    statusColor = const Color(0xFF4CAF50);
                                  if (isVacaciones)
                                    statusColor = const Color(0xFFFF9800);

                                  return DataRow(
                                    onSelectChanged: (_) {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) =>
                                            ChoferFormModal(chofer: chofer),
                                      );
                                    },
                                    cells: [
                                      DataCell(Text(chofer.name ?? 'N/A')),
                                      DataCell(Text(chofer.username ?? 'N/A')),
                                      DataCell(
                                        Text(chofer.numeroLicencia ?? 'N/A'),
                                      ),
                                      DataCell(
                                        Text(chofer.tipoLicencia ?? 'N/A'),
                                      ),
                                      DataCell(
                                        Text(
                                          chofer.vencimientoLicencia != null
                                              ? chofer.vencimientoLicencia!
                                                    .split('T')
                                                    .first
                                              : 'N/A',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          chofer.contactoEmergencia ?? 'N/A',
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: statusColor.withValues(
                                                alpha: 0.3,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            chofer.estado.toUpperCase(),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

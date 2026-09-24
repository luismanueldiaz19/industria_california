import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../camion_victual/providers/camion_victual_provider.dart';
import '../widgets/camiones/camion_victual_form_modal.dart';

class CamionesVictualesAdminScreen extends StatefulWidget {
  const CamionesVictualesAdminScreen({super.key});

  @override
  State<CamionesVictualesAdminScreen> createState() =>
      _CamionesVictualesAdminScreenState();
}

class _CamionesVictualesAdminScreenState
    extends State<CamionesVictualesAdminScreen> {
  String? _filtroEstado = 'todos';
  int? _filtroVendedorId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CamionVictualProvider>().fetchCamiones();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C1E),
      appBar: AppBar(
        title: const Text(
          'Administrar Camiones',
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
              context.read<CamionVictualProvider>().fetchCamiones();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFE31E24)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const CamionVictualFormModal(),
              );
            },
          ),
        ],
      ),
      body: Consumer<CamionVictualProvider>(
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

          if (provider.camiones.isEmpty) {
            return const Center(
              child: Text(
                'No hay camiones victuales registrados.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return Column(
            children: [
              _buildFiltros(provider),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFFE31E24),
                  backgroundColor: const Color(0xFF232529),
                  onRefresh: () async {
                    await provider.fetchCamiones();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Builder(
                      builder: (context) {
                        final camionesFiltrados = provider.camiones.where((c) {
                          if (_filtroEstado != 'todos' &&
                              c.estado != _filtroEstado) {
                            return false;
                          }
                          if (_filtroVendedorId != null &&
                              c.vendedorId != _filtroVendedorId) {
                            return false;
                          }
                          return true;
                        }).toList();

                        if (camionesFiltrados.isEmpty) {
                          return const Center(
                            child: Text(
                              'No hay camiones con estos filtros.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          );
                        }

                        return GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 400,
                                mainAxisExtent: 160,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: camionesFiltrados.length,
                          itemBuilder: (context, index) {
                            final camion = camionesFiltrados[index];

                            Color statusColor = Colors.grey;
                            if (camion.estado == 'vacio') {
                              statusColor = Colors.blueGrey;
                            }
                            if (camion.estado == 'armando') {
                              statusColor = Colors.blue;
                            }
                            if (camion.estado == 'listo') {
                              statusColor = Colors.green;
                            }
                            if (camion.estado == 'en_ruta') {
                              statusColor = Colors.orange;
                            }
                            if (camion.estado == 'cerrado') {
                              statusColor = Colors.red;
                            }

                            return GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      CamionVictualFormModal(camion: camion),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C2F33),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.05,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.local_shipping,
                                          color: statusColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              camion.nombre.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'Vendedor Asignado',
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              camion.vendedorNombre
                                                  .toString()
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const Spacer(),
                                            Wrap(
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              spacing: 12,
                                              runSpacing: 4,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.attach_money,
                                                      color: Colors.greenAccent,
                                                      size: 16,
                                                    ),
                                                    Text(
                                                      camion.montoTotal
                                                          .toStringAsFixed(2),
                                                      style: const TextStyle(
                                                        color:
                                                            Colors.greenAccent,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.shopping_bag,
                                                      color: Colors.white54,
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${camion.pedidos.length} pedidos',
                                                      style: const TextStyle(
                                                        color: Colors.white54,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              camion.estado.toUpperCase(),
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '#${camion.id}',
                                            style: const TextStyle(
                                              color: Colors.white30,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
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

  Widget _buildFiltros(CamionVictualProvider provider) {
    // Extraer vendedores únicos
    final vendedoresMap = <int, String>{};
    for (var c in provider.camiones) {
      if (c.vendedorNombre != null) {
        vendedoresMap[c.vendedorId] = c.vendedorNombre!;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF232529),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filtroEstado,
              dropdownColor: const Color(0xFF3B3E43),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Estado',
                labelStyle: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: const Color(0xFF1A1C1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'todos', child: Text('TODOS')),
                DropdownMenuItem(value: 'vacio', child: Text('VACIO')),
                DropdownMenuItem(value: 'armando', child: Text('ARMANDO')),
                DropdownMenuItem(value: 'listo', child: Text('LISTO')),
                DropdownMenuItem(value: 'en_ruta', child: Text('EN RUTA')),
                DropdownMenuItem(value: 'cerrado', child: Text('CERRADO')),
              ],
              onChanged: (v) => setState(() => _filtroEstado = v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int?>(
              value: _filtroVendedorId,
              dropdownColor: const Color(0xFF3B3E43),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Vendedor',
                labelStyle: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: const Color(0xFF1A1C1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('TODOS')),
                ...vendedoresMap.entries.map((e) {
                  return DropdownMenuItem<int?>(
                    value: e.key,
                    child: Text(
                      e.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (v) => setState(() => _filtroVendedorId = v),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/app_date_picker.dart';
import '../../../core/widgets/quick_date_filter.dart';
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
      context.read<MantenimientoProvider>().loadMantenimientos();
    });
  }

  void _confirmDelete(BuildContext context, MantenimientoProvider provider, dynamic mant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2F33),
        title: const Text('Eliminar Mantenimiento', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text('¿Está seguro de eliminar este mantenimiento?', style: TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await provider.deleteMantenimiento(mant.vehiculoId, mant.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Eliminado'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al eliminar'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C1E),
      appBar: AppBar(
        title: const Text(
          'Mantenimientos y Averías',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF2C2F33),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white70),
            tooltip: 'Exportar PDF',
            onPressed: () {
              context.read<MantenimientoProvider>().generarPdf();
            },
          ),
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
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE31E24)),
            );
          }

          final filtrados = provider.mantenimientosPaginados;
          final vehiculos = provider.vehiculosUnicos;

          return Column(
            children: [
              // PANEL DE FILTROS Y TOTALES
              Container(
                color: const Color(0xFF2C2F33),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    // Fila 1: Filtros principales
                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallDropdown(
                            value: provider.filtroVehiculoFicha,
                            items: ['Todos', ...vehiculos],
                            hint: 'Veh',
                            onChanged: (val) => provider.setFiltroVehiculo(
                              val == 'Todos' ? null : val,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildSmallDropdown(
                            value: provider.filtroTipo,
                            items: [
                              'Todos',
                              'Preventivo',
                              'Correctivo',
                              'Averia',
                            ],
                            hint: 'Tipo',
                            onChanged: (val) => provider.setFiltroTipo(val!),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildSmallDropdown(
                            value: provider.filtroEstado,
                            items: [
                              'Todos',
                              'Pendiente',
                              'En Proceso',
                              'Resuelto',
                            ],
                            hint: 'Est',
                            onChanged: (val) => provider.setFiltroEstado(val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Fila 2: Fechas, Orden y Paginador
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            QuickDateFilter(
                              selectedOption: provider.quickDateFilter,
                              onChanged: (val) => provider.setQuickDateFilter(val),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () async {
                                final picked = await AppDatePicker.showRangePicker(
                                  context: context,
                                  initialDateRange: provider.filtroRangoFecha,
                                );
                                if (picked != null) {
                                  provider.setFiltroRangoFecha(picked);
                                }
                              },
                              onLongPress: () => provider.setFiltroRangoFecha(null),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: provider.filtroRangoFecha != null
                                      ? Colors.redAccent.withValues(alpha: 0.2)
                                      : const Color(0xFF1A1C1E),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.calendar_month,
                                  color: provider.filtroRangoFecha != null
                                      ? Colors.redAccent
                                      : Colors.white70,
                                  size: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: provider.toggleSort,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1C1E),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  provider.sortByDateDesc
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text(
                              'Por pág: ',
                              style: TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                            SizedBox(
                              width: 45,
                              child: _buildSmallDropdown(
                                value: provider.itemsPerPage.toString(),
                                items: ['10', '20', '50', '100'],
                                onChanged: (val) =>
                                    provider.setItemsPerPage(int.parse(val!)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Fila 3: Totales
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mostrando: ${provider.totalReportes}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Costo Total: ${Formatters.formatCurrency(provider.totalCosto)}',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // LISTADO
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final mant = filtrados[index];
                    final bool isAveria = mant.tipo == 'averia';
                    final bool isResuelto = mant.estado == 'resuelto';

                    return Card(
                      color: const Color(0xFF2C2F33),
                      margin: const EdgeInsets.only(bottom: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isAveria
                                      ? Icons.warning_amber_rounded
                                      : Icons.build,
                                  color: isAveria ? Colors.red : Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Vehículo: ${mant.vehiculoFicha ?? 'S/N'}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isResuelto
                                        ? Colors.green.withValues(alpha: 0.2)
                                        : Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    mant.estado.toUpperCase().replaceAll(
                                      '_',
                                      ' ',
                                    ),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isResuelto
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fecha: ${mant.fechaReporte != null ? Formatters.dateShort(mant.fechaReporte!) : 'N/A'} | Tipo: ${mant.tipo.toUpperCase()}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                            if (mant.descripcion.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                mant.descripcion,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Reporta: ${mant.reportadorNombre ?? 'N/A'}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                                if (mant.costo > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Text(
                                      Formatters.formatCurrency(mant.costo),
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => MantenimientoFormModal(mantenimiento: mant),
                                        );
                                      },
                                      child: const Icon(Icons.edit, color: Colors.white54, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _confirmDelete(context, provider, mant),
                                      child: const Icon(Icons.delete, color: Colors.redAccent, size: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // PAGINACION
              if (provider.totalPages > 1)
                Container(
                  color: const Color(0xFF2C2F33),
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: provider.currentPage > 1
                            ? provider.previousPage
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Pág ${provider.currentPage} de ${provider.totalPages}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: provider.currentPage < provider.totalPages
                            ? provider.nextPage
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSmallDropdown({
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? hint,
  }) {
    final currentValue = value ?? 'Todos';

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C1E),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(currentValue) ? currentValue : items.first,
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Colors.white54,
            size: 14,
          ),
          dropdownColor: const Color(0xFF2C2F33),
          style: const TextStyle(color: Colors.white, fontSize: 9),
          items: items.map((item) {
            String label = item;
            if (hint != null) {
              label = '$hint: $item';
            }
            return DropdownMenuItem<String>(
              value: item,
              child: Text(label, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

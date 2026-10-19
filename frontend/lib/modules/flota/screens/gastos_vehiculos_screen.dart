import 'package:flutter/material.dart';
import 'package:industria_california/core/widgets/compact_snack_bar.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/app_date_picker_dark.dart';
import '../../../core/widgets/quick_date_filter.dart';
import '../models/vehiculo_gasto.dart';
import '../providers/gasto_vehiculo_provider.dart';
import '../widgets/vehiculos/gasto_form_modal.dart';
import '../../auth/providers/auth_provider.dart';

class GastosVehiculosScreen extends StatefulWidget {
  const GastosVehiculosScreen({super.key});

  @override
  State<GastosVehiculosScreen> createState() => _GastosVehiculosScreenState();
}

class _GastosVehiculosScreenState extends State<GastosVehiculosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollCtrl = ScrollController();
  final ScrollController _verticalScrollCtrl = ScrollController();

  static const _headerStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 11,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GastoVehiculoProvider>().loadGastos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollCtrl.dispose();
    _verticalScrollCtrl.dispose();
    super.dispose();
  }

  void _confirmDelete(
    BuildContext context,
    GastoVehiculoProvider provider,
    VehiculoGasto gasto,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2F33),
        title: const Text(
          'Eliminar Gasto',
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
        content: Text(
          '¿Está seguro de eliminar el gasto #${gasto.id} "${gasto.concepto}" por ${Formatters.formatCurrency(gasto.montoTotal)}?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await provider.deleteGasto(gasto.vehiculoId, gasto.id);
                if (context.mounted) {
                  CompactSnackBar.showSuccess(context, 'Gasto eliminado con éxito');
                }
              } catch (e) {
                if (context.mounted) {
                  CompactSnackBar.showError(context, 'Error al eliminar el gasto');
                }
              }
            },
            child: const Text(
              'ELIMINAR',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showComprobanteDialog(BuildContext context, VehiculoGasto gasto) {
    final List<dynamic> comps = (gasto.comprobantes != null && gasto.comprobantes!.isNotEmpty)
        ? gasto.comprobantes!
        : (gasto.comprobante != null && gasto.comprobante!.isNotEmpty
            ? [gasto.comprobante!]
            : []);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2F33),
        title: Row(
          children: const [
            Icon(Icons.receipt_long, color: Colors.blueAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'Comprobantes / NCF',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gasto #${gasto.id} - ${gasto.concepto}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (comps.isEmpty)
              const Text(
                'No hay comprobantes asociados registrados.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              )
            else
              ...comps.map(
                (c) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1C1E),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: SelectableText(
                    c.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CERRAR', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Color _getTipoColor(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'combustible':
        return Colors.orangeAccent;
      case 'mantenimiento':
      case 'taller':
      case 'repuesto':
        return Colors.blueAccent;
      case 'dieta':
      case 'comida':
        return Colors.purpleAccent;
      case 'peaje':
        return Colors.cyanAccent;
      case 'lavado':
        return Colors.tealAccent;
      default:
        return Colors.amberAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1C1E),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Color(0xFFE31E24), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Gastos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Consumer<GastoVehiculoProvider>(
              builder: (context, p, _) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${p.totalReportes}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2C2F33),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
            tooltip: 'Recargar datos',
            onPressed: () {
              context.read<GastoVehiculoProvider>().loadGastos();
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white70, size: 20),
            tooltip: 'Exportar PDF',
            onPressed: () {
              context.read<GastoVehiculoProvider>().generarPdf();
            },
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31E24),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 1,
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'Nuevo Gasto',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const GastoFormModal(),
                );
              },
            ),
          ),
        ],
      ),
      body: Consumer<GastoVehiculoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.gastos.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE31E24)),
            );
          }

          final filtrados = provider.gastosPaginados;
          final vehiculos = provider.vehiculosUnicos;
          final bool hasActiveFilters = provider.searchQuery.isNotEmpty ||
              provider.filtroVehiculoFicha != null ||
              provider.filtroTipoGasto != 'Todos' ||
              provider.filtroOrigen != 'Todos' ||
              provider.quickDateFilter != DateFilterOption.todos ||
              provider.filtroRangoFecha != null;

          return Column(
            children: [
              // PANEL SUPERIOR DE FILTROS Y BÚSQUEDA
              Container(
                color: const Color(0xFF2C2F33),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  children: [
                    // Fila 1: Campo de Búsqueda de Texto rápido
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1C1E),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                hintText:
                                    'Buscar en historial (concepto, ficha, viaje, NCF, registrado por)...',
                                hintStyle: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.white54,
                                  size: 16,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          color: Colors.white54,
                                          size: 14,
                                        ),
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          _searchController.clear();
                                          provider.clearSearchQuery();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 9,
                                ),
                              ),
                              onChanged: (val) {
                                setState(() {});
                                provider.setSearchQuery(val);
                              },
                            ),
                          ),
                        ),
                        if (hasActiveFilters) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              _searchController.clear();
                              provider.resetFiltros();
                              setState(() {});
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              height: 34,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.redAccent.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.filter_alt_off,
                                      color: Colors.redAccent, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Limpiar',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Fila 2: Filtros desplegables y de fecha
                    Row(
                      children: [
                        // Origen (Todos / Viajes / Flota)
                        Expanded(
                          flex: 3,
                          child: _buildSmallDropdown(
                            value: provider.filtroOrigen,
                            items: const ['Todos', 'Viajes', 'Flota / Planta'],
                            hint: 'Origen',
                            onChanged: (val) => provider.setFiltroOrigen(val!),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Vehículo
                        Expanded(
                          flex: 3,
                          child: _buildSmallDropdown(
                            value: provider.filtroVehiculoFicha,
                            items: ['Todos', ...vehiculos],
                            hint: 'Vehículo',
                            onChanged: (val) => provider.setFiltroVehiculo(
                              val == 'Todos' ? null : val,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Tipo de Gasto
                        Expanded(
                          flex: 3,
                          child: _buildSmallDropdown(
                            value: provider.filtroTipoGasto,
                            items: [
                              'Todos',
                              ...provider.tiposGasto.map((t) => t.nombre),
                            ],
                            hint: 'Tipo',
                            onChanged: (val) => provider.setFiltroTipo(val!),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Filtros de Fecha Rápida
                        QuickDateFilter(
                          selectedOption: provider.quickDateFilter,
                          onChanged: (val) => provider.setQuickDateFilter(val),
                        ),
                        const SizedBox(width: 4),

                        // Selector Rango Calendario
                        InkWell(
                          onTap: () async {
                            final picked =
                                await AppDatePickerDark.showRangePicker(
                              context: context,
                              initialDateRange: provider.filtroRangoFecha,
                            );
                            if (picked != null) {
                              provider.setFiltroRangoFecha(picked);
                            }
                          },
                          onLongPress: () => provider.setFiltroRangoFecha(null),
                          child: Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: provider.filtroRangoFecha != null
                                  ? Colors.redAccent.withValues(alpha: 0.2)
                                  : const Color(0xFF1A1C1E),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: provider.filtroRangoFecha != null
                                    ? Colors.redAccent
                                    : Colors.white12,
                              ),
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

                        // Ordenar por Fecha Asc / Desc
                        InkWell(
                          onTap: provider.toggleSort,
                          child: Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1C1E),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white12),
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
                    const SizedBox(height: 8),

                    // Fila 3: Totales y métricas de filtrado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Historial: ',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            Text(
                              '${provider.totalReportes} registro${provider.totalReportes == 1 ? '' : 's'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (hasActiveFilters) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orangeAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Filtro activo',
                                  style: TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            const Text(
                              'Costo Total Filtrado: ',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            Text(
                              Formatters.formatCurrency(provider.totalCosto),
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // CONTENIDO PRINCIPAL: DATATABLE
              Expanded(
                child: filtrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.receipt_long_outlined,
                              color: Colors.white24,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No se encontraron gastos con los criterios seleccionados',
                              style: TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            if (hasActiveFilters)
                              TextButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  provider.resetFiltros();
                                  setState(() {});
                                },
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Color(0xFFE31E24),
                                  size: 16,
                                ),
                                label: const Text(
                                  'Restablecer filtros',
                                  style: TextStyle(
                                    color: Color(0xFFE31E24),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return Scrollbar(
                            controller: _horizontalScrollCtrl,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: _horizontalScrollCtrl,
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                ),
                                child: Scrollbar(
                                  controller: _verticalScrollCtrl,
                                  child: SingleChildScrollView(
                                    controller: _verticalScrollCtrl,
                                    child: DataTable(
                                      showCheckboxColumn: false,
                                      columnSpacing: 14,
                                      dataRowMinHeight: 38,
                                      dataRowMaxHeight: 46,
                                      headingRowHeight: 36,
                                      headingRowColor:
                                          WidgetStateProperty.all(
                                        const Color(0xFF24272B),
                                      ),
                                      dividerThickness: 0.5,
                                      columns: const [
                                        DataColumn(
                                          label: Text('# ID', style: _headerStyle),
                                        ),
                                        DataColumn(
                                          label: Text('Fecha', style: _headerStyle),
                                        ),
                                        DataColumn(
                                          label: Text('Vehículo', style: _headerStyle),
                                        ),
                                        DataColumn(
                                          label: Text('Origen', style: _headerStyle),
                                        ),
                                        DataColumn(
                                          label: Text('Tipo', style: _headerStyle),
                                        ),
                                        DataColumn(
                                          label: Text('Concepto', style: _headerStyle),
                                        ),
                                        DataColumn(
                                          numeric: true,
                                          label: Text('Cant.', style: _headerStyle),
                                        ),
                                        DataColumn(
                                          numeric: true,
                                          label: Text('P. Unit.', style: _headerStyle),
                                        ),
                                        DataColumn(
                                          numeric: true,
                                          label: Text('Monto Total', style: _headerStyle),
                                        ),
                                        DataColumn(
                                          label: Text('Comprobante', style: _headerStyle),
                                        ),
                                        DataColumn(
                                          label: Text('Registrador', style: _headerStyle),
                                        ),
                                        DataColumn(
                                          label: Text('Acciones', style: _headerStyle),
                                        ),
                                      ],
                                      rows: filtrados
                                          .map((g) => _buildRow(
                                                context,
                                                provider,
                                                g,
                                                isAdmin,
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // BARRA DE PAGINACIÓN Y FILAS POR PÁGINA
              Container(
                color: const Color(0xFF2C2F33),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Filas por página
                    Row(
                      children: [
                        const Text(
                          'Filas por página: ',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        SizedBox(
                          width: 55,
                          child: _buildSmallDropdown(
                            value: provider.itemsPerPage.toString(),
                            items: const ['10', '20', '50', '100'],
                            onChanged: (val) =>
                                provider.setItemsPerPage(int.parse(val!)),
                          ),
                        ),
                      ],
                    ),

                    // Indicador y controles de página
                    Row(
                      children: [
                        Text(
                          'Página ${provider.currentPage} de ${provider.totalPages == 0 ? 1 : provider.totalPages}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.first_page, size: 18),
                          color: Colors.white70,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: provider.currentPage > 1
                              ? () {
                                  while (provider.currentPage > 1) {
                                    provider.previousPage();
                                  }
                                }
                              : null,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 18),
                          color: Colors.white70,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: provider.currentPage > 1
                              ? provider.previousPage
                              : null,
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 18),
                          color: Colors.white70,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: provider.currentPage < provider.totalPages
                              ? provider.nextPage
                              : null,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.last_page, size: 18),
                          color: Colors.white70,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: provider.currentPage < provider.totalPages
                              ? () {
                                  while (provider.currentPage < provider.totalPages) {
                                    provider.nextPage();
                                  }
                                }
                              : null,
                        ),
                      ],
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

  DataRow _buildRow(
    BuildContext context,
    GastoVehiculoProvider provider,
    VehiculoGasto gasto,
    bool isAdmin,
  ) {
    final tipoColor = _getTipoColor(gasto.tipoGasto);
    final bool isViaje = gasto.viajeId != null;
    final bool hasVehiculo = gasto.vehiculo != null;
    final List<dynamic> comps = (gasto.comprobantes != null && gasto.comprobantes!.isNotEmpty)
        ? gasto.comprobantes!
        : (gasto.comprobante != null && gasto.comprobante!.isNotEmpty
            ? [gasto.comprobante!]
            : []);

    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) {
          return Colors.white.withValues(alpha: 0.04);
        }
        return null;
      }),
      cells: [
        // 1. # ID
        DataCell(
          Text(
            '#${gasto.id}',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // 2. Fecha
        DataCell(
          Text(
            gasto.fechaGasto != null
                ? Formatters.dateShort(gasto.fechaGasto!)
                : '—',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),

        // 3. Vehículo
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (hasVehiculo ? Colors.blue : Colors.amber)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: (hasVehiculo ? Colors.blue : Colors.amber)
                    .withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasVehiculo ? Icons.local_shipping : Icons.business,
                  size: 12,
                  color: hasVehiculo ? Colors.blueAccent : Colors.amberAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  hasVehiculo
                      ? (gasto.vehiculo?['ficha'] ?? 'S/N')
                      : 'GENERAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: hasVehiculo ? Colors.blueAccent : Colors.amberAccent,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 4. Origen / Viaje
        DataCell(
          isViaje
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.tealAccent.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.route, size: 12, color: Colors.tealAccent),
                      const SizedBox(width: 4),
                      Text(
                        gasto.viaje?['codigo'] ?? 'VIAJE',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.tealAccent,
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FLOTA / TALLER',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white60,
                    ),
                  ),
                ),
        ),

        // 5. Tipo de Gasto
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: tipoColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: tipoColor.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Text(
              (gasto.tipoGasto ?? 'OTRO').toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: tipoColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // 6. Concepto
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Tooltip(
              message: gasto.concepto,
              child: Text(
                gasto.concepto.isNotEmpty ? gasto.concepto : '—',
                style: const TextStyle(color: Colors.white, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),

        // 7. Cantidad
        DataCell(
          Text(
            '${gasto.cantidad.toStringAsFixed(gasto.cantidad.truncateToDouble() == gasto.cantidad ? 0 : 2)}${gasto.unidadMedida != null && gasto.unidadMedida != 'UNIDAD' ? ' ${gasto.unidadMedida}' : ''}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),

        // 8. Precio Unitario
        DataCell(
          Text(
            Formatters.formatCurrency(gasto.precioUnitario),
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ),

        // 9. Monto Total
        DataCell(
          Text(
            Formatters.formatCurrency(gasto.montoTotal),
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 10. Comprobante / NCF
        DataCell(
          comps.isNotEmpty
              ? InkWell(
                  onTap: () => _showComprobanteDialog(context, gasto),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.purpleAccent.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.receipt,
                          size: 11,
                          color: Colors.purpleAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          comps.first.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.purpleAccent,
                          ),
                        ),
                        if (comps.length > 1)
                          Text(
                            ' (+${comps.length - 1})',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.purpleAccent,
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : const Text(
                  '—',
                  style: TextStyle(color: Colors.white24, fontSize: 11),
                ),
        ),

        // 11. Registrado por
        DataCell(
          Text(
            gasto.registrador?['name'] ?? '—',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ),

        // 12. Acciones
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16),
                color: Colors.white70,
                tooltip: 'Editar gasto',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => GastoFormModal(gasto: gasto),
                  );
                },
              ),
              if (isAdmin) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  color: Colors.redAccent,
                  tooltip: 'Eliminar gasto',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  onPressed: () => _confirmDelete(context, provider, gasto),
                ),
              ],
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C1E),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(currentValue) ? currentValue : items.first,
          isExpanded: true,
          menuMaxHeight: 300,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Colors.white54,
            size: 14,
          ),
          dropdownColor: const Color(0xFF2C2F33),
          style: const TextStyle(color: Colors.white, fontSize: 11),
          items: items.map((item) {
            String label = item;
            if (hint != null) {
              label = '$hint: $item';
            }
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

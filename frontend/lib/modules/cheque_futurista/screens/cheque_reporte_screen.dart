import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/general_header.dart';
import '../providers/cheque_reporte_provider.dart';
import '../utils/cheque_admin_utils.dart';
import '../../../core/widgets/quick_date_filter.dart';
import '../../../core/utils/app_date_picker_dark.dart';

class ChequeReporteScreen extends StatefulWidget {
  const ChequeReporteScreen({super.key});

  @override
  State<ChequeReporteScreen> createState() => _ChequeReporteScreenState();
}

class _ChequeReporteScreenState extends State<ChequeReporteScreen> {
  DateFilterOption _selectedQuickDate = DateFilterOption.todos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChequeReporteProvider>().fetchReporte();
    });
  }

  Widget _buildFilterBar() {
    return Container(
      color: const Color(0xFF1A1C1E),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Filtro Rápido
          QuickDateFilter(
            isDark: true,
            selectedOption: _selectedQuickDate,
            onChanged: (val) {
              setState(() => _selectedQuickDate = val);
              final provider = context.read<ChequeReporteProvider>();
              if (val == DateFilterOption.todos) {
                provider.setDateRange(null, null);
              } else {
                final range = QuickDateFilter.getRangeForFilter(val)!;
                provider.setDateRange(range.start, range.end);
              }
            },
          ),
          // Rango Personalizado
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              foregroundColor: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            icon: const Icon(
              Icons.date_range,
              color: ChequeAdminColors.blue,
              size: 18,
            ),
            label: const Text('Rango Específico'),
            onPressed: () async {
              final range = await AppDatePickerDark.showRangePicker(
                context: context,
              );
              if (range != null) {
                setState(() => _selectedQuickDate = DateFilterOption.todos);
                context.read<ChequeReporteProvider>().setDateRange(
                  range.start,
                  range.end,
                );
              }
            },
          ),
          // Tipo de Fecha
          Consumer<ChequeReporteProvider>(
            builder: (context, provider, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: provider.tipoFecha,
                    dropdownColor: const Color(0xFF2A2D30),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white54,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'creacion',
                        child: Text('Fecha de Creación'),
                      ),
                      DropdownMenuItem(
                        value: 'deposito',
                        child: Text('Fecha de Depósito'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        provider.setTipoFecha(val);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBgColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GeneralHeader(
            title: 'Reporte de Cheques',
            subtitle: 'Resumen agrupado por vendedores',
            icon: Icons.bar_chart_rounded,
            iconColor: ChequeAdminColors.blue,
            actions: [
              HeaderButton(
                icon: Icons.picture_as_pdf_rounded,
                tooltip: 'Generar PDF',
                onTap: () {},
              ),
              const SizedBox(width: 8),
              HeaderButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Actualizar',
                onTap: () =>
                    context.read<ChequeReporteProvider>().fetchReporte(),
              ),
            ],
          ),
          _buildFilterBar(),
          Expanded(
            child: Consumer<ChequeReporteProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: ChequeAdminColors.blue,
                    ),
                  );
                }
                if (provider.error != null) {
                  return Center(
                    child: Text(
                      provider.error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }
                if (provider.reporte.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay datos para mostrar',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Adaptive layout
                    if (constraints.maxWidth < 600) {
                      return _buildMobileList(provider.reporte);
                    } else {
                      return _buildDesktopTable(provider.reporte);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<Map<String, dynamic>> reporte) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: ChequeAdminColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: 800),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                ChequeAdminColors.header,
              ),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              dataTextStyle: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
              dividerThickness: 0.5,
              columns: const [
                DataColumn(label: Text('VENDEDOR')),
                DataColumn(label: Text('DEPOSITADO'), numeric: true),
                DataColumn(label: Text('CANCELADO'), numeric: true),
                DataColumn(label: Text('PENDIENTE'), numeric: true),
                DataColumn(label: Text('VENCIDO'), numeric: true),
                DataColumn(
                  label: Text(
                    'TOTAL',
                    style: TextStyle(color: ChequeAdminColors.blue),
                  ),
                  numeric: true,
                ),
              ],
              rows: reporte.map((row) {
                return DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return Colors.white.withValues(alpha: 0.04);
                    }
                    return null;
                  }),
                  cells: [
                    DataCell(
                      Text(
                        row['vendedor'].toString().toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    DataCell(Text(row['depositado'].toString())),
                    DataCell(Text(row['cancelado'].toString())),
                    DataCell(Text(row['pendiente'].toString())),
                    DataCell(Text(row['vencido'].toString())),
                    DataCell(
                      Text(
                        row['total'].toString(),
                        style: const TextStyle(
                          color: ChequeAdminColors.blue,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildMobileList(List<Map<String, dynamic>> reporte) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reporte.length,
      itemBuilder: (context, index) {
        final row = reporte[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: ChequeAdminColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row['vendedor'].toString().toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.white10, height: 24),
              _mobileRow(
                'Depositado',
                row['depositado'],
                ChequeAdminUtils.colorEstado('depositado'),
              ),
              const SizedBox(height: 8),
              _mobileRow(
                'Cancelado',
                row['cancelado'],
                ChequeAdminUtils.colorEstado('cancelado'),
              ),
              const SizedBox(height: 8),
              _mobileRow(
                'Pendiente',
                row['pendiente'],
                ChequeAdminUtils.colorEstado('pendiente'),
              ),
              const SizedBox(height: 8),
              _mobileRow(
                'Vencido',
                row['vencido'],
                ChequeAdminUtils.colorEstado('vencido'),
              ),
              const Divider(color: Colors.white10, height: 24),
              _mobileRow(
                'TOTAL',
                row['total'],
                ChequeAdminColors.blue,
                isBold: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _mobileRow(
    String label,
    dynamic value,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

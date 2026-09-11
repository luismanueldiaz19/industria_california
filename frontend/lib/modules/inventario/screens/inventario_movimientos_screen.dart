import 'package:flutter/material.dart';
import 'package:industria_california/core/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../providers/inventario_movimiento_provider.dart';
import '../models/inventario_movimiento.dart';
import '../../../widgets/general_header.dart';

class InventarioMovimientosScreen extends StatefulWidget {
  const InventarioMovimientosScreen({super.key});

  @override
  State<InventarioMovimientosScreen> createState() =>
      _InventarioMovimientosScreenState();
}

class _InventarioMovimientosScreenState
    extends State<InventarioMovimientosScreen> {
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final _dateFormatFilter = DateFormat('yyyy-MM-dd');
  final _dateFormatDisplay = DateFormat('dd/MM/yyyy');
  String _tipoFiltro = '';
  DateTimeRange? _selectedDateRange;
  // static const _dark = Color(0xFFF8F9FA);
  static const _dark = Color(0xFF1A1C1E);
  static const _card = Color(0xFF2C2F33);
  static const _red = Color(0xFFE31E24);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventarioMovimientoProvider>().fetchMovimientos();
    });
  }

  Future<void> _openPdf() async {
    final url = await context.read<InventarioMovimientoProvider>().getPdfUrl();
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _tipoColor(String tipo) {
    return switch (tipo) {
      'PRODUCCION' => const Color(0xFF34A853),
      'VENTA' => const Color(0xFFE31E24),
      'BAJA' => Colors.orange,
      _ => const Color(0xFF1A73E8), // AJUSTE
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioMovimientoProvider>();

    return Scaffold(
      backgroundColor: _dark,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GeneralHeader(
            title: 'Movimientos de Inventario',
            subtitle: '${provider.total} registros',
            icon: Icons.swap_vert_rounded,
          ),

          // Filter bar
          _buildFilterBar(provider),

          // Table
          Expanded(child: _buildContent(provider)),

          // Resumen footer
          if (provider.resumen.isNotEmpty && !provider.isLoading)
            _buildResumen(provider.resumen),
        ],
      ),
    );
  }

  Widget _buildResumen(Map<String, dynamic> resumen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _dark,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: resumen.entries.map((e) {
            final tipo = e.key;
            final total = double.tryParse(e.value.toString()) ?? 0.0;
            final color = _tipoColor(tipo);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tipo,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${total > 0 ? '+' : ''}${total.toStringAsFixed(2).replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), '')}',
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterBar(InventarioMovimientoProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _dark,
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Filtro tipo
          _filterChip('Todos', '', provider),
          _filterChip('Ajuste', 'AJUSTE', provider),
          _filterChip('Producción', 'PRODUCCION', provider),
          _filterChip('Venta', 'VENTA', provider),
          _filterChip('Baja', 'BAJA', provider),

          const SizedBox(width: 8),

          // Fecha
          _buildDateRangeButton(provider),

          const SizedBox(width: 8),

          // PDF
          InkWell(
            onTap: _openPdf,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.picture_as_pdf_outlined,
                    color: Colors.orange.shade400,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'PDF',
                    style: TextStyle(
                      color: Colors.orange.shade400,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    String label,
    String value,
    InventarioMovimientoProvider provider,
  ) {
    final isSelected = _tipoFiltro == value;
    return InkWell(
      onTap: () {
        setState(() => _tipoFiltro = value);
        provider.setFiltros(
          tipo: value.isEmpty ? null : value,
          startDate: _selectedDateRange != null
              ? _dateFormatFilter.format(_selectedDateRange!.start)
              : null,
          endDate: _selectedDateRange != null
              ? _dateFormatFilter.format(_selectedDateRange!.end)
              : null,
        );
        provider.fetchMovimientos();
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? _red.withValues(alpha: 0.15)
              : _card.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? _red.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _red : Colors.white.withValues(alpha: 0.5),
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeButton(InventarioMovimientoProvider provider) {
    final hasDate = _selectedDateRange != null;
    return InkWell(
      onTap: () async {
        final newRange = await showDateRangePicker(
          context: context,
          initialDateRange: _selectedDateRange,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppTheme.accentColor,
                  onPrimary: Colors.white,
                  surface: Color(0xFF1A1C1E),
                  onSurface: Colors.white,
                ),
                scaffoldBackgroundColor: const Color(0xFF1A1C1E),
                datePickerTheme: DatePickerThemeData(
                  rangeSelectionOverlayColor: WidgetStateProperty.all(
                    const Color(0xFF1A73E8).withValues(alpha: 0.2),
                  ),
                  rangePickerBackgroundColor: const Color(0xFF1A1C1E),
                ),
                dialogTheme: DialogThemeData(
                  backgroundColor: const Color(0xFF1A1C1E),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                    maxHeight: 550,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: child!,
                  ),
                ),
              ),
            );
          },
        );

        if (newRange != null) {
          setState(() => _selectedDateRange = newRange);
          provider.setFiltros(
            tipo: _tipoFiltro.isEmpty ? null : _tipoFiltro,
            startDate: _dateFormatFilter.format(newRange.start),
            endDate: _dateFormatFilter.format(newRange.end),
          );
          provider.fetchMovimientos();
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hasDate
              ? const Color(0xFF1A73E8).withValues(alpha: 0.15)
              : _card.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasDate
                ? const Color(0xFF1A73E8).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              color: hasDate
                  ? const Color(0xFF1A73E8)
                  : Colors.white.withValues(alpha: 0.5),
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              hasDate
                  ? '${_dateFormatDisplay.format(_selectedDateRange!.start)} - ${_dateFormatDisplay.format(_selectedDateRange!.end)}'
                  : 'Fecha',
              style: TextStyle(
                color: hasDate
                    ? const Color(0xFF1A73E8)
                    : Colors.white.withValues(alpha: 0.5),
                fontSize: 11.5,
                fontWeight: hasDate ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (hasDate) ...[
              const SizedBox(width: 5),
              InkWell(
                onTap: () {
                  setState(() => _selectedDateRange = null);
                  provider.setFiltros(
                    tipo: _tipoFiltro.isEmpty ? null : _tipoFiltro,
                    startDate: null,
                    endDate: null,
                  );
                  provider.fetchMovimientos();
                },
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: const Color(0xFF1A73E8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(InventarioMovimientoProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE31E24),
          strokeWidth: 2,
        ),
      );
    }

    if (provider.movimientos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_vert_rounded,
              color: Colors.white.withValues(alpha: 0.08),
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              'Sin movimientos',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: _buildTable(provider.movimientos),
    );
  }

  Widget _buildTable(List<InventarioMovimiento> movimientos) {
    return Container(
      decoration: BoxDecoration(
        color: _card.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.6), // Fecha
            1: FlexColumnWidth(1.2), // Código
            2: FlexColumnWidth(3.0), // Producto
            3: FlexColumnWidth(1.4), // Tipo
            4: FlexColumnWidth(1.6), // Cantidad
            5: FlexColumnWidth(1.2), // Ant.
            6: FlexColumnWidth(1.2), // Result.
            7: FlexColumnWidth(1.5), // Usuario
            8: FlexColumnWidth(1.8), // Nota
          },
          border: TableBorder(
            horizontalInside: BorderSide(
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(color: const Color(0xFF1A1C1E)),
              children: [
                _th('Fecha'),
                _th('Código'),
                _th('Producto'),
                _th('Tipo'),
                _th('Cantidad', align: TextAlign.right),
                _th('Ant.', align: TextAlign.right),
                _th('Result.', align: TextAlign.right),
                _th('Usuario'),
                _th('Nota'),
              ],
            ),
            // Filas
            ...movimientos.asMap().entries.map(
              (entry) => _buildRow(entry.value, entry.key),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildRow(InventarioMovimiento mov, int index) {
    final tipoColor = _tipoColor(mov.tipo);
    final esEntrada = mov.esEntrada;

    return TableRow(
      decoration: BoxDecoration(
        color: index.isEven
            ? Colors.transparent
            : Colors.white.withValues(alpha: 0.02),
      ),
      children: [
        _td(
          mov.createdAt != null
              ? _dateFormat.format(
                  mov.createdAt!.subtract(const Duration(hours: 4)),
                )
              : '—',
          fontSize: 10.5,
          isMonospace: true,
        ),
        _td(mov.producto?.codigo ?? '—', fontSize: 10.5, isMonospace: true),
        _td(mov.producto?.nombre ?? '—', bold: true, fontSize: 11),
        _tdWidget(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: tipoColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tipoColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              mov.tipo + (mov.subtipo != null ? '\n${mov.subtipo}' : ''),
              style: TextStyle(
                color: tipoColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        _td(
          '${esEntrada ? '+' : ''}${mov.cantidad.toStringAsFixed(2).replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), '')}',
          align: TextAlign.right,
          color: esEntrada ? const Color(0xFF34A853) : const Color(0xFFE31E24),
          bold: true,
          fontSize: 11,
        ),
        _td(
          mov.stockAnterior
              .toStringAsFixed(2)
              .replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), ''),
          align: TextAlign.right,
          fontSize: 10.5,
        ),
        _td(
          mov.stockResultante
              .toStringAsFixed(2)
              .replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), ''),
          align: TextAlign.right,
          color: mov.stockResultante < 0 ? const Color(0xFFE31E24) : null,
          bold: mov.stockResultante < 0,
          fontSize: 10.5,
        ),
        _td(mov.userName ?? '—', fontSize: 10.5),
        _td(
          mov.nota ?? '—',
          fontSize: 10,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      ],
    );
  }

  Widget _th(String label, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        label,
        textAlign: align,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _td(
    String text, {
    TextAlign align = TextAlign.left,
    Color? color,
    bool bold = false,
    double fontSize = 11.5,
    bool isMonospace = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          color: color ?? Colors.white.withValues(alpha: 0.75),
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontFamily: isMonospace ? 'monospace' : null,
        ),
      ),
    );
  }

  Widget _tdWidget(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: child,
    );
  }
}

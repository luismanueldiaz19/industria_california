import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/widgets/compact_snack_bar.dart';
import '../../../../core/widgets/general_header.dart';
import '../models/cxc_cuarentena_model.dart';
import '../services/cxc_cuarentena_service.dart';

class CxcCuarentenaScreen extends StatefulWidget {
  const CxcCuarentenaScreen({super.key});

  @override
  State<CxcCuarentenaScreen> createState() => _CxcCuarentenaScreenState();
}

class _CxcCuarentenaScreenState extends State<CxcCuarentenaScreen> {
  final _service = CxcCuarentenaService();
  final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  bool _isLoading = false;
  List<CxcCuarentenaModel> _items = [];
  Map<String, dynamic> _resumen = {};

  String _searchQuery = '';
  String _estadoFilter = 'todos';
  String _tipoNotaFilter = 'todos';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalRecords = 0;
  final int _perPage = 15;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _cargarDatos({bool keepPage = false}) async {
    if (!keepPage) _currentPage = 1;
    setState(() => _isLoading = true);

    try {
      final futures = await Future.wait([
        _service.getCuarentenas(
          estado: _estadoFilter,
          tipoNota: _tipoNotaFilter,
          search: _searchQuery,
          page: _currentPage,
          perPage: _perPage,
        ),
        _service.getResumen(),
      ]);

      final paginated = futures[0];
      final resumen = futures[1];

      if (mounted) {
        setState(() {
          _items = paginated['data'] ?? [];
          _currentPage = paginated['current_page'] ?? 1;
          _totalPages = paginated['last_page'] ?? 1;
          _totalRecords = paginated['total'] ?? 0;
          _resumen = resumen;
        });
      }
    } catch (e) {
      if (mounted) {
        CompactSnackBar.showError(
          context,
          'Error al cargar cuarentena: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _searchQuery = query;
      });
      _cargarDatos();
    });
  }

  void _mostrarDetalleSnapshot(CxcCuarentenaModel item) {
    showDialog(
      context: context,
      builder: (ctx) => _SnapshotDetalleDialog(item: item),
    );
  }

  Future<void> _mostrarDialogAplicar(CxcCuarentenaModel item) async {
    final numNotaCtrl = TextEditingController();
    final notaResolucionCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade800),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Aplicar ${item.tipoNota.toUpperCase()} - Doc: ${item.documento}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Esta acción marca la nota como completada en el sistema externo.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: numNotaCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Nº Nota Externa (opcional)',
                  labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFF1E2228),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: notaResolucionCtrl,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Comentario de resolución (opcional)',
                  labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFF1E2228),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text(
                'Confirmar Aplicación',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      try {
        await _service.aplicarNota(
          item.id,
          numeroNotaExterna: numNotaCtrl.text,
          notaResolucion: notaResolucionCtrl.text,
        );
        if (!mounted) return;
        CompactSnackBar.showSuccess(context, 'Nota aplicada correctamente.');
        _cargarDatos(keepPage: true);
      } catch (e) {
        if (!mounted) return;
        CompactSnackBar.showError(context, e.toString());
      }
    }
  }

  Future<void> _mostrarDialogAnular(CxcCuarentenaModel item) async {
    final justificacionCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade800),
          ),
          title: Row(
            children: [
              const Icon(Icons.cancel_rounded, color: AppTheme.dangerColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Anular Nota - Doc: ${item.documento}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Atención: Al anular la nota, la CXC NO se restaura en el sistema local.',
                  style: TextStyle(color: Colors.orange.shade300, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: justificacionCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Motivo de anulación (obligatorio)',
                    labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFF1E2228),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerColor,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text(
                'Confirmar Anulación',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      try {
        await _service.anularNota(
          item.id,
          notaResolucion: justificacionCtrl.text,
        );
        if (!mounted) return;
        CompactSnackBar.showSuccess(context, 'Nota anulada correctamente.');
        _cargarDatos(keepPage: true);
      } catch (e) {
        if (!mounted) return;
        CompactSnackBar.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pCredito = double.tryParse(_resumen['pendiente_credito']?.toString() ?? '0') ?? 0.0;
    final pDebito = double.tryParse(_resumen['pendiente_debito']?.toString() ?? '0') ?? 0.0;
    final totalPend = _resumen['total_pendientes'] ?? 0;
    final totalAplicadas = _resumen['total_aplicadas'] ?? 0;
    final totalAnuladas = _resumen['total_anuladas'] ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.darkBgColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GeneralHeader(
            title: 'Cuarentena CXC (Notas de Crédito / Débito)',
            subtitle: '$_totalRecords documentos en cuarentena',
            icon: Icons.shield_outlined,
            iconColor: Colors.amber,
            actions: [
              HeaderButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Actualizar',
                onTap: () => _cargarDatos(keepPage: true),
              ),
            ],
          ),

          // Barra de Métricas compacta
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.darkCardColor,
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildStatBadge(
                  label: 'NC Pendientes',
                  value: currencyFormatter.format(pCredito),
                  color: Colors.tealAccent,
                  icon: Icons.receipt_long_rounded,
                ),
                _buildStatBadge(
                  label: 'ND Pendientes',
                  value: currencyFormatter.format(pDebito),
                  color: Colors.orangeAccent,
                  icon: Icons.note_add_rounded,
                ),
                _buildStatBadge(
                  label: 'Por Procesar',
                  value: '$totalPend doc(s)',
                  color: const Color(0xFFFB8C00),
                  icon: Icons.pending_actions_rounded,
                ),
                _buildStatBadge(
                  label: 'Aplicadas',
                  value: '$totalAplicadas doc(s)',
                  color: AppTheme.successColor,
                  icon: Icons.check_circle_outline,
                ),
                _buildStatBadge(
                  label: 'Anuladas',
                  value: '$totalAnuladas doc(s)',
                  color: Colors.grey.shade400,
                  icon: Icons.cancel_outlined,
                ),
              ],
            ),
          ),

          // Barra de Filtros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1E22),
              border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF23272E),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Buscar por documento, cliente o nota...',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildDropdown(
                  value: _estadoFilter,
                  items: const [
                    DropdownMenuItem(value: 'todos', child: Text('Todos los Estados')),
                    DropdownMenuItem(value: 'pendiente', child: Text('Pendientes')),
                    DropdownMenuItem(value: 'aplicada', child: Text('Aplicadas')),
                    DropdownMenuItem(value: 'anulada', child: Text('Anuladas')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _estadoFilter = val);
                      _cargarDatos();
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildDropdown(
                  value: _tipoNotaFilter,
                  items: const [
                    DropdownMenuItem(value: 'todos', child: Text('Todos los Tipos')),
                    DropdownMenuItem(value: 'credito', child: Text('Notas de Crédito')),
                    DropdownMenuItem(value: 'debito', child: Text('Notas de Débito')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _tipoNotaFilter = val);
                      _cargarDatos();
                    }
                  },
                ),
              ],
            ),
          ),

          // Tabla de Datos
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppTheme.ledhouseBlue),
                      strokeWidth: 3,
                    ),
                  )
                : _items.isEmpty
                    ? Center(
                        child: Text(
                          'No hay registros en cuarentena.',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: DataTable(
                                  headingRowHeight: 38,
                                  dataRowMinHeight: 40,
                                  dataRowMaxHeight: 48,
                                  horizontalMargin: 12,
                                  columnSpacing: 14,
                                  headingRowColor: WidgetStateProperty.all(const Color(0xFF22262C)),
                                  columns: const [
                                    DataColumn(label: Text('DOCUMENTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                                    DataColumn(label: Text('CLIENTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                                    DataColumn(label: Text('TIPO NOTA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                                    DataColumn(label: Text('MONTO NOTA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                                    DataColumn(label: Text('ORIGINAL (FACT/PAG/PEND)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                                    DataColumn(label: Text('MOTIVO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                                    DataColumn(label: Text('ESTADO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                                    DataColumn(label: Text('ACCIONES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                                  ],
                                  rows: _items.map((item) {
                                    final isCredito = item.isCredito;
                                    Color estadoColor;
                                    if (item.isAplicada) {
                                      estadoColor = AppTheme.successColor;
                                    } else if (item.isAnulada) {
                                      estadoColor = AppTheme.dangerColor;
                                    } else {
                                      estadoColor = const Color(0xFFFB8C00);
                                    }

                                    return DataRow(
                                      cells: [
                                        // Documento
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.description_outlined,
                                                size: 15,
                                                color: Colors.grey.shade400,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                item.documento,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Cliente
                                        DataCell(
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                item.clienteNombre,
                                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Vend: ${item.vendedorNombre}',
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Tipo Nota
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isCredito ? Colors.teal : Colors.orange).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: (isCredito ? Colors.teal : Colors.orange).withValues(alpha: 0.4),
                                              ),
                                            ),
                                            child: Text(
                                              isCredito ? 'CRÉDITO' : 'DÉBITO',
                                              style: TextStyle(
                                                color: isCredito ? Colors.tealAccent : Colors.orangeAccent,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Monto Nota
                                        DataCell(
                                          Text(
                                            currencyFormatter.format(item.montoNota),
                                            style: TextStyle(
                                              color: isCredito ? Colors.tealAccent : Colors.orangeAccent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        // Original (Fact / Pag / Pend)
                                        DataCell(
                                          Text(
                                            '${currencyFormatter.format(item.montoFactura)} / ${currencyFormatter.format(item.montoPagado)} / ${currencyFormatter.format(item.montoPendiente)}',
                                            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                          ),
                                        ),
                                        // Motivo
                                        DataCell(
                                          Tooltip(
                                            message: item.justificacion,
                                            child: Text(
                                              item.motivoLabel,
                                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                                            ),
                                          ),
                                        ),
                                        // Estado
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: estadoColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: estadoColor.withValues(alpha: 0.3)),
                                            ),
                                            child: Text(
                                              item.estado.toUpperCase(),
                                              style: TextStyle(color: estadoColor, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        // Acciones
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.visibility_outlined, size: 16, color: Colors.lightBlueAccent),
                                                tooltip: 'Ver Historial / Snapshot',
                                                padding: const EdgeInsets.all(4),
                                                constraints: const BoxConstraints(),
                                                onPressed: () => _mostrarDetalleSnapshot(item),
                                              ),
                                              if (item.isPendiente) ...[
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  icon: const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.successColor),
                                                  tooltip: 'Marcar Aplicada',
                                                  padding: const EdgeInsets.all(4),
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () => _mostrarDialogAplicar(item),
                                                ),
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  icon: const Icon(Icons.cancel_outlined, size: 16, color: AppTheme.dangerColor),
                                                  tooltip: 'Anular Nota',
                                                  padding: const EdgeInsets.all(4),
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () => _mostrarDialogAnular(item),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Paginación compacta
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppTheme.darkCardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Página $_currentPage de $_totalPages ($_totalRecords registros)',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 18),
                        onPressed: _currentPage > 1
                            ? () {
                                setState(() => _currentPage--);
                                _cargarDatos(keepPage: true);
                              }
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 18),
                        onPressed: _currentPage < _totalPages
                            ? () {
                                setState(() => _currentPage++);
                                _cargarDatos(keepPage: true);
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2228),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 9)),
              Text(
                value,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF23272E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppTheme.darkCardColor,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          icon: const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SnapshotDetalleDialog extends StatelessWidget {
  final CxcCuarentenaModel item;

  const _SnapshotDetalleDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final snap = item.snapshot;
    final soportes = (snap?['soportes'] as List?) ?? [];
    final alertas = (snap?['alertas'] as List?) ?? [];
    final evidencias = (snap?['evidencias'] as List?) ?? [];

    return Dialog(
      backgroundColor: AppTheme.darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade800),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detalle de Cuarentena - ${item.documento}',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white10),
              Expanded(
                child: ListView(
                  children: [
                    _buildRow('Cliente', item.clienteNombre),
                    _buildRow('Vendedor', item.vendedorNombre),
                    _buildRow('Tipo de Nota', item.tipoNota.toUpperCase()),
                    _buildRow('Monto de Nota', currencyFormatter.format(item.montoNota)),
                    _buildRow('Motivo', item.motivoLabel),
                    _buildRow('Justificación', item.justificacion),
                    _buildRow('Estado', item.estado.toUpperCase()),
                    if (item.numeroNotaExterna != null)
                      _buildRow('Nº Nota Externa', item.numeroNotaExterna!),
                    if (item.notaResolucion != null)
                      _buildRow('Nota Resolución', item.notaResolucion!),
                    if (item.enviadoPorNombre != null)
                      _buildRow('Enviado por', item.enviadoPorNombre!),
                    if (item.resueltoPorNombre != null)
                      _buildRow('Resuelto por', item.resueltoPorNombre!),
                    const SizedBox(height: 12),
                    const Text(
                      'Historial Preservado (Snapshot)',
                      style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${soportes.length} gestiones/soportes, ${alertas.length} alertas, ${evidencias.length} evidencias archivadas.',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                    ),
                    if (soportes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Gestiones de Cobro:', style: TextStyle(color: Colors.grey.shade300, fontSize: 12, fontWeight: FontWeight.bold)),
                      ...soportes.map((s) => Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Text(
                              '• [${s['fecha'] ?? ''}] ${s['nota'] ?? ''}',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

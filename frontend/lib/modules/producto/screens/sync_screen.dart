import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/themes/app_theme.dart';
import '../services/sync_service.dart';

/// Wizard de Sincronizacion de Inventario — 3 pasos: Archivo → Preview → Resultado
class InventarioSyncScreen extends StatefulWidget {
  const InventarioSyncScreen({super.key});

  @override
  State<InventarioSyncScreen> createState() => _InventarioSyncScreenState();
}

class _InventarioSyncScreenState extends State<InventarioSyncScreen> {
  final _service = InventarioSyncService();

  int _step = 0;
  int _tab = 0;
  bool _loading = false;
  PlatformFile? _file;
  Map<String, dynamic>? _preview;
  Map<String, dynamic>? _resultado;
  String? _error;

  static const _green = Color(0xFF2E7D32);

  // ── Formato moneda ─────────────────────────────────────────────
  String _fmt(dynamic v) {
    if (v == null) return '0.00';
    final d = v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    final parts = d.toStringAsFixed(2).split('.');
    final buf = StringBuffer();
    int c = 0;
    for (int i = parts[0].length - 1; i >= 0; i--) {
      if (c != 0 && c % 3 == 0 && parts[0][i] != '-') buf.write(',');
      buf.write(parts[0][i]);
      c++;
    }
    return '${buf.toString().split('').reversed.join()}.${parts[1]}';
  }

  // ── Acciones ───────────────────────────────────────────────────
  Future<void> _pickFile() async {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );
    if (f != null) {
      setState(() {
        _file = f;
        _error = null;
      });
    }
  }

  Future<void> _runPreview() async {
    if (_file == null) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await _file!.readAsBytes();
      if (bytes.isEmpty) throw Exception('Archivo vacio o ilegible.');
      final p = await _service.syncPreview(
        fileBytes: bytes,
        fileName: _file!.name,
        token: token,
      );
      setState(() {
        _preview = p;
        _step = 1;
        _tab = 0;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    if (_file == null) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await _file!.readAsBytes();
      if (bytes.isEmpty) throw Exception('Archivo vacio o ilegible.');
      final r = await _service.syncConfirm(
        fileBytes: bytes,
        fileName: _file!.name,
        token: token,
      );
      setState(() {
        _resultado = r;
        _step = 2;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 10,
        12,
        10,
      ),
      child: Row(
        children: [
          _hBtn(
            icon: Icons.arrow_back_rounded,
            tip: 'Volver',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sincronizar Inventario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Actualizacion masiva desde Excel',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hBtn({
    required IconData icon,
    required String tip,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case 0:
        return _step0();
      case 1:
        return _step1();
      case 2:
        return _step2();
      default:
        return _step0();
    }
  }

  // ── Paso 0: Seleccionar archivo ────────────────────────────────
  Widget _step0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stepBar(active: 0),
              const SizedBox(height: 16),
              const Text(
                'Selecciona el archivo Excel',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '6 columnas en este orden exacto:',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
              const SizedBox(height: 10),
              _colTable(),
              const SizedBox(height: 16),
              _dropZone(),
              if (_error != null) ...[
                const SizedBox(height: 10),
                _errCard(_error!),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: _file == null || _loading ? null : _runPreview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_rounded, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Analizar archivo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colTable() {
    final cols = [
      ['A', 'id_producto', 'ID del producto en el sistema (numero)'],
      ['B', 'Descripcion', 'Nombre / descripcion del producto'],
      ['C', 'Presentacion', 'Unidad (UNIDAD, LIBRA, KG, OTRO)'],
      ['D', 'Cantidad', 'Existencia / stock actual'],
      ['E', 'Costo', 'Costo del producto (formato \$1,500.00)'],
      ['F', 'Precio Venta', 'Precio de venta (formato \$1,500.00)'],
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 22,
                  child: Text(
                    'Col',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(
                  width: 90,
                  child: Text(
                    'Campo',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Descripcion',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...cols.asMap().entries.map((e) {
            final i = e.key;
            final c = e.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: i.isEven ? Colors.white : Colors.grey.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      c[0],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: Text(
                      c[1],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      c[2],
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          // Nota col G ignorada
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  'Columna G (Monto) ignorada automaticamente.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropZone() {
    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _file != null ? _green : Colors.blue.shade100,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _file != null
                  ? Icons.check_circle_rounded
                  : Icons.upload_file_rounded,
              color: _file != null ? _green : Colors.blue.shade300,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              _file != null ? _file!.name : 'Toca para seleccionar archivo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _file != null ? _green : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (_file != null)
              FutureBuilder<int>(
                future: _file!.length(),
                builder: (_, s) => s.hasData
                    ? Text(
                        '${(s.data! / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }

  // ── Paso 1: Preview ────────────────────────────────────────────
  Widget _step1() {
    final resumen = _preview!['resumen'] as Map<String, dynamic>;
    final errores = (_preview!['errores'] as List?) ?? [];
    final nuevos = (_preview!['nuevos'] as List?) ?? [];
    final actualizaciones = (_preview!['actualizaciones'] as List?) ?? [];
    final hayValidos = nuevos.isNotEmpty || actualizaciones.isNotEmpty;

    return LayoutBuilder(
      builder: (ctx, bc) {
        final wide = bc.maxWidth > 780;
        final left = _previewLeft(
          resumen,
          hayValidos,
          nuevos.length,
          actualizaciones.length,
          errores.length,
        );
        final right = _previewRight(nuevos, actualizaciones, errores);
        if (wide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: left),
                const SizedBox(width: 20),
                Expanded(flex: 6, child: right),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [left, const SizedBox(height: 20), right],
          ),
        );
      },
    );
  }

  Widget _previewLeft(
    Map<String, dynamic> resumen,
    bool hayValidos,
    int nNuevos,
    int nActual,
    int nErr,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepBar(active: 1),
        const SizedBox(height: 14),
        const Text(
          'Resultado del Analisis',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Revisa antes de confirmar. Los cambios NO se aplican hasta confirmar.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _contador('$nNuevos', 'Nuevos', Colors.green, 0),
            const SizedBox(width: 8),
            _contador('$nActual', 'Actualizar', Colors.orange, 1),
            const SizedBox(width: 8),
            _contador('$nErr', 'Errores', Colors.red, 2),
          ],
        ),
        const SizedBox(height: 16),
        if (_error != null) ...[_errCard(_error!), const SizedBox(height: 10)],
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _step = 0;
                  _preview = null;
                  _error = null;
                }),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text(
                  'Cambiar archivo',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (!hayValidos || _loading) ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Confirmar Sincronizacion',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _previewRight(List nuevos, List actualizaciones, List errores) {
    final List items;
    final String title;
    final Color color;
    final Color bg;
    final IconData icon;

    switch (_tab) {
      case 0:
        items = nuevos;
        title = 'Productos a Crear';
        color = Colors.green;
        bg = Colors.green.shade50;
        icon = Icons.add_circle_outline;
        break;
      case 1:
        items = actualizaciones;
        title = 'A Actualizar';
        color = Colors.orange;
        bg = Colors.orange.shade50;
        icon = Icons.update_rounded;
        break;
      default:
        items = errores;
        title = 'Con Error';
        color = Colors.red;
        bg = Colors.red.shade50;
        icon = Icons.error_outline;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: color.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Text(
                  '$title (${items.length})',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 36,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sin registros en esta categoria',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 520),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    Divider(color: Colors.grey.shade100, height: 1),
                itemBuilder: (ctx, i) => _previewItem(
                  items[i] as Map<String, dynamic>,
                  color,
                  icon,
                  _tab,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _previewItem(
    Map<String, dynamic> item,
    Color color,
    IconData icon,
    int tab,
  ) {
    final nombre = item['nombre'] as String? ?? 'Sin nombre';
    final unidad = item['unidad'] as String? ?? '';
    final idProducto = item['id_producto']?.toString() ?? '';
    final cantidad = item['cantidad'];
    final costo = item['costo'];
    final precio = item['precio_venta'];

    if (tab == 2) {
      return ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          radius: 14,
          child: Icon(icon, color: color, size: 14),
        ),
        title: Text(
          'Fila ${item['fila']}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        subtitle: Text(
          item['razon'] as String? ?? '',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),
      );
    }

    return ExpansionTile(
      dense: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        radius: 14,
        child: Icon(icon, color: color, size: 14),
      ),
      title: Text(
        nombre,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        idProducto.isNotEmpty
            ? 'ID: $idProducto  |  $unidad'
            : 'Nuevo  |  $unidad',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 10.5),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Table(
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
            children: [
              _tRow('Cantidad', _fmt(cantidad)),
              _tRow('Costo', '\$${_fmt(costo)}'),
              _tRow('Precio Venta', '\$${_fmt(precio)}'),
              if (tab == 1 && item['stock_actual'] != null)
                _tRow('Stock anterior', _fmt(item['stock_actual']), dim: true),
              if (tab == 1 && item['costo_actual'] != null)
                _tRow(
                  'Costo anterior',
                  '\$${_fmt(item['costo_actual'])}',
                  dim: true,
                ),
              if (tab == 1 && item['venta_actual'] != null)
                _tRow(
                  'Precio anterior',
                  '\$${_fmt(item['venta_actual'])}',
                  dim: true,
                ),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _tRow(String label, String value, {bool dim = false}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            label,
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: dim ? Colors.grey.shade400 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // ── Paso 2: Resultado ──────────────────────────────────────────
  Widget _step2() {
    final creados = _resultado?['creados'] ?? 0;
    final actualizados = _resultado?['actualizados'] ?? 0;
    final omitidos = _resultado?['omitidos'] ?? 0;
    final errores = (_resultado?['errores'] as List?) ?? [];
    final hayError = errores.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stepBar(active: 2),
              const SizedBox(height: 24),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: hayError
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hayError
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_rounded,
                  color: hayError ? Colors.orange : Colors.green,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                hayError
                    ? 'Sincronizacion con advertencias'
                    : 'Sincronizacion Exitosa!',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                _resultado?['message'] as String? ?? '',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _resCard(
                    'Creados',
                    creados,
                    Colors.green,
                    Icons.add_circle_outline,
                  ),
                  const SizedBox(width: 8),
                  _resCard(
                    'Actualizados',
                    actualizados,
                    Colors.blue,
                    Icons.update_rounded,
                  ),
                  const SizedBox(width: 8),
                  _resCard(
                    'Omitidos',
                    omitidos,
                    Colors.grey,
                    Icons.remove_circle_outline,
                  ),
                ],
              ),
              if (errores.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange.shade700,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Filas con errores (${errores.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...errores.take(5).map((e) {
                        final m = e as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            '• Fila ${m['fila']}: ${m['razon']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        );
                      }),
                      if (errores.length > 5)
                        Text(
                          '... y ${errores.length - 5} mas',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => setState(() {
                    _step = 0;
                    _file = null;
                    _preview = null;
                    _resultado = null;
                    _error = null;
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Nueva Sincronizacion',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Volver al Inventario',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resCard(String label, dynamic value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 5),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets compartidos ────────────────────────────────────────
  Widget _stepBar({required int active}) {
    const steps = ['Archivo', 'Preview', 'Resultado'];
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i == active;
        final isDone = i < active;
        final col = isDone
            ? Colors.green
            : isActive
            ? _green
            : Colors.grey.shade300;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                child: isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 12)
                    : Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 4),
              Text(
                steps[i],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? _green : Colors.grey.shade500,
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Divider(
                    color: isDone
                        ? Colors.green.shade300
                        : Colors.grey.shade300,
                    thickness: 1.2,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _contador(String valor, String label, Color color, int tab) {
    final sel = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: sel ? color.withValues(alpha: 0.09) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: sel ? color : Colors.grey.shade200,
              width: sel ? 2 : 1,
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 6,
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Text(
                valor,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 15),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

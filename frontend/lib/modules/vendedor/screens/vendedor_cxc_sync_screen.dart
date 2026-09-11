import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/auth_provider.dart';
import '../../../../core/app_theme.dart';
import '../services/vendedor_cxc_service.dart';

/// Wizard de Sincronización CXC en 2 fases: Preview → Confirmar
class VendedorCxcSyncScreen extends StatefulWidget {
  const VendedorCxcSyncScreen({super.key});

  @override
  State<VendedorCxcSyncScreen> createState() => _VendedorCxcSyncScreenState();
}

class _VendedorCxcSyncScreenState extends State<VendedorCxcSyncScreen> {
  final _service = VendedorCxcService();

  int _step = 0; // 0=seleccionar, 1=preview, 2=resultado
  int _selectedPreviewTab = 0;

  bool _isLoading = false;
  PlatformFile? _file;
  Map<String, dynamic>? _preview;
  Map<String, dynamic>? _resultado;
  String? _error;

  bool _isAdmin = false;
  List<dynamic> _vendedores = [];
  int? _selectedVendedorId;

  static const _blue = Color(0xFF1565C0);
  static const _blueDark = Color(0xFF0D47A1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAdmin();
    });
  }

  Future<void> _initAdmin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAdmin) {
      setState(() => _isAdmin = true);
      try {
        final vends = await _service.getVendedores(auth.token ?? '');
        setState(() => _vendedores = vends);
      } catch (e) {
        debugPrint('Error loading vendors: $e');
      }
    }
  }

  Future<void> _pickFile() async {
    // Usamos pickFile() y eliminamos withData
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );

    // Evaluamos el archivo directamente
    if (file != null) {
      setState(() {
        _file = file; // Asignamos el PlatformFile directamente
        _error = null;
      });
    }
  }

  Future<void> _runPreview() async {
    // 1. Ahora solo validamos que el archivo no sea nulo
    if (_file == null) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 2. Extraemos los bytes justo en el momento que los necesitamos
      final bytes = await _file!.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception("No se pudo leer el archivo o está vacío.");
      }

      final preview = await _service.syncPreview(
        fileBytes: bytes, // 3. Pasamos los bytes extraídos
        fileName: _file!.name,
        token: token,
        vendedorId: _isAdmin ? _selectedVendedorId : null,
      );

      setState(() {
        _preview = preview;
        _step = 1;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirm() async {
    // 1. Validamos únicamente que el archivo exista
    if (_file == null) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 2. Leemos los bytes del archivo usando el método de la v12
      final bytes = await _file!.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception("No se pudo leer el archivo o está vacío.");
      }

      final resultado = await _service.syncConfirm(
        fileBytes: bytes, // 3. Pasamos los bytes leídos de forma segura
        fileName: _file!.name,
        token: token,
        vendedorId: _isAdmin ? _selectedVendedorId : null,
      );

      setState(() {
        _resultado = resultado;
        _step = 2;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildCustomHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 20,
        16,
        20,
      ),
      child: Row(
        children: [
          _buildHeaderButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Volver',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.ledhouseBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sync_rounded,
              color: AppTheme.ledhouseBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sincronizar CXC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  'Importación Masiva de Excel',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    Color color = Colors.white,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25), width: 1),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1Preview();
      case 2:
        return _buildStep2Resultado();
      default:
        return _buildStep0();
    }
  }

  // ── Paso 0: Seleccionar archivo ──────────────────────────────
  Widget _buildStep0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepIndicator(active: 0),
              const SizedBox(height: 28),
              const Text(
                'Selecciona tu archivo Excel',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El archivo debe tener 4 columnas:',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              _buildColumnasTarjeta(),
              const SizedBox(height: 28),
              // Zona de carga
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _file != null ? _blue : Colors.blue.shade100,
                      width: 2,
                      style: _file == null
                          ? BorderStyle.solid
                          : BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _file != null
                            ? Icons.check_circle_rounded
                            : Icons.upload_file_rounded,
                        color: _file != null
                            ? Colors.green
                            : Colors.blue.shade300,
                        size: 44,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _file != null
                            ? _file!.name
                            : 'Toca para seleccionar archivo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _file != null ? _blue : Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_file != null)
                        // NUEVO: Usamos FutureBuilder porque file.length() es asíncrono en la v12
                        if (_file != null)
                          FutureBuilder<int>(
                            future: _file!.length(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Text(
                                  '${(snapshot.data! / 1024).toStringAsFixed(1)} KB',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                );
                              }
                              // Mientras calcula el tamaño, no mostramos nada
                              return const SizedBox.shrink();
                            },
                          ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_isAdmin) ...[
                const SizedBox(height: 24),
                const Text(
                  'Asignar a Vendedor',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedVendedorId,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  hint: const Text('Selecciona el vendedor...'),
                  items: _vendedores.map((v) {
                    return DropdownMenuItem<int>(
                      value: v['id'],
                      child: Text('${v['name']} (@${v['username']})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedVendedorId = val),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _file == null ||
                          _isLoading ||
                          (_isAdmin && _selectedVendedorId == null)
                      ? null
                      : _runPreview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Analizar archivo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Paso 1: Preview ────────────────────────────────────────────
  Widget _buildStep1Preview() {
    final resumen = _preview!['resumen'] as Map<String, dynamic>;
    final errores = (_preview!['errores'] as List?) ?? [];
    final nuevos = (_preview!['nuevos'] as List?) ?? [];
    final actualizaciones = (_preview!['actualizaciones'] as List?) ?? [];
    final hayValidos = nuevos.isNotEmpty || actualizaciones.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        final leftPane = _buildPreviewLeftPane(resumen, hayValidos);
        final rightPane = _buildPreviewRightPane(
          nuevos,
          actualizaciones,
          errores,
        );

        if (isDesktop) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: leftPane),
                const SizedBox(width: 32),
                Expanded(flex: 6, child: rightPane),
              ],
            ),
          );
        } else {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [leftPane, const SizedBox(height: 32), rightPane],
            ),
          );
        }
      },
    );
  }

  Widget _buildPreviewLeftPane(Map<String, dynamic> resumen, bool hayValidos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepIndicator(active: 1),
        const SizedBox(height: 28),
        const Text(
          'Resultado del Análisis',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Revisa el resumen y selecciona una categoría para ver los detalles completos antes de confirmar.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        // Contadores interactivos
        Row(
          children: [
            _buildInteractiveContador(
              '${resumen['nuevos']}',
              'Nuevos',
              Colors.green,
              0,
            ),
            const SizedBox(width: 12),
            _buildInteractiveContador(
              '${resumen['actualizaciones']}',
              'Actualizar',
              Colors.orange,
              1,
            ),
            const SizedBox(width: 12),
            _buildInteractiveContador(
              '${resumen['errores']}',
              'Errores',
              Colors.red,
              2,
            ),
          ],
        ),
        const SizedBox(height: 32),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        // Botones de acción
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _step = 0;
                  _preview = null;
                }),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text(
                  'Cambiar archivo',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (!hayValidos || _isLoading) ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Confirmar Sincronización',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewRightPane(
    List nuevos,
    List actualizaciones,
    List errores,
  ) {
    List items = [];
    String title = '';
    Color color = Colors.transparent;
    Color bgColor = Colors.transparent;
    IconData icon = Icons.list;

    if (_selectedPreviewTab == 0) {
      items = nuevos;
      title = 'Nuevos Documentos';
      color = Colors.green;
      bgColor = Colors.green.shade50;
      icon = Icons.add_circle_outline;
    } else if (_selectedPreviewTab == 1) {
      items = actualizaciones;
      title = 'Documentos a Actualizar';
      color = Colors.orange;
      bgColor = Colors.orange.shade50;
      icon = Icons.update;
    } else if (_selectedPreviewTab == 2) {
      items = errores;
      title = 'Clientes No Encontrados';
      color = Colors.red;
      bgColor = Colors.red.shade50;
      icon = Icons.error_outline;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: color.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$title (${items.length})',
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay registros en esta categoría',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 600),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    Divider(color: Colors.grey.shade100, height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.1),
                      radius: 20,
                      child: Icon(icon, color: color, size: 20),
                    ),
                    title: Text(
                      '${item['documento'] ?? item['id_ext'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        item['cliente_nombre'] ??
                            item['razon'] ??
                            'ID Cliente: ${item['cliente_id'] ?? ''}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    trailing: item['monto_pendiente'] != null
                        ? Text(
                            '\$${item['monto_pendiente']}',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ── Paso 2: Resultado final ────────────────────────────────────
  Widget _buildStep2Resultado() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '¡Sincronización Completada!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildResultRow(
                      'Creados',
                      '${_resultado!['creados']}',
                      Colors.green,
                    ),
                    _buildResultRow(
                      'Actualizados',
                      '${_resultado!['actualizados']}',
                      Colors.orange,
                    ),
                    _buildResultRow(
                      'Omitidos',
                      '${_resultado!['omitidos']}',
                      Colors.grey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Ver mis CXC',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets auxiliares ─────────────────────────────────────────
  Widget _buildStepIndicator({required int active}) {
    final steps = ['Seleccionar', 'Revisar', 'Confirmar'];
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i == active;
        final isDone = i < active;
        return Expanded(
          child: Row(
            children: [
              if (i > 0)
                Expanded(
                  child: Divider(
                    color: isDone ? _blue : Colors.grey.shade300,
                    thickness: 2,
                  ),
                ),
              Column(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isActive || isDone
                        ? _blue
                        : Colors.grey.shade200,
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[i],
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive ? _blue : Colors.grey.shade500,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildColumnasTarjeta() {
    final cols = [
      ('A', 'ID Cliente Externo', true),
      ('B', 'Documento/Factura', true),
      ('C', 'Monto Pendiente', true),
      ('D', 'Fecha Factura', true),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: cols
            .map(
              (c) => ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: _blue,
                  child: Text(
                    c.$1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  c.$2,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: c.$3
                    ? const Chip(
                        label: Text(
                          'Requerido',
                          style: TextStyle(fontSize: 10),
                        ),
                        padding: EdgeInsets.zero,
                        backgroundColor: Color(0xFFE3F2FD),
                      )
                    : null,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildInteractiveContador(
    String valor,
    String label,
    Color color,
    int tabIndex,
  ) {
    final isSelected = _selectedPreviewTab == tabIndex;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedPreviewTab = tabIndex),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : color.withOpacity(0.1),
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              children: [
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : color,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : color.withOpacity(0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String valor, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

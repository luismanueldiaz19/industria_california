import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/auth_provider.dart';
import '../../../core/app_theme.dart';
import '../services/vendedor_cxc_service.dart';

class VendedorCxcDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> cxcData;

  const VendedorCxcDetalleScreen({super.key, required this.cxcData});

  @override
  State<VendedorCxcDetalleScreen> createState() =>
      _VendedorCxcDetalleScreenState();
}

class _VendedorCxcDetalleScreenState extends State<VendedorCxcDetalleScreen> {
  final _service = VendedorCxcService();

  bool _isSubmitting = false;
  static const _blue = Color(0xFF1565C0);

  // Formulario de alerta
  String _tipoAlerta = 'informacion';
  final _notaController = TextEditingController();
  final _montoController = TextEditingController();

  @override
  void dispose() {
    _notaController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _enviarAlerta() async {
    if (_notaController.text.trim().isEmpty) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    setState(() => _isSubmitting = true);

    try {
      await _service.addAlerta(
        cxcId: widget.cxcData['id'],
        tipo: _tipoAlerta,
        nota: _notaController.text.trim(),
        montoInformado: _montoController.text.trim().isNotEmpty
            ? double.tryParse(_montoController.text.trim())
            : null,
        token: token,
      );
      if (!mounted) return;
      _notaController.clear();
      _montoController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Alerta enviada a contabilidad'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _subirEvidencia() async {
    // 1. Usar pickFile() directamente, que ahora retorna un PlatformFile?
    final PlatformFile? file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    // 2. Validar directamente si se seleccionó un archivo
    if (file == null) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';

    setState(() => _isSubmitting = true);
    try {
      // 3. Leer los bytes usando el nuevo método asíncrono
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception("No se pudo leer el archivo o está vacío.");
      }

      await _service.uploadEvidencia(
        cxcId: widget.cxcData['id'],
        fileBytes: bytes, // Usamos la nueva variable de bytes
        fileName: file.name,
        token: token,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.attach_file, color: Colors.white),
              SizedBox(width: 8),
              Text('Evidencia subida correctamente'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeStyle = Theme.of(context).textTheme;

    final cxc = widget.cxcData;
    final estado = cxc['estado'] ?? 'pendiente';

    Color estadoColor = estado == 'pagado'
        ? Colors.green
        : estado == 'cancelado'
        ? Colors.red
        : Colors.orange;

    return Container(
      color: const Color(0xFF121212), // Fondo oscuro fuera del área móvil
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ClipRRect(
            // Redondeamos los bordes para dar apariencia de dispositivo móvil si está en escritorio
            borderRadius: BorderRadius.circular(
              MediaQuery.of(context).size.width > 500 ? 20 : 0,
            ),
            child: Scaffold(
              backgroundColor: AppTheme.bgColor,
              appBar: AppBar(
                title: Text(
                  cxc['documento'] ?? 'Detalle',
                  style: themeStyle.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                centerTitle: true,
                elevation: 0,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta principal
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // Barra de estado
                          Container(
                            decoration: BoxDecoration(
                              color: estadoColor,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  estado.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(
                                  Icons.receipt_long,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  Icons.person_outline,
                                  'Cliente',
                                  cxc['cliente']?['nombre'] ?? '-',
                                ),
                                const Divider(height: 20),
                                _buildInfoRow(
                                  Icons.attach_money,
                                  'Monto Factura',
                                  '\$${cxc['monto_factura'] ?? '0.00'}',
                                ),
                                _buildInfoRow(
                                  Icons.money_off,
                                  'Monto Pendiente',
                                  '\$${cxc['monto_pendiente'] ?? '0.00'}',
                                  valueColor: Colors.orange,
                                ),
                                _buildInfoRow(
                                  Icons.check_circle_outline,
                                  'Monto Pagado',
                                  '\$${cxc['monto_pagado'] ?? '0.00'}',
                                  valueColor: Colors.green,
                                ),
                                const Divider(height: 20),
                                _buildInfoRow(
                                  Icons.calendar_today,
                                  'Fecha Factura',
                                  _formatDate(cxc['fecha_factura']),
                                ),
                                _buildInfoRow(
                                  Icons.event_busy,
                                  'Fecha Vencimiento',
                                  _formatDate(cxc['fecha_vencimiento']),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sección: Agregar Alerta
                    _buildSectionTitle('📣 Enviar Alerta a Contabilidad'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _tipoAlerta,
                            decoration: _inputDeco(
                              'Tipo de alerta',
                              Icons.label_outline,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'pago_recibido',
                                child: Text('💰 Pago Recibido'),
                              ),
                              DropdownMenuItem(
                                value: 'informacion',
                                child: Text('📋 Información'),
                              ),
                              DropdownMenuItem(
                                value: 'consulta',
                                child: Text('❓ Consulta'),
                              ),
                              DropdownMenuItem(
                                value: 'credito',
                                child: Text('📄 Nota de Crédito'),
                              ),
                              DropdownMenuItem(
                                value: 'debito',
                                child: Text('🧾 Nota de Débito'),
                              ),
                              DropdownMenuItem(
                                value: 'devolucion',
                                child: Text('🔄 Devolución'),
                              ),
                              DropdownMenuItem(
                                value: 'retencion',
                                child: Text('📑 Carta de Retención'),
                              ),
                              DropdownMenuItem(
                                value: 'diferencia',
                                child: Text('⚖️ Diferencia de precio'),
                              ),
                              DropdownMenuItem(
                                value: 'mer_no_entregada',
                                child: Text('📦 Mercancía no entregada'),
                              ),
                              DropdownMenuItem(
                                value: 'anular',
                                child: Text('❌ Anular Factura'),
                              ),
                            ],
                            onChanged: (v) => setState(() => _tipoAlerta = v!),
                          ),
                          const SizedBox(height: 12),
                          if ([
                            'pago_recibido',
                            'credito',
                            'debito',
                            'devolucion',
                            'retencion',
                            'diferencia',
                            'mer_no_entregada',
                            'anular',
                            'informacion',
                          ].contains(_tipoAlerta))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextFormField(
                                controller: _montoController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDeco(
                                  'Monto informado por el cliente',
                                  Icons.attach_money,
                                ),
                              ),
                            ),
                          TextFormField(
                            controller: _notaController,
                            maxLines: 3,
                            decoration: _inputDeco(
                              'Descripción / Nota',
                              Icons.notes,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _enviarAlerta,
                              icon: const Icon(Icons.send_rounded),
                              label: const Text(
                                'Enviar Alerta',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sección: Evidencias
                    _buildSectionTitle('📎 Adjuntar Comprobante'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Text(
                            'Sube un PDF o imagen del comprobante de pago.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isSubmitting ? null : _subirEvidencia,
                              icon: const Icon(Icons.upload_file_rounded),
                              label: const Text(
                                'Seleccionar archivo',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _blue,
                                side: const BorderSide(
                                  color: _blue,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      prefixIcon: Icon(icon, size: 18),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _blue, width: 1.5),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '-';
    try {
      final p = date.split('-');
      return '${p[2]}/${p[1]}/${p[0]}';
    } catch (_) {
      return date;
    }
  }
}

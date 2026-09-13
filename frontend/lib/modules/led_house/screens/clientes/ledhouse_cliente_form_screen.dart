import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/app_theme.dart';
import '../../models/ledhouse_cliente.dart';
import '../../services/ledhouse_cliente_service.dart';
import '../../../../services/gps_service.dart';

class LedhouseClienteFormScreen extends StatefulWidget {
  final LedhouseCliente? cliente;

  const LedhouseClienteFormScreen({super.key, this.cliente});

  @override
  State<LedhouseClienteFormScreen> createState() =>
      _LedhouseClienteFormScreenState();
}

class _LedhouseClienteFormScreenState extends State<LedhouseClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = LedhouseClienteService();

  late TextEditingController _idClienteExternoController;
  late TextEditingController _nombreController;
  late TextEditingController _whatsappController;
  late TextEditingController _direccionController;
  late TextEditingController _documentoController;
  String? _tipoDocumento;
  late TextEditingController _limiteCreditoController;
  late TextEditingController _diasCreditoController;

  late TextEditingController _latitudController;
  late TextEditingController _longitudController;

  double? _latitud;
  double? _longitud;

  bool _isLoading = false;

  bool get _isEditing => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    _idClienteExternoController = TextEditingController(
      text: widget.cliente?.idClienteExterno ?? '',
    );
    _nombreController = TextEditingController(
      text: widget.cliente?.nombre ?? '',
    );
    _whatsappController = TextEditingController(
      text: widget.cliente?.whatsapp ?? '',
    );
    _direccionController = TextEditingController(
      text: widget.cliente?.direccion ?? '',
    );
    _documentoController = TextEditingController(
      text: widget.cliente?.documento ?? '',
    );
    _tipoDocumento = widget.cliente?.tipoDocumento;
    _limiteCreditoController = TextEditingController(
      text: widget.cliente?.limiteCredito != null
          ? widget.cliente!.limiteCredito!.toInt().toString()
          : '',
    );
    _diasCreditoController = TextEditingController(
      text: widget.cliente?.diasCredito != null
          ? widget.cliente!.diasCredito.toString()
          : '',
    );
    _latitud = widget.cliente?.latitud;
    _longitud = widget.cliente?.longitud;

    _latitudController = TextEditingController(
      text: _latitud?.toString() ?? '',
    );
    _longitudController = TextEditingController(
      text: _longitud?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _idClienteExternoController.dispose();
    _nombreController.dispose();
    _whatsappController.dispose();
    _direccionController.dispose();
    _documentoController.dispose();
    _limiteCreditoController.dispose();
    _diasCreditoController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final c = LedhouseCliente(
        id: widget.cliente?.id,
        idClienteExterno: _idClienteExternoController.text.trim(),
        nombre: _nombreController.text.trim(),
        whatsapp: _whatsappController.text.trim().isEmpty
            ? null
            : _whatsappController.text.trim(),
        direccion: _direccionController.text.trim().isEmpty
            ? null
            : _direccionController.text.trim(),
        tipoDocumento: _tipoDocumento,
        documento: _documentoController.text.trim().isEmpty
            ? null
            : _documentoController.text.trim(),
        limiteCredito: _limiteCreditoController.text.trim().isEmpty
            ? null
            : double.tryParse(_limiteCreditoController.text.trim()),
        diasCredito: _diasCreditoController.text.trim().isEmpty
            ? null
            : int.tryParse(_diasCreditoController.text.trim()),
        latitud: double.tryParse(_latitudController.text.trim()),
        longitud: double.tryParse(_longitudController.text.trim()),
      );

      if (_isEditing) {
        await _service.updateCliente(c);
      } else {
        await _service.createCliente(c);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ───────────────────────────────────────────
            _buildDialogHeader(),

            // ── Form ─────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField(
                          controller: _idClienteExternoController,
                          label: 'ID Cliente Externo',
                          hint: 'Ej: CLI-001',
                          icon: Icons.tag_rounded,
                          iconColor: Colors.deepPurple,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Campo requerido'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _nombreController,
                          label: 'Nombre completo',
                          hint: 'Ej: Juan García',
                          icon: Icons.person_outline_rounded,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Campo requerido'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _whatsappController,
                          label: 'WhatsApp',
                          hint: 'Ej: 8097000000',
                          icon: Icons.phone_rounded,
                          iconColor: AppTheme.whatsappColor,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(15),
                          ],
                          optional: true,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _direccionController,
                          label: 'Dirección',
                          hint: 'Opcional',
                          icon: Icons.location_on_outlined,
                          iconColor: AppTheme.dangerColor,
                          optional: true,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildDropdownField(
                                label: 'Tipo documento',
                                value: _tipoDocumento,
                                items: const ['Cédula', 'RNC'],
                                icon: Icons.assignment_ind_outlined,
                                iconColor: Colors.blueGrey,
                                onChanged: (val) {
                                  setState(() {
                                    _tipoDocumento = val;
                                  });
                                },
                                optional: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: _buildField(
                                controller: _documentoController,
                                label: 'Documento',
                                hint: 'Ej: 000-0000000-0',
                                icon: Icons.badge_outlined,
                                iconColor: Colors.teal,
                                keyboardType: TextInputType.text,
                                optional: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                controller: _limiteCreditoController,
                                label: 'Límite de crédito',
                                hint: 'Ej: 10000',
                                icon: Icons.attach_money_rounded,
                                iconColor: Colors.orange,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                optional: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildField(
                                controller: _diasCreditoController,
                                label: 'Días de crédito',
                                hint: 'Ej: 30',
                                icon: Icons.calendar_today_rounded,
                                iconColor: AppTheme.primaryColor,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                optional: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Captura de GPS ───────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.gps_fixed_rounded,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: const Text(
                                            'Ubicación Exacta (GPS)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.green,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Row(
                                                  children: [
                                                    Icon(Icons.info_outline, color: Colors.blue),
                                                    SizedBox(width: 8),
                                                    Text('¿Cómo llenar el GPS?'),
                                                  ],
                                                ),
                                                content: Container(
                                                  constraints: const BoxConstraints(maxWidth: 300),
                                                  child: const Text(
                                                    '• Si está en la oficina (Windows): Ignore el botón "Capturar". Busque el cliente en Google Maps, copie la Latitud y Longitud y péguela en las casillas.\n\n'
                                                    '• Si está en la calle (Móvil): Presione "Capturar" para que el sistema obtenga su ubicación actual automáticamente.',
                                                    style: TextStyle(height: 1.4),
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx),
                                                    child: const Text('Entendido'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          child: const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _latitudController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Latitud',
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 8,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _longitudController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Longitud',
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 8,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : _capturarUbicacion,
                                icon: const Icon(Icons.location_on, size: 16),
                                label: const Text('Capturar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Buttons ─────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.pop(context, false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.ledhouseBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        _isEditing
                                            ? 'Guardar cambios'
                                            : 'Crear cliente',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ), // Cierre Flexible
            ), // Cierre SingleChildScrollView
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.ledhouseBlue, AppTheme.ledhouseBlueDark],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Editar cliente' : 'Nuevo cliente',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isEditing
                      ? 'Actualiza los datos del cliente'
                      : 'Completa los datos del cliente',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context, false),
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white.withOpacity(0.7),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Color iconColor = const Color(0xFF1A73E8),
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool optional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Opcional',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppTheme.ledhouseBlue,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFEA4335),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFEA4335),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    Color iconColor = const Color(0xFF1A73E8),
    bool optional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Opcional',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.expand_more_rounded, color: Colors.grey),
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppTheme.ledhouseBlue,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _capturarUbicacion() async {
    setState(() => _isLoading = true);
    try {
      final pos = await GpsService.getCurrentPosition();
      if (pos != null) {
        setState(() {
          _latitud = pos.latitude;
          _longitud = pos.longitude;
          _latitudController.text = pos.latitude.toString();
          _longitudController.text = pos.longitude.toString();
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación capturada con éxito'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo obtener el GPS: $e. Puede ingresar las coordenadas manualmente.',
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

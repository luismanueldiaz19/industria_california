import 'package:flutter/material.dart';
import 'package:industria_california/core/widgets/compact_snack_bar.dart';
import 'package:flutter/services.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/widgets/cancel_button.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/dialog_header.dart';
import '../../../../core/widgets/drop_down_widget.dart';
import '../../../../core/widgets/general_header.dart';
import '../../../../core/widgets/input_field.dart';
import '../../models/ledhouse_cliente.dart';
import '../../services/ledhouse_cliente_service.dart';
import '../../../../core/services/gps_service.dart';

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
      final cliente = LedhouseCliente(
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
        await _service.updateCliente(cliente);
      } else {
        await _service.createCliente(cliente);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      CompactSnackBar.showError(context, 'Error: $e');
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
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ───────────────────────────────────────────
            DialogHeader(
              title: _isEditing ? 'Editar Cliente' : 'Nuevo Cliente',
              subtitle: _isEditing
                  ? 'Actualiza los datos del cliente'
                  : 'Completa los datos del cliente',
              icon: _isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
              onClose: () => Navigator.pop(context, false),
            ),
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
                        InputField(
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
                        InputField(
                          controller: _nombreController,
                          label: 'Nombre completo',
                          hint: 'Ej: Juan García',
                          icon: Icons.person_outline_rounded,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Campo requerido'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        InputField(
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
                        InputField(
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
                              child: DropDownWidget<String>(
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
                              flex: 2,
                              child: InputField(
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
                              child: InputField(
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
                              child: InputField(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Ubicación Exacta (GPS)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.green,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),

                              Row(
                                spacing: 8,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: InputField(
                                      controller: _latitudController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      label: '',
                                      hint: 'Latitud',
                                    ),
                                  ),
                                  Expanded(
                                    child: InputField(
                                      controller: _longitudController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      hint: 'Longitud',
                                      label: '',
                                    ),
                                  ),
                                  HeaderButton(
                                    icon: Icons.location_on,
                                    color: AppTheme.primaryColor,
                                    tooltip: 'Capturar',
                                    onTap: _isLoading
                                        ? null
                                        : _capturarUbicacion,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Buttons ─────────────────────────────────
                        Row(
                          spacing: 25,
                          children: [
                            Expanded(
                              child: CancelButton(
                                isLoading: _isLoading,
                                borderRadius: 5,
                              ),
                            ),

                            Expanded(
                              flex: 2,
                              child: CustomButton(
                                onPressed: _isLoading ? null : _save,
                                color: _isEditing
                                    ? AppTheme.accentGreen
                                    : AppTheme.ledhouseBlue,
                                textColor: Colors.white,
                                isLoading: _isLoading,
                                text: _isEditing
                                    ? 'Guardar cambios'
                                    : 'Guardar',
                                borderRadius: 5,
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
        CompactSnackBar.showSuccess(context, 'Ubicación capturada con éxito');
      }
    } catch (e) {
      if (!mounted) return;
      CompactSnackBar.showWarning(context, 'No se pudo obtener el GPS: $e. Puede ingresar las coordenadas manualmente.');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

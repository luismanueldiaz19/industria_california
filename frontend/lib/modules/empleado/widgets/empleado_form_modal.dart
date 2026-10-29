import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/nomina_calculator.dart';
import '../../../../core/widgets/cancel_button.dart';
import '../../../../core/widgets/compact_checkbox_tile.dart';
import '../../../../core/widgets/compact_dropdown_field.dart';
import '../../../../core/widgets/compact_snack_bar.dart';
import '../../../../core/widgets/compact_text_field.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/dialog_header.dart';
import '../../../../core/widgets/form_section_header.dart';
import '../models/empleado.dart';

class EmpleadoFormModal extends StatefulWidget {
  final Empleado? empleado;
  final Function(Map<String, dynamic>) onSave;

  const EmpleadoFormModal({super.key, this.empleado, required this.onSave});

  @override
  State<EmpleadoFormModal> createState() => _EmpleadoFormModalState();
}

class _EmpleadoFormModalState extends State<EmpleadoFormModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _cedulaCtrl;
  late TextEditingController _nombresCtrl;
  late TextEditingController _apellidosCtrl;
  late TextEditingController _ocupacionCtrl;
  late TextEditingController _departamentoCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _salarioCtrl;
  late TextEditingController _bancoCtrl;
  late TextEditingController _cuentaCtrl;
  late TextEditingController _fechaIngresoCtrl;
  late TextEditingController _fechaSalidaCtrl;

  DateTime? _fechaIngreso;
  DateTime? _fechaSalida;

  bool _aplicaAfp = true;
  bool _aplicaArs = true;
  bool _aplicaIsr = true;
  String _tipoPago = 'transferencia';
  String _estado = 'activo';
  bool _isSaving = false;

  double _salarioMensual = 0.0;

  @override
  void initState() {
    super.initState();
    final e = widget.empleado;
    _cedulaCtrl = TextEditingController(
      text: Formatters.formatCedula(e?.cedula),
    );
    _nombresCtrl = TextEditingController(text: e?.nombres ?? '');
    _apellidosCtrl = TextEditingController(text: e?.apellidos ?? '');
    _ocupacionCtrl = TextEditingController(text: e?.ocupacion ?? '');
    _departamentoCtrl = TextEditingController(text: e?.departamento ?? '');
    _telefonoCtrl = TextEditingController(text: e?.telefono ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _direccionCtrl = TextEditingController(text: e?.direccion ?? '');
    _salarioCtrl = TextEditingController(
      text: e != null && e.salarioMensual > 0
          ? e.salarioMensual.toStringAsFixed(2)
          : '',
    );
    _bancoCtrl = TextEditingController(text: e?.banco ?? '');
    _cuentaCtrl = TextEditingController(text: e?.numeroCuenta ?? '');

    if (e?.fechaIngreso != null && e!.fechaIngreso!.trim().isNotEmpty) {
      _fechaIngreso = DateTime.tryParse(e.fechaIngreso!);
    } else {
      _fechaIngreso = DateTime.now();
    }
    _fechaIngresoCtrl = TextEditingController(
      text: _fechaIngreso != null ? Formatters.dateShort(_fechaIngreso!) : '',
    );

    if (e?.fechaSalida != null && e!.fechaSalida!.trim().isNotEmpty) {
      _fechaSalida = DateTime.tryParse(e.fechaSalida!);
    }
    _fechaSalidaCtrl = TextEditingController(
      text: _fechaSalida != null ? Formatters.dateShort(_fechaSalida!) : '',
    );

    _aplicaAfp = e?.aplicaAfp ?? true;
    _aplicaArs = e?.aplicaArs ?? true;
    _aplicaIsr = e?.aplicaIsr ?? true;
    _tipoPago = e?.tipoPago ?? 'transferencia';
    _estado = e?.estado ?? 'activo';
    _salarioMensual = e?.salarioMensual ?? 0.0;

    _salarioCtrl.addListener(() {
      final parsed =
          double.tryParse(_salarioCtrl.text.replaceAll(',', '')) ?? 0.0;
      if (parsed != _salarioMensual) {
        setState(() {
          _salarioMensual = parsed;
        });
      }
    });
  }

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _ocupacionCtrl.dispose();
    _departamentoCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _direccionCtrl.dispose();
    _salarioCtrl.dispose();
    _bancoCtrl.dispose();
    _cuentaCtrl.dispose();
    _fechaIngresoCtrl.dispose();
    _fechaSalidaCtrl.dispose();
    super.dispose();
  }

  double get _salarioQuincenal => _salarioMensual / 2;
  double get _salarioHora =>
      _salarioMensual > 0 ? (_salarioMensual / 23.83 / 8) : 0.0;
  double get _afpEstimada =>
      NominaCalculator.calcularAfp(_salarioMensual, aplica: _aplicaAfp);
  double get _arsEstimada =>
      NominaCalculator.calcularArs(_salarioMensual, aplica: _aplicaArs);
  double get _tssEstimada => _afpEstimada + _arsEstimada;
  double get _isrEstimado => NominaCalculator.calcularIsrMensual(
        salarioMensual: _salarioMensual,
        aplicaAfp: _aplicaAfp,
        aplicaArs: _aplicaArs,
        aplicaIsr: _aplicaIsr,
      );
  double get _netoEstimadoMensual =>
      _salarioMensual > 0 ? (_salarioMensual - _tssEstimada - _isrEstimado) : 0.0;

  Future<void> _seleccionarFechaIngreso() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaIngreso ?? DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime(2050),
      helpText: 'SELECCIONAR FECHA DE INGRESO',
    );
    if (picked != null) {
      setState(() {
        _fechaIngreso = picked;
        _fechaIngresoCtrl.text = Formatters.dateShort(picked);
      });
    }
  }

  Future<void> _seleccionarFechaSalida() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSalida ?? _fechaIngreso ?? DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime(2050),
      helpText: 'SELECCIONAR FECHA DE SALIDA',
    );
    if (picked != null) {
      setState(() {
        _fechaSalida = picked;
        _fechaSalidaCtrl.text = Formatters.dateShort(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final data = {
        'cedula': Formatters.formatCedula(_cedulaCtrl.text.trim()),
        'nombres': _nombresCtrl.text.trim().toUpperCase(),
        'apellidos': _apellidosCtrl.text.trim().toUpperCase(),
        'ocupacion': _ocupacionCtrl.text.trim().isEmpty
            ? null
            : _ocupacionCtrl.text.trim(),
        'departamento': _departamentoCtrl.text.trim().isEmpty
            ? null
            : _departamentoCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim().isEmpty
            ? null
            : _telefonoCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim().isEmpty
            ? null
            : _direccionCtrl.text.trim(),
        'salario_mensual': _salarioMensual,
        'aplica_afp': _aplicaAfp,
        'aplica_ars': _aplicaArs,
        'aplica_isr': _aplicaIsr,
        'tipo_pago': _tipoPago,
        'banco': _bancoCtrl.text.trim().isEmpty ? null : _bancoCtrl.text.trim(),
        'numero_cuenta': _cuentaCtrl.text.trim().isEmpty
            ? null
            : _cuentaCtrl.text.trim(),
        'estado': _estado,
        'fecha_ingreso': _fechaIngreso != null
            ? "${_fechaIngreso!.year.toString().padLeft(4, '0')}-${_fechaIngreso!.month.toString().padLeft(2, '0')}-${_fechaIngreso!.day.toString().padLeft(2, '0')}"
            : null,
        'fecha_salida': _fechaSalida != null
            ? "${_fechaSalida!.year.toString().padLeft(4, '0')}-${_fechaSalida!.month.toString().padLeft(2, '0')}-${_fechaSalida!.day.toString().padLeft(2, '0')}"
            : null,
      };

      await widget.onSave(data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) CompactSnackBar.showError(context, 'Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.empleado != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header General Estandarizado ───────────────────────
            DialogHeader(
              title: isEdit ? 'Editar Empleado' : 'Nuevo Empleado',
              subtitle: isEdit
                  ? 'Modifica los datos contractuales y salariales'
                  : 'Registra un colaborador en el sistema de nómina',
              icon: Icons.badge_outlined,
              borderRadius: BorderRadius.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              onClose: () => Navigator.pop(context),
            ),

            // ── Cuerpo del Formulario ──────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección 1: Datos Personales
                      const FormSectionHeader(
                        title: '1. DATOS PERSONALES Y CONTACTO',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: CompactTextField(
                              isRequired: true,
                              controller: _cedulaCtrl,
                              label: 'Cédula de Identidad',
                              hint: 'xxx-xxxxxxx-x',
                              keyboardType: TextInputType.number,
                              inputFormatters: [CedulaInputFormatter()],
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Campo requerido';
                                }
                                final digits = v.replaceAll(RegExp(r'\D'), '');
                                if (digits.length != 11) {
                                  return 'Debe tener 11 dígitos';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 4,
                            child: CompactTextField(
                              isRequired: true,
                              controller: _nombresCtrl,
                              label: 'Nombres',
                              hint: 'Ej. Juan Carlos',
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Campo requerido'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 4,
                            child: CompactTextField(
                              isRequired: true,
                              controller: _apellidosCtrl,
                              label: 'Apellidos',
                              hint: 'Ej. Pérez López',
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Campo requerido'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CompactTextField(
                              controller: _ocupacionCtrl,
                              label: 'Ocupación / Cargo',
                              hint: 'Ej. Chofer, Instalador, Auxiliar',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CompactTextField(
                              controller: _departamentoCtrl,
                              label: 'Departamento',
                              hint: 'Ej. Operaciones, Producción',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CompactTextField(
                              controller: _telefonoCtrl,
                              label: 'Teléfono',
                              hint: '809-000-0000',
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      // Sección 2: Salarios y Cálculos de Ley
                      const FormSectionHeader(
                        title:
                            '2. SALARIO Y FORMULAS DE LEY (REPÚBLICA DOMINICANA)',
                        icon: Icons.monetization_on_outlined,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: CompactTextField(
                              isRequired: true,
                              controller: _salarioCtrl,
                              label: 'Salario Mensual (RD\$)',
                              hint: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Campo requerido';
                                }
                                final parsed = double.tryParse(
                                  v.replaceAll(',', ''),
                                );
                                if (parsed == null || parsed <= 0) {
                                  return 'Ingrese un monto válido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Indicadores automáticos
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CÁLCULOS DERIVADOS AUTOMÁTICOS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Quincenal (Sal/2):',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                      Text(
                                        Formatters.formatCurrency(
                                          _salarioQuincenal,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Valor Hora (Sal/23.83/8):',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                      Text(
                                        'RD\$ ${_salarioHora.toStringAsFixed(2)}/h',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'TSS (AFP 2.87% + SFS 3.04%):',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        Formatters.formatCurrency(_tssEstimada),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Ret. ISR Mensual (DGII):',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        _isrEstimado > 0
                                            ? Formatters.formatCurrency(_isrEstimado)
                                            : 'Exento (RD\$ 0.00)',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: _isrEstimado > 0
                                              ? const Color(0xFFDC2626)
                                              : const Color(0xFF16A34A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  const Divider(height: 6, color: Color(0xFFE2E8F0)),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Neto Mensual Estimado:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        Formatters.formatCurrency(_netoEstimadoMensual),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Banderas de ley con CompactCheckboxTile
                      Row(
                        children: [
                          Expanded(
                            child: CompactCheckboxTile(
                              title: 'Aplica AFP (2.87%)',
                              value: _aplicaAfp,
                              onChanged: (val) =>
                                  setState(() => _aplicaAfp = val ?? true),
                            ),
                          ),
                          Expanded(
                            child: CompactCheckboxTile(
                              title: 'Aplica ARS / SFS (3.04%)',
                              value: _aplicaArs,
                              onChanged: (val) =>
                                  setState(() => _aplicaArs = val ?? true),
                            ),
                          ),
                          Expanded(
                            child: CompactCheckboxTile(
                              title: 'Aplica ISR (DGII)',
                              value: _aplicaIsr,
                              onChanged: (val) =>
                                  setState(() => _aplicaIsr = val ?? true),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      // Sección 3: Datos de Pago, Estado y Fechas
                      const FormSectionHeader(
                        title: '3. MÉTODO DE PAGO, ESTADO Y FECHAS',
                        icon: Icons.account_balance_outlined,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CompactDropdownField<String>(
                              isRequired: true,
                              label: 'Método de Pago',
                              value: _tipoPago,
                              items: const [
                                'transferencia',
                                'efectivo',
                                'cheque',
                              ],
                              itemLabel: (item) {
                                switch (item) {
                                  case 'transferencia':
                                    return 'Transferencia Bancaria';
                                  case 'efectivo':
                                    return 'Efectivo';
                                  case 'cheque':
                                    return 'Cheque';
                                  default:
                                    return item.toUpperCase();
                                }
                              },
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _tipoPago = v);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CompactTextField(
                              controller: _bancoCtrl,
                              label: 'Banco',
                              hint: 'Ej. Banreservas, BHD',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CompactTextField(
                              controller: _cuentaCtrl,
                              label: 'Número de Cuenta',
                              hint: '0000000000',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CompactDropdownField<String>(
                              isRequired: true,
                              label: 'Estado',
                              value: _estado,
                              items: const [
                                'activo',
                                'inactivo',
                                'vacaciones',
                                'licencia',
                              ],
                              itemLabel: (item) {
                                switch (item) {
                                  case 'activo':
                                    return 'Activo';
                                  case 'inactivo':
                                    return 'Inactivo';
                                  case 'vacaciones':
                                    return 'Vacaciones';
                                  case 'licencia':
                                    return 'Licencia';
                                  default:
                                    return item.toUpperCase();
                                }
                              },
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _estado = v);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CompactTextField(
                              controller: _fechaIngresoCtrl,
                              readOnly: true,
                              isRequired: true,
                              label: 'Fecha de Ingreso',
                              hint: 'dd/mm/aaaa',
                              onTap: _seleccionarFechaIngreso,
                              suffixIcon: const Icon(
                                Icons.calendar_today_rounded,
                                size: 15,
                                color: Color(0xFF64748B),
                              ),
                              validator: (v) =>
                                  (_fechaIngreso == null) ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CompactTextField(
                              controller: _fechaSalidaCtrl,
                              readOnly: true,
                              label: 'Fecha Salida (si aplica)',
                              hint: 'dd/mm/aaaa',
                              onTap: _seleccionarFechaSalida,
                              suffixIcon: _fechaSalida != null
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        size: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _fechaSalida = null;
                                          _fechaSalidaCtrl.clear();
                                        });
                                      },
                                    )
                                  : const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 15,
                                      color: Color(0xFF64748B),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CompactTextField(
                              controller: _direccionCtrl,
                              label: 'Dirección de Residencia',
                              hint: 'Calle, sector, ciudad',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer con Botones Estandarizados ───────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CancelButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    text: 'Cancelar',
                    height: 36,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  CustomButton(
                    text: isEdit ? 'Actualizar Empleado' : 'Guardar Empleado',
                    icon: Icons.save_rounded,
                    isLoading: _isSaving,
                    onPressed: _submit,
                    height: 36,
                    fontSize: 12,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: const Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

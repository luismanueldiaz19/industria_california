import 'package:flutter/material.dart';
import '../../../../core/widgets/cancel_button.dart';
import '../../../../core/widgets/compact_dropdown_field.dart';
import '../../../../core/widgets/compact_snack_bar.dart';
import '../../../../core/widgets/compact_text_field.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/dialog_header.dart';
import '../../../../core/widgets/form_section_header.dart';

class NominaNuevoPeriodoModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const NominaNuevoPeriodoModal({super.key, required this.onSave});

  @override
  State<NominaNuevoPeriodoModal> createState() =>
      _NominaNuevoPeriodoModalState();
}

class _NominaNuevoPeriodoModalState extends State<NominaNuevoPeriodoModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _tituloCtrl;
  late TextEditingController _inicioCtrl;
  late TextEditingController _finCtrl;
  late TextEditingController _pagoCtrl;
  late TextEditingController _notasCtrl;

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  DateTime? _fechaPago;

  String _tipoPeriodo = 'quincenal';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final isFirstHalf = now.day <= 15;
    final year = now.year;

    String defaultTitle;
    DateTime start;
    DateTime end;
    DateTime pay;

    if (isFirstHalf) {
      defaultTitle = 'Nómina 1ra Quincena de ${_nombreMes(now.month)} $year';
      start = DateTime(year, now.month, 1);
      end = DateTime(year, now.month, 15);
      pay = DateTime(year, now.month, 15);
    } else {
      defaultTitle = 'Nómina 2da Quincena de ${_nombreMes(now.month)} $year';
      start = DateTime(year, now.month, 16);
      final lastDay = DateTime(year, now.month + 1, 0).day;
      end = DateTime(year, now.month, lastDay);
      pay = DateTime(year, now.month, lastDay);
    }

    _fechaInicio = start;
    _fechaFin = end;
    _fechaPago = pay;

    _tituloCtrl = TextEditingController(text: defaultTitle);
    _inicioCtrl = TextEditingController(text: _formatDate(start));
    _finCtrl = TextEditingController(text: _formatDate(end));
    _pagoCtrl = TextEditingController(text: _formatDate(pay));
    _notasCtrl = TextEditingController();
  }

  String _formatDate(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _nombreMes(int month) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return meses[month - 1];
  }

  void _onTipoPeriodoChanged(String? val) {
    if (val == null) return;
    setState(() {
      _tipoPeriodo = val;
      final now = DateTime.now();
      final year = now.year;
      final lastDay = DateTime(year, now.month + 1, 0).day;

      if (val == 'mensual') {
        _fechaInicio = DateTime(year, now.month, 1);
        _fechaFin = DateTime(year, now.month, lastDay);
        _fechaPago = DateTime(year, now.month, lastDay);
        _tituloCtrl.text = 'Nómina Mes de ${_nombreMes(now.month)} $year';
      } else if (val == 'quincenal') {
        final isFirstHalf = now.day <= 15;
        if (isFirstHalf) {
          _fechaInicio = DateTime(year, now.month, 1);
          _fechaFin = DateTime(year, now.month, 15);
          _fechaPago = DateTime(year, now.month, 15);
          _tituloCtrl.text =
              'Nómina 1ra Quincena de ${_nombreMes(now.month)} $year';
        } else {
          _fechaInicio = DateTime(year, now.month, 16);
          _fechaFin = DateTime(year, now.month, lastDay);
          _fechaPago = DateTime(year, now.month, lastDay);
          _tituloCtrl.text =
              'Nómina 2da Quincena de ${_nombreMes(now.month)} $year';
        }
      }
      if (_fechaInicio != null) _inicioCtrl.text = _formatDate(_fechaInicio!);
      if (_fechaFin != null) _finCtrl.text = _formatDate(_fechaFin!);
      if (_fechaPago != null) _pagoCtrl.text = _formatDate(_fechaPago!);
    });
  }

  Future<void> _seleccionarFecha(
    String campo,
    DateTime? inicial,
    TextEditingController ctrl,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: inicial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      helpText: 'SELECCIONAR $campo',
    );
    if (picked != null) {
      setState(() {
        if (campo == 'INICIO') _fechaInicio = picked;
        if (campo == 'FIN') _fechaFin = picked;
        if (campo == 'PAGO') _fechaPago = picked;
        ctrl.text = _formatDate(picked);
      });
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _inicioCtrl.dispose();
    _finCtrl.dispose();
    _pagoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final data = {
        'titulo': _tituloCtrl.text.trim(),
        'tipo_periodo': _tipoPeriodo,
        'fecha_inicio': _inicioCtrl.text.trim(),
        'fecha_fin': _finCtrl.text.trim(),
        'fecha_pago': _pagoCtrl.text.trim(),
        'notas': _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      };
      await widget.onSave(data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) CompactSnackBar.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DialogHeader(
              title: 'Crear Periodo de Nómina',
              subtitle: 'Define las fechas y tipo de periodo para procesar el pago',
              icon: Icons.calendar_month_outlined,
              borderRadius: BorderRadius.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              onClose: () => Navigator.pop(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FormSectionHeader(
                      title: '1. PARÁMETROS DEL PERIODO',
                      icon: Icons.event_note_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: CompactTextField(
                            isRequired: true,
                            controller: _tituloCtrl,
                            label: 'Título del Periodo',
                            hint: 'Ej. Nómina 1ra Quincena Octubre 2026',
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Campo requerido'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 4,
                          child: CompactDropdownField<String>(
                            isRequired: true,
                            label: 'Tipo de Periodo',
                            value: _tipoPeriodo,
                            items: const ['quincenal', 'mensual', 'extraordinaria'],
                            itemLabel: (v) {
                              switch (v) {
                                case 'quincenal':
                                  return 'Quincenal (15 días)';
                                case 'mensual':
                                  return 'Mensual (30 días)';
                                case 'extraordinaria':
                                  return 'Extraordinaria / Bono';
                                default:
                                  return v;
                              }
                            },
                            onChanged: _onTipoPeriodoChanged,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const FormSectionHeader(
                      title: '2. CALENDARIO DE PAGO',
                      icon: Icons.schedule_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _seleccionarFecha(
                              'INICIO',
                              _fechaInicio,
                              _inicioCtrl,
                            ),
                            child: IgnorePointer(
                              child: CompactTextField(
                                isRequired: true,
                                controller: _inicioCtrl,
                                label: 'Fecha Inicio',
                                hint: 'YYYY-MM-DD',
                                prefixIcon: const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Requerido'
                                        : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _seleccionarFecha(
                              'FIN',
                              _fechaFin,
                              _finCtrl,
                            ),
                            child: IgnorePointer(
                              child: CompactTextField(
                                isRequired: true,
                                controller: _finCtrl,
                                label: 'Fecha Fin',
                                hint: 'YYYY-MM-DD',
                                prefixIcon: const Icon(
                                  Icons.event_available_outlined,
                                  size: 14,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Requerido'
                                        : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _seleccionarFecha(
                              'PAGO',
                              _fechaPago,
                              _pagoCtrl,
                            ),
                            child: IgnorePointer(
                              child: CompactTextField(
                                isRequired: true,
                                controller: _pagoCtrl,
                                label: 'Fecha Pago',
                                hint: 'YYYY-MM-DD',
                                prefixIcon: const Icon(
                                  Icons.payments_outlined,
                                  size: 14,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Requerido'
                                        : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    CompactTextField(
                      controller: _notasCtrl,
                      label: 'Notas u Observaciones (Opcional)',
                      hint: 'Detalles específicos o justificación de este corte',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CancelButton(
                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 10),
                        CustomButton(
                          text: 'Crear Periodo',
                          icon: Icons.check,
                          isLoading: _isSaving,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

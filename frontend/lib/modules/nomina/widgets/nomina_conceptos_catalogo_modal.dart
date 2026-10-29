import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/cancel_button.dart';
import '../../../../core/widgets/compact_dropdown_field.dart';
import '../../../../core/widgets/compact_snack_bar.dart';
import '../../../../core/widgets/compact_text_field.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_table_scroll.dart';
import '../../../../core/widgets/dialog_header.dart';
import '../models/nomina_concepto.dart';
import '../providers/nomina_provider.dart';

class NominaConceptosCatalogoModal extends StatefulWidget {
  const NominaConceptosCatalogoModal({super.key});

  @override
  State<NominaConceptosCatalogoModal> createState() =>
      _NominaConceptosCatalogoModalState();
}

class _NominaConceptosCatalogoModalState
    extends State<NominaConceptosCatalogoModal> {
  String _filtroTipo = 'todos';

  void _abrirFormularioConcepto([NominaConcepto? concepto]) {
    final isEdit = concepto != null;
    final nombreCtrl = TextEditingController(text: concepto?.nombre ?? '');
    final codigoCtrl = TextEditingController(text: concepto?.codigo ?? '');
    String tipo = concepto?.tipo ?? 'deduccion';
    String categoria = concepto?.categoria ?? 'prestamo';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateForm) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.tune,
                                size: 16,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isEdit ? 'Editar Concepto' : 'Nuevo Concepto de Nómina',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => Navigator.pop(ctx),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 14),

                        // Nombre
                        CompactTextField(
                          isRequired: true,
                          controller: nombreCtrl,
                          label: 'Nombre del Concepto',
                          hint: 'Ej. Préstamo Coop. La Altagracia, Descuento Carnet',
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 10),

                        // Código
                        if (!isEdit) ...[
                          CompactTextField(
                            isRequired: true,
                            controller: codigoCtrl,
                            label: 'Código Único (Identificador)',
                            hint: 'Ej. PRESTAMO_ALTAGRACIA, DESC_UNIFORME',
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Requerido';
                              if (!RegExp(r'^[A-Z0-9_]+$').hasMatch(v.trim())) {
                                return 'Solo mayúsculas y guiones bajos (_)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Tipo (Ingreso / Deducción)
                        CompactDropdownField<String>(
                          isRequired: true,
                          label: 'Naturaleza del Concepto',
                          value: tipo,
                          items: const ['deduccion', 'ingreso'],
                          itemLabel: (v) =>
                              v == 'deduccion' ? 'Deducción / Descuento' : 'Ingreso / Haber',
                          onChanged: isEdit
                              ? (_) {}
                              : (v) => setStateForm(() => tipo = v ?? 'deduccion'),
                        ),
                        const SizedBox(height: 10),

                        // Categoría
                        CompactDropdownField<String>(
                          isRequired: true,
                          label: 'Categoría',
                          value: categoria,
                          items: const [
                            'prestamo',
                            'ahorro',
                            'adelanto',
                            'seguro',
                            'novedad',
                            'general',
                          ],
                          itemLabel: (v) {
                            switch (v) {
                              case 'prestamo':
                                return 'Préstamo';
                              case 'ahorro':
                                return 'Ahorro / Fondo';
                              case 'adelanto':
                                return 'Adelanto de Salario';
                              case 'seguro':
                                return 'Seguro Médico Adicional';
                              case 'novedad':
                                return 'Novedad / Horas';
                              default:
                                return 'General';
                            }
                          },
                          onChanged: (v) =>
                              setStateForm(() => categoria = v ?? 'prestamo'),
                        ),

                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CancelButton(onPressed: () => Navigator.pop(ctx)),
                            const SizedBox(width: 8),
                            CustomButton(
                              text: isEdit ? 'Guardar Cambios' : 'Crear Concepto',
                              icon: Icons.check,
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                Navigator.pop(ctx);

                                final prov = context.read<NominaProvider>();
                                try {
                                  if (!context.mounted) return;
                                  if (isEdit) {
                                    await prov.updateConcepto(concepto.id, {
                                      'nombre': nombreCtrl.text.trim(),
                                      'categoria': categoria,
                                    });
                                    if (!context.mounted) return;
                                    CompactSnackBar.showSuccess(
                                      context,
                                      'Concepto actualizado con éxito',
                                    );
                                  } else {
                                    await prov.createConcepto({
                                      'codigo': codigoCtrl.text.trim().toUpperCase(),
                                      'nombre': nombreCtrl.text.trim(),
                                      'tipo': tipo,
                                      'categoria': categoria,
                                      'es_automatico': false,
                                      'activo': true,
                                    });
                                    if (!context.mounted) return;
                                    CompactSnackBar.showSuccess(
                                      context,
                                      'Concepto creado con éxito',
                                    );
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  CompactSnackBar.showError(context, 'Error: $e');
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmarEliminarConcepto(NominaConcepto concepto) {
    if (concepto.esAutomatico) {
      CompactSnackBar.showError(
        context,
        'Los conceptos automáticos de ley (AFP, ARS, ISR) están protegidos y no pueden eliminarse.',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '¿Eliminar Concepto?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFFDC2626),
          ),
        ),
        content: Text(
          '¿Seguro que deseas eliminar el concepto "${concepto.nombre}" (${concepto.codigo})?',
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          CancelButton(onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<NominaProvider>().deleteConcepto(concepto.id);
                if (mounted) {
                  CompactSnackBar.showSuccess(context, 'Concepto eliminado');
                }
              } catch (e) {
                if (mounted) CompactSnackBar.showError(context, 'Error: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NominaProvider>();
    final conceptos = prov.conceptos.where((c) {
      if (_filtroTipo == 'todos') return true;
      return c.tipo.toLowerCase() == _filtroTipo;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 650),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DialogHeader(
              title: 'Catálogo de Conceptos de Nómina',
              subtitle:
                  'Administra los ingresos, deducciones, préstamos y cuotas del sistema',
              icon: Icons.list_alt_outlined,
              borderRadius: BorderRadius.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              onClose: () => Navigator.pop(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Wrap(
                    spacing: 6,
                    children: [
                      _buildFilterChip('todos', 'Todos'),
                      _buildFilterChip('deduccion', 'Deducciones / Préstamos'),
                      _buildFilterChip('ingreso', 'Ingresos / Haberes'),
                    ],
                  ),
                  const Spacer(),
                  CustomButton(
                    text: 'Nuevo Concepto',
                    icon: Icons.add,
                    onPressed: () => _abrirFormularioConcepto(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Tabla de Conceptos
            Expanded(
              child: conceptos.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay conceptos en este filtro',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    )
                  : CustomTableScroll(
                      child: DataTable(
                        headingRowHeight: 36,
                        dataRowMinHeight: 40,
                        dataRowMaxHeight: 46,
                        columnSpacing: 16,
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFFF8FAFC),
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'CÓDIGO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'NOMBRE DEL CONCEPTO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'TIPO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'CATEGORÍA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'SISTEMA / LEY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'ACCIONES',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                        rows: conceptos.map((c) {
                          final isIngreso = c.tipo.toLowerCase() == 'ingreso';

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  c.codigo,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  c.nombre,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isIngreso
                                        ? const Color(0xFFF0FDF4)
                                        : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isIngreso ? 'INGRESO' : 'DEDUCCIÓN',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isIngreso
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  c.categoria.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.esAutomatico
                                        ? const Color(0xFFEFF6FF)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: c.esAutomatico
                                          ? const Color(0xFFBFDBFE)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    c.esAutomatico
                                        ? 'AUTOMÁTICO'
                                        : 'MANUAL / CUOTA',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: c.esAutomatico
                                          ? const Color(0xFF1D4ED8)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 15,
                                        color: Color(0xFF2563EB),
                                      ),
                                      tooltip: 'Editar Concepto',
                                      onPressed: () =>
                                          _abrirFormularioConcepto(c),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    if (!c.esAutomatico)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 15,
                                          color: Color(0xFFDC2626),
                                        ),
                                        tooltip: 'Eliminar Concepto',
                                        onPressed: () =>
                                            _confirmarEliminarConcepto(c),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filtroTipo == value;
    return InkWell(
      onTap: () => setState(() => _filtroTipo = value),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

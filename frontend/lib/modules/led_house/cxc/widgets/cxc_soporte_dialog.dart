import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../models/cxc_model.dart';
import '../providers/cxc_provider.dart';

class CxcSoporteDialog extends StatefulWidget {
  final CxcModel cxc;

  const CxcSoporteDialog({super.key, required this.cxc});

  @override
  State<CxcSoporteDialog> createState() => _CxcSoporteDialogState();
}

class _CxcSoporteDialogState extends State<CxcSoporteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notaController = TextEditingController();
  DateTime _fechaVisita = DateTime.now().add(const Duration(days: 1));
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CxcProvider>(context, listen: false).fetchSoportes(widget.cxc.id!);
    });
  }

  @override
  void dispose() {
    _notaController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = Provider.of<CxcProvider>(context, listen: false);

    final data = {
      'nota': _notaController.text.trim(),
      'fecha': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'fecha_visita': DateFormat('yyyy-MM-dd').format(_fechaVisita),
    };

    final success = await provider.addSoporte(widget.cxc.id!, data);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      _notaController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota guardada'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${provider.error}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = AppTheme.darkBgColor;
    const cardDark = AppTheme.darkCardColor;
    const inputDark = AppTheme.darkInputColor;

    return Dialog(
      backgroundColor: cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 700,
        height: 420,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Gestión de Cobro - ${widget.cxc.cliente}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white70),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Divider(color: Colors.grey.shade800, height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lado izquierdo: Historial
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Historial de Intervenciones',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Consumer<CxcProvider>(
                            builder: (context, provider, child) {
                              if (provider.isLoadingSoportes) {
                                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                              }
                              if (provider.soportes.isEmpty) {
                                return Center(
                                  child: Text('No hay historial registrado.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                );
                              }
                              return ListView.builder(
                                itemCount: provider.soportes.length,
                                itemBuilder: (context, index) {
                                  final soporte = provider.soportes[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: darkBg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade800),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.phone_in_talk_rounded, color: Colors.blueAccent, size: 14),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                soporte.nota,
                                                style: const TextStyle(fontSize: 13, color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Gestión: ${soporte.fecha} | Próx. Visita: ${soporte.fechaVisita ?? 'N/A'}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  VerticalDivider(color: Colors.grey.shade800, width: 1),
                  const SizedBox(width: 16),
                  // Lado derecho: Formulario
                  Expanded(
                    flex: 4,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nueva Nota',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notaController,
                            maxLines: 4,
                            style: const TextStyle(fontSize: 13, color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Nota de lo conversado...',
                              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                              alignLabelWithHint: true,
                              isDense: true,
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade700)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade800)),
                              filled: true,
                              fillColor: inputDark,
                            ),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 16),
                          Text('Agendar Próxima Visita / Cobro:', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _fechaVisita,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: Colors.blueAccent,
                                        onPrimary: Colors.white,
                                        surface: darkBg,
                                        onSurface: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) setState(() => _fechaVisita = date);
                            },
                            child: IgnorePointer(
                              child: TextFormField(
                                key: ValueKey(_fechaVisita),
                                initialValue: DateFormat('dd/MM/yyyy').format(_fechaVisita),
                                style: const TextStyle(fontSize: 13, color: Colors.white),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.calendar_month_rounded, color: Colors.grey.shade500, size: 16),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 36),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade700)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade800)),
                                  filled: true,
                                  fillColor: inputDark,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _save,
                              icon: _isSaving
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.save_rounded, color: Colors.white, size: 16),
                              label: const Text('Guardar', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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


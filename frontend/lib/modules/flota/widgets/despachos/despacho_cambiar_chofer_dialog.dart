import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/compact_snack_bar.dart';
import '../../../camion_victual/models/camion_victual.dart';
import '../../../camion_victual/providers/camion_victual_provider.dart';
import '../../providers/chofer_provider.dart';

class DespachoCambiarChoferDialog extends StatefulWidget {
  final CamionVictual camion;

  const DespachoCambiarChoferDialog({super.key, required this.camion});

  @override
  State<DespachoCambiarChoferDialog> createState() =>
      _DespachoCambiarChoferDialogState();
}

class _DespachoCambiarChoferDialogState
    extends State<DespachoCambiarChoferDialog> {
  int? _selectedChoferId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedChoferId =
        widget.camion.choferID == 0 ? null : widget.camion.choferID;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChoferProvider>().fetchChoferes();
    });
  }

  Future<void> _guardar() async {
    if (_selectedChoferId == null) {
      CompactSnackBar.showError(context, 'Seleccione un chofer');
      return;
    }
    if (_selectedChoferId == widget.camion.choferID) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<CamionVictualProvider>();
    try {
      await provider.update(widget.camion.id, {'chofer_id': _selectedChoferId});
      if (!mounted) return;
      CompactSnackBar.showSuccess(context, 'Chofer asignado correctamente');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      CompactSnackBar.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE31E24).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_pin,
                      color: Color(0xFFE31E24),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Asignar Conductor',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.camion.nombre,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Seleccione el chofer responsable de este camión virtual:',
                style: TextStyle(color: Color(0xFF475569), fontSize: 12),
              ),
              const SizedBox(height: 12),
              Consumer<ChoferProvider>(
                builder: (context, choferProvider, child) {
                  if (choferProvider.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFE31E24),
                        ),
                      ),
                    );
                  }

                  return DropdownButtonFormField<int>(
                    initialValue: _selectedChoferId,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 1.5,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: choferProvider.choferes.map((chofer) {
                      return DropdownMenuItem<int>(
                        value: chofer.id,
                        child: Text(
                          chofer.name ?? 'Chofer #${chofer.id}',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedChoferId = val),
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _guardar,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 16),
                    label: const Text(
                      'Asignar',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

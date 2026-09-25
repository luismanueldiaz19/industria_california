import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vehiculo_provider.dart';
import '../../providers/mantenimiento_provider.dart';
import '../../services/vehiculo_service.dart';
import '../../models/vehiculo_mantenimiento.dart';

class MantenimientoFormModal extends StatefulWidget {
  final VehiculoMantenimiento? mantenimiento;

  const MantenimientoFormModal({super.key, this.mantenimiento});

  @override
  State<MantenimientoFormModal> createState() => _MantenimientoFormModalState();
}

class _MantenimientoFormModalState extends State<MantenimientoFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _costoController = TextEditingController();

  int? _vehiculoId;
  String? _tipo;
  String? _estado;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.mantenimiento != null) {
      _vehiculoId = widget.mantenimiento!.vehiculoId;
      _tipo = widget.mantenimiento!.tipo;
      _estado = widget.mantenimiento!.estado;
      _descripcionController.text = widget.mantenimiento!.descripcion;
      _costoController.text = widget.mantenimiento!.costo.toString();
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _costoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vehiculoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione un vehículo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'tipo': _tipo!,
        'descripcion': _descripcionController.text.trim(),
        'estado': _estado!,
        'costo': _costoController.text.isNotEmpty
            ? double.tryParse(_costoController.text)
            : 0,
      };

      if (widget.mantenimiento == null) {
        await VehiculoService().createMantenimiento(_vehiculoId!, data);
      } else {
        await VehiculoService().updateMantenimiento(
          _vehiculoId!,
          widget.mantenimiento!.id,
          data,
        );
      }

      if (mounted) {
        context.read<MantenimientoProvider>().loadMantenimientos();
        context.read<VehiculoProvider>().loadVehiculos(); // Refresh stats
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.mantenimiento == null
                  ? 'Mantenimiento registrado'
                  : 'Mantenimiento actualizado',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al registrar mantenimiento'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiculos = context.watch<VehiculoProvider>().vehiculos;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF2C2F33),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.mantenimiento == null
                          ? 'Reportar Mantenimiento'
                          : 'Editar Mantenimiento',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _vehiculoId,
                  isExpanded: true,
                  iconSize: 20,
                  decoration: _inputDecoration('Vehículo'),
                  dropdownColor: const Color(0xFF2C2F33),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  items: vehiculos.map((v) {
                    return DropdownMenuItem<int>(
                      value: v.id,
                      child: Text('${v.ficha} - ${v.placa ?? 'S/N'}'),
                    );
                  }).toList(),
                  onChanged: widget.mantenimiento == null
                      ? (val) {
                          setState(() => _vehiculoId = val);
                        }
                      : null, // Disable changing vehicle on edit
                  validator: (val) => val == null ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _tipo,
                        isExpanded: true,
                        iconSize: 20,
                        decoration: _inputDecoration('Tipo'),
                        dropdownColor: const Color(0xFF2C2F33),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'preventivo',
                            child: Text('Preventivo'),
                          ),
                          DropdownMenuItem(
                            value: 'correctivo',
                            child: Text('Correctivo'),
                          ),
                          DropdownMenuItem(
                            value: 'averia',
                            child: Text('Avería'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _tipo = val);
                        },
                        validator: (val) => val == null ? 'Req' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _estado,
                        isExpanded: true,
                        iconSize: 20,
                        decoration: _inputDecoration('Estado'),
                        dropdownColor: const Color(0xFF2C2F33),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'pendiente',
                            child: Text('Pendiente'),
                          ),
                          DropdownMenuItem(
                            value: 'en_proceso',
                            child: Text('En Proceso'),
                          ),
                          DropdownMenuItem(
                            value: 'resuelto',
                            child: Text('Resuelto'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _estado = val);
                        },
                        validator: (val) => val == null ? 'Req' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descripcionController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _inputDecoration('Descripción del problema'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _costoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _inputDecoration('Costo (Opcional)').copyWith(
                    prefixIcon: const Icon(
                      Icons.attach_money,
                      color: Colors.white54,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: _isLoading ? null : _guardar,
                    child: _isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.mantenimiento == null
                                ? 'GUARDAR REPORTE'
                                : 'ACTUALIZAR',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
      filled: true,
      fillColor: const Color(0xFF1A1C1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
    );
  }
}

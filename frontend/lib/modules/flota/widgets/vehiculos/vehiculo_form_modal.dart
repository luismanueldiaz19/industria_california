import 'package:flutter/material.dart';
import 'package:industria_california/core/widgets/compact_snack_bar.dart';
import 'package:provider/provider.dart';
import '../../models/vehiculo.dart';
import '../../providers/vehiculo_provider.dart';

class VehiculoFormModal extends StatefulWidget {
  final Vehiculo? vehiculo;

  const VehiculoFormModal({super.key, this.vehiculo});

  static Future<bool?> show(BuildContext context, {Vehiculo? vehiculo}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => VehiculoFormModal(vehiculo: vehiculo),
    );
  }

  @override
  State<VehiculoFormModal> createState() => _VehiculoFormModalState();
}

class _VehiculoFormModalState extends State<VehiculoFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fichaController;
  late TextEditingController _placaController;
  late TextEditingController _marcaController;
  late TextEditingController _modeloController;
  late TextEditingController _anioController;
  late TextEditingController _capacidadCargaController;

  late String _tipoEnergia;
  late String _estado;
  bool _isLoading = false;

  bool get isEditing => widget.vehiculo != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehiculo;
    _fichaController = TextEditingController(text: v?.ficha ?? '');
    _placaController = TextEditingController(text: v?.placa ?? '');
    _marcaController = TextEditingController(text: v?.marca ?? '');
    _modeloController = TextEditingController(text: v?.modelo ?? '');
    _anioController = TextEditingController(text: v?.anio?.toString() ?? '');
    _capacidadCargaController = TextEditingController(
      text: v?.capacidadCarga != null
          ? (v!.capacidadCarga! % 1 == 0
                ? v.capacidadCarga!.toInt().toString()
                : v.capacidadCarga!.toString())
          : '',
    );

    const validEnergias = ['diesel', 'gasolina', 'electrico', 'hibrido', 'gas'];
    _tipoEnergia = (v != null && validEnergias.contains(v.tipoEnergia))
        ? v.tipoEnergia
        : 'diesel';

    const validEstados = ['disponible', 'en_mantenimiento', 'inactivo'];
    _estado = (v != null && validEstados.contains(v.estado))
        ? v.estado
        : 'disponible';
  }

  @override
  void dispose() {
    _fichaController.dispose();
    _placaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _capacidadCargaController.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'ficha': _fichaController.text.trim(),
      'placa': _placaController.text.trim().isEmpty
          ? null
          : _placaController.text.trim(),
      'marca': _marcaController.text.trim().isEmpty
          ? null
          : _marcaController.text.trim(),
      'modelo': _modeloController.text.trim().isEmpty
          ? null
          : _modeloController.text.trim(),
      'tipo_energia': _tipoEnergia,
      'estado': _estado,
    };

    final anioText = _anioController.text.trim();
    if (anioText.isNotEmpty) {
      final anioVal = int.tryParse(anioText);
      if (anioVal != null) {
        data['anio'] = anioVal;
      }
    } else {
      data['anio'] = null;
    }

    final capText = _capacidadCargaController.text.trim();
    if (capText.isNotEmpty) {
      final capVal = double.tryParse(capText);
      if (capVal != null) {
        data['capacidad_carga'] = capVal;
      }
    } else {
      data['capacidad_carga'] = null;
    }

    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        await context.read<VehiculoProvider>().updateVehiculo(
          widget.vehiculo!.id,
          data,
        );
      } else {
        await context.read<VehiculoProvider>().createVehiculo(data);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      CompactSnackBar.showSuccess(context, isEditing
                ? 'Vehículo actualizado con éxito'
                : 'Vehículo registrado con éxito');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      CompactSnackBar.showError(context, 'Error al ${isEditing ? "actualizar" : "guardar"} el vehículo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2C2F33),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white12),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        isEditing
                            ? Icons.edit_note
                            : Icons.directions_car_outlined,
                        color: const Color(0xFFE31E24),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isEditing ? 'Editar Vehículo' : 'Registrar Vehículo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white54,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 18, color: Colors.white12),

                  // Ficha & Placa
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Ficha (Ej: F-120)',
                          Icons.tag,
                          _fichaController,
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          'Placa (Ej: 215860)',
                          Icons.pin_drop_outlined,
                          _placaController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Marca & Modelo
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Marca (Ej: Ford)',
                          Icons.directions_car,
                          _marcaController,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          'Modelo (Ej: Cargo)',
                          Icons.category,
                          _modeloController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Año & Capacidad Carga
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Año (Ej: 2022)',
                          Icons.calendar_today_outlined,
                          _anioController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          'Capacidad Carga (kg)',
                          Icons.scale_outlined,
                          _capacidadCargaController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Tipo Energía & Estado
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _tipoEnergia,
                          isExpanded: true,
                          iconSize: 18,
                          decoration: _inputDecoration(
                            'Tipo de Energía',
                            Icons.local_gas_station_outlined,
                          ),
                          dropdownColor: const Color(0xFF2C2F33),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'diesel',
                              child: Text('Diesel'),
                            ),
                            DropdownMenuItem(
                              value: 'gasolina',
                              child: Text('Gasolina'),
                            ),
                            DropdownMenuItem(
                              value: 'electrico',
                              child: Text('Eléctrico'),
                            ),
                            DropdownMenuItem(
                              value: 'hibrido',
                              child: Text('Híbrido'),
                            ),
                            DropdownMenuItem(value: 'gas', child: Text('Gas')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _tipoEnergia = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _estado,
                          isExpanded: true,
                          iconSize: 18,
                          decoration: _inputDecoration(
                            'Estado',
                            Icons.info_outline,
                          ),
                          dropdownColor: const Color(0xFF2C2F33),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'disponible',
                              child: Text('Disponible'),
                            ),
                            DropdownMenuItem(
                              value: 'en_mantenimiento',
                              child: Text('En Taller'),
                            ),
                            DropdownMenuItem(
                              value: 'inactivo',
                              child: Text('Inactivo'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _estado = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'CANCELAR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE31E24),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 11),
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
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isEditing
                                      ? 'ACTUALIZAR VEHÍCULO'
                                      : 'GUARDAR VEHÍCULO',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
      prefixIcon: Icon(icon, color: Colors.white54, size: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 32),
      filled: true,
      fillColor: const Color(0xFF1A1C1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFE31E24), width: 1.2),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: _inputDecoration(label, icon),
      validator: required
          ? (value) =>
                value == null || value.trim().isEmpty ? 'Requerido' : null
          : null,
    );
  }
}

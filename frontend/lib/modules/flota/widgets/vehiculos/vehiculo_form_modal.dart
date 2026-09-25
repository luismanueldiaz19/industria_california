import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vehiculo_provider.dart';

class VehiculoFormModal extends StatefulWidget {
  const VehiculoFormModal({super.key});

  @override
  State<VehiculoFormModal> createState() => _VehiculoFormModalState();
}

class _VehiculoFormModalState extends State<VehiculoFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _fichaController = TextEditingController();
  final _placaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  String _tipoEnergia = 'diesel';

  @override
  void dispose() {
    _fichaController.dispose();
    _placaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'ficha': _fichaController.text.trim(),
      'placa': _placaController.text.trim(),
      'marca': _marcaController.text.trim(),
      'modelo': _modeloController.text.trim(),
      'tipo_energia': _tipoEnergia,
      'estado': 'disponible',
    };

    try {
      await context.read<VehiculoProvider>().createVehiculo(data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar el vehículo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    const Text(
                      'Registrar Vehículo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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
                _buildTextField(
                  'Ficha (Ej: F-120)',
                  Icons.tag,
                  _fichaController,
                  required: true,
                ),
                const SizedBox(height: 8),
                _buildTextField('Placa', Icons.pin_drop, _placaController),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Marca',
                        Icons.directions_car,
                        _marcaController,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        'Modelo',
                        Icons.category,
                        _modeloController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _tipoEnergia,
                  isExpanded: true,
                  iconSize: 20,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    labelText: 'Tipo de Energía',
                    labelStyle: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A1C1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: const Color(0xFF2C2F33),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  items: const [
                    DropdownMenuItem(value: 'diesel', child: Text('Diesel')),
                    DropdownMenuItem(
                      value: 'gasolina',
                      child: Text('Gasolina'),
                    ),
                    DropdownMenuItem(
                      value: 'electrico',
                      child: Text('Eléctrico'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _tipoEnergia = val);
                  },
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
                    onPressed: _guardar,
                    child: const Text(
                      'GUARDAR VEHÍCULO',
                      style: TextStyle(
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

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white54, size: 16),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        filled: true,
        fillColor: const Color(0xFF1A1C1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
      ),
      validator: required
          ? (value) => value == null || value.isEmpty ? 'Requerido' : null
          : null,
    );
  }
}

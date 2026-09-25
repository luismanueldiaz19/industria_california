import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/vehiculo_gasto.dart';
import '../../providers/gasto_vehiculo_provider.dart';
import '../../providers/vehiculo_provider.dart';
import 'tipo_gasto_manager_dialog.dart';

class GastoFormModal extends StatefulWidget {
  final VehiculoGasto? gasto;
  final int? initialVehiculoId;

  const GastoFormModal({super.key, this.gasto, this.initialVehiculoId});

  @override
  State<GastoFormModal> createState() => _GastoFormModalState();
}

class _GastoFormModalState extends State<GastoFormModal> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  static const List<String> _unidadesMedida = [
    'UNIDAD',
    'LITRO',
    'GALÓN',
    'KM',
    'HORA',
    'SERVICIO',
  ];

  int? _selectedVehiculoId;
  String _selectedTipoGasto = 'combustible';
  String _selectedUnidadMedida = 'UNIDAD';
  DateTime _selectedDate = DateTime.now();

  final _conceptoController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _precioUnitarioController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Load vehicles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehiculoProvider>().loadVehiculos();
    });

    _selectedVehiculoId = widget.initialVehiculoId;

    if (widget.gasto != null) {
      final g = widget.gasto!;
      _selectedVehiculoId = g.vehiculoId;
      _selectedTipoGasto = g.tipoGasto ?? 'combustible';
      if (g.fechaGasto != null) {
        _selectedDate = g.fechaGasto!;
      }
      _conceptoController.text = g.concepto;
      _cantidadController.text = g.cantidad.toString();
      _precioUnitarioController.text = g.precioUnitario.toString();
      if (g.unidadMedida != null &&
          _unidadesMedida.contains(g.unidadMedida!.toUpperCase())) {
        _selectedUnidadMedida = g.unidadMedida!.toUpperCase();
      }
    }
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _cantidadController.dispose();
    _precioUnitarioController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE31E24),
              onPrimary: Colors.white,
              surface: Color(0xFF2C2F33),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehiculoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un vehículo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'tipo_gasto': _selectedTipoGasto,
      'fecha_gasto': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'concepto': _conceptoController.text,
      'cantidad': _cantidadController.text.isNotEmpty
          ? _cantidadController.text
          : '1',
      'unidad_medida': _selectedUnidadMedida,
      'precio_unitario': _precioUnitarioController.text,
    };

    final provider = context.read<GastoVehiculoProvider>();
    bool success;

    if (widget.gasto == null) {
      success = await provider.createGasto(_selectedVehiculoId!, data);
    } else {
      success = await provider.updateGasto(
        _selectedVehiculoId!,
        widget.gasto!.id,
        data,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guardado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Error al guardar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2C2F33),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(16.0),
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
                      widget.gasto == null ? 'Registrar Gasto' : 'Editar Gasto',
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

                Consumer<VehiculoProvider>(
                  builder: (context, vehiculoProvider, child) {
                    if (vehiculoProvider.isLoading &&
                        vehiculoProvider.vehiculos.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // ignore: deprecated_member_use
                    return DropdownButtonFormField<int>(
                      value: _selectedVehiculoId,
                      isExpanded: true,
                      iconSize: 20,
                      menuMaxHeight: 300,
                      decoration: _inputDecoration('Vehículo'),
                      dropdownColor: const Color(0xFF2C2F33),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      items: vehiculoProvider.vehiculos.map((v) {
                        return DropdownMenuItem<int>(
                          value: v.id,
                          child: Text('${v.ficha} - ${v.marca} ${v.modelo}'),
                        );
                      }).toList(),
                      onChanged: widget.initialVehiculoId != null
                          ? null // Locked if coming from specific vehicle view
                          : (val) => setState(() => _selectedVehiculoId = val),
                    );
                  },
                ),
                const SizedBox(height: 8),

                Consumer<GastoVehiculoProvider>(
                  builder: (context, gastoProvider, child) {
                    final tiposNames = gastoProvider.tiposGasto
                        .map((t) => t.nombre)
                        .toList();
                    if (tiposNames.isEmpty) {
                      tiposNames.add('combustible');
                    }
                    if (!tiposNames.contains(_selectedTipoGasto)) {
                      // Usar Future.microtask para actualizar el estado sin conflicto en el build
                      Future.microtask(() {
                        if (mounted) {
                          setState(() => _selectedTipoGasto = tiposNames.first);
                        }
                      });
                    }

                    return Row(
                      children: [
                        Expanded(
                          // ignore: deprecated_member_use
                          child: DropdownButtonFormField<String>(
                            value: tiposNames.contains(_selectedTipoGasto)
                                ? _selectedTipoGasto
                                : tiposNames.first,
                            isExpanded: true,
                            iconSize: 20,
                            menuMaxHeight: 300,
                            decoration: _inputDecoration('Tipo de Gasto'),
                            dropdownColor: const Color(0xFF2C2F33),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            items: tiposNames.map((t) {
                              return DropdownMenuItem<String>(
                                value: t,
                                child: Text(t.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedTipoGasto = val);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const TipoGastoManagerDialog(),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),

                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: _inputDecoration('Fecha de Gasto'),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _conceptoController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _inputDecoration('Concepto (Ej. Gasolina)'),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnidadMedida,
                        isExpanded: true,
                        iconSize: 20,
                        menuMaxHeight: 300,
                        decoration: _inputDecoration('Unidad de Medida'),
                        dropdownColor: const Color(0xFF2C2F33),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        items: _unidadesMedida.map((u) {
                          return DropdownMenuItem<String>(
                            value: u,
                            child: Text(u),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _selectedUnidadMedida = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _cantidadController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        decoration: _inputDecoration('Cantidad (Ej. 10)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _precioUnitarioController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _inputDecoration('Precio Unitario'),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? 'Requerido' : null,
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
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.gasto == null
                                ? 'REGISTRAR GASTO'
                                : 'ACTUALIZAR GASTO',
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

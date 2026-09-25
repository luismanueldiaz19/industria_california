import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chofer.dart';
import '../../providers/chofer_provider.dart';

class ChoferFormModal extends StatefulWidget {
  final Chofer? chofer;

  const ChoferFormModal({super.key, this.chofer});

  @override
  State<ChoferFormModal> createState() => _ChoferFormModalState();
}

class _ChoferFormModalState extends State<ChoferFormModal> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _licenciaController;
  late TextEditingController _tipoLicenciaController;
  late TextEditingController _vencimientoLicenciaController;
  late TextEditingController _contactoEmergenciaController;
  
  String _estado = 'activo';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.chofer?.name ?? '');
    _usernameController = TextEditingController(text: widget.chofer?.username ?? '');
    _emailController = TextEditingController(text: widget.chofer?.email ?? '');
    _passwordController = TextEditingController();
    _licenciaController = TextEditingController(text: widget.chofer?.numeroLicencia ?? '');
    _tipoLicenciaController = TextEditingController(text: widget.chofer?.tipoLicencia ?? '');
    
    // Parse vencimiento_licencia to YYYY-MM-DD
    String vencimiento = '';
    if (widget.chofer?.vencimientoLicencia != null) {
      vencimiento = widget.chofer!.vencimientoLicencia!.split('T').first;
    }
    _vencimientoLicenciaController = TextEditingController(text: vencimiento);
    
    _contactoEmergenciaController = TextEditingController(text: widget.chofer?.contactoEmergencia ?? '');
    
    if (widget.chofer != null) {
      _estado = widget.chofer!.estado;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _licenciaController.dispose();
    _tipoLicenciaController.dispose();
    _vencimientoLicenciaController.dispose();
    _contactoEmergenciaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text.trim(),
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      'numero_licencia': _licenciaController.text.trim(),
      'tipo_licencia': _tipoLicenciaController.text.trim(),
      'vencimiento_licencia': _vencimientoLicenciaController.text.trim(),
      'contacto_emergencia': _contactoEmergenciaController.text.trim(),
      'estado': _estado,
    };

    if (_passwordController.text.isNotEmpty) {
      data['password'] = _passwordController.text;
    }

    try {
      if (widget.chofer == null) {
        await context.read<ChoferProvider>().createChofer(data);
      } else {
        await context.read<ChoferProvider>().updateChofer(widget.chofer!.id, data);
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.chofer == null 
              ? 'Chofer creado correctamente' 
              : 'Chofer actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.chofer != null;
    
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2C2F33),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Editar Chofer' : 'Añadir Chofer',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nameController,
                label: 'Nombre Completo',
                icon: Icons.person,
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _usernameController,
                label: 'Nombre de Usuario',
                icon: Icons.account_circle,
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Correo Electrónico (Opcional)',
                icon: Icons.email,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                label: isEditing ? 'Contraseña (Dejar en blanco para no cambiar)' : 'Contraseña (Opcional, 12345678 por defecto)',
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _licenciaController,
                      label: 'No. Licencia',
                      icon: Icons.badge,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _tipoLicenciaController,
                      label: 'Tipo Licencia',
                      icon: Icons.card_membership,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
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
                        if (date != null) {
                          setState(() {
                            _vencimientoLicenciaController.text = date.toIso8601String().split('T').first;
                          });
                        }
                      },
                      child: IgnorePointer(
                        child: _buildTextField(
                          controller: _vencimientoLicenciaController,
                          label: 'Vencimiento Lic.',
                          icon: Icons.calendar_today,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _contactoEmergenciaController,
                      label: 'Contacto de Emergencia',
                      icon: Icons.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _estado,
                dropdownColor: const Color(0xFF3B3E43),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Estado',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1A1C1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.info, color: Colors.white54),
                ),
                items: const [
                  DropdownMenuItem(value: 'activo', child: Text('ACTIVO')),
                  DropdownMenuItem(value: 'vacaciones', child: Text('VACACIONES')),
                  DropdownMenuItem(value: 'inactivo', child: Text('INACTIVO')),
                ],
                onChanged: (v) => setState(() => _estado = v!),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31E24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEditing ? 'GUARDAR CAMBIOS' : 'CREAR CHOFER',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1A1C1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon, color: Colors.white54),
      ),
      validator: validator,
    );
  }
}

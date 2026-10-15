import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chofer.dart';
import '../../providers/chofer_provider.dart';

class ChoferFormModal extends StatelessWidget {
  final Chofer? chofer;

  const ChoferFormModal({super.key, this.chofer});

  static Future<bool?> show(BuildContext context, {Chofer? chofer}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ChoferFormModal(chofer: chofer),
    );
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
        child: ChoferFormWidget(
          chofer: chofer,
          onClose: () => Navigator.pop(context),
          onSuccess: () => Navigator.pop(context, true),
        ),
      ),
    );
  }
}

class ChoferFormWidget extends StatefulWidget {
  final Chofer? chofer;
  final VoidCallback? onClose;
  final VoidCallback? onSuccess;

  const ChoferFormWidget({
    super.key,
    this.chofer,
    this.onClose,
    this.onSuccess,
  });

  @override
  State<ChoferFormWidget> createState() => _ChoferFormWidgetState();
}

class _ChoferFormWidgetState extends State<ChoferFormWidget> {
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
  bool _obscurePassword = true;

  bool get isEditing => widget.chofer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _licenciaController = TextEditingController();
    _tipoLicenciaController = TextEditingController();
    _vencimientoLicenciaController = TextEditingController();
    _contactoEmergenciaController = TextEditingController();
    _initData();
  }

  @override
  void didUpdateWidget(covariant ChoferFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chofer?.id != widget.chofer?.id) {
      _initData();
    }
  }

  void _initData() {
    final c = widget.chofer;
    _nameController.text = c?.name ?? '';
    _usernameController.text = c?.username ?? '';
    _emailController.text = c?.email ?? '';
    _passwordController.clear();
    _licenciaController.text = c?.numeroLicencia ?? '';
    _tipoLicenciaController.text = c?.tipoLicencia ?? '';

    String vencimiento = '';
    if (c?.vencimientoLicencia != null) {
      vencimiento = c!.vencimientoLicencia!.split('T').first;
    }
    _vencimientoLicenciaController.text = vencimiento;
    _contactoEmergenciaController.text = c?.contactoEmergencia ?? '';

    const validEstados = ['activo', 'vacaciones', 'inactivo'];
    if (c != null && validEstados.contains(c.estado)) {
      _estado = c.estado;
    } else {
      _estado = 'activo';
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

  Future<void> _seleccionarFechaVencimiento() async {
    DateTime initial = DateTime.now();
    if (_vencimientoLicenciaController.text.isNotEmpty) {
      final parsed = DateTime.tryParse(_vencimientoLicenciaController.text);
      if (parsed != null) initial = parsed;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
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
        _vencimientoLicenciaController.text = date
            .toIso8601String()
            .split('T')
            .first;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      'numero_licencia': _licenciaController.text.trim().isEmpty
          ? null
          : _licenciaController.text.trim(),
      'tipo_licencia': _tipoLicenciaController.text.trim().isEmpty
          ? null
          : _tipoLicenciaController.text.trim(),
      'vencimiento_licencia': _vencimientoLicenciaController.text.trim().isEmpty
          ? null
          : _vencimientoLicenciaController.text.trim(),
      'contacto_emergencia': _contactoEmergenciaController.text.trim().isEmpty
          ? null
          : _contactoEmergenciaController.text.trim(),
      'estado': _estado,
    };

    if (_passwordController.text.trim().isNotEmpty) {
      data['password'] = _passwordController.text.trim();
    }

    try {
      if (widget.chofer == null) {
        await context.read<ChoferProvider>().createChofer(data);
      } else {
        await context.read<ChoferProvider>().updateChofer(
          widget.chofer!.id,
          data,
        );
      }

      if (!mounted) return;
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        Navigator.pop(context, true);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.chofer == null
                ? 'Chofer creado correctamente'
                : 'Chofer actualizado correctamente',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final cleanMsg = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('HttpException: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(cleanMsg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                        : Icons.person_add_alt_1_outlined,
                    color: const Color(0xFFE31E24),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Editar Chofer' : 'Añadir Chofer',
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
                    onPressed: () {
                      if (widget.onClose != null) {
                        widget.onClose!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
              const Divider(height: 18, color: Colors.white12),

              // Nombre Completo & Nombre de Usuario
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _nameController,
                      label: 'Nombre Completo',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _usernameController,
                      label: 'Nombre de Usuario',
                      icon: Icons.account_circle_outlined,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Correo Electrónico
              _buildTextField(
                controller: _emailController,
                label: 'Correo Electrónico (Opcional)',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),

              // Contraseña
              _buildTextField(
                controller: _passwordController,
                label: isEditing
                    ? 'Contraseña (Opcional, dejar vacía para conservar)'
                    : 'Contraseña (Defecto: 12345678)',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white38,
                    size: 16,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),

              // No. Licencia & Tipo Licencia
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _licenciaController,
                      label: 'No. Licencia',
                      icon: Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _tipoLicenciaController,
                      label: 'Tipo Licencia',
                      icon: Icons.card_membership_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Vencimiento Lic. & Contacto Emergencia
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _seleccionarFechaVencimiento,
                      child: IgnorePointer(
                        child: _buildTextField(
                          controller: _vencimientoLicenciaController,
                          label: 'Vencimiento Lic.',
                          icon: Icons.calendar_today_outlined,
                          suffixIcon: const Icon(
                            Icons.calendar_month,
                            color: Colors.white38,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _contactoEmergenciaController,
                      label: 'Contacto de Emergencia',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Estado
              DropdownButtonFormField<String>(
                initialValue: _estado,
                isExpanded: true,
                iconSize: 18,
                decoration: _inputDecoration('Estado', Icons.info_outline),
                dropdownColor: const Color(0xFF2C2F33),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                items: const [
                  DropdownMenuItem(value: 'activo', child: Text('Activo')),
                  DropdownMenuItem(
                    value: 'vacaciones',
                    child: Text('Vacaciones'),
                  ),
                  DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _estado = v);
                },
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (widget.onClose != null) {
                          widget.onClose!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
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
                      onPressed: _isLoading ? null : _submit,
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
                              isEditing ? 'GUARDAR CAMBIOS' : 'CREAR CHOFER',
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
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
      prefixIcon: Icon(icon, color: Colors.white54, size: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 32),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 32),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      obscureText: obscureText,
      decoration: _inputDecoration(label, icon, suffixIcon: suffixIcon),
      validator: validator,
    );
  }
}

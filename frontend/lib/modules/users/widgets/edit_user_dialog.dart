import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/users_provider.dart';

class EditUserDialog extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditUserDialog({super.key, required this.user});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  final TextEditingController _passwordController = TextEditingController();
  
  String? _selectedRole;
  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name']?.toString() ?? '');
    _usernameController = TextEditingController(text: widget.user['username']?.toString() ?? '');
    // Asumimos que viene el nombre del rol o podemos dejarlo null si no se envió en el JSON
    _selectedRole = widget.user['roles'] != null && (widget.user['roles'] as List).isNotEmpty
        ? widget.user['roles'][0]['name']
        : 'vendedor';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final usersProvider = Provider.of<UsersProvider>(context, listen: false);

      final success = await usersProvider.updateUser(
        widget.user['id'],
        _nameController.text,
        _usernameController.text,
        _passwordController.text.isNotEmpty ? _passwordController.text : null,
        _selectedRole,
      );

      setState(() => _isLoading = false);

      if (success) {
        if (!mounted) return;
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario actualizado exitosamente.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              usersProvider.errorMessage ?? 'Error al actualizar el usuario.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1A1C1E);
    final accentColor = const Color(0xFFE31E24);

    return Dialog(
      backgroundColor: primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Editar Usuario',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nameController,
                label: 'Nombre Completo',
                icon: Icons.person_outline,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _usernameController,
                label: 'Nombre de Usuario',
                icon: Icons.account_circle_outlined,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                label: 'Nueva Contraseña (Opcional)',
                icon: Icons.lock_outline,
                isPassword: true,
                validator: (value) {
                  return null; // Opcional al editar
                },
              ),
              const SizedBox(height: 16),
              _buildRoleDropdown(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Actualizar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    final secondaryColor = const Color(0xFF2C2F33);
    final accentColor = const Color(0xFFE31E24);

    return TextFormField(
      controller: controller,
      obscureText: isPassword && _isObscure,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: secondaryColor,
        prefixIcon: Icon(icon, color: Colors.white54),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isObscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white54,
                ),
                onPressed: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    final secondaryColor = const Color(0xFF2C2F33);
    final accentColor = const Color(0xFFE31E24);
    
    final roles = [
      {'name': 'admin', 'label': 'Administrador (CRUD Total)'},
      {'name': 'gerente', 'label': 'Gerente (Vista Global)'},
      {'name': 'contable', 'label': 'Contador (Sin Eliminar)'},
      {'name': 'vendedor', 'label': 'Vendedor (Reporta Pagos)'},
    ];

    // Verificar que _selectedRole es válido, si no, fallback
    if (!roles.any((r) => r['name'] == _selectedRole)) {
      _selectedRole = 'vendedor';
    }

    return DropdownButtonFormField<String>(
      value: _selectedRole,
      dropdownColor: secondaryColor,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Rol del Usuario',
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: secondaryColor,
        prefixIcon: const Icon(Icons.shield_outlined, color: Colors.white54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 1),
        ),
      ),
      items: roles.map((role) {
        return DropdownMenuItem<String>(
          value: role['name'],
          child: Text(role['label']!),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedRole = value;
        });
      },
    );
  }
}

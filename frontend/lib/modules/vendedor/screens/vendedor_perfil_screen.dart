import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/auth_provider.dart';
import '../../../../core/services/profile_service.dart';
import '../../../core/app_theme.dart';
import '../../auth/login_screen.dart';

class VendedorPerfilScreen extends StatefulWidget {
  const VendedorPerfilScreen({super.key});

  @override
  State<VendedorPerfilScreen> createState() => _VendedorPerfilScreenState();
}

class _VendedorPerfilScreenState extends State<VendedorPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();

  late TextEditingController _nameCtrl;
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLoading = false;
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoName;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _nameCtrl = TextEditingController(
      text: authProvider.name ?? authProvider.username ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _pickImage() async {
    final PlatformFile? file = await FilePicker.pickFile(
      type: FileType.image,
      allowedExtensions: ['jpg', 'png'],
      compressionQuality: 80,
    );

    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _selectedPhotoBytes = bytes;
        _selectedPhotoName = file.name;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordCtrl.text.isNotEmpty &&
        _newPasswordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _profileService.updateProfile(
        name: _nameCtrl.text,
        currentPassword: _currentPasswordCtrl.text,
        newPassword: _newPasswordCtrl.text,
        photoBytes: _selectedPhotoBytes,
        photoName: _selectedPhotoName,
      );

      if (mounted) {
        // Actualizar el provider con los nuevos datos
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.updateProfileData(
          newName: res['user']['name'],
          newPhotoUrl: res['user']['profile_photo_url'],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Limpiar campos de contraseña
        _currentPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeStyle = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Mi Perfil',
          style: themeStyle.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Avatar
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                                color: Colors.grey.shade200,
                              ),
                              child: ClipOval(
                                child: _selectedPhotoBytes != null
                                    ? Image.memory(
                                        _selectedPhotoBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : (authProvider.profilePhotoUrl != null
                                          ? Image.network(
                                              authProvider.profilePhotoUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, stack) =>
                                                  const Icon(
                                                    Icons.person,
                                                    size: 60,
                                                    color: Colors.grey,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.grey,
                                            )),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Campos de Información
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información Personal',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _nameCtrl,
                            label: 'Nombre Completo',
                            icon: Icons.person_outline,
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Requerido' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Seguridad
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seguridad',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Deja los campos vacíos si no deseas cambiar tu contraseña.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _currentPasswordCtrl,
                            label: 'Contraseña Actual',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            validator: (val) {
                              if (_newPasswordCtrl.text.isNotEmpty &&
                                  (val == null || val.isEmpty)) {
                                return 'Requerida para cambiar contraseña';
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            controller: _newPasswordCtrl,
                            label: 'Nueva Contraseña (min. 6)',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            validator: (val) {
                              if (val != null &&
                                  val.isNotEmpty &&
                                  val.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            controller: _confirmPasswordCtrl,
                            label: 'Confirmar Nueva Contraseña',
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Botón Guardar
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          'Guardar Cambios',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          elevation: 5,
                          shadowColor: AppTheme.primaryBlue.withValues(
                            alpha: 0.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Botón Cerrar Sesión
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          'Cerrar Sesión',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: const BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}

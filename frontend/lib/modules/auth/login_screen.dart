import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../models/company.dart';
import '../../main.dart';
import '../vendedor/screens/vendedor_main_layout.dart';
import 'forgot_password_screen.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_submit_button.dart';
// import 'widgets/auth_quick_credential_card.dart';
import 'widgets/login_branding_panel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  late AnimationController _formAnimController;
  late Animation<Offset> _formSlideAnimation;
  late Animation<double> _formFadeAnimation;

  @override
  void initState() {
    super.initState();
    _formAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _formSlideAnimation =
        Tween<Offset>(begin: const Offset(0.12, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _formAnimController,
            curve: Curves.easeOutCubic,
          ),
        );

    _formFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formAnimController, curve: Curves.easeOut),
    );

    _formAnimController.forward();
  }

  @override
  void dispose() {
    _formAnimController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              authProvider.isVendedor
              ? const VendedorMainLayout()
              : const MainLayout(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  // --- INICIO: AUTOLLENADO RÁPIDO PARA DESARROLLO ---
  // Comentar o eliminar esta sección en producción
  void _autofillCredentials(String role) {
    FocusScope.of(context).unfocus();
    setState(() {
      if (role == 'admin') {
        _usernameController.text = "ludeveloper";
        _passwordController.text = "199512";
      } else if (role == 'gerente') {
        _usernameController.text =
            "gerente"; // Placeholder (agregalo en seeder si necesitas)
        _passwordController.text = "123456";
      } else if (role == 'vendedor') {
        _usernameController.text = "wagner";
        _passwordController.text = "123456";
      }
    });
  }

  Widget _buildQuickLoginRoles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Autollenado Rápido (Desarrollo):',
          style: TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _roleOption('admin', 'Admin', const Color(0xFFE31E24)),
            _roleOption('gerente', 'Gerente', const Color(0xFF4CAF50)),
            _roleOption('vendedor', 'Vendedor', const Color(0xFF2196F3)),
          ],
        ),
      ],
    );
  }

  Widget _roleOption(String role, String label, Color color) {
    return InkWell(
      onTap: () => _autofillCredentials(role),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- FIN: AUTOLLENADO RÁPIDO PARA DESARROLLO ---

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 850;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image with deep dark overlay
          Positioned.fill(
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFF121214));
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1A1C1E).withValues(alpha: 0.8),
            ),
          ),

          // Main Layout
          Positioned.fill(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(minHeight: size.height),
                alignment: Alignment.center,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 740 : 380,
                    minHeight: 400,
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: isDesktop
                        ? IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _buildBrandingSide()),
                                Expanded(child: _buildLoginFormSide()),
                              ],
                            ),
                          )
                        : _buildLoginFormSide(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Left branding panel for Desktop layouts
  Widget _buildBrandingSide() {
    return const LoginBrandingPanel(company: Company.current);
  }

  // Right side form panel (Mobile showing only this)
  Widget _buildLoginFormSide() {
    final authProvider = Provider.of<AuthProvider>(context);
    final accentColor = const Color(0xFFE31E24);
    final isDesktop = MediaQuery.of(context).size.width > 850;
    const company = Company.current;

    return Container(
      color: const Color(0xFF2C2F33).withValues(alpha: 0.55),
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
      child: SlideTransition(
        position: _formSlideAnimation,
        child: FadeTransition(
          opacity: _formFadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mobile logo placement
              if (!isDesktop) ...[
                Center(
                  child: Hero(
                    tag: 'company_logo_hero',
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        company.logo,
                        height: 55,
                        width: 55,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.business,
                              color: Color(0xFFE31E24),
                              size: 35,
                            ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    company.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const Text(
                'Iniciar Sesión',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bienvenido a ${company.name}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 14),

              // Error Display Banner
              if (authProvider.errorMessage != null) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authProvider.errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Login Form with modular fields
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AuthTextField(
                      controller: _usernameController,
                      hintText: 'Nombre de usuario',
                      prefixIcon: Icons.person_outline,
                      accentColor: accentColor,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese su nombre de usuario';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    AuthTextField(
                      controller: _passwordController,
                      hintText: 'Contraseña',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      accentColor: accentColor,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white54,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese su contraseña';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Keep me logged in & Forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (val) {
                            setState(() {
                              _rememberMe = val ?? false;
                            });
                          },
                          activeColor: accentColor,
                          checkColor: Colors.white,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          side: const BorderSide(
                            color: Colors.white30,
                            width: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Recordarme',
                        style: TextStyle(color: Colors.white70, fontSize: 11.5),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '¿Olvidó contraseña?',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Modular Submit Button
              AuthSubmitButton(
                text: 'INGRESAR AL SISTEMA',
                isLoading: authProvider.isLoading,
                onPressed: _handleLogin,
                backgroundColor: accentColor,
                height: 40,
              ),

              // Comentar esto en producción para ocultar los botones de prueba
              // _buildQuickLoginRoles(),
            ],
          ),
        ),
      ),
    );
  }
}

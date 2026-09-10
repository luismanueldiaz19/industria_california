import 'package:flutter/material.dart';
import '../../../models/company.dart';

class LoginBrandingPanel extends StatelessWidget {
  final Company company;

  const LoginBrandingPanel({
    super.key,
    required this.company,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E2124),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF25282C), Color(0xFF16181A)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          // HERO LOGO - Centerpiece Cristal Compacto
          Hero(
            tag: 'company_logo_hero',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Image.asset(
                company.logo,
                height: 95,
                width: 95,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.business,
                  color: Color(0xFFE31E24),
                  size: 55,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Nombre de la empresa
          Text(
            company.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.5,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(1, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2.5,
            width: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE31E24),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'SISTEMA DE GESTIÓN INTEGRAL',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
            ),
          ),

          const Spacer(),

          // Footer branding
          Text(
            '© ${DateTime.now().year} ${company.developer}. Todos los derechos reservados.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

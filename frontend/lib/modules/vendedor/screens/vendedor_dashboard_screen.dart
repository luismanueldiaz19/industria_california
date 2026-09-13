import 'package:flutter/material.dart';
import 'package:industria_california/core/auth_provider.dart';
import 'package:industria_california/models/company.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../widgets/action_quick_vendedor.dart';
import '../widgets/header_clipper.dart';
import '../widgets/mini_chart_painter.dart';

class VendedorDashboardScreen extends StatelessWidget {
  final VoidCallback? onProfileTap;

  const VendedorDashboardScreen({super.key, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final styleTheme = Theme.of(context).textTheme;
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con curva y tarjetas superpuestas
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Fondo curvo
                ClipPath(
                  clipper: HeaderClipper(),
                  child: Container(
                    height: 210,
                    width: double.infinity,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                // Contenido del Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barra superior (Logo + Perfil)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.bar_chart,
                                color: Colors.blue.shade300,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                Company.current.name,
                                style: styleTheme.bodySmall?.copyWith(
                                  color: Colors.white,

                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: onProfileTap,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.white,
                                  backgroundImage:
                                      authProvider.profilePhotoUrl != null
                                      ? NetworkImage(
                                          authProvider.profilePhotoUrl!,
                                        )
                                      : null,
                                  child: authProvider.profilePhotoUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          color: AppTheme.primaryBlue,
                                          size: 20,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  authProvider.username ?? 'Error Logueo',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Saludo
                      Text(
                        '¡Hola, ${authProvider.username ?? 'Error'}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tarjetas de métricas (Superpuestas)
                Positioned(
                  top: 120,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      // Tarjeta Ventas Hoy (Azul)
                      Expanded(
                        child: Container(
                          height: 110,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryBlue,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.secondaryBlue.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ventas Hoy',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '\$0,000.00',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '+0% hoy',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              // Mini Chart placeholder
                              SizedBox(
                                height: 20,
                                width: double.infinity,
                                child: CustomPaint(painter: MiniChartPainter()),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Tarjeta Objetivo (Blanco)
                      Expanded(
                        child: Container(
                          height: 110,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Objetivo Mensual',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Circular Progress
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      value: 0.50,
                                      strokeWidth: 4,
                                      backgroundColor: Colors.grey.shade200,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '78%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'COMPLETADO',
                                        style: TextStyle(
                                          fontSize: 6,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                '\$00,000 / \$00,000',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Espaciador para compensar las tarjetas superpuestas
            const SizedBox(height: 40),

            // Acciones Rápidas
            ActionQuickVendedor(styleTheme: styleTheme),

            const SizedBox(height: 20),

            // Pedidos Recientes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ventas Recientes',
                    style: styleTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Container(
                  //   decoration: BoxDecoration(
                  //     color: Colors.white,
                  //     borderRadius: BorderRadius.circular(20),
                  //     boxShadow: [
                  //       BoxShadow(
                  //         color: Colors.black.withValues(alpha: 0.03),
                  //         blurRadius: 10,
                  //         offset: const Offset(0, 5),
                  //       ),
                  //     ],
                  //   ),
                  //   child: Column(
                  //     children: [
                  //       _buildOrderRow(
                  //         id: '#VF-1092',
                  //         name: 'Juan Pérez',
                  //         time: 'Hoy 14:15',
                  //         amount: '\$650.00',
                  //         status: 'Completado',
                  //         statusColor: AppTheme.accentGreen,
                  //         icon: Icons.check_circle,
                  //       ),
                  //       const Divider(height: 1, indent: 16, endIndent: 16),
                  //       _buildOrderRow(
                  //         id: '#VF-1091',
                  //         name: 'Ana Gómez',
                  //         time: 'Hoy 11:30',
                  //         amount: '\$1,280.00',
                  //         status: 'En Proceso',
                  //         statusColor: AppTheme.accentYellow,
                  //         icon: Icons.sync,
                  //       ),
                  //       const Divider(height: 1, indent: 16, endIndent: 16),
                  //       _buildOrderRow(
                  //         id: '#VF-1090',
                  //         name: 'Carlos Ruiz',
                  //         time: 'Ayer',
                  //         amount: '\$940.00',
                  //         status: 'Completado',
                  //         statusColor: AppTheme.accentGreen,
                  //         icon: Icons.check_circle,
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderRow({
    required String id,
    required String name,
    required String time,
    required String amount,
    required String status,
    required Color statusColor,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                id,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    name,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    time,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          // Right side
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(icon, color: statusColor, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

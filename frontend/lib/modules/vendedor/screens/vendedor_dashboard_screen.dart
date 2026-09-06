import 'package:flutter/material.dart';
import '../widgets/header_clipper.dart';
import '../widgets/mini_chart_painter.dart';

class VendedorDashboardScreen extends StatelessWidget {
  const VendedorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // Colores del diseño
    const primaryBlue = Color(0xFF1E2F4C); // Azul oscuro
    const secondaryBlue = Color(0xFF284168); // Azul más claro para tarjeta
    const accentGreen = Color(0xFF2E7D32); // Verde para éxito
    const accentYellow = Color(0xFFF9A825); // Amarillo para proceso
    const bgColor = Color(0xFFF5F7FA); // Gris claro de fondo

    return Scaffold(
      backgroundColor: bgColor,
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
                    height: 250,
                    width: double.infinity,
                    color: primaryBlue,
                  ),
                ),
                // Contenido del Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barra superior (Logo + Perfil)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bar_chart, color: Colors.blue.shade300, size: 28),
                              const SizedBox(width: 8),
                              const Text(
                                'VENTAFLOW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white,
                                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'), // Placeholder
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Alejandro R.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Saludo
                      const Text(
                        '¡Hola, Alejandro!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Tarjetas de métricas (Superpuestas)
                Positioned(
                  top: 150,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      // Tarjeta Ventas Hoy (Azul)
                      Expanded(
                        child: Container(
                          height: 140,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: secondaryBlue,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: secondaryBlue.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ventas Hoy',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '\$4,850.20',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '+15% hoy',
                                style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              // Mini Chart placeholder
                              SizedBox(
                                height: 30,
                                width: double.infinity,
                                child: CustomPaint(
                                  painter: MiniChartPainter(),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Tarjeta Objetivo (Blanco)
                      Expanded(
                        child: Container(
                          height: 140,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Objetivo Mensual',
                                style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              // Circular Progress
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 55,
                                    height: 55,
                                    child: CircularProgressIndicator(
                                      value: 0.78,
                                      strokeWidth: 6,
                                      backgroundColor: Colors.grey.shade200,
                                      color: Colors.blue.shade400,
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '78%',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        'COMPLETADO',
                                        style: TextStyle(fontSize: 5, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              const Spacer(),
                              Text(
                                '\$19,500 / \$25,000',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 60),

            // Acciones Rápidas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Acciones Rápidas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton(Icons.add_shopping_cart, 'Nuevo\nPedido', true),
                      _buildActionButton(Icons.folder_outlined, 'Catálogo', false),
                      _buildActionButton(Icons.people_outline, 'Clientes', false, showBadge: true),
                      _buildActionButton(Icons.bar_chart_outlined, 'Reportes', false),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Pedidos Recientes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pedidos Recientes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildOrderRow(
                          id: '#VF-1092',
                          name: 'Juan Pérez',
                          time: 'Hoy 14:15',
                          amount: '\$650.00',
                          status: 'Completado',
                          statusColor: accentGreen,
                          icon: Icons.check_circle,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildOrderRow(
                          id: '#VF-1091',
                          name: 'Ana Gómez',
                          time: 'Hoy 11:30',
                          amount: '\$1,280.00',
                          status: 'En Proceso',
                          statusColor: accentYellow,
                          icon: Icons.sync,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildOrderRow(
                          id: '#VF-1090',
                          name: 'Carlos Ruiz',
                          time: 'Ayer',
                          amount: '\$940.00',
                          status: 'Completado',
                          statusColor: accentGreen,
                          icon: Icons.check_circle,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, bool isPrimary, {bool showBadge = false}) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: isPrimary ? Colors.blue.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Icon(
                icon,
                color: isPrimary ? Colors.blue.shade700 : const Color(0xFF1E2F4C),
                size: 28,
              ),
            ),
            if (showBadge)
              Positioned(
                bottom: 8,
                right: 28,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              )
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
              )
            ],
          ),
          // Right side
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(icon, color: statusColor, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    status,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}


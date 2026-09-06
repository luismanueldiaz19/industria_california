import 'package:flutter/material.dart';
import 'vendedor_dashboard_screen.dart';
import 'vendedor_perfil_screen.dart';
import 'vendedor_cxc_screen.dart';

class VendedorMainLayout extends StatefulWidget {
  const VendedorMainLayout({super.key});

  @override
  State<VendedorMainLayout> createState() => _VendedorMainLayoutState();
}

class _VendedorMainLayoutState extends State<VendedorMainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const VendedorDashboardScreen(),
    const VendedorCxcScreen(),
    const Center(child: Text('Clientes')),
    const Center(child: Text('Actividad')),
    const VendedorPerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Estructura que centra y limita el ancho para que parezca una app móvil si se abre en pantallas grandes
    return Container(
      color: const Color(0xFF121212), // Fondo oscuro fuera del área móvil
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ClipRRect(
            // Redondeamos los bordes para dar apariencia de dispositivo móvil si está en escritorio
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width > 500 ? 20 : 0),
            child: Scaffold(
              backgroundColor: const Color(0xFFF5F7FA), // Gris claro de fondo
              body: SafeArea(child: _screens[_currentIndex]),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                selectedItemColor: const Color(0xFF1976D2), // Azul estilo VentaFlow
                unselectedItemColor: Colors.grey.shade500,
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                ),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Inicio',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long_outlined),
                    activeIcon: Icon(Icons.receipt_long),
                    label: 'Pedidos',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people_outline),
                    activeIcon: Icon(Icons.people),
                    label: 'Clientes',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart_outlined),
                    activeIcon: Icon(Icons.bar_chart),
                    label: 'Actividad',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Perfil',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../widgets/vendedor_mobile_wrapper.dart';
import 'vendedor_dashboard_screen.dart';
import 'vendedor_cxc_screen.dart';
import 'vendedor_actividad_screen.dart';
import 'vendedor_inventario_screen.dart';
import '../../camion_victual/screens/vendedor_camiones_screen.dart';

class VendedorMainLayout extends StatefulWidget {
  const VendedorMainLayout({super.key});

  @override
  State<VendedorMainLayout> createState() => _VendedorMainLayoutState();
}

class _VendedorMainLayoutState extends State<VendedorMainLayout> {
  int _currentIndex = 0;

  List<Widget> _getScreens() {
    return [
      const VendedorDashboardScreen(), // index 0
      const VendedorCxcScreen(), // index 1
      const VendedorInventarioScreen(), // index 2
      const VendedorCamionesScreen(), // index 3
      const VendedorActividadScreen(), // index 4
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MobileWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA), // Gris claro de fondo
        body: SafeArea(child: _getScreens()[_currentIndex]),
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
              label: 'CXC',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Inventario',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping),
              label: 'Camiones',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined),
              activeIcon: Icon(Icons.campaign),
              label: 'Alertas',
            ),
          ],
        ),
      ),
    );
  }
}

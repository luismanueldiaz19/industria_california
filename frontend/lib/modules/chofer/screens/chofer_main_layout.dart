import 'package:flutter/material.dart';
import '../widgets/chofer_mobile_wrapper.dart';
import 'chofer_ruta_screen.dart';
import 'chofer_liquidacion_screen.dart';
import 'chofer_historial_screen.dart';
import 'chofer_perfil_screen.dart';

class ChoferMainLayout extends StatefulWidget {
  const ChoferMainLayout({super.key});

  @override
  State<ChoferMainLayout> createState() => _ChoferMainLayoutState();
}

class _ChoferMainLayoutState extends State<ChoferMainLayout> {
  int _currentIndex = 0;

  void _irALiquidar() {
    setState(() {
      _currentIndex = 1;
    });
  }

  void _volverARuta() {
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ChoferRutaScreen(onIrALiquidar: _irALiquidar),
      ChoferLiquidacionScreen(onLiquidadoExitoso: _volverARuta),
      const ChoferHistorialScreen(),
      const ChoferPerfilScreen(),
    ];

    return ChoferMobileWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 8,
            selectedItemColor: const Color(0xFF1976D2),
            unselectedItemColor: Colors.grey.shade500,
            selectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 10,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.route_outlined, size: 20),
                activeIcon: Icon(Icons.route, size: 22),
                label: 'Mi Ruta',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payments_outlined, size: 20),
                activeIcon: Icon(Icons.payments, size: 22),
                label: 'Liquidar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined, size: 20),
                activeIcon: Icon(Icons.history, size: 22),
                label: 'Historial',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline, size: 20),
                activeIcon: Icon(Icons.person, size: 22),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

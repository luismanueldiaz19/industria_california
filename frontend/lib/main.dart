import 'dart:ui';
import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'core/auth_provider.dart';
import 'models/company.dart';
import 'modules/auth/splash_screen.dart';
import 'modules/led_house/providers/ledhouse_cliente_provider.dart';
import 'modules/led_house/screens/ledhouse_detalles_screen.dart';

import 'package:provider/provider.dart';
import 'modules/dashboard/dashboard_provider.dart';
import 'modules/users/providers/users_provider.dart';
import 'modules/users/users_screen.dart';
import 'modules/users/roles_screen.dart';

import 'widgets/custom_sidebar.dart';
import 'modules/led_house/providers/ledhouse_provider.dart';
import 'modules/led_house/cxc/screens/cxc_screen.dart';
import 'modules/led_house/cxp/screens/cxp_screen.dart';
import 'modules/led_house/cxc/providers/cxc_provider.dart';
import 'modules/led_house/cxp/providers/cxp_provider.dart';
import 'modules/led_house/cxc/services/cxc_service.dart';
import 'modules/led_house/cxp/services/cxp_service.dart';
import 'modules/led_house/providers/cuenta_catalogo_provider.dart';
import 'modules/led_house/screens/cuenta_catalogo_screen.dart';
import 'modules/led_house/screens/clientes/ledhouse_clientes_screen.dart';
import 'modules/led_house/screens/ledhouse_alertas_screen.dart';
import 'modules/led_house/providers/ledhouse_proveedor_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
// Módulo Inventario
import 'modules/inventario/providers/inventario_categoria_provider.dart';
import 'modules/inventario/providers/inventario_producto_provider.dart';
import 'modules/inventario/providers/inventario_movimiento_provider.dart';
import 'modules/inventario/screens/inventario_productos_screen.dart';
import 'modules/inventario/screens/inventario_movimientos_screen.dart';
// Módulo Logística
import 'modules/logistica/providers/ruta_provider.dart';
import 'modules/logistica/providers/pedido_provider.dart';
import 'modules/logistica/screens/pedidos_screen.dart';
import 'modules/logistica/screens/rutas_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => LedhouseProvider()),
        ChangeNotifierProvider(create: (_) => CxcProvider(CxcService())),
        ChangeNotifierProvider(create: (_) => CxpProvider(CxpService())),
        ChangeNotifierProvider(create: (_) => CuentaCatalogoProvider()),
        ChangeNotifierProvider(create: (_) => LedhouseClienteProvider()),
        ChangeNotifierProvider(create: (_) => LedhouseProveedorProvider()),
        // Módulo Inventario
        ChangeNotifierProvider(create: (_) => InventarioCategoriaProvider()),
        ChangeNotifierProvider(create: (_) => InventarioProductoProvider()),
        ChangeNotifierProvider(create: (_) => InventarioMovimientoProvider()),
        // Módulo Logística
        ChangeNotifierProvider(create: (_) => RutaProvider()),
        ChangeNotifierProvider(create: (_) => PedidoProvider()),
      ],
      child: const ConstruccionERP(),
    ),
  );
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class ConstruccionERP extends StatelessWidget {
  const ConstruccionERP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Company.current.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scrollBehavior: AppScrollBehavior(),
      home: const SplashScreen(),
    );
  }
}

class EmptyScreen extends StatelessWidget {
  final String title;
  const EmptyScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '$title\n(En desarrollo)',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const LedhouseDetallesScreen(), //0
    const CxcScreen(), // 1
    const CxpScreen(), // 2
    const CuentaCatalogoScreen(), // 3
    const LedhouseClientesScreen(), // 4
    const LedhouseAlertasScreen(), // 5 — Alertas de Vendedores
    // Configuración (6-7)
    const RolesScreen(), // 6
    const UsersScreen(), // 7
    // Módulo Inventario (8-9)
    const InventarioProductosScreen(), // 8
    const InventarioMovimientosScreen(), // 9
    // Módulo Logística y Pedidos (10-11)
    const PedidosScreen(), // 10
    const RutasScreen(), // 11
  ];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width <= 850;

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              backgroundColor: const Color(0xFF1A1C1E),
              elevation: 0,
              title: Row(
                children: [
                  Image.asset(
                    Company.current.logo,
                    height: 30,
                    color: Colors.white,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.construction,
                      color: Color(0xFFE31E24),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Company.current.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      drawer: isMobile
          ? Drawer(
              width: 260,
              child: CustomSidebar(
                extended: true,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                  Navigator.of(context).pop(); // Cierra el Drawer
                },
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            CustomSidebar(
              extended: true,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                color: Colors.white.withValues(alpha: 0.7),
                child: _screens[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

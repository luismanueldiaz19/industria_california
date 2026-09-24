import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/themes/app_theme.dart';
import 'modules/auth/providers/auth_provider.dart';
import 'modules/produccion/providers/produccion_agrupada_provider.dart';
import 'modules/produccion/screens/produccion_agrupada_screen.dart';
import 'models/company.dart';
import 'modules/auth/screens/splash_screen.dart';
import 'modules/led_house/providers/ledhouse_cliente_provider.dart';
import 'modules/led_house/screens/ledhouse_detalles_screen.dart';
import 'modules/dashboard/dashboard_provider.dart';
import 'modules/users/providers/users_provider.dart';
import 'modules/users/users_screen.dart';
import 'modules/users/roles_screen.dart';

import 'core/widgets/custom_sidebar.dart';
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
import 'modules/producto/providers/categoria_provider.dart';
import 'modules/producto/providers/producto_provider.dart';
import 'modules/producto/screens/productos_screen.dart';
import 'modules/producto/screens/categorias_screen.dart';

// Módulo Flota y Despacho
import 'modules/flota/screens/choferes_screen.dart';
import 'modules/flota/screens/vehiculos_screen.dart';
import 'modules/flota/screens/despachos_screen.dart';
import 'modules/flota/screens/mantenimientos_screen.dart';
import 'modules/flota/screens/gastos_vehiculos_screen.dart';
import 'modules/flota/screens/camiones_victuales_admin_screen.dart';
import 'modules/flota/providers/chofer_provider.dart';
import 'modules/flota/providers/vehiculo_provider.dart';
import 'modules/flota/providers/despacho_provider.dart';
import 'modules/flota/providers/mantenimiento_provider.dart';
import 'modules/flota/providers/gasto_vehiculo_provider.dart';
// Módulo Logística
import 'modules/ruta/providers/ruta_provider.dart';
import 'modules/pedido/providers/pedido_provider.dart';
import 'modules/pedido/screens/pedidos_screen.dart';
import 'modules/ruta/screens/rutas_screen.dart';
import 'modules/produccion/screens/admin_ordenes_produccion_screen.dart';
import 'modules/pedido/screens/reporte_vendedores_screen.dart';
import 'modules/pedido/providers/reporte_vendedores_provider.dart';

import 'modules/produccion/providers/orden_produccion_provider.dart';
// Módulo Camiones Victuales
import 'modules/camion_victual/providers/camion_victual_provider.dart';

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
        ChangeNotifierProvider(create: (_) => CategoriaProvider()),
        ChangeNotifierProvider(create: (_) => ProductoProvider()),
        // Módulo Logística
        ChangeNotifierProvider(create: (_) => RutaProvider()),
        ChangeNotifierProvider(create: (_) => PedidoProvider()),
        ChangeNotifierProvider(create: (_) => OrdenProduccionProvider()),
        ChangeNotifierProvider(create: (_) => ProduccionAgrupadaProvider()),
        ChangeNotifierProvider(create: (_) => ReporteVendedoresProvider()),
        // Módulo Flota y Despacho
        ChangeNotifierProvider(create: (_) => ChoferProvider()),
        ChangeNotifierProvider(create: (_) => VehiculoProvider()),
        ChangeNotifierProvider(create: (_) => DespachoProvider()),
        ChangeNotifierProvider(create: (_) => MantenimientoProvider()),
        ChangeNotifierProvider(create: (_) => GastoVehiculoProvider()),
        // Módulo Camiones Victuales
        ChangeNotifierProvider(create: (_) => CamionVictualProvider()),
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
    // Módulo Inventario (8)
    const ProductosScreen(), // 8
    const CategoriasScreen(), // 9
    // Módulo Logística y Pedidos (10-13)
    const PedidosScreen(), // 10
    const RutasScreen(), // 11
    const AdminOrdenesProduccionScreen(), // 12
    const ReporteVendedoresScreen(), // 13
    // Módulo Flota y Despacho (14-18)
    const ChoferesScreen(), // 14
    const VehiculosScreen(), // 15
    const DespachosScreen(), // 16
    const MantenimientosScreen(), // 17
    const GastosVehiculosScreen(), // 18
    // Módulo Producción Agrupada (19-22)
    const ProduccionAgrupadaScreen(tipo: TipoAgrupacion.producto), // 19
    const ProduccionAgrupadaScreen(tipo: TipoAgrupacion.pedido), // 20
    const ProduccionAgrupadaScreen(tipo: TipoAgrupacion.cliente), // 21
    const ProduccionAgrupadaScreen(tipo: TipoAgrupacion.fecha), // 22
    const CamionesVictualesAdminScreen(), // 23
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

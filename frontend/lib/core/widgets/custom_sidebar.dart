import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../modules/auth/providers/auth_provider.dart';
import '../utils/constants.dart';
import '../../modules/auth/screens/login_screen.dart';

class CustomSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final bool extended;

  const CustomSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.extended = true,
  });

  @override
  State<CustomSidebar> createState() => _CustomSidebarState();
}

class _CustomSidebarState extends State<CustomSidebar> {
  String? _expandedSection;

  @override
  void initState() {
    super.initState();
    _updateExpandedSection();
  }

  @override
  void didUpdateWidget(CustomSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _updateExpandedSection();
    }
  }

  void _updateExpandedSection() {
    // Guardamos el índice en una variable local para que el código sea más limpio
    final int index = widget.selectedIndex;

    if (index >= 0 && index <= 5) {
      _expandedSection = '1. GESTIÓN COBROS Y PAGOS';
    } else if (index == 6 || index == 7) {
      _expandedSection = '2. CONFIGURACIÓN';
    } else if (index == 8 || index == 9) {
      _expandedSection = '3. PRODUCTOS Y CATEGORÍAS';
    } else if (index == 10 || index == 11 || index == 13) {
      _expandedSection = '4. LOGÍSTICA Y PEDIDOS';
    } else if (index == 12 || (index >= 20 && index <= 23)) {
      // 12: Pendientes, 20-23: Por Producto, Por Pedido, Por Cliente, Por Fecha
      _expandedSection = '5. PRODUCCIÓN';
    } else if (index == 15 || index == 17 || index == 24) {
      // 15: Vehículos, 17: Mantenimientos, 24: Camiones Victuales
      _expandedSection = '6. VEHÍCULOS';
    } else if (index == 14 || index == 16) {
      // 14: Choferes, 16: Despachos
      _expandedSection = '7. CHOFERES Y DESPACHOS';
    } else if (index == 18 || index == 19) {
      // 18: Gastos y Combustible, 19: Estadísticas
      _expandedSection = '8. GASTOS Y COMBUSTIBLE';
    }
    // if (widget.selectedIndex >= 38 && widget.selectedIndex <= 42) {
    //   _expandedSection = '9. CONFIGURACIÓN';
    // } else if (widget.selectedIndex >= 43 && widget.selectedIndex <= 46) {
    //   _expandedSection = '10. REPORTES Y AUDITORÍA';
    // } else if (widget.selectedIndex >= 48 && widget.selectedIndex <= 52) {
    //   _expandedSection = '11.';
    // } else if (widget.selectedIndex == 8 || widget.selectedIndex == 9) {
    //   _expandedSection = '3. PRODUCTOS Y CATEGORÍAS';
    // } else if (widget.selectedIndex == 10 ||
    //     widget.selectedIndex == 11 ||
    //     widget.selectedIndex == 13) {
    //   _expandedSection = '4. LOGÍSTICA Y PEDIDOS';
    // } else if (widget.selectedIndex == 12 ||
    //     (widget.selectedIndex >= 19 && widget.selectedIndex <= 22)) {
    //   _expandedSection = '5. PRODUCCIÓN';
    // } else if (widget.selectedIndex == 15 ||
    //     widget.selectedIndex == 17 ||
    //     widget.selectedIndex == 23) {
    //   _expandedSection = '6. VEHÍCULOS';
    // } else if (widget.selectedIndex == 14 || widget.selectedIndex == 16) {
    //   _expandedSection = '7. CHOFERES Y DESPACHOS';
    // } else if (widget.selectedIndex == 18) {
    //   _expandedSection = '8. GASTOS Y COMBUSTIBLE';
    // }
  }

  void _handleExpansion(String section, bool expanded) {
    setState(() {
      if (expanded) {
        _expandedSection = section;
      } else if (_expandedSection == section) {
        _expandedSection = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1A1C1E); // Dark Grey
    final accentColor = const Color(0xFFE31E24); // Red
    final secondaryColor = const Color(0xFF2C2F33); // Lighter Grey

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: widget.extended ? 280 : 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryColor, secondaryColor],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children:
            [
              _buildHeader(accentColor),
              const Divider(color: Colors.white10, height: 1),
              Expanded(
                child:
                    ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      children:
                          [
                            _buildExpansionSection(
                              '1. GESTIÓN COBROS Y PAGOS',
                              Icons.lightbulb_outline,
                              [
                                _buildMenuItem(
                                  0,
                                  Icons.bar_chart_outlined,
                                  Icons.bar_chart,
                                  'Estado de Resultado',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  1,
                                  Icons.account_balance_wallet_outlined,
                                  Icons.account_balance_wallet,
                                  'Cuentas por Cobrar',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  2,
                                  Icons.money_off_outlined,
                                  Icons.money_off,
                                  'Cuentas por Pagar',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  3,
                                  Icons.list_alt_outlined,
                                  Icons.list_alt,
                                  'Catálogo de Cuentas',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  4,
                                  Icons.people_outline,
                                  Icons.people,
                                  'Clientes',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  5,
                                  Icons.notifications_none_rounded,
                                  Icons.notifications_active_rounded,
                                  'Alertas Vendedores',
                                  accentColor,
                                ),
                              ],
                            ),

                            _buildExpansionSection(
                              '2. CONFIGURACIÓN',
                              Icons.settings_outlined,
                              [
                                _buildMenuItem(
                                  6,
                                  Icons.admin_panel_settings_outlined,
                                  Icons.admin_panel_settings,
                                  'Roles y permisos',
                                  accentColor,
                                ),

                                _buildMenuItem(
                                  7,
                                  Icons.manage_accounts_outlined,
                                  Icons.manage_accounts,
                                  'Usuarios',
                                  accentColor,
                                ),
                              ],
                            ),

                            _buildExpansionSection(
                              '3. PRODUCTOS Y CATEGORÍAS',
                              Icons.inventory_2_outlined,
                              [
                                _buildMenuItem(
                                  8,
                                  Icons.grid_view_outlined,
                                  Icons.grid_view_rounded,
                                  'Productos',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  9,
                                  Icons.category_outlined,
                                  Icons.category_rounded,
                                  'Categorías',
                                  accentColor,
                                ),
                              ],
                            ),

                            _buildExpansionSection(
                              '4. LOGÍSTICA Y PEDIDOS',
                              Icons.local_shipping_outlined,
                              [
                                _buildMenuItem(
                                  10,
                                  Icons.shopping_cart_outlined,
                                  Icons.shopping_cart_rounded,
                                  'Pedidos',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  13,
                                  Icons.bar_chart_outlined,
                                  Icons.bar_chart_rounded,
                                  'Análisis de Ventas',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  11,
                                  Icons.map_outlined,
                                  Icons.map_rounded,
                                  'Rutas',
                                  accentColor,
                                ),
                              ],
                            ),

                            _buildExpansionSection(
                              '5. PRODUCCIÓN',
                              Icons.precision_manufacturing_outlined,
                              [
                                _buildMenuItem(
                                  12,
                                  Icons.pending_actions_outlined,
                                  Icons.pending_actions_rounded,
                                  'Pendientes (Órdenes)',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  20,
                                  Icons.inventory_2_outlined,
                                  Icons.inventory_2_rounded,
                                  'Por Producto',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  21,
                                  Icons.receipt_long_outlined,
                                  Icons.receipt_long_rounded,
                                  'Por Pedido',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  22,
                                  Icons.group_outlined,
                                  Icons.group_rounded,
                                  'Por Cliente',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  23,
                                  Icons.calendar_month_outlined,
                                  Icons.calendar_month_rounded,
                                  'Por Fecha Entrega',
                                  accentColor,
                                ),
                              ],
                            ),

                            _buildExpansionSection(
                              '6. VEHÍCULOS',
                              Icons.directions_car_outlined,
                              [
                                _buildMenuItem(
                                  15,
                                  Icons.directions_car_outlined,
                                  Icons.directions_car_rounded,
                                  'Vehículos',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  24,
                                  Icons.local_shipping_outlined,
                                  Icons.local_shipping_rounded,
                                  'Camiones Victuales',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  17,
                                  Icons.build_outlined,
                                  Icons.build_rounded,
                                  'Mantenimientos',
                                  accentColor,
                                ),
                              ],
                            ),

                            _buildExpansionSection(
                              '7. CHOFERES Y DESPACHOS',
                              Icons.badge_outlined,
                              [
                                _buildMenuItem(
                                  14,
                                  Icons.badge_outlined,
                                  Icons.badge_rounded,
                                  'Choferes',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  16,
                                  Icons.route_outlined,
                                  Icons.route_rounded,
                                  'Despachos',
                                  accentColor,
                                ),
                              ],
                            ),

                            _buildExpansionSection(
                              '8. GASTOS Y COMBUSTIBLE',
                              Icons.receipt_long_outlined,
                              [
                                _buildMenuItem(
                                  18,
                                  Icons.receipt_long_outlined,
                                  Icons.receipt_long_rounded,
                                  'Gastos y Combustible',
                                  accentColor,
                                ),
                                _buildMenuItem(
                                  19,
                                  Icons.bar_chart_outlined,
                                  Icons.bar_chart_rounded,
                                  'Estadísticas',
                                  accentColor,
                                ),
                              ],
                            ),
                          ],
                    ),
              ),
              const Divider(color: Colors.white10, height: 1),
              _buildLogoutButton(accentColor),
            ],
      ),
    );
  }

  Widget _buildExpansionSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    final bool isExpanded = _expandedSection == title;

    if (!widget.extended) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Icon(icon, color: Colors.white24, size: 20),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        hoverColor: Colors.white.withValues(alpha: 0.05),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            color: isExpanded
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.transparent,
            child: ExpansionTile(
              key: Key('${title}_$isExpanded'),
              initiallyExpanded: isExpanded,
              onExpansionChanged: (expanded) =>
                  _handleExpansion(title, expanded),
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: Icon(
                icon,
                color: isExpanded
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4),
                size: 20,
              ),
              title: Text(
                title,
                style: TextStyle(
                  color: isExpanded
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              trailing: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.white24,
                size: 18,
              ),
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(left: 16, bottom: 8),
                  padding: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: const Color(0xFFE31E24).withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accentColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: widget.extended ? 120 : 80,
      padding: EdgeInsets.symmetric(vertical: widget.extended ? 12 : 10),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: Image.asset(
              logoPath,
              key: ValueKey(widget.extended),
              color: Colors.white,
              height: widget.extended ? 65 : 40,
              fit: BoxFit.contain,
            ),
          ),
          if (widget.extended && isDemoMode) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                border: Border.all(color: Colors.amber.shade400, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'VERSIÓN DEMO',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
    Color accentColor,
  ) {
    final isSelected = widget.selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () => widget.onDestinationSelected(index),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected
                    ? accentColor
                    : Colors.white.withValues(alpha: 0.6),
                size: 20,
              ),
              if (widget.extended) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 14,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF2C2F33),
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  '¿Está seguro de que desea salir del sistema?',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                    ),
                    child: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: widget.extended
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_outlined,
                color: Colors.white70,
                size: 20,
              ),
              if (widget.extended) ...[
                const SizedBox(width: 12),
                const Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

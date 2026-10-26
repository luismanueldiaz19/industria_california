import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../core/services/http_service.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/general_header.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla para consultar los productos facturados pendientes de entrega agrupados por vendedor.
/// - Modo Light limpio y amigable.
/// - Resumen de KPIs de unidades y montos pendientes.
/// - Filtro por Vendedor y búsqueda rápida.
/// - Vistas alternables: Agrupado por Vendedor o Agrupado por Producto.
/// - Tour guiado interactivo con [showcaseview] (v5.1+) para usuarios que ingresan por primera vez.
class ProductosPendientesEntregaScreen extends StatefulWidget {
  const ProductosPendientesEntregaScreen({super.key});

  @override
  State<ProductosPendientesEntregaScreen> createState() =>
      _ProductosPendientesEntregaScreenState();
}

class _ProductosPendientesEntregaScreenState
    extends State<ProductosPendientesEntregaScreen> {
  final HttpService _http = HttpService();
  final NumberFormat _currencyFmt = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  final NumberFormat _qtyFmt = NumberFormat('#,##0.##', 'en_US');

  // Showcase Keys para el tour guiado
  final GlobalKey _keyTourKpis = GlobalKey();
  final GlobalKey _keyTourFiltros = GlobalKey();
  final GlobalKey _keyTourVistas = GlobalKey();
  final GlobalKey _keyTourLista = GlobalKey();

  // Estados de datos
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _resumen;
  List<dynamic> _porVendedor = [];
  List<dynamic> _porProducto = [];

  // Filtros
  int? _vendedorSeleccionadoId; // null = Todos
  String _filtroBusqueda = '';
  final TextEditingController _searchCtrl = TextEditingController();
  int _vistaIndex = 0; // 0 = Por Vendedor, 1 = Por Producto
  bool _isExportingPdf = false;

  @override
  void initState() {
    super.initState();

    // 1. Configurar ShowcaseView con Omitir y soporte de auto-scroll
    ShowcaseView.register(
      enableAutoScroll: true,
      blurValue: 1.5,
      globalFloatingActionWidget: (showcaseContext) => FloatingActionWidget(
        top: 16,
        right: 16,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: TextButton.icon(
            onPressed: () => ShowcaseView.get().dismiss(),
            icon: const Icon(Icons.close, color: Colors.white, size: 14),
            label: const Text(
              'Omitir Tour',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      globalTooltipActionConfig: const TooltipActionConfig(
        position: TooltipActionPosition.outside,
        alignment: MainAxisAlignment.spaceBetween,
        gapBetweenContentAndAction: 10,
      ),
      globalTooltipActions: const [
        TooltipActionButton(
          type: TooltipDefaultActionType.previous,
          name: 'Anterior',
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.skip,
          name: 'Omitir',
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          name: 'Siguiente',
        ),
      ],
    );

    // Cargar datos (el tour se verificará automáticamente al terminar de cargar los widgets)
    _cargarDatos();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _verificarYEjecutarTour({bool forzar = false}) async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final bool yaVisto = prefs.getBool('tour_productos_pendientes_v2') ?? false;

    if ((!yaVisto || forzar) && mounted) {
      ShowcaseView.get().startShowCase([
        _keyTourKpis,
        _keyTourFiltros,
        _keyTourVistas,
        _keyTourLista,
      ]);
      await prefs.setBool('tour_productos_pendientes_v2', true);
    }
  }

  void _reiniciarTourManualmente() {
    _verificarYEjecutarTour(forzar: true);
  }

  Future<void> _exportarPdf() async {
    if (_isLoading) return;
    setState(() => _isExportingPdf = true);
    try {
      final Map<String, String> params = {
        'vista': _vistaIndex == 0 ? 'vendedor' : 'producto',
      };
      if (_vendedorSeleccionadoId != null) {
        params['vendedor_id'] = _vendedorSeleccionadoId.toString();
      }
      if (_filtroBusqueda.trim().isNotEmpty) {
        params['search'] = _filtroBusqueda.trim();
      }

      final res = await _http.getV2(
        'pedidos/productos-pendientes-entrega/pdf-url',
        params: params,
      );

      if (res is Map<String, dynamic> && res['url'] != null) {
        final urlStr = res['url'] as String;
        final uri = Uri.parse(urlStr);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          // Fallback en web si externalApplication no abre
          await launchUrl(uri);
        }
      } else {
        throw Exception('Respuesta inesperada al generar URL del PDF');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir PDF: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final Map<String, String> params = {};
      if (_vendedorSeleccionadoId != null) {
        params['vendedor_id'] = _vendedorSeleccionadoId.toString();
      }
      if (_filtroBusqueda.trim().isNotEmpty) {
        params['search'] = _filtroBusqueda.trim();
      }

      final res = await _http.getV2(
        'pedidos/productos-pendientes-entrega',
        params: params,
      );

      if (res is Map<String, dynamic>) {
        setState(() {
          _resumen = res['resumen'] as Map<String, dynamic>?;
          _porVendedor = res['por_vendedor'] as List<dynamic>? ?? [];
          _porProducto = res['por_producto'] as List<dynamic>? ?? [];
          _isLoading = false;
        });

        // Una vez que los datos cargaron y los widgets están montados en pantalla, se inicia el tour
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _verificarYEjecutarTour();
          }
        });
      } else {
        setState(() {
          _error = 'Respuesta inesperada del servidor.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al consultar productos pendientes: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Column(
        children: [
          // ── Header Institucional ──────────────────────────────────────
          GeneralHeader(
            title: 'Productos por Entregar',
            subtitle:
                'Consulta de productos facturados pendientes de despacho por vendedor',
            icon: Icons.pending_actions_rounded,
            iconColor: Colors.blue.shade700,
            gradientColors: const [
              AppTheme.primaryBlue,
              AppTheme.secondaryBlue,
            ],
            actions: [
              IconButton(
                icon: _isExportingPdf
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.white,
                      ),
                tooltip: 'Exportar PDF del filtro actual',
                onPressed: _isExportingPdf ? null : _exportarPdf,
              ),
              IconButton(
                icon: const Icon(Icons.auto_awesome, color: Color(0xFFFBBF24)),
                tooltip: 'Guía interactiva (Tour)',
                onPressed: _reiniciarTourManualmente,
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Actualizar datos',
                onPressed: _cargarDatos,
              ),
            ],
          ),

          // ── Contenido Principal ───────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildErrorView()
                : RefreshIndicator(
                    onRefresh: _cargarDatos,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. KPIs de Resumen
                          Showcase(
                            key: _keyTourKpis,
                            title: '1. Resumen General de Pendientes',
                            description:
                                'Visualiza rápidamente el total de unidades facturadas que aún están en almacén, el monto total en RD\$ y la cantidad de pedidos pendientes.',
                            targetPadding: const EdgeInsets.all(4),
                            targetShapeBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _buildKpisRow(),
                          ),
                          const SizedBox(height: 12),

                          // 2. Barra de Filtros y Búsqueda
                          Showcase(
                            key: _keyTourFiltros,
                            title: '2. Filtros y Búsqueda Rápida',
                            description:
                                'Puedes buscar por código o nombre del producto, o filtrar por un vendedor específico para ver solo sus entregas pendientes.',
                            targetPadding: const EdgeInsets.all(4),
                            targetShapeBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _buildFiltersBar(),
                          ),
                          const SizedBox(height: 12),

                          // 3. Selector de Vista (Por Vendedor / Por Producto)
                          Showcase(
                            key: _keyTourVistas,
                            title: '3. Modos de Visualización',
                            description:
                                'Alterna entre "Por Vendedor" (para logística y control de vendedores) o "Por Producto" (ideal para bodega y preparación de carga).',
                            targetPadding: const EdgeInsets.all(4),
                            targetShapeBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _buildViewToggle(),
                          ),
                          const SizedBox(height: 12),

                          // 4. Lista o Tablas de Contenido
                          Showcase(
                            key: _keyTourLista,
                            title: '4. Detalle y Agrupación',
                            description:
                                'Cada tarjeta muestra el desglose exacto de los productos, unidades pendientes y las facturas/clientes asignados.',
                            targetPadding: const EdgeInsets.all(4),
                            targetShapeBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _vistaIndex == 0
                                ? _buildListaPorVendedor()
                                : _buildListaPorProducto(),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Widgets de Construcción ───────────────────────────────────────────────

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarDatos,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpisRow() {
    final unidades =
        (_resumen?['total_unidades_pendientes'] as num?)?.toDouble() ?? 0.0;
    final monto =
        (_resumen?['total_monto_pendiente'] as num?)?.toDouble() ?? 0.0;
    final pedidos = (_resumen?['total_pedidos'] as num?)?.toInt() ?? 0;
    final vendedores = (_resumen?['total_vendedores'] as num?)?.toInt() ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;
        final cardWidth = isCompact
            ? (constraints.maxWidth - 8) / 2
            : (constraints.maxWidth - 24) / 4;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildKpiCard(
              title: 'Unidades Pendientes',
              value: _qtyFmt.format(unidades),
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFF2563EB),
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'Monto Facturado Pend.',
              value: _currencyFmt.format(monto),
              icon: Icons.attach_money_rounded,
              color: const Color(0xFF16A34A),
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'Facturas / Pedidos',
              value: '$pedidos pendientes',
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFFD97706),
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'Vendedores Activos',
              value: '$vendedores vendedores',
              icon: Icons.badge_outlined,
              color: const Color(0xFF7C3AED),
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar() {
    // Extraer lista única de vendedores para el selector
    final Map<int, String> vendedoresMap = {};
    for (final v in _porVendedor) {
      final id = v['vendedor_id'] as int?;
      final name = v['vendedor_nombre'] as String? ?? 'Sin Asignar';
      if (id != null) {
        vendedoresMap[id] = name;
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;

          if (isCompact) {
            return Column(
              children: [
                _buildSearchInput(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildVendedorDropdown(vendedoresMap)),
                    const SizedBox(width: 8),
                    _buildBotonPdf(),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: _buildSearchInput()),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _buildVendedorDropdown(vendedoresMap)),
              const SizedBox(width: 10),
              _buildBotonPdf(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBotonPdf() {
    return SizedBox(
      height: 38,
      child: ElevatedButton.icon(
        onPressed: _isExportingPdf ? null : _exportarPdf,
        icon: _isExportingPdf
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.picture_as_pdf_rounded, size: 16),
        label: Text(
          _isExportingPdf ? 'Generando...' : 'Exportar PDF',
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDC2626),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) {
          setState(() => _filtroBusqueda = val);
        },
        onSubmitted: (_) => _cargarDatos(),
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Buscar por producto, código, cliente o # factura...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11.5),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: Color(0xFF64748B),
          ),
          suffixIcon: _filtroBusqueda.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _filtroBusqueda = '');
                    _cargarDatos();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 0,
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF2563EB)),
          ),
        ),
      ),
    );
  }

  Widget _buildVendedorDropdown(Map<int, String> vendedoresMap) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _vendedorSeleccionadoId,
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: Color(0xFF64748B),
          ),
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12),
          hint: const Text(
            'Todos los vendedores',
            style: TextStyle(fontSize: 12),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text(
                'Todos los vendedores',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...vendedoresMap.entries.map((entry) {
              return DropdownMenuItem<int?>(
                value: entry.key,
                child: Text('Vend: ${entry.value}'),
              );
            }),
          ],
          onChanged: (val) {
            setState(() => _vendedorSeleccionadoId = val);
            _cargarDatos();
          },
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _vistaIndex == 0
              ? 'VISTA AGRUPADA POR VENDEDOR'
              : 'VISTA CONSOLIDADA POR PRODUCTO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
            letterSpacing: 0.3,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleButton('Por Vendedor', Icons.people_alt_outlined, 0),
              _buildToggleButton('Por Producto', Icons.inventory_2_outlined, 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, IconData icon, int index) {
    final bool isSelected = _vistaIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _vistaIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Vista 1: Por Vendedor ─────────────────────────────────────────────────

  Widget _buildListaPorVendedor() {
    if (_porVendedor.isEmpty) {
      return _buildEmptyState(
        'No hay productos pendientes de entrega para los filtros seleccionados.',
      );
    }

    return Column(
      children: _porVendedor.map((vendedor) {
        final vNombre = vendedor['vendedor_nombre'] as String? ?? 'Sin Asignar';
        final totalPedidos = vendedor['total_pedidos'] as int? ?? 0;
        final totalUnidades =
            (vendedor['total_unidades'] as num?)?.toDouble() ?? 0.0;
        final totalMonto = (vendedor['total_monto'] as num?)?.toDouble() ?? 0.0;
        final productos = vendedor['productos'] as List<dynamic>? ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              leading: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.person_pin_circle_outlined,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      vNombre.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      '$totalPedidos ${totalPedidos == 1 ? 'factura' : 'facturas'}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Text(
                      'Total: ${_qtyFmt.format(totalUnidades)} unids.',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                    const SizedBox(width: 8),
                    Text(
                      _currencyFmt.format(totalMonto),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
              children: [
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),
                // Lista de productos de este vendedor
                ...productos.map((prod) => _buildProductoItemVendedor(prod)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProductoItemVendedor(dynamic prod) {
    final codigo = prod['codigo'] as String? ?? 'N/A';
    final nombreCompleto =
        prod['nombre_completo'] as String? ??
        prod['descripcion'] as String? ??
        '';
    final unidad = prod['unidad'] as String? ?? 'UND';
    final cantidad = (prod['cantidad_pendiente'] as num?)?.toDouble() ?? 0.0;
    final monto = (prod['monto_pendiente'] as num?)?.toDouble() ?? 0.0;
    final pedidos = prod['pedidos'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  codigo,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nombreCompleto,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Cantidad destacada
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${_qtyFmt.format(cantidad)} $unidad',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _currencyFmt.format(monto),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          if (pedidos.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: pedidos.map((p) {
                final fact = p['num_factura'] as String? ?? 'S/F';
                final cli = p['cliente_nombre'] as String? ?? 'Cliente';
                final cantP = (p['cantidad'] as num?)?.toDouble() ?? 0.0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Text(
                    'Fac: $fact • $cli (${_qtyFmt.format(cantP)})',
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ── Vista 2: Consolidado Por Producto ────────────────────────────────────

  Widget _buildListaPorProducto() {
    if (_porProducto.isEmpty) {
      return _buildEmptyState(
        'No hay productos pendientes de entrega para los filtros seleccionados.',
      );
    }

    return Column(
      children: _porProducto.map((prod) {
        final codigo = prod['codigo'] as String? ?? 'N/A';
        final nombreCompleto =
            prod['nombre_completo'] as String? ??
            prod['descripcion'] as String? ??
            '';
        final unidad = prod['unidad'] as String? ?? 'UND';
        final totalCantidad =
            (prod['total_cantidad_pendiente'] as num?)?.toDouble() ?? 0.0;
        final totalMonto =
            (prod['total_monto_pendiente'] as num?)?.toDouble() ?? 0.0;
        final stock = (prod['stock_actual'] as num?)?.toDouble() ?? 0.0;
        final vendedores = prod['vendedores'] as List<dynamic>? ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Text(
                      codigo,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nombreCompleto,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Cantidad consolidada
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      '${_qtyFmt.format(totalCantidad)} $unidad',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currencyFmt.format(totalMonto),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Fila con Stock y Vendedores
              Row(
                children: [
                  Icon(
                    stock >= totalCantidad
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    size: 13,
                    color: stock >= totalCantidad
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Stock en almacén: ${_qtyFmt.format(stock)}',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: stock >= totalCantidad
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFD97706),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Desglose de Vendedores que lo tienen pedido
                  if (vendedores.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: vendedores.map((v) {
                        final vNom = v['vendedor_nombre'] as String? ?? 'Vend';
                        final vCant =
                            (v['cantidad'] as num?)?.toDouble() ?? 0.0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '$vNom: ${_qtyFmt.format(vCant)}',
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF475569),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            '¡Al día!',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:industria_california/core/widgets/compact_snack_bar.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/general_header.dart';
import '../../../core/widgets/compact_info_banner.dart';
import '../../../core/utils/formatters.dart';
import '../services/vendedor_cxc_service.dart';
import '../widgets/cxc_filter_bar.dart';
import '../widgets/vendedor_pago_agrupado_dialog.dart';
import 'vendedor_cxc_detalle_screen.dart';

class VendedorCxcScreen extends StatefulWidget {
  const VendedorCxcScreen({super.key});

  @override
  State<VendedorCxcScreen> createState() => _VendedorCxcScreenState();
}

class _VendedorCxcScreenState extends State<VendedorCxcScreen> {
  final _service = VendedorCxcService();
  List<dynamic> _cxcs = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalRecords = 0;

  double _totalFacturadoGlobal = 0.0;
  double _totalPendienteGlobal = 0.0;
  double _totalVencidoGlobal = 0.0;

  String _searchQuery = '';
  bool _soloVencidos = false;
  bool _conAlerta = false;
  String? _ordenMonto;

  // Selección múltiple para pago agrupado
  bool _modoSeleccion = false;
  final Set<int> _seleccionadosIds = {};
  int? _clienteSeleccionadoId;

  // Showcase keys para onboarding interactivo
  final GlobalKey _keyBotonSeleccion = GlobalKey();
  final GlobalKey _keyPrimerFactura = GlobalKey();
  bool _mostrarBannerTip = true;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Configuración moderna de ShowcaseView con botón de omitir y navegación
    ShowcaseView.register(
      enableAutoScroll: true,
      blurValue: 1.5,
      globalFloatingActionWidget: (showcaseContext) => FloatingActionWidget(
        top: 16,
        right: 16,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.90),
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
        position: TooltipActionPosition.inside,
        alignment: MainAxisAlignment.spaceBetween,
        gapBetweenContentAndAction: 14,
      ),
      globalTooltipActions: [
        TooltipActionButton(
          type: TooltipDefaultActionType.previous,
          name: 'Anterior',
          backgroundColor: AppTheme.secondaryBlue,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          leadIcon: const ActionButtonIcon(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              size: 11,
              color: Colors.white,
            ),
          ),
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.skip,
          name: 'Omitir',
          backgroundColor: const Color(0xFFF1F5F9),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          textStyle: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          name: 'Siguiente',
          backgroundColor: AppTheme.primaryBlue,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          tailIcon: const ActionButtonIcon(
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 11,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );

    _cargarPreferenciaBanner();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
        _load();
      });
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
      _cxcs.clear();
    });
    try {
      final data = await _service.getMisCxcPaginated(
        token: token,
        page: _currentPage,
        search: _searchQuery,
        vencidos: _soloVencidos,
        conAlerta: _conAlerta,
        ordenMonto: _ordenMonto,
      );
      final rawItems = data['data'] as List;
      final items = rawItems.where((c) => c['estado'] != 'pagado').toList();
      setState(() {
        _cxcs = items;
        _hasMore = data['current_page'] < data['last_page'];
        _totalRecords = data['total'] ?? 0;
        if (data['totales_globales'] != null) {
          _totalFacturadoGlobal =
              double.tryParse(
                data['totales_globales']['facturado'].toString(),
              ) ??
              0;
          _totalPendienteGlobal =
              double.tryParse(
                data['totales_globales']['pendiente'].toString(),
              ) ??
              0;
          _totalVencidoGlobal =
              double.tryParse(data['totales_globales']['vencido'].toString()) ??
              0;
        }
      });
      if (items.isNotEmpty) {
        _verificarYEjecutarTour();
      }
    } catch (e) {
      if (mounted) {
        CompactSnackBar.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarPreferenciaBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final bool dismissed =
        prefs.getBool('cxc_pago_agrupado_banner_dismissed_v1') ?? false;
    if (mounted && dismissed) {
      setState(() => _mostrarBannerTip = false);
    }
  }

  Future<void> _verificarYEjecutarTour({bool forzar = false}) async {
    if (!mounted || _cxcs.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final bool yaVisto = prefs.getBool('tour_pago_agrupado_cxc_v1') ?? false;

    if ((!yaVisto || forzar) && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _cxcs.isEmpty) return;
        ShowcaseView.get().startShowCase([
          _keyBotonSeleccion,
          _keyPrimerFactura,
        ]);
      });
      await prefs.setBool('tour_pago_agrupado_cxc_v1', true);
    }
  }

  void _iniciarTourManualmente() {
    if (_cxcs.isEmpty) {
      CompactSnackBar.showInfo(
        context,
        'No hay facturas cargadas en la lista para mostrar el tour interactivo.',
      );
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ShowcaseView.get().startShowCase([
        _keyBotonSeleccion,
        _keyPrimerFactura,
      ]);
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    try {
      final data = await _service.getMisCxcPaginated(
        token: token,
        page: _currentPage,
        search: _searchQuery,
        vencidos: _soloVencidos,
        conAlerta: _conAlerta,
        ordenMonto: _ordenMonto,
      );
      final rawItems = data['data'] as List;
      final items = rawItems.where((c) => c['estado'] != 'pagado').toList();
      setState(() {
        _cxcs.addAll(items);
        _hasMore = data['current_page'] < data['last_page'];
        _totalRecords = data['total'] ?? _totalRecords;
        if (data['totales_globales'] != null) {
          _totalFacturadoGlobal =
              double.tryParse(
                data['totales_globales']['facturado'].toString(),
              ) ??
              0;
          _totalPendienteGlobal =
              double.tryParse(
                data['totales_globales']['pendiente'].toString(),
              ) ??
              0;
          _totalVencidoGlobal =
              double.tryParse(data['totales_globales']['vencido'].toString()) ??
              0;
        }
      });
    } catch (e) {
      setState(() => _currentPage--);
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _openPdf() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    CompactSnackBar.showInfo(context, 'Abriendo PDF...');
    try {
      final urlStr = await _service.obtenerUrlPdfMisCxc(
        token: token,
        search: _searchQuery,
        vencidos: _soloVencidos,
        conAlerta: _conAlerta,
        ordenMonto: _ordenMonto,
      );
      final url = Uri.parse(urlStr);
      if (!await launchUrl(url)) {
        throw Exception('No se pudo abrir el enlace');
      }
    } catch (e) {
      if (mounted) {
        CompactSnackBar.showError(context, 'Error al abrir PDF: $e');
      }
    }
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'pagado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GeneralHeader(
            title: 'Cuentas por Cobrar',
            subtitle: '$_totalRecords facturas pendientes',
            icon: Icons.receipt_long_rounded,
            iconColor: Colors.greenAccent,
            gradientColors: const [AppTheme.primaryBlue, AppTheme.secondaryBlue],
            isCompact: true,
            actions: [
              if (_cxcs.isNotEmpty) ...[
                Showcase(
                  key: _keyBotonSeleccion,
                  title: '1. Selección Múltiple',
                  description:
                      'Toca este botón para activar la selección de facturas de un mismo cliente y crear un Pago Agrupado con una sola foto de comprobante.',
                  tooltipBackgroundColor: Colors.white,
                  textColor: const Color(0xFF1E293B),
                  titleTextStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                  descTextStyle: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF334155),
                    height: 1.35,
                  ),
                  tooltipBorderRadius: BorderRadius.circular(10),
                  tooltipPadding: const EdgeInsets.all(14),
                  targetPadding: const EdgeInsets.all(4),
                  targetShapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: HeaderButton(
                    icon: _modoSeleccion
                        ? Icons.close_rounded
                        : Icons.checklist_rounded,
                    tooltip: _modoSeleccion
                        ? 'Cancelar selección'
                        : 'Seleccionar para pago agrupado',
                    color: _modoSeleccion ? Colors.orangeAccent : Colors.white,
                    size: 34,
                    iconSize: 18,
                    onTap: () {
                      setState(() {
                        _modoSeleccion = !_modoSeleccion;
                        if (!_modoSeleccion) {
                          _seleccionadosIds.clear();
                          _clienteSeleccionadoId = null;
                        }
                      });
                    },
                  ),
                ),
                HeaderButton(
                  icon: Icons.picture_as_pdf_rounded,
                  tooltip: 'Generar PDF',
                  color: Colors.redAccent,
                  size: 34,
                  iconSize: 18,
                  onTap: _openPdf,
                ),
              ],
              HeaderButton(
                icon: Icons.help_outline_rounded,
                tooltip: 'Guía: ¿Cómo agrupar pagos?',
                color: Colors.amberAccent,
                size: 34,
                iconSize: 18,
                onTap: _iniciarTourManualmente,
              ),
              HeaderButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Actualizar',
                size: 34,
                iconSize: 18,
                onTap: _load,
              ),
            ],
          ),
          CxcFilterBar(
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            onClearSearch: () {
              _searchController.clear();
              _onSearchChanged('');
            },
            soloVencidos: _soloVencidos,
            onToggleVencidos: (val) {
              setState(() {
                _soloVencidos = val;
                _load();
              });
            },
            conAlerta: _conAlerta,
            onToggleConAlerta: (val) {
              setState(() {
                _conAlerta = val;
                _load();
              });
            },
            ordenMonto: _ordenMonto,
            onOrdenChanged: (val) {
              setState(() {
                _ordenMonto = val;
                _load();
              });
            },
            onResetFilters: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _soloVencidos = false;
                _conAlerta = false;
                _ordenMonto = null;
                _load();
              });
            },
          ),
          if (_mostrarBannerTip && !_modoSeleccion && _cxcs.isNotEmpty)
            CompactInfoBanner(
              icon: Icons.touch_app_outlined,
              iconColor: AppTheme.primaryBlue,
              backgroundColor: const Color(0xFFEFF6FF),
              borderColor: const Color(0xFFBFDBFE),
              textColor: const Color(0xFF1E3A8A),
              actionBackgroundColor: AppTheme.primaryBlue,
              actionTextColor: Colors.white,
              title: '💡 Tip Pago Agrupado:',
              message:
                  'Mantén presionada cualquier factura o usa el botón checklist en la cabecera para pagar varias facturas con una sola foto.',
              actionLabel: 'Ver Guía',
              onAction: _iniciarTourManualmente,
              onDismiss: () async {
                setState(() => _mostrarBannerTip = false);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('cxc_pago_agrupado_banner_dismissed_v1', true);
              },
            ),
          Expanded(
            child: _isLoading && _currentPage == 1
                ? const Center(child: CircularProgressIndicator())
                : _cxcs.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      itemCount: _cxcs.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _cxcs.length) {
                          return const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final card = _buildCxcCard(_cxcs[i]);
                        if (i == 0) {
                          return Showcase(
                            key: _keyPrimerFactura,
                            title: '2. Mantén Presionada la Factura',
                            description:
                                '¡Atajo rápido! Deja presionada (long-press) cualquier factura directamente para seleccionarla e iniciar un pago agrupado para este cliente.',
                            tooltipBackgroundColor: Colors.white,
                            textColor: const Color(0xFF1E293B),
                            titleTextStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                            descTextStyle: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF334155),
                              height: 1.35,
                            ),
                            tooltipBorderRadius: BorderRadius.circular(10),
                            tooltipPadding: const EdgeInsets.all(14),
                            targetPadding: const EdgeInsets.all(4),
                            targetShapeBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: card,
                          );
                        }
                        return card;
                      },
                    ),
                  ),
          ),
          if (_seleccionadosIds.isNotEmpty) _buildBarraPagoAgrupado(),
          if (_cxcs.isNotEmpty)
            _buildTotales(
              _totalFacturadoGlobal,
              _totalPendienteGlobal,
              _totalVencidoGlobal,
            ),
        ],
      ),
    );
  }

  Widget _buildBarraPagoAgrupado() {
    double totalSeleccionado = 0;
    final facturas = <Map<String, dynamic>>[];
    for (var c in _cxcs) {
      final id = int.tryParse(c['id']?.toString() ?? '0') ?? 0;
      if (_seleccionadosIds.contains(id)) {
        facturas.add(Map<String, dynamic>.from(c));
        totalSeleccionado +=
            double.tryParse(c['monto_pendiente']?.toString() ?? '0') ?? 0;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade800,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_seleccionadosIds.length} facturas seleccionadas',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Total pendiente: ${Formatters.formatCurrency(totalSeleccionado)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (facturas.length < 2) {
                  CompactSnackBar.showWarning(
                    context,
                    'Selecciona al menos 2 facturas para pago agrupado',
                  );
                  return;
                }
                VendedorPagoAgrupadoDialog.show(
                  context: context,
                  facturas: facturas,
                  onSuccess: () {
                    setState(() {
                      _modoSeleccion = false;
                      _seleccionadosIds.clear();
                      _clienteSeleccionadoId = null;
                    });
                    _load();
                  },
                );
              },
              icon: const Icon(Icons.send_rounded, size: 14),
              label: const Text(
                'Pago Agrupado',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange.shade900,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotales(double facturado, double pendiente, double vencido) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _buildMiniTotalCard(
                'FACTURADO',
                Formatters.formatCurrency(_totalFacturadoGlobal),
                AppTheme.primaryBlue,
                onTap: () {
                  if (_soloVencidos || _conAlerta) {
                    setState(() {
                      _soloVencidos = false;
                      _conAlerta = false;
                      _load();
                    });
                    CompactSnackBar.showInfo(
                      context,
                      'Mostrando todas las facturas',
                    );
                  }
                },
                isActive: false,
                tooltip: 'Total facturado en cartera',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniTotalCard(
                'PENDIENTE',
                Formatters.formatCurrency(_totalPendienteGlobal),
                const Color(0xFFFB8C00),
                onTap: () {
                  if (_soloVencidos) {
                    setState(() {
                      _soloVencidos = false;
                      _load();
                    });
                    CompactSnackBar.showInfo(
                      context,
                      'Mostrando facturas pendientes',
                    );
                  }
                },
                isActive: !_soloVencidos && !_conAlerta,
                tooltip: 'Toca para ver todas las pendientes',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniTotalCard(
                'VENCIDO',
                Formatters.formatCurrency(_totalVencidoGlobal),
                Colors.red.shade700,
                onTap: () {
                  setState(() {
                    _soloVencidos = !_soloVencidos;
                    _load();
                  });
                  CompactSnackBar.showInfo(
                    context,
                    _soloVencidos
                        ? 'Filtrando solo facturas vencidas'
                        : 'Filtro de vencidas desactivado',
                  );
                },
                isActive: _soloVencidos,
                tooltip: 'Toca para filtrar solo vencidas',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTotalCard(
    String title,
    String value,
    Color color, {
    VoidCallback? onTap,
    bool isActive = false,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.12)
                : color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? color : color.withValues(alpha: 0.2),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 3),
                    Icon(Icons.check_circle_rounded, size: 9, color: color),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: isActive ? color : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCxcCard(Map<String, dynamic> cxc) {
    final estado = cxc['estado'] ?? 'pendiente';
    final color = _estadoColor(estado);
    final alertasPendientes = cxc['alertas_pendientes'] ?? 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    bool isVencido = false;
    if (cxc['fecha_vencimiento'] != null) {
      try {
        final d = DateTime.parse(cxc['fecha_vencimiento']);
        final pend =
            double.tryParse(cxc['monto_pendiente']?.toString() ?? '0') ?? 0;
        if (d.isBefore(todayDate) && pend > 0 && estado != 'pagado') {
          isVencido = true;
        }
      } catch (_) {}
    }

    final int id = int.tryParse(cxc['id']?.toString() ?? '0') ?? 0;
    final bool isSelected = _seleccionadosIds.contains(id);
    final int clienteId =
        int.tryParse(cxc['cliente_id']?.toString() ?? '0') ?? 0;
    final bool isDifferentClient =
        _clienteSeleccionadoId != null &&
        _clienteSeleccionadoId != clienteId &&
        _seleccionadosIds.isNotEmpty;

    final bgColor = isSelected
        ? Colors.orange.shade50
        : isVencido
        ? Colors.red.shade50
        : Colors.white;

    final borderColor = isSelected
        ? Colors.orange.shade700
        : isDifferentClient && _modoSeleccion
        ? Colors.grey.shade300
        : Colors.transparent;

    void onCardTap() {
      if (_modoSeleccion) {
        if (isDifferentClient) {
          CompactSnackBar.showWarning(
            context,
            'Solo puedes agrupar facturas del mismo cliente',
          );
          return;
        }
        setState(() {
          if (isSelected) {
            _seleccionadosIds.remove(id);
            if (_seleccionadosIds.isEmpty) {
              _clienteSeleccionadoId = null;
            }
          } else {
            _clienteSeleccionadoId = clienteId;
            _seleccionadosIds.add(id);
          }
        });
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VendedorCxcDetalleScreen(cxcData: cxc),
          ),
        ).then((_) => _load());
      }
    }

    void onCardLongPress() {
      if (isDifferentClient && _modoSeleccion) {
        CompactSnackBar.showWarning(
          context,
          'Solo puedes agrupar facturas del mismo cliente',
        );
        return;
      }
      setState(() {
        _modoSeleccion = true;
        if (isSelected) {
          _seleccionadosIds.remove(id);
          if (_seleccionadosIds.isEmpty) {
            _clienteSeleccionadoId = null;
          }
        } else {
          _clienteSeleccionadoId = clienteId;
          _seleccionadosIds.add(id);
        }
      });
    }

    final String? fechaVenceRaw = cxc['fecha_vencimiento']?.toString();
    String venceBadgeText = '';
    Color venceBadgeColor = Colors.grey.shade600;
    Color venceBadgeBg = Colors.grey.shade100;

    if (fechaVenceRaw != null) {
      final parsed = DateTime.tryParse(fechaVenceRaw);
      if (parsed != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final due = DateTime(parsed.year, parsed.month, parsed.day);
        final diff = due.difference(today).inDays;
        if (diff < 0) {
          venceBadgeText = 'Venció hace ${-diff}d';
          venceBadgeColor = Colors.red.shade800;
          venceBadgeBg = const Color(0xFFFEE2E2);
        } else if (diff == 0) {
          venceBadgeText = '¡Vence Hoy!';
          venceBadgeColor = const Color(0xFFD97706);
          venceBadgeBg = const Color(0xFFFEF3C7);
        } else if (diff <= 5) {
          venceBadgeText = 'Vence en ${diff}d';
          venceBadgeColor = const Color(0xFFB45309);
          venceBadgeBg = const Color(0xFFFFFBEB);
        }
      }
    }

    return GestureDetector(
      onTap: onCardTap,
      onLongPress: onCardLongPress,
      child: Opacity(
        opacity: (isDifferentClient && _modoSeleccion) ? 0.45 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? Colors.orange.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Barra vertical de estado
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(
                  color: isSelected ? Colors.orange.shade700 : color,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_modoSeleccion)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 16,
                              color: isSelected
                                  ? Colors.orange.shade800
                                  : Colors.grey.shade400,
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.receipt_outlined,
                                size: 11,
                                color: Color(0xFF475569),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                cxc['documento'] ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  color: Color(0xFF0F172A),
                                  fontFamily: 'monospace',
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (alertasPendientes > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(
                                color: Colors.red.shade200,
                                width: 0.8,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.notifications_active,
                                  color: Colors.red,
                                  size: 10,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '$alertasPendientes',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (venceBadgeText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              color: venceBadgeBg,
                              border: Border.all(
                                color: venceBadgeColor.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              venceBadgeText,
                              style: TextStyle(
                                color: venceBadgeColor,
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            estado.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            cxc['cliente']?['nombre']?.toString().toUpperCase() ??
                                'SIN CLIENTE',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildMontoItem(
                          'Pendiente',
                          Formatters.formatCurrency(cxc['monto_pendiente']),
                          const Color(0xFFD97706),
                        ),
                        _buildMontoItem(
                          'Factura',
                          Formatters.formatCurrency(cxc['monto_factura']),
                          const Color(0xFF2563EB),
                        ),
                        _buildMontoItem(
                          'Vencimiento',
                          _formatDate(cxc['fecha_vencimiento']),
                          isVencido ? Colors.red.shade700 : const Color(0xFF475569),
                        ),
                        if (!_modoSeleccion)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 2),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMontoItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin resultados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black45,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontró ningún documento o cliente\nque coincida con tu búsqueda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin facturas aún',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sincroniza tu Excel para importar tus CXC',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '-';
    try {
      final parts = date.split('-');
      return '${parts[2]}/${parts[1]}/${parts[0].substring(2)}';
    } catch (_) {
      return date;
    }
  }
}

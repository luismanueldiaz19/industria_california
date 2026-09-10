import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/auth_provider.dart';
import '../../../core/app_theme.dart';
import '../../../../widgets/general_header.dart';
import '../services/vendedor_cxc_service.dart';
import 'package:intl/intl.dart';
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
  String _searchQuery = '';
  bool _soloVencidos = false;
  bool _conAlerta = false;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
      );
      final items = data['data'] as List;
      setState(() {
        _cxcs = items;
        _hasMore = data['current_page'] < data['last_page'];
        _totalRecords = data['total'] ?? 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      );
      final items = data['data'] as List;
      setState(() {
        _cxcs.addAll(items);
        _hasMore = data['current_page'] < data['last_page'];
        _totalRecords = data['total'] ?? _totalRecords;
      });
    } catch (e) {
      setState(() => _currentPage--);
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _openPdf() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Abriendo PDF...')));
    try {
      final urlStr = await _service.obtenerUrlPdfMisCxc(
        token: token,
        search: _searchQuery,
        vencidos: _soloVencidos,
        conAlerta: _conAlerta,
      );
      final url = Uri.parse(urlStr);
      if (!await launchUrl(url)) {
        throw Exception('No se pudo abrir el enlace');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al abrir PDF: $e')));
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
    final themeStyle = Theme.of(context).textTheme;

    double totalFacturado = 0;
    double totalPendiente = 0;
    double totalVencido = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var cxc in _cxcs) {
      final fac = double.tryParse(cxc['monto_factura']?.toString() ?? '0') ?? 0;
      final pend =
          double.tryParse(cxc['monto_pendiente']?.toString() ?? '0') ?? 0;
      totalFacturado += fac;
      totalPendiente += pend;

      final dateStr = cxc['fecha_vencimiento'];
      if (dateStr != null && pend > 0) {
        try {
          final date = DateTime.parse(dateStr);
          if (date.isBefore(today)) {
            totalVencido += pend;
          }
        } catch (_) {}
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.bgColor,

      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cuentas por Cobrar (CXC)',
              style: themeStyle.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (_totalRecords > 0)
              Text(
                '$_totalRecords registros',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          HeaderButton(
            icon: Icons.picture_as_pdf_rounded,
            tooltip: 'Generar PDF',
            color: Colors.redAccent,
            onTap: _openPdf,
          ),
          HeaderButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Actualizar',
            onTap: _load,
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Buscar por documento o cliente...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text(
                          'Solo Vencidos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        value: _soloVencidos,
                        onChanged: (val) {
                          setState(() {
                            _soloVencidos = val ?? false;
                            _load();
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        activeColor: Colors.red.shade700,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text(
                          'Con Alerta',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        value: _conAlerta,
                        onChanged: (val) {
                          setState(() {
                            _conAlerta = val ?? false;
                            _load();
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        activeColor: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: _cxcs.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _cxcs.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _buildCxcCard(_cxcs[i]);
                      },
                    ),
                  ),
          ),
          if (_cxcs.isNotEmpty)
            _buildTotales(totalFacturado, totalPendiente, totalVencido),
        ],
      ),
    );
  }

  Widget _buildTotales(double facturado, double pendiente, double vencido) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                currencyFormatter.format(facturado),
                AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniTotalCard(
                'PENDIENTE',
                currencyFormatter.format(pendiente),
                const Color(0xFFFB8C00),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniTotalCard(
                'VENCIDO',
                currencyFormatter.format(vencido),
                Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTotalCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
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

    final bgColor = isVencido ? Colors.red.shade50 : Colors.white;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VendedorCxcDetalleScreen(cxcData: cxc),
        ),
      ).then((_) => _load()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Barra vertical
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 5,
              child: Container(color: color),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          cxc['documento'] ?? '-',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.grey.shade800,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (alertasPendientes > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.notifications_active,
                                    color: Colors.red,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 4),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              estado.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          cxc['cliente']?['nombre']?.toString().toUpperCase() ??
                              'SIN CLIENTE',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMontoItem(
                        'Pendiente',
                        '\$${cxc['monto_pendiente'] ?? '0.00'}',
                        Colors.orange.shade700,
                      ),
                      _buildMontoItem(
                        'Factura',
                        '\$${cxc['monto_factura'] ?? '0.00'}',
                        Colors.blue.shade600,
                      ),
                      _buildMontoItem(
                        'Vence',
                        _formatDate(cxc['fecha_vencimiento']),
                        isVencido ? Colors.red.shade700 : Colors.grey.shade700,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
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

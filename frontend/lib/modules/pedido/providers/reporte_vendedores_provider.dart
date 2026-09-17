import 'package:flutter/foundation.dart';
import '../services/pedido_service.dart';

/// Modelo liviano para un vendedor en el reporte agrupado
class VendedorReporte {
  final int vendedorId;
  final String vendedorNombre;
  final int totalPedidos;
  final double totalMonto;
  final double totalFaltante;
  final double totalReal;
  final int borrador;
  final int enviado;
  final int facturado;
  final int cancelado;

  VendedorReporte({
    required this.vendedorId,
    required this.vendedorNombre,
    required this.totalPedidos,
    required this.totalMonto,
    required this.totalFaltante,
    required this.totalReal,
    required this.borrador,
    required this.enviado,
    required this.facturado,
    required this.cancelado,
  });

  factory VendedorReporte.fromJson(Map<String, dynamic> json) {
    return VendedorReporte(
      vendedorId: json['vendedor_id'] ?? 0,
      vendedorNombre: json['vendedor_nombre'] ?? '',
      totalPedidos: int.tryParse(json['total_pedidos']?.toString() ?? '0') ?? 0,
      totalMonto: _parseDouble(json['total_monto']),
      totalFaltante: _parseDouble(json['total_faltante']),
      totalReal: _parseDouble(json['total_real']),
      borrador: int.tryParse(json['borrador']?.toString() ?? '0') ?? 0,
      enviado: int.tryParse(json['enviado']?.toString() ?? '0') ?? 0,
      facturado: int.tryParse(json['facturado']?.toString() ?? '0') ?? 0,
      cancelado: int.tryParse(json['cancelado']?.toString() ?? '0') ?? 0,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Punto de dato para los gráficos de mes
class GraficoMesDato {
  final String mes; // 'YYYY-MM'
  final String mesLabel; // 'Ene 2026'
  final int totalPedidos;
  final double totalMonto;

  GraficoMesDato({
    required this.mes,
    required this.mesLabel,
    required this.totalPedidos,
    required this.totalMonto,
  });

  factory GraficoMesDato.fromJson(Map<String, dynamic> json) {
    return GraficoMesDato(
      mes: json['mes'] ?? '',
      mesLabel: json['mes_label'] ?? json['mes'] ?? '',
      totalPedidos: int.tryParse(json['total_pedidos']?.toString() ?? '0') ?? 0,
      totalMonto: VendedorReporte._parseDouble(json['total_monto']),
    );
  }
}

/// Punto de dato para el gráfico vendedor × mes
class GraficoVendedorMes {
  final String vendedorNombre;
  final String mes;
  final int totalPedidos;
  final double totalMonto;

  GraficoVendedorMes({
    required this.vendedorNombre,
    required this.mes,
    required this.totalPedidos,
    required this.totalMonto,
  });

  factory GraficoVendedorMes.fromJson(Map<String, dynamic> json) {
    return GraficoVendedorMes(
      vendedorNombre: json['vendedor_nombre'] ?? '',
      mes: json['mes'] ?? '',
      totalPedidos: int.tryParse(json['total_pedidos']?.toString() ?? '0') ?? 0,
      totalMonto: VendedorReporte._parseDouble(json['total_monto']),
    );
  }
}

class ReporteVendedoresProvider extends ChangeNotifier {
  final PedidoService _service = PedidoService();

  // ── Estado ──
  List<VendedorReporte> _vendedores = [];
  List<GraficoMesDato> _graficoMeses = [];
  List<GraficoVendedorMes> _graficoVendedoresMeses = [];

  bool _isLoading = false;
  String? _error;

  // ── Paginación ──
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  int _perPage = 10;

  // ── Resumen general ──
  int _totalPedidosGral = 0;
  double _totalMontoGral = 0;
  double _totalFaltanteGral = 0;
  double _totalRealGral = 0;
  int _totalVendedores = 0;

  // ── Filtros ──
  String? _startDate;
  String? _endDate;
  String? _search;

  // ── Getters ──
  List<VendedorReporte> get vendedores => _vendedores;
  List<GraficoMesDato> get graficoMeses => _graficoMeses;
  List<GraficoVendedorMes> get graficoVendedoresMeses =>
      _graficoVendedoresMeses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get total => _total;
  bool get hasMore => _currentPage < _lastPage;
  int get totalPedidosGral => _totalPedidosGral;
  double get totalMontoGral => _totalMontoGral;
  double get totalFaltanteGral => _totalFaltanteGral;
  double get totalRealGral => _totalRealGral;
  int get totalVendedores => _totalVendedores;
  String? get startDate => _startDate;
  String? get endDate => _endDate;
  String? get search => _search;

  /// Actualiza los filtros sin hacer fetch
  void setFiltros({String? startDate, String? endDate, String? search}) {
    _startDate = startDate;
    _endDate = endDate;
    // El búsqueda se guarda tal cual; backend aplica mb_strtolower()
    _search = (search != null && search.trim().isNotEmpty)
        ? search.trim()
        : null;
  }

  Future<void> fetchReporte({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getReporteVendedores(
        startDate: _startDate,
        endDate: _endDate,
        search: _search,
        page: page,
        perPage: _perPage,
      );

      // Vendedores paginados
      final paginado = result['vendedores'] as Map<String, dynamic>? ?? {};
      final dataList = paginado['data'] as List? ?? [];
      _vendedores = dataList.map((e) => VendedorReporte.fromJson(e)).toList();
      _currentPage = paginado['current_page'] ?? 1;
      _lastPage = paginado['last_page'] ?? 1;
      _total = paginado['total'] ?? 0;

      // Gráfico meses
      final gMeses = result['grafico_meses'] as List? ?? [];
      _graficoMeses = gMeses.map((e) => GraficoMesDato.fromJson(e)).toList();

      // Gráfico vendedores × mes
      final gVM = result['grafico_vendedores_meses'] as List? ?? [];
      _graficoVendedoresMeses = gVM
          .map((e) => GraficoVendedorMes.fromJson(e))
          .toList();

      // Resumen
      final resumen = result['resumen'] as Map<String, dynamic>? ?? {};
      _totalPedidosGral = resumen['total_pedidos'] ?? 0;
      _totalMontoGral = VendedorReporte._parseDouble(resumen['total_monto']);
      _totalFaltanteGral = VendedorReporte._parseDouble(
        resumen['total_faltante'],
      );
      _totalRealGral = VendedorReporte._parseDouble(resumen['total_real']);
      _totalVendedores = resumen['total_vendedores'] ?? 0;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page > _lastPage) return;
    await fetchReporte(page: page);
  }

  Future<String> getReportePdfUrl() async {
    return await _service.getReporteVendedoresPdfUrl(
      startDate: _startDate,
      endDate: _endDate,
      search: _search,
    );
  }
}

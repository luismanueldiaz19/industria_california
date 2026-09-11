import 'package:flutter/foundation.dart';
import '../models/inventario_movimiento.dart';
import '../services/inventario_movimiento_service.dart';

class InventarioMovimientoProvider with ChangeNotifier {
  final InventarioMovimientoService _service = InventarioMovimientoService();

  List<InventarioMovimiento> _movimientos = [];
  Map<String, dynamic> _resumen = {};
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;

  // Filtros
  int? _productoId;
  String _tipo = '';
  String? _startDate;
  String? _endDate;

  List<InventarioMovimiento> get movimientos => _movimientos;
  Map<String, dynamic> get resumen => _resumen;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get total => _total;
  bool get hasMore => _currentPage < _lastPage;

  void setFiltros({int? productoId, String? tipo, String? startDate, String? endDate}) {
    _productoId = productoId;
    _tipo = tipo ?? '';
    _startDate = startDate;
    _endDate = endDate;
  }

  Future<void> fetchMovimientos() async {
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final result = await _service.getMovimientos(
        productoId: _productoId,
        tipo: _tipo.isNotEmpty ? _tipo : null,
        startDate: _startDate,
        endDate: _endDate,
        page: 1,
      );
      _movimientos = result['items'] as List<InventarioMovimiento>;
      
      final resumenRaw = result['resumen'];
      if (resumenRaw is Map) {
        _resumen = Map<String, dynamic>.from(resumenRaw);
      } else {
        _resumen = {};
      }
      
      _currentPage = result['current_page'] as int;
      _lastPage = result['last_page'] as int;
      _total = result['total'] as int;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> registrarMovimiento(InventarioMovimiento movimiento) async {
    try {
      final nuevo = await _service.registrarMovimiento(movimiento);
      _movimientos.insert(0, nuevo);
      _total++;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<String?> getPdfUrl() async {
    try {
      return await _service.getMovimientoPdfUrl(
        productoId: _productoId,
        tipo: _tipo.isNotEmpty ? _tipo : null,
        startDate: _startDate,
        endDate: _endDate,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}

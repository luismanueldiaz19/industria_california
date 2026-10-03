import 'package:flutter/material.dart';
import '../models/cheque_futurista.dart';
import '../services/cheque_futurista_service.dart';

class ChequeAdminProvider extends ChangeNotifier {
  final ChequeFuturistaService _service = ChequeFuturistaService();

  List<ChequeFuturista> _cheques = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  int _totalFilas = 0;
  double _montoTotal = 0.0;

  // Filtros
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? _buscar;
  String? _estado;
  int? _idVendedor;
  bool _soloAtrasados = false;

  // Getters
  List<ChequeFuturista> get cheques => _cheques;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  DateTime? get fechaInicio => _fechaInicio;
  DateTime? get fechaFin => _fechaFin;
  String? get buscar => _buscar;
  String? get estado => _estado;
  int? get idVendedor => _idVendedor;
  bool get soloAtrasados => _soloAtrasados;
  int get totalFilas => _totalFilas;
  double get montoTotal => _montoTotal;

  void setDateRange(DateTime start, DateTime end) {
    _fechaInicio = start;
    _fechaFin = end;
    fetchCheques(refresh: true);
  }

  void clearDateRange() {
    _fechaInicio = null;
    _fechaFin = null;
    fetchCheques(refresh: true);
  }

  void setSearch(String query) {
    if (_buscar == query) return;
    _buscar = query.trim().isEmpty ? null : query.trim();
    fetchCheques(refresh: true);
  }

  void setEstado(String? nuevoEstado) {
    _estado = nuevoEstado;
    fetchCheques(refresh: true);
  }

  void setVendedor(int? id) {
    _idVendedor = id;
    fetchCheques(refresh: true);
  }

  void toggleAtrasados() {
    _soloAtrasados = !_soloAtrasados;
    fetchCheques(refresh: true);
  }

  void clearAllFilters() {
    _fechaInicio = null;
    _fechaFin = null;
    _buscar = null;
    _estado = null;
    _idVendedor = null;
    _soloAtrasados = false;
    fetchCheques(refresh: true);
  }

  Future<void> fetchCheques({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _cheques.clear();
      _totalFilas = 0;
      _montoTotal = 0.0;
      _isLoading = true;
    } else {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
    }

    _error = null;
    notifyListeners();

    try {
      final String? startStr =
          _fechaInicio != null ? _fechaInicio!.toIso8601String().split('T')[0] : null;
      final String? endStr =
          _fechaFin != null ? _fechaFin!.toIso8601String().split('T')[0] : null;

      final data = await _service.obtenerChequesAdmin(
        page: _currentPage,
        fechaInicio: startStr,
        fechaFin: endStr,
        buscar: _buscar,
        estado: _estado,
        idVendedor: _idVendedor,
        atrasados: _soloAtrasados,
      );

      final List rawList = data['data'] ?? [];
      final int lastPage = data['last_page'] ?? 1;

      final newCheques = rawList.map((json) => ChequeFuturista.fromJson(json)).toList();
      _cheques.addAll(newCheques);

      if (data['resumen_filtro'] != null) {
        _totalFilas = data['resumen_filtro']['total_filas'] ?? 0;
        _montoTotal = (data['resumen_filtro']['monto_total'] ?? 0).toDouble();
      }

      _hasMore = _currentPage < lastPage;
      if (_hasMore) _currentPage++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}

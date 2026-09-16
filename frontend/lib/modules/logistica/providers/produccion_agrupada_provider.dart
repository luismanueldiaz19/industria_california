import 'package:flutter/material.dart';
import '../../../core/services/http_service.dart';

enum TipoAgrupacion { producto, pedido, cliente, fecha }

class ProduccionAgrupadaProvider extends ChangeNotifier {
  final HttpService _http = HttpService();

  List<Map<String, dynamic>> _datos = [];
  bool _isLoading = false;
  String? _error;

  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRows = 0;
  int _rowsPerPage = 10;
  String _searchQuery = '';

  List<Map<String, dynamic>> get datos => _datos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get totalRows => _totalRows;
  int get rowsPerPage => _rowsPerPage;

  void setRowsPerPage(int rows, TipoAgrupacion tipo) {
    _rowsPerPage = rows;
    fetchDatos(tipo, refresh: true);
  }

  void setSearchQuery(String query, TipoAgrupacion tipo) {
    _searchQuery = query;
    fetchDatos(tipo, refresh: true);
  }

  Future<void> fetchDatos(
    TipoAgrupacion tipo, {
    bool refresh = false,
    int? page,
  }) async {
    if (page != null) {
      _currentPage = page;
      refresh = true;
    }

    if (refresh) {
      if (page == null) _currentPage = 1;
      _datos.clear();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final endpoint = _getEndpoint(tipo);
      final params = {
        'page': _currentPage.toString(),
        'per_page': _rowsPerPage.toString(),
      };

      if (_searchQuery.isNotEmpty) {
        params['search'] = _searchQuery;
      }

      final response = await _http.get(endpoint, params: params);

      _datos = List<Map<String, dynamic>>.from(response['data']);
      _lastPage = response['last_page'] ?? 1;
      _totalRows = response['total'] ?? _datos.length;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getEndpoint(TipoAgrupacion tipo) {
    switch (tipo) {
      case TipoAgrupacion.producto:
        return 'industria-california/produccion/agrupada/producto';
      case TipoAgrupacion.pedido:
        return 'industria-california/produccion/agrupada/pedido';
      case TipoAgrupacion.cliente:
        return 'industria-california/produccion/agrupada/cliente';
      case TipoAgrupacion.fecha:
        return 'industria-california/produccion/agrupada/fecha';
    }
  }
}

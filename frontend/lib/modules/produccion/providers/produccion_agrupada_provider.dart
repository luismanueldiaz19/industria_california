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

  Future<bool> marcarListoAgrupadoProducto(int productoId, int clienteId) async {
    try {
      await _http.post(
        'industria-california/produccion/agrupada/marcar-listo',
        {
          'producto_id': productoId,
          'cliente_id': clienteId,
        },
      );
      
      // Actualizamos la tabla
      await fetchDatos(TipoAgrupacion.producto, refresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<String?> getPdfUrl(TipoAgrupacion tipo) async {
    try {
      final endpoint = 'industria-california/produccion-agrupada/pdf-url';
      final params = <String, String>{};
      
      switch (tipo) {
        case TipoAgrupacion.producto: params['tipo'] = 'producto'; break;
        case TipoAgrupacion.pedido: params['tipo'] = 'pedido'; break;
        case TipoAgrupacion.cliente: params['tipo'] = 'cliente'; break;
        case TipoAgrupacion.fecha: params['tipo'] = 'fecha'; break;
      }
      
      if (_searchQuery.isNotEmpty) {
        params['search'] = _searchQuery;
      }

      final response = await _http.get(endpoint, params: params);
      return response['url']?.toString();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
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

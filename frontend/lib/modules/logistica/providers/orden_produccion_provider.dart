import 'package:flutter/material.dart';
import '../models/orden_produccion.dart';
import '../../../services/http_service.dart';

class OrdenProduccionProvider extends ChangeNotifier {
  final HttpService _http = HttpService();

  List<OrdenProduccion> _ordenes = [];
  bool _isLoading = false;
  String? _error;

  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  bool _hasMore = true;

  // Filters
  String? _estadoFiltro;

  List<OrdenProduccion> get ordenes => _ordenes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  OrdenProduccionProvider();

  void setEstadoFiltro(String? estado) {
    _estadoFiltro = estado;
    fetchOrdenes(refresh: true);
  }

  Future<void> fetchOrdenes({bool refresh = false, int? vendedorId}) async {
    if (refresh) {
      _currentPage = 1;
      _ordenes.clear();
      _hasMore = true;
    }

    if (!_hasMore) return;

    _isLoading = true;
    _error = null;
    if (refresh) notifyListeners();

    try {
      final query = {'page': _currentPage.toString(), 'per_page': '20'};

      if (_estadoFiltro != null && _estadoFiltro!.isNotEmpty) {
        query['estado'] = _estadoFiltro!;
      }

      if (vendedorId != null) {
        query['vendedor_id'] = vendedorId.toString();
      }

      final response = await _http.get(
        'industria-california/produccion',
        params: query,
      );
      final data = response['data'] as List;
      final nuevas = data
          .map((json) => OrdenProduccion.fromJson(json))
          .toList();

      if (refresh) {
        _ordenes = nuevas;
      } else {
        _ordenes.addAll(nuevas);
      }

      _lastPage = response['last_page'];
      _hasMore = _currentPage < _lastPage;
      if (_hasMore) _currentPage++;
    } catch (e) {
      _error = _handleError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> marcarDetalleListo(int detalleId) async {
    try {
      final response = await _http.patch(
        'industria-california/produccion/detalles/$detalleId/listo',
        {},
      );

      // Actualizar estado localmente
      final nuevoEstadoOrden = response['orden_estado'];

      for (int i = 0; i < _ordenes.length; i++) {
        final orden = _ordenes[i];
        for (int j = 0; j < orden.detalles.length; j++) {
          if (orden.detalles[j].id == detalleId) {
            // Re-creamos el detalle con el nuevo estado
            final det = orden.detalles[j];
            orden.detalles[j] = OrdenProduccionDetalle(
              id: det.id,
              ordenProduccionId: det.ordenProduccionId,
              productoId: det.productoId,
              pedidoDetalleId: det.pedidoDetalleId,
              cantidadFaltante: det.cantidadFaltante,
              cantidadProducida: det.cantidadFaltante,
              estado: 'listo',
              producto: det.producto,
            );
          }
        }

        // Re-creamos la orden si el estado cambió
        if (orden.estado != nuevoEstadoOrden) {
          _ordenes[i] = OrdenProduccion(
            id: orden.id,
            pedidoId: orden.pedidoId,
            clienteId: orden.clienteId,
            vendedorId: orden.vendedorId,
            estado: nuevoEstadoOrden,
            fechaEstimadaEntrega: orden.fechaEstimadaEntrega,
            notas: orden.notas,
            createdAt: orden.createdAt,
            cliente: orden.cliente,
            vendedor: orden.vendedor,
            pedido: orden.pedido,
            detalles: orden.detalles,
          );
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = _handleError(e);
      notifyListeners();
      return false;
    }
  }

  String _handleError(dynamic e) {
    if (e is HttpServiceException) {
      return e.message;
    }
    return e.toString();
  }
}

import 'package:flutter/foundation.dart';
import '../models/camion_victual.dart';
import '../services/camion_victual_service.dart';

class CamionVictualProvider extends ChangeNotifier {
  final CamionVictualService _service = CamionVictualService();

  List<CamionVictual> _camiones = [];
  List<PedidoDisponible> _pedidosDisponibles = [];
  double _montoMinimo = 0;

  bool _isLoading = false;
  bool _isLoadingPedidos = false;
  bool _isActualizando = false;
  String? _error;

  List<CamionVictual> get camiones => _camiones;
  List<PedidoDisponible> get pedidosDisponibles => _pedidosDisponibles;
  double get montoMinimo => _montoMinimo;
  bool get isLoading => _isLoading;
  bool get isLoadingPedidos => _isLoadingPedidos;
  bool get isActualizando => _isActualizando;
  String? get error => _error;

  Future<String> getConducePdfUrl(int id) async {
    return await _service.getConducePdfUrl(id);
  }

  /// Carga los camiones activos y el monto mínimo configurado.
  Future<void> fetchCamiones() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getCamiones(withPedidos: true),
        _service.getMontoMinimo(),
      ]);
      _camiones = results[0] as List<CamionVictual>;

      _montoMinimo = results[1] as double;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    try {
      final newCamion = await _service.createCamion(data);
      _camiones.add(newCamion);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    try {
      final updatedCamion = await _service.updateCamion(id, data);
      final index = _camiones.indexWhere((c) => c.id == id);
      if (index != -1) {
        _camiones[index] = updatedCamion;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await _service.deleteCamion(id);
      _camiones.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Recarga solo un camión específico (actualiza en la lista local).
  Future<void> refreshCamion(int camionId) async {
    try {
      final actualizado = await _service.getCamion(camionId);
      final idx = _camiones.indexWhere((c) => c.id == camionId);
      if (idx != -1) {
        _camiones[idx] = actualizado;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Carga los pedidos facturados disponibles para agregar (con búsqueda opcional).
  Future<void> fetchPedidosDisponibles({String? search}) async {
    _isLoadingPedidos = true;
    notifyListeners();
    try {
      _pedidosDisponibles = await _service.getPedidosDisponibles(
        search: search,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingPedidos = false;
      notifyListeners();
    }
  }

  /// Agrega un pedido al camión y refresca el camión actualizado.
  Future<bool> agregarPedido(int camionId, int pedidoId) async {
    _isActualizando = true;
    notifyListeners();
    try {
      final actualizado = await _service.agregarPedido(camionId, pedidoId);
      _actualizarEnLista(actualizado);
      // Quitar el pedido de la lista de disponibles localmente
      _pedidosDisponibles.removeWhere((p) => p.id == pedidoId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isActualizando = false;
      notifyListeners();
    }
  }

  /// Quita un pedido del camión y refresca.
  Future<bool> quitarPedido(int camionId, int pedidoId) async {
    _isActualizando = true;
    notifyListeners();
    try {
      final actualizado = await _service.quitarPedido(camionId, pedidoId);
      _actualizarEnLista(actualizado);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isActualizando = false;
      notifyListeners();
    }
  }

  /// Guarda el nuevo orden de viaje después de un drag-and-drop.
  Future<bool> reordenar(
    int camionId,
    List<CamionPedido> pedidosOrdenados,
  ) async {
    _isActualizando = true;
    notifyListeners();
    try {
      final orden = pedidosOrdenados
          .asMap()
          .entries
          .map((e) => {'pedido_id': e.value.id, 'orden_viaje': e.key + 1})
          .toList();
      final actualizado = await _service.reordenar(camionId, orden);
      _actualizarEnLista(actualizado);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isActualizando = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _actualizarEnLista(CamionVictual camion) {
    final idx = _camiones.indexWhere((c) => c.id == camion.id);
    if (idx != -1) {
      _camiones[idx] = camion;
    } else {
      _camiones.add(camion);
    }
  }

  Future<bool> actualizarEntrega(
    int camionId,
    int pedidoId,
    String estadoEntrega, {
    String? comentarioEntrega,
  }) async {
    _isActualizando = true;
    notifyListeners();
    try {
      final actualizado = await _service.actualizarEntrega(
        camionId,
        pedidoId,
        estadoEntrega,
        comentarioEntrega: comentarioEntrega,
      );
      _actualizarEnLista(actualizado);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isActualizando = false;
      notifyListeners();
    }
  }

  Future<bool> vaciarCamion(int camionId) async {
    _isActualizando = true;
    notifyListeners();
    try {
      final actualizado = await _service.vaciarCamion(camionId);
      _actualizarEnLista(actualizado);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isActualizando = false;
      notifyListeners();
    }
  }

  Future<bool> ponerEnRuta(
    int camionId, {
    required int vehiculoId,
    required int choferId,
    int? cantAyudantes,
    String? nombresAyudantes,
    String? comentarios,
    List<Map<String, dynamic>>? gastos,
  }) async {
    _isActualizando = true;
    notifyListeners();
    try {
      final actualizado = await _service.ponerEnRuta(
        camionId,
        vehiculoId: vehiculoId,
        choferId: choferId,
        cantAyudantes: cantAyudantes,
        nombresAyudantes: nombresAyudantes,
        comentarios: comentarios,
        gastos: gastos,
      );
      _actualizarEnLista(actualizado);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isActualizando = false;
      notifyListeners();
    }
  }

  Future<bool> cerrar(int camionId) async {
    _isActualizando = true;
    notifyListeners();
    try {
      final actualizado = await _service.cerrar(camionId);
      _actualizarEnLista(actualizado);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isActualizando = false;
      notifyListeners();
    }
  }

  /// Guarda datos preliminares del viaje (gastos, ayudantes, notas)
  /// SIN cerrar el viaje ni liberar el camión.
  Future<bool> guardarDatosViaje(
    int camionId,
    Map<String, dynamic> data,
  ) async {
    _isActualizando = true;
    notifyListeners();
    try {
      final res = await _service.guardarDatosViaje(camionId, data);
      if (res['camion'] != null) {
        final camionActualizado = CamionVictual.fromJson(res['camion']);
        _actualizarEnLista(camionActualizado);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isActualizando = false;
      notifyListeners();
    }
  }

  /// Cierra el camión con liquidación de viaje y actualiza el camión liberado.
  Future<bool> cerrarConLiquidacion(
    int camionId,
    Map<String, dynamic> data,
  ) async {
    _isActualizando = true;
    notifyListeners();
    try {
      final res = await _service.cerrarConLiquidacion(camionId, data);
      if (res['camion'] != null) {
        final camionActualizado = CamionVictual.fromJson(res['camion']);
        _actualizarEnLista(camionActualizado);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isActualizando = false;
      notifyListeners();
    }
  }
}

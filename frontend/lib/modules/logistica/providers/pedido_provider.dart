import 'package:flutter/foundation.dart';
import '../models/pedido.dart';
import '../services/pedido_service.dart';

class PedidoProvider extends ChangeNotifier {
  final PedidoService _service = PedidoService();
  
  List<Pedido> _pedidos = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;

  int? _clienteId;
  int? _rutaId;
  String? _estado;
  String? _startDate;
  String? _endDate;

  List<Pedido> get pedidos => _pedidos;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _currentPage < _lastPage;
  int get total => _total;

  void setFiltros({
    int? clienteId,
    int? rutaId,
    String? estado,
    String? startDate,
    String? endDate,
  }) {
    _clienteId = clienteId;
    _rutaId = rutaId;
    _estado = estado;
    _startDate = startDate;
    _endDate = endDate;
  }

  Future<void> fetchPedidos() async {
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final result = await _service.getPedidos(
        clienteId: _clienteId,
        rutaId: _rutaId,
        estado: _estado,
        startDate: _startDate,
        endDate: _endDate,
        page: _currentPage,
      );
      _pedidos = result['data'];
      _currentPage = result['current_page'];
      _lastPage = result['last_page'];
      _total = result['total'];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMore() async {
    if (!hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _service.getPedidos(
        clienteId: _clienteId,
        rutaId: _rutaId,
        estado: _estado,
        startDate: _startDate,
        endDate: _endDate,
        page: _currentPage + 1,
      );
      _pedidos.addAll(result['data']);
      _currentPage = result['current_page'];
      _lastPage = result['last_page'];
      _total = result['total'];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> createPedido(Map<String, dynamic> data) async {
    try {
      await _service.createPedido(data);
      await fetchPedidos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePedido(int id, Map<String, dynamic> data) async {
    try {
      await _service.updatePedido(id, data);
      await fetchPedidos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> changeStatus(int id, String estado) async {
    try {
      await _service.changeStatus(id, estado);
      await fetchPedidos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

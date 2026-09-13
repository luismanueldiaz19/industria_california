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
  int? _vendedorId;
  String? _estado;
  String? _startDate;
  String? _endDate;

  List<Pedido> get pedidos => _pedidos;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _currentPage < _lastPage;
  int get total => _total;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;

  void setFiltros({
    int? clienteId,
    int? rutaId,
    int? vendedorId,
    String? estado,
    String? startDate,
    String? endDate,
  }) {
    _clienteId = clienteId;
    _rutaId = rutaId;
    _vendedorId = vendedorId;
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
        vendedorId: _vendedorId,
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

  Future<void> fetchPage(int page) async {
    if (page < 1 || (page > _lastPage && _lastPage > 0)) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getPedidos(
        clienteId: _clienteId,
        rutaId: _rutaId,
        vendedorId: _vendedorId,
        estado: _estado,
        startDate: _startDate,
        endDate: _endDate,
        page: page,
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
        vendedorId: _vendedorId,
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

  Future<bool> deletePedido(int id) async {
    try {
      await _service.deletePedido(id);
      await fetchPedidos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignRuta(List<int> pedidoIds, int rutaId) async {
    try {
      await _service.assignRuta(pedidoIds, rutaId);
      await fetchPedidos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<String> getPdfUrl(int id) async {
    return await _service.getPdfUrl(id);
  }

  Future<String> getGeneralPdfUrl() async {
    return await _service.getGeneralPdfUrl(
      clienteId: _clienteId,
      rutaId: _rutaId,
      vendedorId: _vendedorId,
      estado: _estado,
      startDate: _startDate,
      endDate: _endDate,
    );
  }
}

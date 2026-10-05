import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../led_house/models/ledhouse_cliente.dart';

/// Estado del formulario de registro de un cheque futurista.
/// El vendedor es siempre el usuario autenticado — se pasa desde fuera.
class ChequeFormProvider extends ChangeNotifier {
  // ── Campos del formulario ─────────────────────────────────

  LedhouseCliente? _cliente;
  String _numCheque = '';
  String _numPedido = '';
  String _monto = '';
  String _estado = 'pendiente';
  String _comentario = '';
  String? _fechaDeposito;
  List<XFile> _archivos = [];

  LedhouseCliente? get cliente => _cliente;
  String get numCheque => _numCheque;
  String get numPedido => _numPedido;
  String get monto => _monto;
  String get estado => _estado;
  String get comentario => _comentario;
  String? get fechaDeposito => _fechaDeposito;
  List<XFile> get archivos => _archivos;

  // ── Validación ────────────────────────────────────────────

  bool get isFormValid => _cliente != null && _numCheque.trim().isNotEmpty && _monto.trim().isNotEmpty && double.tryParse(_monto) != null && double.tryParse(_monto)! >= 0;

  // ── Setters ───────────────────────────────────────────────

  void setCliente(LedhouseCliente? c) {
    _cliente = c;
    notifyListeners();
  }

  void setNumCheque(String v) {
    _numCheque = v;
    notifyListeners();
  }

  void setNumPedido(String v) {
    _numPedido = v;
    notifyListeners();
  }

  void setMonto(String v) {
    _monto = v;
    notifyListeners();
  }

  void setEstado(String v) {
    _estado = v;
    notifyListeners();
  }

  void setComentario(String v) {
    _comentario = v;
    notifyListeners();
  }

  void setFechaDeposito(String? v) {
    _fechaDeposito = v;
    notifyListeners();
  }

  void addArchivos(List<XFile> nuevosArchivos) {
    _archivos.addAll(nuevosArchivos);
    notifyListeners();
  }

  void removeArchivo(int index) {
    if (index >= 0 && index < _archivos.length) {
      _archivos.removeAt(index);
      notifyListeners();
    }
  }

  // ── Payload para la API ───────────────────────────────────
  // vendedorId se pasa desde el controller al confirmar (viene de AuthProvider)

  Map<String, dynamic> toPayload(int vendedorId) {
    return {
      'id_cliente': _cliente!.id,
      'id_vendedor': vendedorId,
      'num_cheque': _numCheque.trim(),
      if (_numPedido.trim().isNotEmpty) 'num_pedido': _numPedido.trim(),
      'monto': double.parse(_monto),
      'estado': _estado,
      if (_comentario.trim().isNotEmpty) 'comentario': _comentario.trim(),
      if (_fechaDeposito != null) 'fecha_deposito': _fechaDeposito,
    };
  }

  void reset() {
    _cliente = null;
    _numCheque = '';
    _numPedido = '';
    _monto = '';
    _estado = 'pendiente';
    _comentario = '';
    _fechaDeposito = null;
    _archivos = [];
    notifyListeners();
  }
}

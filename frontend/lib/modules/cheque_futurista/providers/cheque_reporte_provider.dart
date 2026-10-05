import 'package:flutter/material.dart';
import '../services/cheque_futurista_service.dart';

class ChequeReporteProvider extends ChangeNotifier {
  final ChequeFuturistaService _service = ChequeFuturistaService();

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _reporte = [];

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _tipoFecha = 'creacion';

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get reporte => _reporte;
  DateTime? get fechaInicio => _fechaInicio;
  DateTime? get fechaFin => _fechaFin;
  String get tipoFecha => _tipoFecha;

  void setDateRange(DateTime? start, DateTime? end) {
    _fechaInicio = start;
    _fechaFin = end;
    fetchReporte();
  }

  void setTipoFecha(String tipo) {
    _tipoFecha = tipo;
    fetchReporte();
  }

  void clearFilters() {
    _fechaInicio = null;
    _fechaFin = null;
    _tipoFecha = 'creacion';
    fetchReporte();
  }

  Future<void> fetchReporte() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _service.obtenerReporteVendedores(
        fechaInicio: _fechaInicio?.toIso8601String().split('T').first,
        fechaFin: _fechaFin?.toIso8601String().split('T').first,
        tipoFecha: _tipoFecha,
      );
      _reporte = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      _error = 'Error al cargar reporte: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

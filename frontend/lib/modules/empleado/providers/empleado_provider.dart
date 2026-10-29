import 'package:flutter/material.dart';
import '../models/empleado.dart';
import '../services/empleado_service.dart';

class EmpleadoProvider extends ChangeNotifier {
  final EmpleadoService _service = EmpleadoService();

  List<Empleado> _empleados = [];
  Map<String, dynamic> _resumen = {};
  bool _isLoading = false;
  String? _error;
  String _filtroEstado = 'todos';
  String _filtroDepartamento = 'todos';
  String _searchQuery = '';

  List<Empleado> get empleados => _empleados;
  Map<String, dynamic> get resumen => _resumen;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filtroEstado => _filtroEstado;
  String get filtroDepartamento => _filtroDepartamento;
  String get searchQuery => _searchQuery;

  Future<void> loadEmpleados() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _empleados = await _service.getEmpleados(
        estado: _filtroEstado,
        departamento: _filtroDepartamento,
        search: _searchQuery,
      );
      _resumen = await _service.getResumen();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFiltroEstado(String estado) {
    _filtroEstado = estado;
    loadEmpleados();
  }

  void setFiltroDepartamento(String depto) {
    _filtroDepartamento = depto;
    loadEmpleados();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadEmpleados();
  }

  Future<Empleado> createEmpleado(Map<String, dynamic> data) async {
    final nuevo = await _service.createEmpleado(data);
    await loadEmpleados();
    return nuevo;
  }

  Future<Empleado> updateEmpleado(int id, Map<String, dynamic> data) async {
    final updated = await _service.updateEmpleado(id, data);
    await loadEmpleados();
    return updated;
  }

  Future<void> deleteEmpleado(int id) async {
    await _service.deleteEmpleado(id);
    await loadEmpleados();
  }
}

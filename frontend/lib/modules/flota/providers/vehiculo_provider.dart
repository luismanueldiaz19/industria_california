import 'package:flutter/material.dart';
import '../models/vehiculo.dart';
import '../services/vehiculo_service.dart';

class VehiculoProvider with ChangeNotifier {
  final VehiculoService _service = VehiculoService();
  
  bool isLoading = false;
  List<Vehiculo> vehiculos = [];
  Map<String, dynamic> resumen = {
    'total': 0,
    'disponibles': 0,
    'en_mantenimiento': 0,
    'inactivos': 0,
  };
  
  Future<void> loadVehiculos() async {
    isLoading = true;
    notifyListeners();
    try {
      vehiculos = await _service.getVehiculos();
      resumen = await _service.getResumen();
    } catch (e) {
      debugPrint('Error cargando vehículos: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  int get totalDisponibles => resumen['disponibles'] ?? 0;
  int get totalMantenimiento => resumen['en_mantenimiento'] ?? 0;
  int get totalInactivos => resumen['inactivos'] ?? 0;

  Future<void> createVehiculo(Map<String, dynamic> data) async {
    try {
      await _service.createVehiculo(data);
      await loadVehiculos();
    } catch (e) {
      debugPrint('Error creating vehiculo: $e');
      rethrow;
    }
  }

  Future<void> updateVehiculo(int id, Map<String, dynamic> data) async {
    try {
      await _service.updateVehiculo(id, data);
      await loadVehiculos();
    } catch (e) {
      debugPrint('Error updating vehiculo: $e');
      rethrow;
    }
  }
}

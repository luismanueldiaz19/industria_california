import 'package:flutter/material.dart';

class MantenimientoModel {
  final String id;
  final String vehiculoFicha;
  final String tipo;
  final String fecha;
  final String estado;

  MantenimientoModel({
    required this.id,
    required this.vehiculoFicha,
    required this.tipo,
    required this.fecha,
    required this.estado,
  });
}

class MantenimientoProvider with ChangeNotifier {
  bool isLoading = false;
  List<MantenimientoModel> mantenimientos = [];
  
  void mockLoad() {
    isLoading = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 1), () {
      mantenimientos = [
        MantenimientoModel(id: '1', vehiculoFicha: 'F-121', tipo: 'preventivo', fecha: '2026-09-10', estado: 'en_proceso'),
        MantenimientoModel(id: '2', vehiculoFicha: 'F-119', tipo: 'averia', fecha: '2026-09-14', estado: 'pendiente'),
      ];
      isLoading = false;
      notifyListeners();
    });
  }
}

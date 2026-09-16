import 'package:flutter/material.dart';

class DespachoModel {
  final String id;
  final String vehiculoFicha;
  final String choferNombre;
  final String fechaSalida;
  final String estado;

  DespachoModel({
    required this.id,
    required this.vehiculoFicha,
    required this.choferNombre,
    required this.fechaSalida,
    required this.estado,
  });
}

class DespachoProvider with ChangeNotifier {
  bool isLoading = false;
  List<DespachoModel> despachos = [];
  
  void mockLoad() {
    isLoading = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 1), () {
      despachos = [
        DespachoModel(id: '1', vehiculoFicha: 'F-119', choferNombre: 'Juan Pérez', fechaSalida: '2026-09-15 08:00', estado: 'en_transito'),
        DespachoModel(id: '2', vehiculoFicha: 'F-120', choferNombre: 'Luis Guzmán', fechaSalida: '2026-09-16 07:30', estado: 'programado'),
      ];
      isLoading = false;
      notifyListeners();
    });
  }
}

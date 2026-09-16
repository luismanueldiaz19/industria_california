import 'package:flutter/material.dart';

class GastoVehiculoModel {
  final String id;
  final String vehiculoFicha;
  final String concepto;
  final double montoTotal;
  final String fecha;

  GastoVehiculoModel({
    required this.id,
    required this.vehiculoFicha,
    required this.concepto,
    required this.montoTotal,
    required this.fecha,
  });
}

class GastoVehiculoProvider with ChangeNotifier {
  bool isLoading = false;
  List<GastoVehiculoModel> gastos = [];
  
  void mockLoad() {
    isLoading = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 1), () {
      gastos = [
        GastoVehiculoModel(id: '1', vehiculoFicha: 'F-119', concepto: 'Combustible Diesel', montoTotal: 5000.00, fecha: '2026-09-15'),
        GastoVehiculoModel(id: '2', vehiculoFicha: 'F-120', concepto: 'Recarga Eléctrica', montoTotal: 850.00, fecha: '2026-09-14'),
      ];
      isLoading = false;
      notifyListeners();
    });
  }
}

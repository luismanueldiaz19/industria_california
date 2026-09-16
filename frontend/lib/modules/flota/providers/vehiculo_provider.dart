import 'package:flutter/material.dart';

class VehiculoModel {
  final String id;
  final String ficha;
  final String placa;
  final String marca;
  final String modelo;
  final String tipoEnergia;
  final String estado;

  VehiculoModel({
    required this.id,
    required this.ficha,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.tipoEnergia,
    required this.estado,
  });
}

class VehiculoProvider with ChangeNotifier {
  bool isLoading = false;
  List<VehiculoModel> vehiculos = [];
  
  void mockLoad() {
    isLoading = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 1), () {
      vehiculos = [
        VehiculoModel(id: '1', ficha: 'F-119', placa: 'L123456', marca: 'Isuzu', modelo: 'NPR', tipoEnergia: 'diesel', estado: 'disponible'),
        VehiculoModel(id: '2', ficha: 'F-120', placa: 'L987654', marca: 'BYD', modelo: 'T3', tipoEnergia: 'electrico', estado: 'disponible'),
        VehiculoModel(id: '3', ficha: 'F-121', placa: 'L555555', marca: 'Hino', modelo: '300', tipoEnergia: 'diesel', estado: 'en_mantenimiento'),
      ];
      isLoading = false;
      notifyListeners();
    });
  }

  int get totalDisponibles => vehiculos.where((v) => v.estado == 'disponible').length;
  int get totalMantenimiento => vehiculos.where((v) => v.estado == 'en_mantenimiento').length;
  int get totalInactivos => vehiculos.where((v) => v.estado == 'inactivo').length;
}

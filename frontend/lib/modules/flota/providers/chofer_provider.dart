import 'package:flutter/material.dart';

class ChoferModel {
  final String id;
  final String nombre;
  final String licencia;
  final String estado;

  ChoferModel({
    required this.id,
    required this.nombre,
    required this.licencia,
    required this.estado,
  });
}

class ChoferProvider with ChangeNotifier {
  bool isLoading = false;
  List<ChoferModel> choferes = [];
  
  void mockLoad() {
    isLoading = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 1), () {
      choferes = [
        ChoferModel(id: '1', nombre: 'Juan Pérez', licencia: '001-1234567-8', estado: 'activo'),
        ChoferModel(id: '2', nombre: 'Pedro Ramírez', licencia: '001-8765432-1', estado: 'vacaciones'),
        ChoferModel(id: '3', nombre: 'Luis Guzmán', licencia: '402-1111111-1', estado: 'activo'),
      ];
      isLoading = false;
      notifyListeners();
    });
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/vehiculo_mantenimiento.dart';
import '../services/vehiculo_service.dart';
import '../../../core/widgets/quick_date_filter.dart';

class MantenimientoProvider with ChangeNotifier {
  final VehiculoService _service = VehiculoService();

  bool isLoading = false;
  List<VehiculoMantenimiento> mantenimientos = [];

  // Filtros
  String? filtroVehiculoFicha; // null means 'Todos'
  String filtroTipo = 'Todos';
  String filtroEstado = 'Todos';
  DateFilterOption quickDateFilter = DateFilterOption.todos;
  DateTimeRange? filtroRangoFecha;
  bool sortByDateDesc = true;

  // Paginación
  int itemsPerPage = 20;
  int currentPage = 1;

  List<VehiculoMantenimiento> get mantenimientosFiltrados {
    var lista = mantenimientos.where((m) {
      bool passVehiculo =
          filtroVehiculoFicha == null || m.vehiculoFicha == filtroVehiculoFicha;
      bool passTipo =
          filtroTipo == 'Todos' || m.tipo == filtroTipo.toLowerCase();
      bool passEstado =
          filtroEstado == 'Todos' ||
          m.estado == filtroEstado.toLowerCase().replaceAll(' ', '_');

      bool passFecha = true;
      if (quickDateFilter != DateFilterOption.todos) {
        if (m.fechaReporte == null) {
          passFecha = false;
        } else {
          passFecha = QuickDateFilter.isDateInFilter(
            m.fechaReporte!,
            quickDateFilter,
          );
        }
      }

      bool passRango = true;
      if (filtroRangoFecha != null) {
        if (m.fechaReporte == null) {
          passRango = false;
        } else {
          final fr = m.fechaReporte!;
          final dateSolo = DateTime(fr.year, fr.month, fr.day);
          final start = DateTime(
            filtroRangoFecha!.start.year,
            filtroRangoFecha!.start.month,
            filtroRangoFecha!.start.day,
          );
          final end = DateTime(
            filtroRangoFecha!.end.year,
            filtroRangoFecha!.end.month,
            filtroRangoFecha!.end.day,
          );
          passRango =
              (dateSolo.isAtSameMomentAs(start) || dateSolo.isAfter(start)) &&
              (dateSolo.isAtSameMomentAs(end) || dateSolo.isBefore(end));
        }
      }

      return passVehiculo && passTipo && passEstado && passFecha && passRango;
    }).toList();

    lista.sort((a, b) {
      final dateA = a.fechaReporte ?? DateTime.now();
      final dateB = b.fechaReporte ?? DateTime.now();
      return sortByDateDesc ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });

    return lista;
  }

  int get totalReportes => mantenimientosFiltrados.length;
  int get totalPages => (totalReportes / itemsPerPage).ceil();
  double get totalCosto =>
      mantenimientosFiltrados.fold(0, (sum, item) => sum + item.costo);

  List<VehiculoMantenimiento> get mantenimientosPaginados {
    final filtrados = mantenimientosFiltrados;
    final startIndex = (currentPage - 1) * itemsPerPage;
    return filtrados.skip(startIndex).take(itemsPerPage).toList();
  }

  List<String> get vehiculosUnicos {
    final fichas = mantenimientos
        .map((e) => e.vehiculoFicha ?? 'S/N')
        .toSet()
        .toList();
    fichas.sort();
    return fichas;
  }

  void setFiltroVehiculo(String? ficha) {
    filtroVehiculoFicha = ficha;
    currentPage = 1;
    notifyListeners();
  }

  void setFiltroTipo(String tipo) {
    filtroTipo = tipo;
    currentPage = 1;
    notifyListeners();
  }

  void setFiltroEstado(String estado) {
    filtroEstado = estado;
    currentPage = 1;
    notifyListeners();
  }

  void setQuickDateFilter(DateFilterOption filter) {
    quickDateFilter = filter;
    filtroRangoFecha = null; // Limpiar el rango si usamos el filtro rápido
    currentPage = 1;
    notifyListeners();
  }

  void setFiltroRangoFecha(DateTimeRange? rango) {
    filtroRangoFecha = rango;
    quickDateFilter =
        DateFilterOption.todos; // Limpiar el filtro rápido si usamos rango
    currentPage = 1;
    notifyListeners();
  }

  void toggleSort() {
    sortByDateDesc = !sortByDateDesc;
    currentPage = 1; // reset page on sort
    notifyListeners();
  }

  void setItemsPerPage(int limit) {
    itemsPerPage = limit;
    currentPage = 1;
    notifyListeners();
  }

  void nextPage() {
    if (currentPage < totalPages) {
      currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (currentPage > 1) {
      currentPage--;
      notifyListeners();
    }
  }

  Future<void> loadMantenimientos() async {
    isLoading = true;
    notifyListeners();

    try {
      mantenimientos = await _service.getMantenimientosTodos();
    } catch (e) {
      debugPrint("Error loading mantenimientos: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMantenimientosPorVehiculo(int vehiculoId) async {
    isLoading = true;
    notifyListeners();

    try {
      mantenimientos = await _service.getMantenimientos(vehiculoId);
    } catch (e) {
      debugPrint("Error loading mantenimientos: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generarPdf() async {
    try {
      Map<String, dynamic> params = {};
      
      if (filtroVehiculoFicha != null) {
        params['vehiculo_ficha'] = filtroVehiculoFicha;
      }
      if (filtroTipo != 'Todos') {
        params['tipo'] = filtroTipo;
      }
      if (filtroEstado != 'Todos') {
        params['estado'] = filtroEstado;
      }

      // Procesar fechas según el filtro seleccionado
      DateTime? start;
      DateTime? end;

      if (filtroRangoFecha != null) {
        start = filtroRangoFecha!.start;
        end = filtroRangoFecha!.end;
      } else if (quickDateFilter != DateFilterOption.todos) {
        final now = DateTime.now();
        switch (quickDateFilter) {
          case DateFilterOption.todos:
            break;
          case DateFilterOption.esteMes:
            start = DateTime(now.year, now.month, 1);
            end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
            break;
          case DateFilterOption.mesPasado:
            start = DateTime(now.year, now.month - 1, 1);
            end = DateTime(now.year, now.month, 0, 23, 59, 59);
            break;
          case DateFilterOption.ultimos7Dias:
            start = now.subtract(const Duration(days: 7));
            end = now;
            break;
          case DateFilterOption.ultimos30Dias:
            start = now.subtract(const Duration(days: 30));
            end = now;
            break;
          case DateFilterOption.hace2Meses:
            start = DateTime(now.year, now.month - 2, 1);
            end = DateTime(now.year, now.month - 1, 0, 23, 59, 59);
            break;
          case DateFilterOption.hace3Meses:
            start = DateTime(now.year, now.month - 3, 1);
            end = DateTime(now.year, now.month - 2, 0, 23, 59, 59);
            break;
          case DateFilterOption.esteAno:
            start = DateTime(now.year, 1, 1);
            end = DateTime(now.year, 12, 31, 23, 59, 59);
            break;
          case DateFilterOption.anoPasado:
            start = DateTime(now.year - 1, 1, 1);
            end = DateTime(now.year - 1, 12, 31, 23, 59, 59);
            break;
        }
      }

      if (start != null && end != null) {
        params['fecha_inicio'] = start.toIso8601String().split('T')[0];
        params['fecha_fin'] = end.toIso8601String().split('T')[0];
      }

      final urlStr = await _service.getMantenimientosPdfUrl(params);
      final url = Uri.parse(urlStr);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint("Could not launch $urlStr");
      }
    } catch (e) {
      debugPrint("Error generando PDF de mantenimientos: $e");
    }
  }

  Future<void> deleteMantenimiento(int vehiculoId, int mantenimientoId) async {
    try {
      await _service.deleteMantenimiento(vehiculoId, mantenimientoId);
      await loadMantenimientos();
    } catch (e) {
      debugPrint("Error deleting mantenimiento: $e");
      rethrow;
    }
  }
}

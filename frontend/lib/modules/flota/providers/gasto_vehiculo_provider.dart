import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/vehiculo_gasto.dart';
import '../models/tipo_gasto.dart';
import '../services/vehiculo_service.dart';
import '../../../core/widgets/quick_date_filter.dart';

class GastoVehiculoProvider with ChangeNotifier {
  final VehiculoService _service = VehiculoService();

  bool isLoading = false;
  String? error;
  List<VehiculoGasto> gastos = [];
  List<TipoGasto> tiposGasto = [];

  // Filtros
  String? filtroVehiculoFicha; // null means 'Todos'
  String filtroTipoGasto = 'Todos';
  DateFilterOption quickDateFilter = DateFilterOption.todos;
  DateTimeRange? filtroRangoFecha;
  bool sortByDateDesc = true;

  // Paginación
  int itemsPerPage = 20;
  int currentPage = 1;

  List<VehiculoGasto> get gastosFiltrados {
    var lista = gastos.where((g) {
      bool passVehiculo =
          filtroVehiculoFicha == null ||
          g.vehiculo?['ficha'] == filtroVehiculoFicha;
      bool passTipo =
          filtroTipoGasto == 'Todos' ||
          g.tipoGasto?.toLowerCase() == filtroTipoGasto.toLowerCase();

      bool passFecha = true;
      if (quickDateFilter != DateFilterOption.todos) {
        if (g.fechaGasto == null) {
          passFecha = false;
        } else {
          passFecha = QuickDateFilter.isDateInFilter(
            g.fechaGasto!,
            quickDateFilter,
          );
        }
      }

      bool passRango = true;
      if (filtroRangoFecha != null) {
        if (g.fechaGasto == null) {
          passRango = false;
        } else {
          final fr = g.fechaGasto!;
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

      return passVehiculo && passTipo && passFecha && passRango;
    }).toList();

    lista.sort((a, b) {
      final dateA = a.fechaGasto ?? DateTime.now();
      final dateB = b.fechaGasto ?? DateTime.now();
      return sortByDateDesc ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });

    return lista;
  }

  int get totalReportes => gastosFiltrados.length;
  int get totalPages => (totalReportes / itemsPerPage).ceil();
  double get totalCosto =>
      gastosFiltrados.fold(0, (sum, item) => sum + item.montoTotal);

  List<VehiculoGasto> get gastosPaginados {
    final filtrados = gastosFiltrados;
    final startIndex = (currentPage - 1) * itemsPerPage;
    return filtrados.skip(startIndex).take(itemsPerPage).toList();
  }

  List<String> get vehiculosUnicos {
    final fichas = gastos
        .map((e) => e.vehiculo?['ficha']?.toString() ?? 'S/N')
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
    filtroTipoGasto = tipo;
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

  Future<void> loadGastos() async {
    isLoading = true;
    notifyListeners();

    try {
      gastos = await _service.getGastosTodos();
      tiposGasto = await _service.getTipoGastos();
    } catch (e) {
      debugPrint("Error loading gastos: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGastosPorVehiculo(int vehiculoId) async {
    isLoading = true;
    notifyListeners();

    try {
      gastos = await _service.getGastos(vehiculoId);
    } catch (e) {
      debugPrint("Error loading gastos: $e");
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
      if (filtroTipoGasto != 'Todos') {
        params['tipo_gasto'] = filtroTipoGasto;
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

      final urlStr = await _service.getGastosPdfUrl(params);
      final url = Uri.parse(urlStr);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint("Could not launch $urlStr");
      }
    } catch (e) {
      debugPrint("Error generando PDF de gastos: $e");
    }
  }

  Future<bool> createGasto(int vehiculoId, Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _service.createGasto(vehiculoId, data);
      await loadGastos();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateGasto(
    int vehiculoId,
    int gastoId,
    Map<String, dynamic> data,
  ) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _service.updateGasto(vehiculoId, gastoId, data);
      await loadGastos();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteGasto(int vehiculoId, int gastoId) async {
    try {
      await _service.deleteGasto(vehiculoId, gastoId);
      await loadGastos();
    } catch (e) {
      debugPrint("Error deleting gasto: $e");
      rethrow;
    }
  }

  // Tipo Gasto Management
  Future<void> loadTiposGasto() async {
    try {
      tiposGasto = await _service.getTipoGastos();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading tipos gasto: $e");
    }
  }

  Future<bool> createTipoGasto(String nombre) async {
    try {
      await _service.createTipoGasto(nombre);
      await loadTiposGasto();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTipoGasto(int id, String nombre) async {
    try {
      await _service.updateTipoGasto(id, nombre);
      await loadTiposGasto();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTipoGasto(int id) async {
    try {
      await _service.deleteTipoGasto(id);
      await loadTiposGasto();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

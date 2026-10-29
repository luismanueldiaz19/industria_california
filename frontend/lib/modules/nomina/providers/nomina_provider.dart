import 'package:flutter/material.dart';
import '../../../../core/utils/nomina_calculator.dart';
import '../models/nomina.dart';
import '../models/nomina_concepto.dart';
import '../models/nomina_recurrente.dart';
import '../services/nomina_service.dart';

class NominaProvider extends ChangeNotifier {
  final NominaService _service = NominaService();

  List<Nomina> _nominas = [];
  Nomina? _nominaSeleccionada;
  List<NominaConcepto> _conceptos = [];
  List<NominaEmpleadoRecurrente> _recurrentes = [];
  List<TramoIsrModel> _escalasIsr = [];
  double _tasaAfp = 0.0287;
  double _tasaArs = 0.0304;
  Map<String, dynamic> _resumen = {};
  bool _isLoading = false;
  String? _error;
  String _filtroEstado = 'todos';
  String _filtroPeriodo = 'todos';

  List<Nomina> get nominas => _nominas;
  Nomina? get nominaSeleccionada => _nominaSeleccionada;
  List<NominaConcepto> get conceptos => _conceptos;
  List<NominaEmpleadoRecurrente> get recurrentes => _recurrentes;
  List<TramoIsrModel> get escalasIsr => _escalasIsr;
  double get tasaAfp => _tasaAfp;
  double get tasaArs => _tasaArs;
  double get tasaTss => _tasaAfp + _tasaArs;
  Map<String, dynamic> get resumen => _resumen;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filtroEstado => _filtroEstado;
  String get filtroPeriodo => _filtroPeriodo;

  Future<void> loadNominas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Sincronizar escalas de la DGII en caliente
      loadEscalasIsr();

      _nominas = await _service.getNominas(
        estado: _filtroEstado,
        tipoPeriodo: _filtroPeriodo,
      );
      _resumen = await _service.getResumen();
      if (_nominas.isNotEmpty && _nominaSeleccionada == null) {
        _nominaSeleccionada = await _service.getNomina(_nominas.first.id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectNomina(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _nominaSeleccionada = await _service.getNomina(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFiltroEstado(String estado) {
    _filtroEstado = estado;
    loadNominas();
  }

  void setFiltroPeriodo(String periodo) {
    _filtroPeriodo = periodo;
    loadNominas();
  }

  Future<Nomina> createNomina(Map<String, dynamic> data) async {
    final nueva = await _service.createNomina(data);
    await loadNominas();
    _nominaSeleccionada = await _service.getNomina(nueva.id);
    notifyListeners();
    return nueva;
  }

  Future<void> calcularNomina(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _nominaSeleccionada = await _service.calcularNomina(id);
      await loadNominas();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> aprobarNomina(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _nominaSeleccionada = await _service.aprobarNomina(id);
      await loadNominas();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pagarNomina(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _nominaSeleccionada = await _service.pagarNomina(id);
      await loadNominas();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> anularNomina(int id, {String? motivo}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _nominaSeleccionada = await _service.anularNomina(id, motivo: motivo);
      await loadNominas();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteNomina(int id) async {
    await _service.deleteNomina(id);
    _nominaSeleccionada = null;
    await loadNominas();
  }

  Future<NominaDetalle?> agregarConceptoDetalle(int nominaId, int detalleId, Map<String, dynamic> data) async {
    _nominaSeleccionada = await _service.agregarConceptoDetalle(nominaId, detalleId, data);
    await loadNominas();
    notifyListeners();
    try {
      return _nominaSeleccionada?.detalles.firstWhere((d) => d.id == detalleId);
    } catch (_) {
      return null;
    }
  }

  Future<NominaDetalle?> eliminarConceptoDetalle(int nominaId, int detalleId, int conceptoId) async {
    _nominaSeleccionada = await _service.eliminarConceptoDetalle(nominaId, detalleId, conceptoId);
    await loadNominas();
    notifyListeners();
    try {
      return _nominaSeleccionada?.detalles.firstWhere((d) => d.id == detalleId);
    } catch (_) {
      return null;
    }
  }

  // ── CONCEPTOS ─────────────────────────────────────────────
  Future<void> loadConceptos() async {
    try {
      _conceptos = await _service.getConceptos();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<NominaConcepto> createConcepto(Map<String, dynamic> data) async {
    final nuevo = await _service.createConcepto(data);
    await loadConceptos();
    return nuevo;
  }

  Future<void> updateConcepto(int id, Map<String, dynamic> data) async {
    await _service.updateConcepto(id, data);
    await loadConceptos();
  }

  Future<void> deleteConcepto(int id) async {
    await _service.deleteConcepto(id);
    await loadConceptos();
  }

  // ── RECURRENTES ───────────────────────────────────────────
  Future<void> loadRecurrentes() async {
    try {
      _recurrentes = await _service.getRecurrentes();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> createRecurrente(Map<String, dynamic> data) async {
    await _service.createRecurrente(data);
    await loadRecurrentes();
  }

  Future<void> deleteRecurrente(int id) async {
    await _service.deleteRecurrente(id);
    await loadRecurrentes();
  }

  // ── ESCALAS ISR DINÁMICAS (DGII) ──────────────────────────
  Future<void> loadEscalasIsr() async {
    try {
      final res = await _service.getEscalasIsr();
      final List rawEscalas = res['escalas'] is List ? res['escalas'] : [];
      final tramos = rawEscalas
          .map((e) => TramoIsrModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _escalasIsr = tramos;
      _tasaAfp = double.tryParse(res['tasa_afp']?.toString() ?? '') ?? 0.0287;
      _tasaArs = double.tryParse(res['tasa_ars']?.toString() ?? '') ?? 0.0304;

      NominaCalculator.setConfiguracionDinamica(
        tramos: tramos,
        tasaAfp: _tasaAfp,
        tasaArs: _tasaArs,
      );
      notifyListeners();
    } catch (_) {
      // Si la API falla temporalmente, NominaCalculator retiene el fallback 2026 sin interrumpir
    }
  }
}

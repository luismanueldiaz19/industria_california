import 'dart:async';
import 'package:flutter/material.dart';
import 'package:industria_california/core/widgets/compact_snack_bar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../../core/themes/app_theme.dart';
import '../../../core/utils/alerta_utils.dart';
import '../../../core/utils/app_date_picker_dark.dart';
import '../../../core/widgets/general_header.dart';
import '../../led_house/cxc/providers/cxc_provider.dart';
import '../models/cxc_alerta_model.dart';
import '../services/cxc_alerta_service.dart';
import '../widgets/alertas_filtros_bar.dart';
import '../widgets/alertas_data_table.dart';
import '../widgets/alertas_totals_bar.dart';
import '../widgets/alerta_gestion_dialog.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  final _service = CxcAlertaService();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<CxcAlertaModel> _alertas = [];
  bool _isLoading = true;

  // Estado de consulta: 'pendiente' (por defecto), 'procesada', 'todos'
  String _filtroEstado = 'pendiente';

  // Rango de fechas: por defecto null (para consultar todas las pendientes sin restricción)
  DateTime? _startDate;
  DateTime? _endDate;

  // Paginación y límite de filas
  int _currentPage = 1;
  int _limit = 20;
  int _totalRows = 0;
  int _lastPage = 1;

  // Filtros adicionales
  String _filtroVendedor = 'Todos';
  String _searchQuery = '';
  String _filtroTipo = 'Todos';

  List<String> _vendedores = ['Todos'];
  List<String> _tipos = ['Todos'];

  bool _soloRepetidas = false;
  Set<int> _facturasRepetidasIds = {};

  final Map<String, int> _mapaVendedores = {};
  final Map<String, String> _mapaTipos = {};

  @override
  void initState() {
    super.initState();
    _initTipos();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _initTipos() {
    _mapaTipos.clear();
    for (var t in AlertaUtils.tiposDeAlerta) {
      _mapaTipos[AlertaUtils.getTipoLabel(t)] = t;
    }
    _tipos = ['Todos', ..._mapaTipos.keys];
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      if (mounted) {
        await Provider.of<CxcProvider>(context, listen: false).fetchCxcs();
      }

      final startStr = _startDate != null
          ? DateFormat('yyyy-MM-dd').format(_startDate!)
          : null;
      final endStr = _endDate != null
          ? DateFormat('yyyy-MM-dd').format(_endDate!)
          : null;

      final String? tipoParam =
          (_filtroTipo != 'Todos' && _mapaTipos.containsKey(_filtroTipo))
          ? _mapaTipos[_filtroTipo]
          : null;

      final int? vendedorIdParam =
          (_filtroVendedor != 'Todos' &&
              _mapaVendedores.containsKey(_filtroVendedor))
          ? _mapaVendedores[_filtroVendedor]
          : null;

      final String estadoParam = _filtroEstado == 'todos'
          ? 'todos'
          : _filtroEstado;

      final res = await _service.getAlertas(
        estado: estadoParam,
        page: _currentPage,
        limit: _limit,
        startDate: startStr,
        endDate: endStr,
        tipo: tipoParam,
        vendedorId: vendedorIdParam,
        search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
      );

      List<CxcAlertaModel> lista = [];
      if (res is List) {
        lista = res.cast<CxcAlertaModel>();
        _totalRows = lista.length;
        _lastPage = 1;
      } else if (res is Map) {
        lista = (res['data'] as List).cast<CxcAlertaModel>();
        _totalRows = res['total'] ?? lista.length;
        _lastPage = res['last_page'] ?? 1;
      }

      if (mounted) {
        setState(() {
          _alertas = lista;
          _extraerVendedores(lista);
          _calcularRepetidas(lista);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _extraerVendedores(List<CxcAlertaModel> lista) {
    for (var a in lista) {
      if (a.vendedor != null) {
        _mapaVendedores[a.vendedor!.name] = a.vendedor!.id;
      }
    }

    _vendedores = ['Todos', ..._mapaVendedores.keys.toList()..sort()];
    if (!_vendedores.contains(_filtroVendedor)) {
      _filtroVendedor = 'Todos';
    }
  }

  void _calcularRepetidas(List<CxcAlertaModel> lista) {
    final Map<int, int> conteoFacturas = {};
    for (var a in lista) {
      if (a.cxc != null) {
        conteoFacturas[a.cxc!.id] = (conteoFacturas[a.cxc!.id] ?? 0) + 1;
      }
    }
    _facturasRepetidasIds = conteoFacturas.entries
        .where((e) => e.value > 1)
        .map((e) => e.key)
        .toSet();
  }

  List<CxcAlertaModel> get _alertasMostradas {
    if (!_soloRepetidas) return _alertas;
    return _alertas
        .where(
          (a) => a.cxc != null && _facturasRepetidasIds.contains(a.cxc!.id),
        )
        .toList();
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _currentPage = 1;
      _load();
    });
  }

  Future<void> _pickDateRange() async {
    final res = await AppDatePickerDark.showRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(start: DateTime.now(), end: DateTime.now()),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (res != null) {
      setState(() {
        _startDate = res.start;
        _endDate = res.end;
        _currentPage = 1;
      });
      _load();
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _currentPage = 1;
    });
    _load();
  }

  Future<void> _generarPdf() async {
    try {
      if (mounted) {
        CompactSnackBar.showInfo(context, 'Generando reporte PDF...');
      }

      Map<String, String> params = {};
      if (_filtroEstado != 'todos') {
        params['estado'] = _filtroEstado;
      }
      if (_startDate != null) {
        params['start_date'] = DateFormat('yyyy-MM-dd').format(_startDate!);
      }
      if (_endDate != null) {
        params['end_date'] = DateFormat('yyyy-MM-dd').format(_endDate!);
      }
      if (_filtroVendedor != 'Todos' &&
          _mapaVendedores[_filtroVendedor] != null) {
        params['vendedor_id'] = _mapaVendedores[_filtroVendedor].toString();
      }
      if (_searchQuery.trim().isNotEmpty) {
        params['search'] = _searchQuery.trim();
      }
      if (_filtroTipo != 'Todos' && _mapaTipos[_filtroTipo] != null) {
        params['tipo'] = _mapaTipos[_filtroTipo].toString();
      }

      final urlStr = await _service.getReporteAlertasPdfUrl(params);
      if (urlStr != null) {
        final url = Uri.parse(urlStr);
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          if (mounted) {
            CompactSnackBar.showError(context, 'No se pudo abrir el PDF');
          }
        }
      } else {
        if (mounted) {
          CompactSnackBar.showError(context, 'No se pudo generar la URL del reporte');
        }
      }
    } catch (e) {
      if (mounted) {
        CompactSnackBar.showError(context, 'Error al generar PDF: $e');
      }
    }
  }

  void _gestionarAlerta(CxcAlertaModel alerta) {
    AlertaGestionDialog.show(
      context: context,
      alerta: alerta,
      onUpdated: _load,
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppTheme.darkCardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Filas por pág: ',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
              DropdownButton<int>(
                value: _limit,
                dropdownColor: AppTheme.darkInputColor,
                underline: const SizedBox(),
                items: [20, 50, 100]
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          '$e',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _limit = v;
                      _currentPage = 1;
                    });
                    _load();
                  }
                },
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'Total: $_totalRows registros | Página $_currentPage de $_lastPage',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
              const SizedBox(width: 14),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 18),
                color: _currentPage > 1 ? Colors.white : Colors.grey,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _currentPage > 1
                    ? () {
                        setState(() => _currentPage--);
                        _load();
                      }
                    : null,
              ),
              const SizedBox(width: 14),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 18),
                color: _currentPage < _lastPage ? Colors.white : Colors.grey,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _currentPage < _lastPage
                    ? () {
                        setState(() => _currentPage++);
                        _load();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalInformado = _alertasMostradas.fold(
      0.0,
      (sum, a) => sum + (a.montoInformado ?? 0.0),
    );

    double totalPendiente = 0.0;
    if (mounted) {
      final globalCxcs = Provider.of<CxcProvider>(context, listen: false).cxcs;
      for (var cxc in globalCxcs) {
        bool matches = true;
        if (_filtroVendedor != 'Todos') {
          if (cxc.vendedorId != _mapaVendedores[_filtroVendedor]) {
            matches = false;
          }
        }
        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.trim().toLowerCase();
          final nombre = cxc.cliente.toLowerCase();
          final cxcDoc = cxc.documento.toLowerCase();
          if (!(nombre.contains(q) || cxcDoc.contains(q))) {
            matches = false;
          }
        }
        if (matches) {
          totalPendiente += cxc.montoPendiente;
        }
      }
    }

    final double montoReal = totalPendiente - totalInformado;

    return Scaffold(
      backgroundColor: AppTheme.darkBgColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GeneralHeader(
            title: 'Alertas de Vendedores',
            subtitle: 'Revisar y procesar alertas CXC',
            icon: Icons.notifications_active_rounded,
            iconColor: Colors.orange.shade500,
            actions: [
              HeaderButton(
                icon: Icons.picture_as_pdf_rounded,
                tooltip: 'Exportar PDF',
                color: Colors.redAccent,
                onTap: _generarPdf,
              ),
              HeaderButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Actualizar',
                onTap: _load,
              ),
            ],
          ),
          AlertasFiltrosBar(
            vendedores: _vendedores,
            tipos: _tipos,
            filtroVendedor: _filtroVendedor,
            filtroTipo: _filtroTipo,
            filtroEstado: _filtroEstado,
            soloRepetidas: _soloRepetidas,
            searchController: _searchController,
            startDate: _startDate,
            endDate: _endDate,
            onPickDateRange: _pickDateRange,
            onClearDateRange: _clearDateRange,
            onChangedVendedor: (v) {
              if (v != null) {
                setState(() {
                  _filtroVendedor = v;
                  _currentPage = 1;
                });
                _load();
              }
            },
            onSearchChanged: _onSearchChanged,
            onChangedTipo: (v) {
              if (v != null) {
                setState(() {
                  _filtroTipo = v;
                  _currentPage = 1;
                });
                _load();
              }
            },
            onChangedEstado: (v) {
              if (v != null) {
                setState(() {
                  _filtroEstado = v;
                  _currentPage = 1;
                });
                _load();
              }
            },
            onChangedSoloRepetidas: (v) => setState(() => _soloRepetidas = v),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppTheme.ledhouseBlue),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _load,
                          color: AppTheme.ledhouseBlue,
                          child: AlertasDataTable(
                            alertas: _alertasMostradas,
                            filtroEstado: _filtroEstado,
                            facturasRepetidasIds: _facturasRepetidasIds,
                            onGestionarAlerta: _gestionarAlerta,
                          ),
                        ),
                      ),
                      if (_totalRows > 0) _buildPaginationControls(),
                      if (_alertasMostradas.isNotEmpty)
                        AlertasTotalsBar(
                          totalInformado: totalInformado,
                          totalPendiente: totalPendiente,
                          montoReal: montoReal,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

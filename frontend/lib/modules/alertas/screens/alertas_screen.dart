import 'package:flutter/material.dart';
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

class _AlertasScreenState extends State<AlertasScreen>
    with SingleTickerProviderStateMixin {
  final _service = CxcAlertaService();

  late TabController _tabController;
  List<CxcAlertaModel> _alertasPendientes = [];
  List<CxcAlertaModel> _alertasProcesadas = [];
  bool _isLoading = true;

  // Paginación y fechas para Procesadas
  DateTime? _startDate = DateTime.now();
  DateTime? _endDate = DateTime.now();
  int _currentPage = 1;
  int _limit = 20;
  int _totalRows = 0;
  int _lastPage = 1;

  // Filtros
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
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      if (mounted) {
        await Provider.of<CxcProvider>(context, listen: false).fetchCxcs();
      }

      final pendientesRes = await _service.getAlertas(estado: 'pendiente');
      List<CxcAlertaModel> pendientes = [];
      if (pendientesRes is List) {
        pendientes = pendientesRes.cast<CxcAlertaModel>();
      } else if (pendientesRes is Map) {
        pendientes = (pendientesRes['data'] as List).cast<CxcAlertaModel>();
      }

      final startStr = _startDate != null
          ? DateFormat('yyyy-MM-dd').format(_startDate!)
          : null;
      final endStr = _endDate != null
          ? DateFormat('yyyy-MM-dd').format(_endDate!)
          : null;

      final procesadasRes = await _service.getAlertas(
        estado: 'procesada',
        page: _currentPage,
        limit: _limit,
        startDate: startStr,
        endDate: endStr,
      );

      List<CxcAlertaModel> procesadas = [];
      if (procesadasRes is List) {
        procesadas = procesadasRes.cast<CxcAlertaModel>();
      } else if (procesadasRes is Map) {
        procesadas = (procesadasRes['data'] as List).cast<CxcAlertaModel>();
        _totalRows = procesadasRes['total'] ?? 0;
        _lastPage = procesadasRes['last_page'] ?? 1;
      }

      if (mounted) {
        setState(() {
          _alertasPendientes = pendientes;
          _alertasProcesadas = procesadas;
          _extraerFiltros();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _extraerFiltros() {
    _mapaVendedores.clear();
    _mapaTipos.clear();

    final Map<int, int> conteoFacturas = {};
    final todos = [..._alertasPendientes, ..._alertasProcesadas];

    for (var a in todos) {
      if (a.cxc != null) {
        conteoFacturas[a.cxc!.id] = (conteoFacturas[a.cxc!.id] ?? 0) + 1;
      }

      if (a.vendedor != null) {
        _mapaVendedores[a.vendedor!.name] = a.vendedor!.id;
      }
      if (a.tipo.isNotEmpty) {
        _mapaTipos[AlertaUtils.getTipoLabel(a.tipo)] = a.tipo;
      }
    }

    _facturasRepetidasIds = conteoFacturas.entries
        .where((e) => e.value > 1)
        .map((e) => e.key)
        .toSet();

    _vendedores = ['Todos', ..._mapaVendedores.keys.toList()..sort()];
    _tipos = ['Todos', ..._mapaTipos.keys.toList()..sort()];

    if (!_vendedores.contains(_filtroVendedor)) _filtroVendedor = 'Todos';
    if (!_tipos.contains(_filtroTipo)) _filtroTipo = 'Todos';
  }

  List<CxcAlertaModel> _filtrarLista(List<CxcAlertaModel> lista) {
    return lista.where((a) {
      final matchVendedor =
          _filtroVendedor == 'Todos' || (a.vendedor?.name == _filtroVendedor);
      final matchTipo =
          _filtroTipo == 'Todos' ||
          (AlertaUtils.getTipoLabel(a.tipo) == _filtroTipo);

      bool matchSearch = true;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nombre = a.cxc?.cliente?.nombre.toLowerCase() ?? '';
        final fact = a.cxc?.noFactura.toLowerCase() ?? '';
        matchSearch = nombre.contains(q) || fact.contains(q);
      }

      if (!(matchVendedor && matchSearch && matchTipo)) return false;

      if (_soloRepetidas) {
        if (a.cxc == null || !_facturasRepetidasIds.contains(a.cxc!.id)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _generarPdf() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Generando reporte PDF...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      String estado = _tabController.index == 0 ? "pendiente" : "procesada";
      Map<String, String> params = {'estado': estado};

      if (_filtroVendedor != 'Todos' &&
          _mapaVendedores[_filtroVendedor] != null) {
        params['vendedor_id'] = _mapaVendedores[_filtroVendedor].toString();
      }
      if (_searchQuery.isNotEmpty) {
        params['search'] = _searchQuery;
      }
      if (_filtroTipo != 'Todos' && _mapaTipos[_filtroTipo] != null) {
        params['tipo'] = _mapaTipos[_filtroTipo].toString();
      }

      final urlStr = await _service.getReporteAlertasPdfUrl(params);
      if (urlStr != null) {
        final url = Uri.parse(urlStr);
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo abrir el PDF'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo generar la URL del reporte'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
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

  Widget _buildProcesadasFilters() {
    final format = DateFormat('dd-MM-yyyy');
    final startStr = _startDate != null ? format.format(_startDate!) : '-';
    final endStr = _endDate != null ? format.format(_endDate!) : '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppTheme.darkCardColor,
      child: Row(
        children: [
          Text(
            'Fechas:',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _pickDateRange,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.darkBorderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 13,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$startStr  →  $endStr',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.redAccent, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  _startDate = DateTime.now();
                  _endDate = DateTime.now();
                  _currentPage = 1;
                });
                _load();
              },
            ),
          const Spacer(),
          Text(
            'Filas: ',
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
                      style: const TextStyle(color: Colors.white, fontSize: 11),
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
    );
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

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppTheme.darkCardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
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
    );
  }

  Widget _buildAlertasListTab(
    List<CxcAlertaModel> alertas, {
    required bool isPendiente,
  }) {
    final double totalInformado = alertas.fold(
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
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
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

    return Column(
      children: [
        if (!isPendiente) _buildProcesadasFilters(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppTheme.ledhouseBlue,
            child: AlertasDataTable(
              alertas: alertas,
              isPendiente: isPendiente,
              facturasRepetidasIds: _facturasRepetidasIds,
              onGestionarAlerta: _gestionarAlerta,
            ),
          ),
        ),
        if (!isPendiente && _alertasProcesadas.isNotEmpty)
          _buildPaginationControls(),
        if (alertas.isNotEmpty)
          AlertasTotalsBar(
            totalInformado: totalInformado,
            totalPendiente: totalPendiente,
            montoReal: montoReal,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
            searchQuery: _searchQuery,
            filtroTipo: _filtroTipo,
            soloRepetidas: _soloRepetidas,
            onChangedVendedor: (v) => setState(() => _filtroVendedor = v!),
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onChangedTipo: (v) => setState(() => _filtroTipo = v!),
            onChangedSoloRepetidas: (v) => setState(() => _soloRepetidas = v),
          ),
          Container(
            color: AppTheme.darkCardColor,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.ledhouseBlue,
              unselectedLabelColor: Colors.grey.shade500,
              indicatorColor: AppTheme.ledhouseBlue,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pending_actions, size: 15),
                      const SizedBox(width: 6),
                      const Text('Pendientes'),
                      if (_alertasPendientes.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_alertasPendientes.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 15),
                      SizedBox(width: 6),
                      Text('Procesadas'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppTheme.ledhouseBlue),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAlertasListTab(
                        _filtrarLista(_alertasPendientes),
                        isPendiente: true,
                      ),
                      _buildAlertasListTab(
                        _filtrarLista(_alertasProcesadas),
                        isPendiente: false,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

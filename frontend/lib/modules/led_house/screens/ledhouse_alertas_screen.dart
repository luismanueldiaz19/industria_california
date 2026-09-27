import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../../core/themes/app_theme.dart';
import '../../../core/utils/alerta_utils.dart';
import '../../../core/utils/constants.dart';
import '../../../core/services/http_service.dart';
import '../../../core/widgets/general_header.dart';
import '../../../core/widgets/zoom_dialog.dart';
import '../cxc/providers/cxc_provider.dart';
import '../models/cxc_alerta_model.dart';
import '../services/ledhouse_cxc_alerta_service.dart';

import '../widgets/alertas/ledhouse_alertas_filtros_bar.dart';
import '../widgets/alertas/ledhouse_alertas_data_table.dart';
import '../widgets/alertas/ledhouse_alertas_totals_bar.dart';
import '../widgets/alertas/ledhouse_alerta_procesar_dialog.dart';

class LedhouseAlertasScreen extends StatefulWidget {
  const LedhouseAlertasScreen({super.key});

  @override
  State<LedhouseAlertasScreen> createState() => _LedhouseAlertasScreenState();
}

class _LedhouseAlertasScreenState extends State<LedhouseAlertasScreen>
    with SingleTickerProviderStateMixin {
  final _service = LedhouseCxcAlertaService();

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

      final queryStr = Uri(queryParameters: params).query;
      final endpoint = 'ledhouse/cxc/alertas-pdf-url?$queryStr';

      final res = await HttpService().get(endpoint);
      final url = Uri.parse(res['url']);

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

  Future<void> _resolverAlerta(
    CxcAlertaModel alerta,
    String estadoAlerta,
  ) async {
    try {
      await _service.resolverAlerta(
        alertaId: alerta.id,
        estadoAlerta: estadoAlerta,
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _eliminarAlerta(CxcAlertaModel alerta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.darkBorderColor),
        ),
        title: const Text(
          'Eliminar Alerta',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta alerta? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _service.deleteAlerta(alerta.id);
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alerta eliminada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogoProcesar(CxcAlertaModel alerta) {
    showDialog(
      context: context,
      builder: (ctx) => LedhouseAlertaProcesarDialog(
        alerta: alerta,
        onProcesar: (actualizarCxc, montoPagado, estadoCxc) async {
          try {
            await _service.resolverAlerta(
              alertaId: alerta.id,
              estadoAlerta: 'procesada',
              actualizarCxc: actualizarCxc,
              montoPagado: montoPagado,
              estadoCxc: estadoCxc,
            );
            if (actualizarCxc && mounted) {
              Provider.of<CxcProvider>(context, listen: false).fetchCxcs();
            }
            _load();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Alerta procesada correctamente'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  void _verEvidencias(List<EvidenciaModel> evidencias) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.darkBorderColor),
        ),
        title: const Text(
          'Evidencias Adjuntas',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: evidencias.map((ev) {
              return ActionChip(
                backgroundColor: AppTheme.darkInputColor,
                side: BorderSide(color: AppTheme.darkBorderColor),
                avatar: Icon(
                  ev.isImage ? Icons.image_outlined : Icons.picture_as_pdf,
                  size: 16,
                  color: Colors.redAccent,
                ),
                label: Text(
                  ev.nombreArchivo,
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  final ruta = ev.rutaArchivo;
                  if (ruta.isNotEmpty) {
                    final url = Uri.parse('$host/storage/$ruta');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _verNota(CxcAlertaModel alerta, Color tipoColor) {
    ZoomDialog.show(
      context: context,
      title: 'Nota de alerta',
      content: alerta.nota!,
      icon: Icons.comment_rounded,
      iconColor: tipoColor,
    );
  }

  void _editarConcepto(CxcAlertaModel alerta) {
    String nuevoTipo = alerta.tipo;
    final screenContext = context;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (statefulCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.darkCardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppTheme.darkBorderColor),
              ),
              title: const Text(
                'Actualizar Concepto',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              content: DropdownButtonFormField<String>(
                value: nuevoTipo,
                dropdownColor: AppTheme.darkCardColor,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.darkInputColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: AlertaUtils.tiposDeAlerta
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          AlertaUtils.getTipoLabel(t),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => nuevoTipo = val);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    final success = await _service.updateTipoAlerta(
                      alertaId: alerta.id,
                      nuevoTipo: nuevoTipo,
                    );
                    if (!mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(screenContext).showSnackBar(
                        const SnackBar(
                          content: Text('Concepto actualizado'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _load();
                    } else {
                      ScaffoldMessenger.of(screenContext).showSnackBar(
                        const SnackBar(
                          content: Text('Error al actualizar concepto'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Actualizar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProcesadasFilters() {
    final format = DateFormat('dd-MM-yyyy');
    final startStr = _startDate != null ? format.format(_startDate!) : '-';
    final endStr = _endDate != null ? format.format(_endDate!) : '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.darkCardColor,
      child: Row(
        children: [
          Text(
            'Fechas:',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _pickDateRange,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.darkBorderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$startStr  →  $endStr',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.redAccent, size: 18),
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
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
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
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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
    final res = await showDateRangePicker(
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.darkCardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Total: $_totalRows registros | Página $_currentPage de $_lastPage',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_left),
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
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_right),
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
            child: LedhouseAlertasDataTable(
              alertas: alertas,
              isPendiente: isPendiente,
              facturasRepetidasIds: _facturasRepetidasIds,
              onResolverAlerta: _resolverAlerta,
              onEliminarAlerta: _eliminarAlerta,
              onProcesarAlerta: _mostrarDialogoProcesar,
              onVerEvidencias: _verEvidencias,
              onVerNota: _verNota,
              onEditarConcepto: _editarConcepto,
            ),
          ),
        ),
        if (!isPendiente && _alertasProcesadas.isNotEmpty)
          _buildPaginationControls(),
        if (alertas.isNotEmpty)
          LedhouseAlertasTotalsBar(
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
          LedhouseAlertasFiltrosBar(
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
                fontSize: 13,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pending_actions, size: 16),
                      const SizedBox(width: 6),
                      const Text('Pendientes'),
                      if (_alertasPendientes.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_alertasPendientes.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
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
                      Icon(Icons.check_circle_outline, size: 16),
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

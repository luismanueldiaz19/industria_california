import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/constants.dart';
import '../models/cxc_alerta_model.dart';
import '../services/ledhouse_cxc_alerta_service.dart';
import '../../../../widgets/general_header.dart';
import '../../../../widgets/zoom_dialog.dart';
import 'package:provider/provider.dart';
import '../cxc/providers/cxc_provider.dart';
import '../../../../services/http_service.dart';

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

  // Filtros
  String _filtroVendedor = 'Todos';
  String _filtroCliente = 'Todos';
  String _filtroTipo = 'Todos';

  List<String> _vendedores = ['Todos'];
  List<String> _clientes = ['Todos'];
  List<String> _tipos = ['Todos'];

  bool _soloRepetidas = false;
  Set<int> _facturasRepetidasIds = {};

  final Map<String, int> _mapaVendedores = {};
  final Map<String, int> _mapaClientes = {};
  final Map<String, String> _mapaTipos = {};

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_US', symbol: '\$').format(amount);
  }

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
      final pendientes = await _service.getAlertas(estado: 'pendiente');
      final procesadas = await _service.getAlertas(estado: 'procesada');
      setState(() {
        _alertasPendientes = pendientes;
        _alertasProcesadas = procesadas;
        _extraerFiltros();
      });
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _extraerFiltros() {
    _mapaVendedores.clear();
    _mapaClientes.clear();
    _mapaTipos.clear();

    final Map<int, int> conteoFacturas = {};
    final todos = [..._alertasPendientes, ..._alertasProcesadas];

    for (var a in todos) {
      if (a.cxc != null) {
        conteoFacturas[a.cxc!.id] = (conteoFacturas[a.cxc!.id] ?? 0) + 1;
      }

      if (a.vendedor != null && a.vendedor!.name != null) {
        _mapaVendedores[a.vendedor!.name!] = a.vendedor!.id;
      }
      if (a.cxc?.cliente != null && a.cxc!.cliente!.nombre != null) {
        _mapaClientes[a.cxc!.cliente!.nombre!] = a.cxc!.cliente!.id;
      }
      if (a.tipo.isNotEmpty) {
        _mapaTipos[_tipoLabel(a.tipo)] = a.tipo;
      }
    }

    _facturasRepetidasIds = conteoFacturas.entries
        .where((e) => e.value > 1)
        .map((e) => e.key)
        .toSet();

    _vendedores = ['Todos', ..._mapaVendedores.keys.toList()..sort()];
    _clientes = ['Todos', ..._mapaClientes.keys.toList()..sort()];
    _tipos = ['Todos', ..._mapaTipos.keys.toList()..sort()];

    if (!_vendedores.contains(_filtroVendedor)) _filtroVendedor = 'Todos';
    if (!_clientes.contains(_filtroCliente)) _filtroCliente = 'Todos';
    if (!_tipos.contains(_filtroTipo)) _filtroTipo = 'Todos';
  }

  List<CxcAlertaModel> _filtrarLista(List<CxcAlertaModel> lista) {
    return lista.where((a) {
      final matchVendedor =
          _filtroVendedor == 'Todos' || (a.vendedor?.name == _filtroVendedor);
      final matchCliente =
          _filtroCliente == 'Todos' ||
          (a.cxc?.cliente?.nombre == _filtroCliente);
      final matchTipo =
          _filtroTipo == 'Todos' || (_tipoLabel(a.tipo) == _filtroTipo);

      if (!(matchVendedor && matchCliente && matchTipo)) return false;

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

      if (_filtroVendedor != 'Todos' && _mapaVendedores[_filtroVendedor] != null) {
        params['vendedor_id'] = _mapaVendedores[_filtroVendedor].toString();
      }
      if (_filtroCliente != 'Todos' && _mapaClientes[_filtroCliente] != null) {
        params['cliente_id'] = _mapaClientes[_filtroCliente].toString();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
          _buildFiltrosBar(),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.ledhouseBlue,
              unselectedLabelColor: Colors.grey,
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
                            color: Colors.red,
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
                      _buildAlertasList(
                        _filtrarLista(_alertasPendientes),
                        isPendiente: true,
                      ),
                      _buildAlertasList(
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

  Widget _buildFiltrosBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdownFiltro(
                  'Vendedor',
                  _vendedores,
                  _filtroVendedor,
                  (v) {
                    setState(() => _filtroVendedor = v!);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdownFiltro(
                  'Cliente',
                  _clientes,
                  _filtroCliente,
                  (v) {
                    setState(() => _filtroCliente = v!);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdownFiltro('Tipo', _tipos, _filtroTipo, (v) {
                  setState(() => _filtroTipo = v!);
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "Mostrar solo facturas con múltiples alertas",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 24,
                child: Switch(
                  value: _soloRepetidas,
                  onChanged: (v) => setState(() => _soloRepetidas = v),
                  activeColor: AppTheme.ledhouseBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFiltro(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey.shade400,
                size: 18,
              ),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              onChanged: onChanged,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertasList(
    List<CxcAlertaModel> alertas, {
    required bool isPendiente,
  }) {
    if (alertas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPendiente
                  ? Icons.notifications_none
                  : Icons.check_circle_outline,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isPendiente ? 'Sin alertas pendientes' : 'Sin alertas procesadas',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black45,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

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
          if (cxc.vendedorId != _mapaVendedores[_filtroVendedor])
            matches = false;
        }
        if (_filtroCliente != 'Todos') {
          if (cxc.clienteId != _mapaClientes[_filtroCliente]) matches = false;
        }
        if (matches) {
          totalPendiente += cxc.montoPendiente;
        }
      }
    }

    final double montoReal = totalPendiente - totalInformado;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width,
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.grey.shade100,
                          dataTableTheme: DataTableThemeData(
                            headingRowColor: WidgetStateProperty.all(
                              const Color(0xFFF9FAFB),
                            ),
                            dataRowColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.hovered)) {
                                return Colors.blue.withValues(alpha: 0.04);
                              }
                              return Colors.white;
                            }),
                          ),
                        ),
                        child: DataTable(
                          dataRowMinHeight: 60,
                          dataRowMaxHeight: 85,
                          columnSpacing: 24,
                          headingRowHeight: 48,
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                          columns: const [
                            DataColumn(label: Text('FECHA')),
                            DataColumn(label: Text('CLIENTE')),
                            DataColumn(label: Text('CONCEPTO')),
                            DataColumn(label: Text('FACTURA')),
                            DataColumn(label: Text('MONTO')),
                            DataColumn(label: Text('ACCIONES')),
                          ],
                          rows: alertas
                              .map(
                                (alerta) => _buildDataRow(alerta, isPendiente),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTotalItem('Monto Informado', totalInformado, Colors.blue),
              Container(width: 1, height: 30, color: Colors.grey.shade300),
              _buildTotalItem(
                'Monto Pendiente',
                totalPendiente,
                const Color(0xFFFB8C00),
              ),
              Container(width: 1, height: 30, color: Colors.grey.shade300),
              _buildTotalItem('Monto Real', montoReal, AppTheme.successColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalItem(String label, double amount, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  DataRow _buildDataRow(CxcAlertaModel alerta, bool isPendiente) {
    final tipo = alerta.tipo;
    final cxc = alerta.cxc;
    final cliente = cxc?.cliente;

    Color tipoColor;
    switch (tipo) {
      case 'pago_recibido':
        tipoColor = Colors.green;
        break;
      case 'consulta':
        tipoColor = Colors.blue;
        break;
      case 'credito':
      case 'debito':
      case 'devolucion':
      case 'retencion':
        tipoColor = Colors.purple;
        break;
      default:
        tipoColor = Colors.orange;
    }

    final listaEvidencias = <EvidenciaModel>[];
    final idsVistos = <int>{};
    for (var ev in alerta.evidencias) {
      if (!idsVistos.contains(ev.id)) {
        listaEvidencias.add(ev);
        idsVistos.add(ev.id);
      }
    }
    if (alerta.cxc?.evidencias != null) {
      for (var ev in alerta.cxc!.evidencias) {
        if (!idsVistos.contains(ev.id)) {
          listaEvidencias.add(ev);
          idsVistos.add(ev.id);
        }
      }
    }

    return DataRow(
      cells: [
        DataCell(
          Text(
            _formatTimestamp(alerta.createdAt),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        DataCell(
          Text(
            cliente?.nombre ?? '-',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 13,
            ),
          ),
        ),
        DataCell(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: tipoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_offer_rounded,
                        size: 12,
                        color: tipoColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _tipoLabel(tipo),
                        style: TextStyle(
                          color: tipoColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (alerta.nota != null && alerta.nota!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () {
                      ZoomDialog.show(
                        context: context,
                        title: 'Nota de alerta',
                        content: alerta.nota!,
                        icon: Icons.comment_rounded,
                        iconColor: tipoColor,
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.comment_rounded,
                            size: 13,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ver nota',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cxc?.noFactura ?? '-',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.blueGrey.shade800,
                ),
              ),
              if (cxc != null && _facturasRepetidasIds.contains(cxc.id))
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Tooltip(
                    message: 'Esta factura tiene múltiples alertas',
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        DataCell(
          Text(
            alerta.montoInformado != null
                ? _formatCurrency(alerta.montoInformado!)
                : '-',
            style: const TextStyle(
              fontWeight: FontWeight.w800, // Thicker font
              fontSize: 14,
              color: Colors.green,
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPendiente) ...[
                IconButton(
                  icon: const Icon(
                    Icons.visibility_outlined,
                    color: Colors.orange,
                    size: 20,
                  ),
                  tooltip: 'Marcar revisada (Mover a procesadas)',
                  onPressed: () =>
                      _resolverAlerta(alerta, estadoAlerta: 'procesada'),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  tooltip: 'Eliminar alerta',
                  onPressed: () => _eliminarAlerta(alerta),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: Colors.blue,
                    size: 20,
                  ),
                  tooltip: 'Procesar',
                  onPressed: () => _mostrarDialogoProcesar(alerta),
                ),
              ] else ...[
                Tooltip(
                  message: 'Procesada por ${alerta.revisador?.name ?? '-'}',
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  tooltip: 'Eliminar alerta',
                  onPressed: () => _eliminarAlerta(alerta),
                ),
              ],
              if (listaEvidencias.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.attach_file,
                    color: Colors.red,
                    size: 20,
                  ),
                  tooltip: 'Ver evidencias',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Evidencias Adjuntas'),
                        content: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: listaEvidencias.map((ev) {
                              return ActionChip(
                                avatar: Icon(
                                  ev.isImage
                                      ? Icons.image_outlined
                                      : Icons.picture_as_pdf,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                label: Text(ev.nombreArchivo),
                                onPressed: () async {
                                  final ruta = ev.rutaArchivo;
                                  if (ruta.isNotEmpty) {
                                    final url = Uri.parse(
                                      '$host/storage/$ruta',
                                    );
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
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _resolverAlerta(
    CxcAlertaModel alerta, {
    required String estadoAlerta,
  }) async {
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
        title: const Text('Eliminar Alerta'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta alerta? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
    final montoController = TextEditingController(
      text: alerta.montoInformado?.toString() ?? '',
    );
    String estadoCxc = 'pendiente';
    bool actualizarCxc = alerta.tipo == 'pago_recibido';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit_rounded, color: Color(0xFF1A73E8)),
              SizedBox(width: 10),
              Text('Procesar Alerta', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Actualizar CXC',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Aplicar cambios en la factura',
                  style: TextStyle(fontSize: 12),
                ),
                value: actualizarCxc,
                activeColor: AppTheme.ledhouseBlue,
                onChanged: (v) => setDialogState(() => actualizarCxc = v),
              ),
              if (actualizarCxc) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: montoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monto pagado a registrar',
                    prefixIcon: const Icon(Icons.attach_money),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: estadoCxc,
                  decoration: InputDecoration(
                    labelText: 'Nuevo estado del CXC',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'pendiente',
                      child: Text('Pendiente'),
                    ),
                    DropdownMenuItem(value: 'pagado', child: Text('Pagado')),
                    DropdownMenuItem(
                      value: 'cancelado',
                      child: Text('Cancelado'),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => estadoCxc = v!),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _service.resolverAlerta(
                    alertaId: alerta.id,
                    estadoAlerta: 'procesada',
                    actualizarCxc: actualizarCxc,
                    montoPagado:
                        actualizarCxc && montoController.text.isNotEmpty
                        ? double.tryParse(montoController.text)
                        : null,
                    estadoCxc: actualizarCxc ? estadoCxc : null,
                  );
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
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.ledhouseBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Procesar y Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'pago_recibido':
        return '💵 Pago Recibido';
      case 'credito':
        return '💳 Nota de credito';
      case 'debito':
        return '🧾 Nota de débito';
      case 'devolucion':
        return '↩️ Devolución';
      case 'retencion':
        return '✂️ Retención';
      case 'diferencia':
        return '⚖️ Diferencia de Precio';
      case 'mer_no_entregada':
        return '📦 Mercancía No Entregada';
      case 'anular':
        return '❌ Anular Factura';
      case 'consulta':
        return '❓ Consulta';
      case 'informacion':
      default:
        return '📝 Información';
    }
  }

  String _formatTimestamp(String? ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts).toLocal();
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (_) {
      return ts;
    }
  }
}

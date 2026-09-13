import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/constants.dart';
import '../../../../services/http_service.dart';
import '../../../../widgets/general_header.dart';
import '../../../../widgets/zoom_dialog.dart';
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
      final pendientes = await _service.getAlertas(estado: 'pendiente');
      final procesadas = await _service.getAlertas(estado: 'procesada');
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
        _mapaTipos[_tipoLabel(a.tipo)] = a.tipo;
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
          _filtroTipo == 'Todos' || (_tipoLabel(a.tipo) == _filtroTipo);

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
            ),
          ),
        ),
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

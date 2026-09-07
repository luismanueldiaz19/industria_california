import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/constants.dart';
import '../models/cxc_alerta_model.dart';
import '../services/ledhouse_cxc_alerta_service.dart';

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

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_US', symbol: '\$').format(amount);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final pendientes = await _service.getAlertas(estado: 'pendiente');
      final procesadas = await _service.getAlertas(estado: 'procesada');
      setState(() {
        _alertasPendientes = pendientes;
        _alertasProcesadas = procesadas;
      });
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                color: Colors.orange.shade700,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alertas de Vendedores',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Revisar y procesar alertas CXC',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
                onPressed: _load,
              ),
              if (_alertasPendientes.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${_alertasPendientes.length > 9 ? '9+' : _alertasPendientes.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAlertasList(_alertasPendientes, isPendiente: true),
                _buildAlertasList(_alertasProcesadas, isPendiente: false),
              ],
            ),
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

    final double totalSuma = alertas.fold(
      0.0,
      (sum, a) => sum + (a.montoInformado ?? 0.0),
    );

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 70,
                  columnSpacing: 24,
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
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
                      .map((alerta) => _buildDataRow(alerta, isPendiente))
                      .toList(),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPendiente ? 'Total Pendiente:' : 'Total Procesado:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Text(
                _formatCurrency(totalSuma),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
            ],
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
        DataCell(Text(_formatTimestamp(alerta.createdAt))),
        DataCell(Text(cliente?.nombre ?? '-')),
        DataCell(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tipoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _tipoLabel(tipo),
                    style: TextStyle(
                      color: tipoColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (alerta.nota != null && alerta.nota!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 200,
                    child: Text(
                      alerta.nota!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        DataCell(Text(cxc?.noFactura ?? '-')),
        DataCell(
          Text(
            alerta.montoInformado != null
                ? _formatCurrency(alerta.montoInformado!)
                : '-',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
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
                  tooltip: 'Marcar revisada',
                  onPressed: () =>
                      _resolverAlerta(alerta, estadoAlerta: 'revisada'),
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
      return DateFormat('dd-MM-yyyy HH:mm').format(dt);
    } catch (_) {
      return ts;
    }
  }
}

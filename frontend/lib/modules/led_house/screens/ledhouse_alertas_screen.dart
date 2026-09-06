import 'package:flutter/material.dart';
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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alertas.length,
        itemBuilder: (_, i) =>
            _buildAlertaCard(alertas[i], isPendiente: isPendiente),
      ),
    );
  }

  Widget _buildAlertaCard(CxcAlertaModel alerta, {required bool isPendiente}) {
    final tipo = alerta.tipo;
    final vendedor = alerta.vendedor;
    final cxc = alerta.cxc;
    final cliente = cxc?.cliente;

    Color tipoColor;
    IconData tipoIcon;
    switch (tipo) {
      case 'pago_recibido':
        tipoColor = Colors.green;
        tipoIcon = Icons.payments_rounded;
        break;
      case 'consulta':
        tipoColor = Colors.blue;
        tipoIcon = Icons.help_outline_rounded;
        break;
      default:
        tipoColor = Colors.orange;
        tipoIcon = Icons.info_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tipoColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header coloreado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: tipoColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(tipoIcon, color: tipoColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  _tipoLabel(tipo),
                  style: TextStyle(
                    color: tipoColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(alerta.createdAt),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info del CXC y Cliente
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.receipt_long_outlined,
                        cxc?.noFactura ?? '-',
                        Colors.blueGrey,
                      ),
                    ),
                    if (cliente != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoChip(
                          Icons.person_outline,
                          cliente.nombre,
                          Colors.blueGrey,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Vendedor y Monto
                Row(
                  children: [
                    if (vendedor != null) ...[
                      const Icon(
                        Icons.assignment_ind_outlined,
                        size: 14,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        vendedor.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.purple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (alerta.montoInformado != null) ...[
                      _buildInfoChip(
                        Icons.attach_money,
                        '\$${alerta.montoInformado}',
                        Colors.green,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Nota
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    alerta.nota ?? '',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),

                // Evidencias
                // Evidencias
                Builder(
                  builder: (context) {
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

                    if (listaEvidencias.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          children: listaEvidencias.map<Widget>((ev) {
                            return ActionChip(
                              avatar: Icon(
                                ev.isImage
                                    ? Icons.image_outlined
                                    : Icons.picture_as_pdf,
                                size: 14,
                                color: Colors.red,
                              ),
                              label: Text(
                                ev.nombreArchivo,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black87,
                                ),
                              ),
                              backgroundColor: Colors.red.shade50,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              side: BorderSide(color: Colors.red.shade200),
                              onPressed: () async {
                                final ruta = ev.rutaArchivo;
                                if (ruta.isNotEmpty) {
                                  final url = Uri.parse('$host/storage/$ruta');
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'No se pudo abrir el archivo',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),

                // Acciones (solo si pendiente)
                if (isPendiente) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _resolverAlerta(alerta, estadoAlerta: 'revisada'),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text(
                            'Marcar revisada',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _mostrarDialogoProcesar(alerta),
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text(
                            'Procesar',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.ledhouseBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Procesada por ${alerta.revisador?.name ?? '-'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
        return '💰 Pago Recibido';
      case 'consulta':
        return '❓ Consulta';
      default:
        return '📋 Información';
    }
  }

  String _formatTimestamp(String? ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts;
    }
  }
}

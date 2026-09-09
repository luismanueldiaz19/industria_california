import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/auth_provider.dart';
import '../../../core/app_theme.dart';
import '../services/vendedor_cxc_service.dart';
import 'package:intl/intl.dart';

class VendedorActividadScreen extends StatefulWidget {
  const VendedorActividadScreen({super.key});

  @override
  State<VendedorActividadScreen> createState() => _VendedorActividadScreenState();
}

class _VendedorActividadScreenState extends State<VendedorActividadScreen> {
  final _service = VendedorCxcService();
  List<dynamic> _alertas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    try {
      final data = await _service.getMisAlertas(token: token);
      setState(() {
        _alertas = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Color _estadoColor(String estado) {
    if (estado == 'pendiente') return Colors.orange;
    if (estado == 'revisada') return Colors.blue;
    if (estado == 'procesada') return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final themeStyle = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text(
          'Actividades',
          style: themeStyle.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {
            setState(() => _isLoading = true);
            _load();
          }),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alertas.isEmpty
              ? const Center(child: Text('No has creado actividades aún.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _alertas.length,
                  itemBuilder: (context, index) {
                    final alerta = _alertas[index];
                    final cxc = alerta['cxc'] ?? {};
                    final estado = alerta['estado_alerta'] ?? 'pendiente';
                    final date = DateTime.parse(alerta['created_at']).toLocal();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      elevation: 0,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                cxc['documento'] ?? 'Doc Desconocido',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _estadoColor(estado).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                estado.toUpperCase(),
                                style: TextStyle(
                                  color: _estadoColor(estado),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Cliente: ${cxc['cliente']?['nombre'] ?? '-'}',
                              style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text('Tipo: ${alerta['tipo'] ?? '-'}', style: TextStyle(color: Colors.grey.shade700)),
                            if (alerta['monto_informado'] != null)
                              Text('Monto Informado: \$${alerta['monto_informado']}', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Nota: ${alerta['nota'] ?? '-'}'),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(date),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

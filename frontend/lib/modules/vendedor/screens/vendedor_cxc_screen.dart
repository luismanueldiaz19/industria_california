import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/auth_provider.dart';
import '../services/vendedor_cxc_service.dart';
import 'vendedor_cxc_detalle_screen.dart';
import 'vendedor_cxc_sync_screen.dart';

class VendedorCxcScreen extends StatefulWidget {
  const VendedorCxcScreen({super.key});

  @override
  State<VendedorCxcScreen> createState() => _VendedorCxcScreenState();
}

class _VendedorCxcScreenState extends State<VendedorCxcScreen> {
  final _service = VendedorCxcService();
  List<dynamic> _cxcs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> get _filteredCxcs {
    if (_searchQuery.isEmpty) return _cxcs;
    final q = _searchQuery.toLowerCase();
    return _cxcs.where((cxc) {
      final doc = (cxc['documento'] ?? '').toString().toLowerCase();
      final cliente = (cxc['cliente']?['nombre'] ?? '')
          .toString()
          .toLowerCase();
      return doc.contains(q) || cliente.contains(q);
    }).toList();
  }

  static const _blue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    setState(() => _isLoading = true);
    try {
      final data = await _service.getMisCxc(token);
      setState(() => _cxcs = data);
    } catch (_) {
      // manejar error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'pagado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text(
          'Mis Cuentas por Cobrar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const VendedorCxcSyncScreen()),
          );
          if (result == true) _load();
        },
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_rounded),
        label: const Text(
          'Sincronizar Excel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Buscar por documento o cliente...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredCxcs.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: _filteredCxcs.length,
                            itemBuilder: (_, i) =>
                                _buildCxcCard(_filteredCxcs[i]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildCxcCard(Map<String, dynamic> cxc) {
    final estado = cxc['estado'] ?? 'pendiente';
    final color = _estadoColor(estado);
    final alertasPendientes = cxc['alertas_pendientes'] ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VendedorCxcDetalleScreen(cxcData: cxc),
        ),
      ).then((_) => _load()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header de color según estado
            Container(
              height: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          cxc['documento'] ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          if (alertasPendientes > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.notifications_active,
                                    color: Colors.red,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$alertasPendientes',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              estado.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          cxc['cliente']?['nombre'] ?? 'Sin cliente',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMontoItem(
                        'Pendiente',
                        '\$${cxc['monto_pendiente'] ?? '0.00'}',
                        Colors.orange,
                      ),
                      _buildMontoItem(
                        'Factura',
                        '\$${cxc['monto_factura'] ?? '0.00'}',
                        Colors.blue,
                      ),
                      _buildMontoItem(
                        'Vence',
                        _formatDate(cxc['fecha_vencimiento']),
                        Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMontoItem(String label, String valor, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin resultados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black45,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontró ningún documento o cliente\nque coincida con tu búsqueda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin facturas aún',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sincroniza tu Excel para importar tus CXC',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '-';
    try {
      final parts = date.split('-');
      return '${parts[2]}/${parts[1]}/${parts[0].substring(2)}';
    } catch (_) {
      return date;
    }
  }
}

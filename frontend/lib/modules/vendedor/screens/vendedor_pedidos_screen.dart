import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../logistica/models/pedido.dart';
import '../../logistica/providers/pedido_provider.dart';
import 'vendedor_pedido_flow_screen.dart';
import 'vendedor_pedido_detalle_screen.dart';

class VendedorPedidosScreen extends StatefulWidget {
  const VendedorPedidosScreen({super.key});

  @override
  State<VendedorPedidosScreen> createState() => _VendedorPedidosScreenState();
}

class _VendedorPedidosScreenState extends State<VendedorPedidosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final _currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  // Colores del home (VentaFlow / Industria California)
  static const _bgPrimary = Color(0xFF1E2F4C);
  static const _bgSecondary = Color(0xFF1976D2);

  static const _estados = [
    'todos',
    'borrador',
    'enviado',
    'facturado',
    'cancelado',
  ];
  int _estadoIndex = 0;

  static final Map<String, Color> _estadoColor = {
    'borrador': const Color(0xFFFF9800),
    'enviado': const Color(0xFF2196F3),
    'facturado': const Color(0xFF4CAF50),
    'cancelado': const Color(0xFFE53935),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _estados.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _estadoIndex = _tabController.index);
        _loadData();
      }
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<PedidoProvider>().fetchMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final provider = context.read<PedidoProvider>();
    final estado = _estados[_estadoIndex];
    provider.setFiltros(estado: estado == 'todos' ? null : estado);
    provider.fetchPedidos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _goToCreate() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const VendedorPedidoFlowScreen()),
    );
    if (result == true && mounted) _loadData();
  }

  Future<void> _goToEdit(Pedido pedido) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VendedorPedidoFlowScreen(pedidoOriginal: pedido),
      ),
    );
    if (result == true && mounted) _loadData();
  }

  void _goToDetalle(Pedido pedido) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => VendedorPedidoDetalleScreen(pedido: pedido),
          ),
        )
        .then((_) => _loadData());
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(color: _bgPrimary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + botón nuevo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mis Pedidos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                // Un solo botón: Nuevo Pedido
                GestureDetector(
                  onTap: _goToCreate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _bgSecondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text(
                          'Nuevo',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tabs de estado
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.white,
            indicatorWeight: 2.5,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
            tabs: _estados.map((e) => Tab(text: e.toUpperCase())).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<PedidoProvider>(
      builder: (ctx, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: _bgSecondary),
          );
        }
        if (provider.error != null && provider.pedidos.isEmpty) {
          return _buildError(provider.error!, provider);
        }
        if (provider.pedidos.isEmpty) {
          return _buildEmpty();
        }
        return RefreshIndicator(
          color: _bgSecondary,
          onRefresh: () async => _loadData(),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount:
                provider.pedidos.length + (provider.isLoadingMore ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == provider.pedidos.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: _bgSecondary),
                  ),
                );
              }
              return _buildPedidoCard(provider.pedidos[i]);
            },
          ),
        );
      },
    );
  }

  Widget _buildPedidoCard(Pedido pedido) {
    final estadoColor = _estadoColor[pedido.estado] ?? Colors.grey;
    final fecha = DateFormat(
      'dd MMM yyyy, HH:mm',
      'es',
    ).format(pedido.createdAt);

    return GestureDetector(
      onTap: () => _goToDetalle(pedido),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Cabecera de la tarjeta
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: estadoColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_cart_rounded,
                    color: estadoColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pedido #${pedido.id}',
                      style: const TextStyle(
                        color: _bgPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: estadoColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      pedido.estado.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Cuerpo
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _infoRow(Icons.person_outline, pedido.clienteNombre ?? '—'),
                  if (pedido.rutaNombre != null) ...[
                    const SizedBox(height: 6),
                    _infoRow(Icons.map_outlined, pedido.rutaNombre!),
                  ],
                  const SizedBox(height: 6),
                  _infoRow(Icons.schedule_outlined, fecha),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${pedido.detalles.length} ítem(s)',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _currencyFmt.format(pedido.total),
                        style: const TextStyle(
                          color: _bgSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Acciones — solo para borradores
            if (pedido.estado == 'borrador') ...[
              const Divider(height: 1),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _goToEdit(pedido),
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text(
                        'Editar',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: TextButton.styleFrom(foregroundColor: _bgPrimary),
                    ),
                  ),
                  const SizedBox(height: 36, child: VerticalDivider(width: 1)),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _confirmarEnvio(pedido),
                      icon: const Icon(Icons.send_outlined, size: 15),
                      label: const Text(
                        'Enviar',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 14),
          Text(
            'No hay pedidos',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toca "Nuevo" para crear tu primer pedido',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String err, PedidoProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(
            err,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(backgroundColor: _bgSecondary),
            child: const Text(
              'Reintentar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEnvio(Pedido pedido) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enviar Pedido'),
        content: Text(
          '¿Confirmas el envío del Pedido #${pedido.id}?\nUna vez enviado no podrás editarlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sí, Enviar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final ok = await context.read<PedidoProvider>().changeStatus(
      pedido.id,
      'enviado',
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Pedido enviado correctamente' : 'Error al enviar'),
        backgroundColor: ok ? const Color(0xFF4CAF50) : Colors.red,
      ),
    );
  }
}

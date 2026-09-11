import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logistica/models/pedido.dart';
import '../providers/pedido_form_provider.dart';
import 'pedido/vendedor_pedido_info_screen.dart';
import 'pedido/vendedor_pedido_catalogo_screen.dart';
import 'pedido/vendedor_pedido_revision_screen.dart';
import '../../led_house/providers/ledhouse_cliente_provider.dart';
import '../../logistica/providers/ruta_provider.dart';
import '../../inventario/providers/inventario_producto_provider.dart';

/// Pantalla Orquestadora del Flujo de Creación de Pedido (Multi-paso)
/// Aquí se inyecta el Provider compartido para los 3 pasos.
class VendedorPedidoFlowScreen extends StatelessWidget {
  final Pedido? pedidoOriginal;

  const VendedorPedidoFlowScreen({super.key, this.pedidoOriginal});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PedidoFormProvider>(
      create: (_) => PedidoFormProvider(),
      child: _VendedorPedidoFlowContent(pedidoOriginal: pedidoOriginal),
    );
  }
}

class _VendedorPedidoFlowContent extends StatefulWidget {
  final Pedido? pedidoOriginal;

  const _VendedorPedidoFlowContent({this.pedidoOriginal});

  @override
  State<_VendedorPedidoFlowContent> createState() => _VendedorPedidoFlowContentState();
}

class _VendedorPedidoFlowContentState extends State<_VendedorPedidoFlowContent> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  Future<void> _initData() async {
    final futures = [
      context.read<LedhouseClienteProvider>().fetchClientes(),
      context.read<RutaProvider>().fetchRutas(),
      context.read<InventarioProductoProvider>().fetchProductos(),
    ];
    await Future.wait(futures);

    if (widget.pedidoOriginal != null && mounted) {
      final formProvider = context.read<PedidoFormProvider>();
      formProvider.initFromPedido(
        widget.pedidoOriginal!,
        context.read<LedhouseClienteProvider>().clientes,
        context.read<RutaProvider>().rutas,
        context.read<InventarioProductoProvider>().productos,
      );
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    FocusScope.of(context).unfocus(); // Cerrar teclados
    if (_currentIndex < 2) {
      _pageController.animateToPage(
        _currentIndex + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentIndex++);
    }
  }

  void _prevStep() {
    FocusScope.of(context).unfocus(); // Cerrar teclados
    if (_currentIndex > 0) {
      _pageController.animateToPage(
        _currentIndex - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentIndex--);
    } else {
      Navigator.of(context).pop(); // Salir si estamos en paso 1
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // Custom AppBar para los pasos
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _prevStep,
        ),
        title: Text(
          widget.pedidoOriginal != null ? 'Editar Pedido' : 'Nuevo Pedido',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: _StepperIndicators(currentIndex: _currentIndex),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Bloquear scroll manual
        children: [
          VendedorPedidoInfoScreen(onNext: _nextStep),
          VendedorPedidoCatalogoScreen(onNext: _nextStep, onPrev: _prevStep),
          VendedorPedidoRevisionScreen(onPrev: _prevStep),
        ],
      ),
    );
  }
}

class _StepperIndicators extends StatelessWidget {
  final int currentIndex;

  const _StepperIndicators({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final steps = ['1. Info', '2. Catálogo', '3. Revisión'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (i) {
          final isPast = i < currentIndex;
          final isCurrent = i == currentIndex;
          final color = isPast || isCurrent ? const Color(0xFF1976D2) : Colors.white30;
          return Expanded(
            child: Row(
              children: [
                if (i > 0) Expanded(child: Container(height: 2, color: color, margin: const EdgeInsets.symmetric(horizontal: 8))),
                Text(
                  steps[i],
                  style: TextStyle(
                    color: color,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
                if (i == 0 && currentIndex == 0) Expanded(child: Container(height: 2, color: Colors.transparent, margin: const EdgeInsets.symmetric(horizontal: 8))),
              ],
            ),
          );
        }),
      ),
    );
  }
}

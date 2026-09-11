import 'package:flutter/material.dart';
import '../../../services/http_service.dart';
import '../models/inventario_producto.dart';
import 'stock_badge_widget.dart';

class ProductoGridCard extends StatefulWidget {
  final InventarioProducto producto;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMovimiento;
  final VoidCallback? onTap;

  const ProductoGridCard({
    super.key,
    required this.producto,
    this.isAdmin = false,
    this.onEdit,
    this.onDelete,
    this.onMovimiento,
    this.onTap,
  });

  @override
  State<ProductoGridCard> createState() => _ProductoGridCardState();
}

class _ProductoGridCardState extends State<ProductoGridCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  static const _cardBg = Color(0xFF2C2F33);
  static const _accentRed = Color(0xFFE31E24);
  static const _darkBg = Color(0xFF1A1C1E);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.025,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() => _hovered = hovering);
    if (hovering) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final estado = p.estadoStockEnum;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnim.value, child: child),
      child: MouseRegion(
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _cardBg.withValues(alpha: _hovered ? 0.95 : 0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovered
                    ? _accentRed.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.06),
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hovered
                      ? _accentRed.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.25),
                  blurRadius: _hovered ? 18 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Imagen / placeholder ──
                Expanded(flex: 5, child: _buildImage(p)),

                // ── Info ──
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Código
                        Text(
                          p.codigo,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Nombre
                        Text(
                          p.nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Categoría
                        if (p.categoria != null)
                          Text(
                            p.categoria!.nombre,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                        const Spacer(),

                        // Stock + Badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            StockBadgeWidget(
                              estado: estado,
                              stock: p.stock,
                              compact: true,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              p.stock.toStringAsFixed(2).replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), ''),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              p.unidad,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 8.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Precios
                        Row(
                          children: [
                            _priceChip('C', p.costo),
                            const SizedBox(width: 4),
                            _priceChip('V', p.venta, isVenta: true),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Acciones
                        _buildActions(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(InventarioProducto p) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Container(
        color: _darkBg,
        child: p.imagenUrl != null
            ? Image.network(
                p.imagenUrl!,
                fit: BoxFit.cover,
                headers: {'Authorization': 'Bearer ${HttpService.token}'},
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                          : null,
                      color: const Color(0xFFE31E24),
                      strokeWidth: 2,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    _placeholderIcon(),
              )
            : _placeholderIcon(),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: Colors.white.withValues(alpha: 0.12),
            size: 36,
          ),
        ],
      ),
    );
  }

  Widget _priceChip(String prefix, double amount, {bool isVenta = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$prefix ',
              style: TextStyle(
                color: isVenta
                    ? const Color(0xFFE31E24).withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.35),
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: isVenta
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
                fontSize: 9.5,
                fontWeight: isVenta ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        // Movimiento siempre disponible
        _actionBtn(
          Icons.swap_vert_rounded,
          Colors.blue.shade300,
          widget.onMovimiento,
          tooltip: 'Registrar movimiento',
        ),
        if (widget.isAdmin) ...[
          const SizedBox(width: 4),
          _actionBtn(
            Icons.edit_outlined,
            Colors.white54,
            widget.onEdit,
            tooltip: 'Editar',
          ),
          const SizedBox(width: 4),
          _actionBtn(
            Icons.delete_outline,
            const Color(0xFFE31E24).withValues(alpha: 0.7),
            widget.onDelete,
            tooltip: 'Eliminar',
          ),
        ],
      ],
    );
  }

  Widget _actionBtn(
    IconData icon,
    Color color,
    VoidCallback? onTap, {
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
      ),
    );
  }
}

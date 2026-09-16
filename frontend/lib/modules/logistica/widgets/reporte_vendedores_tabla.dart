import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/reporte_vendedores_provider.dart';
import 'reporte_vendedores_constants.dart';

/// Tabla paginada de vendedores con contadores por estado.
class ReporteVendedoresTabla extends StatelessWidget {
  final ReporteVendedoresProvider prov;
  const ReporteVendedoresTabla({super.key, required this.prov});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kColorSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TablaHeader(total: prov.total),
          _TablaColumnas(),
          if (prov.vendedores.isEmpty)
            const _TablaVacia()
          else
            ...prov.vendedores.asMap().entries.map(
                  (e) => _TablaFila(vendedor: e.value, isOdd: e.key.isOdd),
                ),
          _TablaPaginacion(prov: prov),
        ],
      ),
    );
  }
}

// ── Encabezado de la tabla ────────────────────────────────────────────────────

class _TablaHeader extends StatelessWidget {
  final int total;
  const _TablaHeader({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black26)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Resumen por Vendedor',
            style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text('$total registros',
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Cabecera de columnas ──────────────────────────────────────────────────────

class _TablaColumnas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: kColorBg.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _ColHeader(label: 'VENDEDOR', flex: 3),
          _ColHeader(label: 'PEDIDOS', flex: 1, align: TextAlign.center),
          _ColHeader(label: 'BORRADOR', flex: 1, color: kColorBorrador),
          _ColHeader(label: 'ENVIADO', flex: 1, color: kColorEnviado),
          _ColHeader(label: 'FACTURADO', flex: 1, color: kColorFacturado),
          _ColHeader(label: 'CANCELADO', flex: 1, color: kColorCancelado),
          _ColHeader(label: 'T. ORIG', flex: 2, align: TextAlign.right),
          _ColHeader(label: 'FALTANTE', flex: 2, align: TextAlign.right),
          _ColHeader(label: 'M. REAL', flex: 2, align: TextAlign.right),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String label;
  final int flex;
  final Color? color;
  final TextAlign align;

  const _ColHeader({
    required this.label,
    required this.flex,
    this.color,
    this.align = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final c = color?.withValues(alpha: 0.7) ?? Colors.white38;
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: TextStyle(
          color: c,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Fila de datos ─────────────────────────────────────────────────────────────

class _TablaFila extends StatelessWidget {
  final VendedorReporte vendedor;
  final bool isOdd;

  const _TablaFila({required this.vendedor, required this.isOdd});

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat('#,##0.00', 'en_US');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isOdd ? Colors.white.withValues(alpha: 0.02) : Colors.transparent,
      child: Row(
        children: [
          Expanded(flex: 3, child: _VendedorCell(nombre: vendedor.vendedorNombre)),
          Expanded(
            flex: 1,
            child: Text(
              vendedor.totalPedidos.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(flex: 1, child: _ContadorBadge(count: vendedor.borrador, color: kColorBorrador)),
          Expanded(flex: 1, child: _ContadorBadge(count: vendedor.enviado, color: kColorEnviado)),
          Expanded(flex: 1, child: _ContadorBadge(count: vendedor.facturado, color: kColorFacturado)),
          Expanded(flex: 1, child: _ContadorBadge(count: vendedor.cancelado, color: kColorCancelado)),
          Expanded(
            flex: 2,
            child: Text(
              '\$${moneyFmt.format(vendedor.totalMonto)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '\$${moneyFmt.format(vendedor.totalFaltante)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: vendedor.totalFaltante > 0 ? Colors.redAccent : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '\$${moneyFmt.format(vendedor.totalReal)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: kColorFacturado,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _VendedorCell extends StatelessWidget {
  final String nombre;
  const _VendedorCell({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: kColorAccent.withValues(alpha: 0.15),
          child: Text(
            nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
            style: const TextStyle(
                color: kColorAccent, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(nombre,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _ContadorBadge extends StatelessWidget {
  final int count;
  final Color color;
  const _ContadorBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: count > 0
              ? color.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          count.toString(),
          style: TextStyle(
              color: count > 0 ? color : Colors.white24,
              fontSize: 11,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _TablaVacia extends StatelessWidget {
  const _TablaVacia();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Text(
          'Sin datos para los filtros aplicados',
          style: TextStyle(color: Colors.white38),
        ),
      ),
    );
  }
}

// ── Paginación ────────────────────────────────────────────────────────────────

class _TablaPaginacion extends StatelessWidget {
  final ReporteVendedoresProvider prov;
  const _TablaPaginacion({required this.prov});

  @override
  Widget build(BuildContext context) {
    if (prov.lastPage <= 1) return const SizedBox.shrink();

    // Páginas visibles: la actual ±2, la primera y la última.
    final paginasVisibles = List.generate(prov.lastPage, (i) => i + 1)
        .where(
          (p) =>
              (p - prov.currentPage).abs() <= 2 ||
              p == 1 ||
              p == prov.lastPage,
        )
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black26)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Página ${prov.currentPage} de ${prov.lastPage}  ·  ${prov.total} vendedores',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          Row(
            children: [
              _PageBtn(
                icon: Icons.first_page_rounded,
                onTap: prov.currentPage > 1 ? () => prov.goToPage(1) : null,
              ),
              const SizedBox(width: 4),
              _PageBtn(
                icon: Icons.chevron_left_rounded,
                onTap: prov.currentPage > 1
                    ? () => prov.goToPage(prov.currentPage - 1)
                    : null,
              ),
              const SizedBox(width: 4),
              ...paginasVisibles.map((p) => _PageNumber(
                    page: p,
                    isActive: p == prov.currentPage,
                    onTap: () => prov.goToPage(p),
                  )),
              const SizedBox(width: 4),
              _PageBtn(
                icon: Icons.chevron_right_rounded,
                onTap: prov.currentPage < prov.lastPage
                    ? () => prov.goToPage(prov.currentPage + 1)
                    : null,
              ),
              const SizedBox(width: 4),
              _PageBtn(
                icon: Icons.last_page_rounded,
                onTap: prov.currentPage < prov.lastPage
                    ? () => prov.goToPage(prov.lastPage)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _PageBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            color: onTap != null ? Colors.white54 : Colors.white12, size: 18),
      ),
    );
  }
}

class _PageNumber extends StatelessWidget {
  final int page;
  final bool isActive;
  final VoidCallback onTap;
  const _PageNumber({
    required this.page,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: isActive ? null : onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? kColorAccent
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            page.toString(),
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white54,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

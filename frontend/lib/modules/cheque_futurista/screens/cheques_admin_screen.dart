import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/app_date_picker.dart';
import '../../../core/utils/formatters.dart';
import '../models/cheque_futurista.dart';
import '../providers/cheque_admin_provider.dart';

/// Pantalla de administración global de Cheques Futuristas.
/// Modo oscuro empresarial — vista de tabla para gestión contable.
class ChequesAdminScreen extends StatefulWidget {
  const ChequesAdminScreen({super.key});

  @override
  State<ChequesAdminScreen> createState() => _ChequesAdminScreenState();
}

class _ChequesAdminScreenState extends State<ChequesAdminScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  static const _estados = [
    {'label': 'Todos', 'value': null},
    {'label': 'Pendiente', 'value': 'pendiente'},
    {'label': 'Depositado', 'value': 'depositado'},
    {'label': 'Cancelado', 'value': 'cancelado'},
    {'label': 'Vencido', 'value': 'vencido'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChequeAdminProvider>().fetchCheques(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<ChequeAdminProvider>().fetchCheques();
    }
  }

  Future<void> _pickDateRange() async {
    final provider = context.read<ChequeAdminProvider>();
    final initialStart =
        provider.fechaInicio ??
        DateTime.now().subtract(const Duration(days: 30));
    final initialEnd = provider.fechaFin ?? DateTime.now();
    final picked = await AppDatePicker.showRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );
    if (picked != null && mounted) {
      provider.setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChequeAdminProvider>();
    return Scaffold(
      backgroundColor: AppTheme.darkBgColor,
      body: Column(
        children: [
          _buildTopBar(provider),
          _buildFilterBar(provider),
          _buildActiveBanners(provider),
          _buildTableHeader(),
          Expanded(child: _buildTableBody(provider)),
          _buildFooter(provider),
        ],
      ),
    );
  }

  Widget _buildTopBar(ChequeAdminProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        border: const Border(bottom: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Cheques Futuristas',
                    style: TextStyle(
                      color: AppTheme.textPrimarySec,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Gestión contable global · Todos los vendedores',
                style: TextStyle(color: AppTheme.textSecond, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          _iconBtn(
            icon: provider.soloAtrasados
                ? Icons.warning_rounded
                : Icons.warning_amber_outlined,
            tooltip: provider.soloAtrasados
                ? 'Quitar filtro atrasados'
                : 'Solo Atrasados (+20 días)',
            active: provider.soloAtrasados,
            activeColor: Colors.orange,
            onTap: () => provider.toggleAtrasados(),
          ),
          const SizedBox(width: 8),
          _iconBtn(
            icon: Icons.date_range_outlined,
            tooltip: 'Filtrar por Fechas',
            active: provider.fechaInicio != null,
            activeColor: AppTheme.accent,
            onTap: _pickDateRange,
          ),
          const SizedBox(width: 8),
          _iconBtn(
            icon: Icons.refresh_rounded,
            tooltip: 'Actualizar',
            onTap: () => provider.fetchCheques(refresh: true),
          ),
          if (provider.fechaInicio != null ||
              provider.estado != null ||
              provider.soloAtrasados ||
              (provider.buscar?.isNotEmpty == true)) ...[
            const SizedBox(width: 8),
            _iconBtn(
              icon: Icons.filter_alt_off_outlined,
              tooltip: 'Limpiar todos los filtros',
              activeColor: Colors.redAccent,
              active: true,
              onTap: () {
                _searchCtrl.clear();
                provider.clearAllFilters();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterBar(ChequeAdminProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => provider.setSearch(v),
                style: const TextStyle(
                  color: AppTheme.textPrimarySec,
                  fontSize: 13,
                ),
                cursorColor: AppTheme.accent,
                decoration: InputDecoration(
                  hintText: 'Buscar cliente o N° de cheque...',
                  hintStyle: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.textSecond,
                    size: 18,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 16,
                            color: AppTheme.textSecond,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            provider.setSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.surfaceAlt,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppTheme.accent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _estados.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final e = _estados[i];
                  final isSelected = provider.estado == e['value'];
                  return GestureDetector(
                    onTap: () => provider.setEstado(e['value'] as String?),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accent.withValues(alpha: 0.18)
                            : AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? AppTheme.accent : AppTheme.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          e['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.accent
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBanners(ChequeAdminProvider provider) {
    final banners = <Widget>[];
    if (provider.fechaInicio != null && provider.fechaFin != null) {
      banners.add(
        _banner(
          Icons.date_range,
          'Desde ${DateFormat('dd/MM/yyyy').format(provider.fechaInicio!)} hasta ${DateFormat('dd/MM/yyyy').format(provider.fechaFin!)}',
          AppTheme.accent,
          () => provider.clearDateRange(),
        ),
      );
    }
    if (provider.soloAtrasados) {
      banners.add(
        _banner(
          Icons.warning_amber_rounded,
          'Mostrando cheques con más de 20 días de atraso',
          Colors.orange,
          () => provider.toggleAtrasados(),
        ),
      );
    }
    if (banners.isEmpty) return const SizedBox.shrink();
    return Column(children: banners);
  }

  Widget _banner(
    IconData icon,
    String text,
    Color color,
    VoidCallback onClear,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Icon(Icons.close, size: 15, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceAlt,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1.5)),
      ),
      child: Row(
        children: [
          _th('#', flex: 1),
          _th('Fecha', flex: 3),
          _th('Cliente', flex: 5),
          _th('N° Cheque', flex: 3),
          _th('Estado', flex: 3),
          _th('Días', flex: 2),
          _th('Monto', flex: 3, align: TextAlign.right),
        ],
      ),
    );
  }

  Widget _th(
    String label, {
    required int flex,
    TextAlign align = TextAlign.left,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        textAlign: align,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildTableBody(ChequeAdminProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
            SizedBox(height: 16),
            Text(
              'Cargando cheques...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 44, color: Colors.red.shade400),
            const SizedBox(height: 14),
            Text(
              'Error al cargar:\n${provider.error}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade300, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => provider.fetchCheques(refresh: true),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
              ),
            ),
          ],
        ),
      );
    }
    if (provider.cheques.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 36,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron cheques',
              style: TextStyle(
                color: AppTheme.textPrimarySec,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Intenta cambiar los filtros de búsqueda',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      itemCount: provider.cheques.length + (provider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.cheques.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppTheme.accent,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }
        return _buildRow(provider.cheques[index], index);
      },
    );
  }

  Widget _buildRow(ChequeFuturista cheque, int index) {
    final isEven = index % 2 == 0;
    String fechaFormat = '—';
    int diasTranscurridos = 0;
    try {
      final dt = DateTime.parse(cheque.createdAt);
      diasTranscurridos = DateTime.now().difference(dt).inDays;
      fechaFormat = DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {}
    final bool atrasado = diasTranscurridos > 20;
    final Color statusColor = _colorPorEstado(cheque.estado);

    return Container(
      decoration: BoxDecoration(
        color: atrasado
            ? Colors.red.withValues(alpha: 0.04)
            : isEven
            ? AppTheme.surface
            : AppTheme.bg,
        border: const Border(
          bottom: BorderSide(color: AppTheme.border, width: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          hoverColor: AppTheme.accent.withValues(alpha: 0.05),
          splashColor: AppTheme.accent.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    '#${cheque.id}',
                    style: TextStyle(
                      color: AppTheme.accent.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    fechaFormat,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    cheque.nombreCliente.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.textPrimarySec,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    cheque.numCheque,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        cheque.estado.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (atrasado)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            size: 12,
                            color: Colors.orange.shade400,
                          ),
                        ),
                      Text(
                        '${diasTranscurridos}d',
                        style: TextStyle(
                          color: atrasado
                              ? Colors.orange.shade400
                              : AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: atrasado
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    Formatters.formatCurrency(cheque.monto),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppTheme.textPrimarySec,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
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

  Widget _buildFooter(ChequeAdminProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceAlt,
        border: Border(top: BorderSide(color: AppTheme.border, width: 1.5)),
      ),
      child: Row(
        children: [
          Text(
            'Total: ${provider.totalFilas} cheque${provider.totalFilas == 1 ? '' : 's'}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (provider.isLoadingMore)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'MONTO TOTAL',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Formatters.formatCurrency(provider.montoTotal),
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool active = false,
    Color activeColor = AppTheme.accent,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: active
                ? activeColor.withValues(alpha: 0.15)
                : AppTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? activeColor.withValues(alpha: 0.5)
                  : AppTheme.border,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? activeColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Color _colorPorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return const Color(0xFFF59E0B);
      case 'depositado':
        return const Color(0xFF10B981);
      case 'cancelado':
        return const Color(0xFF6B7280);
      case 'vencido':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

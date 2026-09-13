import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/app_theme.dart';
import '../models/cxc_model.dart';
import '../providers/cxc_provider.dart';
import '../widgets/cxc_form_dialog.dart';
import '../widgets/cxc_soporte_dialog.dart';
import '../widgets/cxc_modern_totals_bar.dart';
import 'cxc_cliente_detail_screen.dart';
import '../../../vendedor/screens/vendedor_cxc_sync_screen.dart';
import '../../../../widgets/general_header.dart';
import '../../../../services/http_service.dart';
import '../../../users/providers/users_provider.dart';

class CxcScreen extends StatefulWidget {
  const CxcScreen({super.key});

  @override
  State<CxcScreen> createState() => _CxcScreenState();
}

class _CxcScreenState extends State<CxcScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchGroupedController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  String _searchQuery = '';
  String _statusFilter = 'Todos';
  int? _selectedVendedorId;
  bool _soloVencidos = false;
  bool _conVisita = false;

  int _currentPage = 1;
  int _rowsPerPage = 10;

  static const _darkBg = AppTheme.darkBgColor;
  static const _cardDark = AppTheme.darkCardColor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CxcProvider>(context, listen: false).fetchCxcs();
      Provider.of<UsersProvider>(context, listen: false).fetchUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchGroupedController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
          _currentPage = 1;
        });
      }
    });
  }

  void _showFormDialog([cxc]) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => CxcFormDialog(cxc: cxc),
    );
  }

  void _showSoporteDialog(cxc) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => CxcSoporteDialog(cxc: cxc),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pagado':
        return AppTheme.successColor;
      case 'cancelado':
        return AppTheme.dangerColor;
      default:
        return const Color(0xFFFB8C00); // Naranja
    }
  }

  bool _isPastDue(String dateStr, String status) {
    if (status.toLowerCase() != 'pendiente') return false;
    try {
      final date = DateTime.parse(dateStr);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      return date.isBefore(todayDate);
    } catch (e) {
      return false;
    }
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n');
  }

  List<CxcModel> _getFilteredList(List<CxcModel> list) {
    return list.where((cxc) {
      bool matchesStatus =
          _statusFilter == 'Todos' ||
          cxc.estado.toLowerCase() == _statusFilter.toLowerCase();
      if (!matchesStatus) return false;

      if (_selectedVendedorId != null &&
          cxc.vendedorId != _selectedVendedorId) {
        return false;
      }

      if (_soloVencidos && !_isPastDue(cxc.fechaVencimiento, cxc.estado)) {
        return false;
      }

      if (_conVisita && cxc.ultimaFechaVisita == null) {
        return false;
      }

      if (_searchQuery.isEmpty) return true;

      final normalizedQuery = _normalizeText(_searchQuery);
      final normalizedCliente = _normalizeText(cxc.cliente);
      final normalizedDocumento = _normalizeText(cxc.documento);

      return normalizedCliente.contains(normalizedQuery) ||
          normalizedDocumento.contains(normalizedQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CxcProvider>(
      builder: (context, provider, _) {
        final filteredCxcs = _getFilteredList(provider.cxcs);
        final groupedClients = provider.clientesAgrupados.where((c) {
          final totalPendienteStr = c['total_pendiente']?.toString() ?? '0';
          final totalPendiente = double.tryParse(totalPendienteStr) ?? 0.0;
          if (totalPendiente <= 0) return false;

          if (_searchQuery.isEmpty) return true;
          final normalizedQuery = _normalizeText(_searchQuery);
          final normalizedName = _normalizeText(c['nombre'] ?? '');
          return normalizedName.contains(normalizedQuery);
        }).toList();

        double totalFactura = 0;
        double totalPendiente = 0;
        double totalVencido = 0;
        int totalIntervenciones = 0;

        for (var cxc in filteredCxcs) {
          totalFactura += cxc.montoFactura;
          totalPendiente += cxc.montoPendiente;
          if (_isPastDue(cxc.fechaVencimiento, cxc.estado)) {
            totalVencido += cxc.montoPendiente;
          }
          totalIntervenciones += cxc.totalIntervenciones;
        }

        return Scaffold(
          backgroundColor: _darkBg,
          bottomNavigationBar: ModernTotalsBar(
            facturado: totalFactura,
            pendiente: totalPendiente,
            vencido: totalVencido,
            intervenciones: totalIntervenciones,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(filteredCxcs.length, provider.isLoading),
              _buildGlobalFiltersBar(),
              Container(
                color: _cardDark,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.ledhouseBlue,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey.shade500,
                  tabs: const [
                    Tab(text: 'Agrupado por Cliente'),
                    Tab(text: 'Todos los Documentos'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Agrupado por Cliente
                    _buildGroupedView(provider, groupedClients),
                    // Tab 2: Todos los Documentos
                    _buildContent(provider, filteredCxcs),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Paleta de colores para avatares
  static const List<Color> _avatarColors = [
    AppTheme.ledhouseBlue,
    AppTheme.successColor,
    AppTheme.dangerColor,
    Color(0xFFFBBC05), // Google Yellow
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF607D8B), // Blue Grey
  ];

  Color _avatarColor(String nombre) {
    return _avatarColors[nombre.hashCode.abs() % _avatarColors.length];
  }

  String _initials(String nombre) {
    final parts = nombre.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  Widget _buildGroupedView(
    CxcProvider provider,
    List<Map<String, dynamic>> groupedClients,
  ) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppTheme.ledhouseBlue),
          strokeWidth: 3,
        ),
      );
    }

    return Column(
      children: [
        if (groupedClients.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'No hay clientes coincidentes.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: groupedClients.length,
              itemBuilder: (context, index) {
                final cliente = groupedClients[index];
                final totalPendiente =
                    double.tryParse(
                      cliente['total_pendiente']?.toString() ?? '0',
                    ) ??
                    0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: _cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade800, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.015),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CxcClienteDetailScreen(
                              clienteAgrupado: cliente,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Avatar Premium
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _avatarColor(cliente['nombre'] ?? ''),
                                    _avatarColor(
                                      cliente['nombre'] ?? '',
                                    ).withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: _avatarColor(
                                      cliente['nombre'] ?? '',
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _initials(cliente['nombre'] ?? ''),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cliente['nombre'] ?? 'Sin Nombre',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone_rounded,
                                        size: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        cliente['whatsapp'] ?? 'N/A',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (cliente['whatsapp'] != null &&
                                cliente['whatsapp']
                                    .toString()
                                    .trim()
                                    .isNotEmpty &&
                                totalPendiente > 0)
                              IconButton(
                                icon: const FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  color: Colors.green,
                                ),
                                tooltip: 'Enviar WhatsApp',
                                onPressed: () async {
                                  final cxcsCliente = provider.cxcs
                                      .where(
                                        (c) =>
                                            c.clienteId == cliente['id'] &&
                                            c.montoPendiente > 0,
                                      )
                                      .toList();
                                  if (cxcsCliente.isEmpty) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'El cliente no tiene deudas pendientes',
                                          ),
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  String mensaje =
                                      'Hola *${cliente['nombre']}*,\n\nLe recordamos que tiene facturas pendientes con *Ledhouse*:\n\n';
                                  for (var cxc in cxcsCliente) {
                                    int diasAtraso = 0;
                                    try {
                                      final date = DateTime.parse(
                                        cxc.fechaVencimiento,
                                      );
                                      final todayDate = DateTime(
                                        DateTime.now().year,
                                        DateTime.now().month,
                                        DateTime.now().day,
                                      );
                                      final diff = todayDate
                                          .difference(date)
                                          .inDays;
                                      if (diff > 0) diasAtraso = diff;
                                    } catch (e) {}

                                    mensaje +=
                                        '*Doc:* ${cxc.documento} | *Vence:* ${cxc.fechaVencimiento}';
                                    if (diasAtraso > 0) {
                                      mensaje +=
                                          ' (*$diasAtraso días de atraso*)';
                                    }
                                    mensaje +=
                                        ' | *Pendiente:* ${currencyFormatter.format(cxc.montoPendiente)}\n';
                                  }
                                  mensaje +=
                                      '\n*Total Pendiente:* ${currencyFormatter.format(totalPendiente)}\n\nPor favor, contáctenos para coordinar el pago. Gracias.';

                                  String phone = cliente['whatsapp']
                                      .toString()
                                      .replaceAll(RegExp(r'\D'), '');
                                  if (!phone.startsWith('1') &&
                                      phone.length == 10) {
                                    phone = '1$phone';
                                  }

                                  if (phone.isNotEmpty) {
                                    final url = Uri.parse(
                                      'https://wa.me/$phone?text=${Uri.encodeComponent(mensaje)}',
                                    );
                                    if (!await launchUrl(url)) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'No se pudo abrir WhatsApp',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormatter.format(totalPendiente),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: totalPendiente > 0
                                        ? AppTheme.dangerColor
                                        : Colors.grey.shade400,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Deuda Total',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey.shade400,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(int total, bool isLoading) {
    return GeneralHeader(
      title: 'Cuentas por Cobrar (CXC)',
      subtitle: isLoading
          ? null
          : '$total ${total == 1 ? 'registro' : 'registros'}',
      icon: Icons.request_quote_rounded,
      iconColor: AppTheme.ledhouseBlue,
      actions: [
        HeaderButton(
          icon: Icons.picture_as_pdf_rounded,
          tooltip: 'Generar PDF',
          color: Colors.redAccent,
          onTap: () async {
            String endpoint = _tabController.index == 0
                ? 'ledhouse/cxc/reporte-agrupado-pdf-url'
                : 'ledhouse/cxc/reporte-general-pdf-url';

            final queryParams = <String>[];
            if (_searchQuery.isNotEmpty) {
              queryParams.add('search=${Uri.encodeComponent(_searchQuery)}');
            }
            if (_selectedVendedorId != null) {
              queryParams.add('vendedor_id=$_selectedVendedorId');
            }
            if (_soloVencidos) queryParams.add('vencidos=1');

            if (_tabController.index == 1) {
              if (_conVisita) queryParams.add('con_visita=1');
              if (_statusFilter != 'Todos') {
                queryParams.add('estado=${Uri.encodeComponent(_statusFilter)}');
              }
            }

            if (queryParams.isNotEmpty) {
              endpoint += '?${queryParams.join('&')}';
            }

            try {
              final response = await HttpService().get(endpoint);
              final url = Uri.parse(response['url']);
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo abrir el PDF en el navegador'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al obtener URL del PDF: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
        HeaderButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Actualizar',
          onTap: () =>
              Provider.of<CxcProvider>(context, listen: false).fetchCxcs(),
        ),
        HeaderButton(
          icon: Icons.upload_file_rounded,
          tooltip: 'Importar CXC',
          onTap: () =>
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VendedorCxcSyncScreen(),
                ),
              ).then((_) {
                Provider.of<CxcProvider>(context, listen: false).fetchCxcs();
              }),
          color: AppTheme.successColor,
        ),
        HeaderButton(
          icon: Icons.add_rounded,
          tooltip: 'Nueva CXC',
          onTap: () => _showFormDialog(),
          color: AppTheme.accentColor,
        ),
      ],
    );
  }

  // ── Filtros Globales ────────────────────────────────────────────────────────
  Widget _buildGlobalFiltersBar() {
    return Container(
      color: _cardDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSearchBar()),
              const SizedBox(width: 8),
              _buildFilterDropdown(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildVendedorDropdown(),
              const SizedBox(width: 12),
              Expanded(child: _buildCheckboxes()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVendedorDropdown() {
    final usuariosProvider = Provider.of<UsersProvider>(context);
    final users = usuariosProvider.users;
    final vendedores = users.where((u) {
      final roles = u['roles'] as List<dynamic>? ?? [];
      return roles.any((r) => r['name'] == 'vendedor');
    }).toList();

    return Expanded(
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.darkInputColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade800),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            value: _selectedVendedorId,
            isExpanded: true,
            isDense: true,
            dropdownColor: AppTheme.darkInputColor,
            hint: Text(
              'Todos los Vendedores',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey.shade500,
              size: 18,
            ),
            style: const TextStyle(fontSize: 13, color: Colors.white),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Todos los Vendedores'),
              ),
              ...vendedores.map(
                (u) => DropdownMenuItem(
                  value: u['id'] as int,
                  child: Text(u['name'] ?? 'Sin Nombre'),
                ),
              ),
            ],
            onChanged: (val) {
              setState(() {
                _selectedVendedorId = val;
                _currentPage = 1;
              });
              Provider.of<CxcProvider>(context, listen: false).fetchCxcs(
                vendedorId: _selectedVendedorId,
                vencidos: _soloVencidos,
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Filtros Individuales Tab 2 ──────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.darkInputColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(fontSize: 13, color: Colors.white),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Buscar cliente o doc...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade400,
            size: 18,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      width: 135,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.darkInputColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,
          isExpanded: true,
          isDense: true,
          dropdownColor: AppTheme.darkInputColor,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey.shade500,
            size: 18,
          ),
          style: const TextStyle(fontSize: 13, color: Colors.white),
          items: const [
            DropdownMenuItem(value: 'Todos', child: Text('Todos los Estados')),
            DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
            DropdownMenuItem(value: 'pagado', child: Text('Pagado')),
            DropdownMenuItem(value: 'cancelado', child: Text('Cancelado')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _statusFilter = val;
                _currentPage = 1;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildCheckboxes() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCustomCheckbox(
            label: 'Solo Vencidos',
            value: _soloVencidos,
            onChanged: (v) {
              setState(() {
                _soloVencidos = v;
                _currentPage = 1;
              });
              Provider.of<CxcProvider>(context, listen: false).fetchCxcs(
                vendedorId: _selectedVendedorId,
                vencidos: _soloVencidos,
              );
            },
          ),
          const SizedBox(width: 12),
          _buildCustomCheckbox(
            label: 'Con Visita',
            value: _conVisita,
            onChanged: (v) => setState(() {
              _conVisita = v;
              _currentPage = 1;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCheckbox({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: value ? AppTheme.ledhouseBlue : Colors.transparent,
                border: Border.all(
                  color: value ? AppTheme.ledhouseBlue : Colors.grey.shade600,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: value
                  ? const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Content ────────────────────────────────────────────────────────────────
  Widget _buildContent(CxcProvider provider, List<CxcModel> list) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppTheme.ledhouseBlue),
          strokeWidth: 3,
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar los datos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => provider.fetchCxcs(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.ledhouseBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: AppTheme.ledhouseBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No se encontraron resultados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3C4043),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajusta los filtros o agrega una nueva cuenta',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final totalRows = list.length;
    final totalPages = (totalRows / _rowsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    }
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage > totalRows)
        ? totalRows
        : startIndex + _rowsPerPage;
    final pageItems = list.sublist(startIndex, endIndex);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF24262A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade800),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFF1E2024),
                          ),
                          headingRowHeight: 46,
                          dataRowMinHeight: 52,
                          dataRowMaxHeight: 60,
                          horizontalMargin: 16,
                          columnSpacing: 18,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'DOCUMENTO',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'CLIENTE',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'F. FACTURA',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'F. VENCIMIENTO',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              numeric: true,
                              label: Text(
                                'FACTURADO',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              numeric: true,
                              label: Text(
                                'PAGADO',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              numeric: true,
                              label: Text(
                                'PENDIENTE',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'ESTADO',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'ACCIONES',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                          rows: pageItems.map((cxc) {
                            final color = _getStatusColor(cxc.estado);
                            final pastDue = _isPastDue(
                              cxc.fechaVencimiento,
                              cxc.estado,
                            );
                            int diffDays = 0;
                            if (pastDue) {
                              try {
                                final date = DateTime.parse(
                                  cxc.fechaVencimiento,
                                );
                                final today = DateTime.now();
                                final todayDate = DateTime(
                                  today.year,
                                  today.month,
                                  today.day,
                                );
                                diffDays = todayDate.difference(date).inDays;
                              } catch (_) {}
                            }
                            return DataRow(
                              cells: [
                                // Documento
                                DataCell(
                                  InkWell(
                                    onTap: () => _showFormDialog(cxc),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              Icons.description_rounded,
                                              size: 15,
                                              color: color,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            cxc.documento,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Cliente
                                DataCell(
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 180,
                                    ),
                                    child: Tooltip(
                                      message: cxc.cliente,
                                      child: Text(
                                        cxc.cliente,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade300,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                // Fecha Factura
                                DataCell(
                                  Text(
                                    cxc.fechaFactura ?? '-',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                                // Fecha Vencimiento
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (pastDue)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 4,
                                          ),
                                          child: Icon(
                                            Icons.warning_amber_rounded,
                                            size: 14,
                                            color: AppTheme.dangerColor,
                                          ),
                                        ),
                                      Text(
                                        cxc.fechaVencimiento,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: pastDue
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: pastDue
                                              ? AppTheme.dangerColor
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                      if (pastDue && diffDays > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4,
                                          ),
                                          child: Text(
                                            '($diffDays d)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.dangerColor,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Facturado
                                DataCell(
                                  Text(
                                    currencyFormatter.format(cxc.montoFactura),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                // Pagado
                                DataCell(
                                  Text(
                                    currencyFormatter.format(cxc.montoPagado),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                                // Pendiente
                                DataCell(
                                  Text(
                                    currencyFormatter.format(
                                      cxc.montoPendiente,
                                    ),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: cxc.montoPendiente <= 0
                                          ? AppTheme.successColor
                                          : (pastDue
                                                ? AppTheme.dangerColor
                                                : const Color(0xFFEA580C)),
                                    ),
                                  ),
                                ),
                                // Estado
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: color.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      cxc.estado.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ),
                                // Acciones
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (cxc.clienteObj?.whatsapp != null &&
                                          cxc.clienteObj!.whatsapp!
                                              .toString()
                                              .trim()
                                              .isNotEmpty)
                                        IconButton(
                                          icon: const FaIcon(
                                            FontAwesomeIcons.whatsapp,
                                            color: Colors.green,
                                            size: 18,
                                          ),
                                          tooltip: 'WhatsApp',
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _sendWhatsApp(cxc),
                                        ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.support_agent_rounded,
                                          color: Colors.purple,
                                          size: 19,
                                        ),
                                        tooltip: 'Gestión de Cobro',
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                        onPressed: () =>
                                            _showSoporteDialog(cxc),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_note_rounded,
                                          color: Color(0xFF1A73E8),
                                          size: 22,
                                        ),
                                        tooltip: 'Editar / Registrar Pago',
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _showFormDialog(cxc),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        _buildPaginationBar(totalRows, totalPages, startIndex, endIndex),
      ],
    );
  }

  // ── Paginación ─────────────────────────────────────────────────────────────
  Widget _buildPaginationBar(
    int totalRows,
    int totalPages,
    int startIndex,
    int endIndex,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Text(
                totalRows > 0
                    ? 'Mostrando ${startIndex + 1} - $endIndex de $totalRows registros'
                    : '0 registros',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Por pág:',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 6),
                  DropdownButton<int>(
                    value: _rowsPerPage,
                    isDense: true,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 10,
                        child: Text('10', style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 25,
                        child: Text('25', style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 50,
                        child: Text('50', style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 100,
                        child: Text('100', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _rowsPerPage = val;
                          _currentPage = 1;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.first_page_rounded),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    tooltip: 'Primera página',
                    onPressed: _currentPage > 1
                        ? () => setState(() => _currentPage = 1)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    tooltip: 'Página anterior',
                    onPressed: _currentPage > 1
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '$_currentPage / ${totalPages == 0 ? 1 : totalPages}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    tooltip: 'Página siguiente',
                    onPressed: _currentPage < totalPages
                        ? () => setState(() => _currentPage++)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.last_page_rounded),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    tooltip: 'Última página',
                    onPressed: _currentPage < totalPages
                        ? () => setState(() => _currentPage = totalPages)
                        : null,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Enviar WhatsApp ────────────────────────────────────────────────────────
  Future<void> _sendWhatsApp(CxcModel cxc) async {
    int diasAtraso = 0;
    try {
      final date = DateTime.parse(cxc.fechaVencimiento);
      final todayDate = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final diff = todayDate.difference(date).inDays;
      if (diff > 0) diasAtraso = diff;
    } catch (e) {}

    String mensaje =
        'Hola *${cxc.cliente}*,\n\nLe recordamos que tiene un saldo pendiente con *Industria California*.\n\n';
    mensaje += '*Doc:* ${cxc.documento}\n';
    mensaje += '*Vencimiento:* ${cxc.fechaVencimiento}\n';
    if (diasAtraso > 0) {
      mensaje += '*Días de atraso:* $diasAtraso días\n';
    }
    mensaje += '*Monto:* ${currencyFormatter.format(cxc.montoPendiente)}\n\n';
    mensaje += 'Por favor, contáctenos para coordinar el pago. Gracias.';

    String phone = (cxc.clienteObj?.whatsapp ?? '').toString().replaceAll(
      RegExp(r'\D'),
      '',
    );
    if (!phone.startsWith('1') && phone.length == 10) {
      phone = '1$phone';
    }

    if (phone.isNotEmpty) {
      final url = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(mensaje)}',
      );
      if (!await launchUrl(url)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo abrir WhatsApp',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

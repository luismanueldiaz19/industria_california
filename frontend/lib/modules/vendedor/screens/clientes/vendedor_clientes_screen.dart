import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/app_theme.dart';
import '../../../led_house/models/ledhouse_cliente.dart';
import '../../../led_house/services/ledhouse_cliente_service.dart';
import 'vendedor_cliente_form_screen.dart';

class VendedorClientesScreen extends StatefulWidget {
  const VendedorClientesScreen({super.key});

  @override
  State<VendedorClientesScreen> createState() => _VendedorClientesScreenState();
}

class _VendedorClientesScreenState extends State<VendedorClientesScreen>
    with TickerProviderStateMixin {
  final LedhouseClienteService _service = LedhouseClienteService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  List<LedhouseCliente> _clientes = [];
  bool _isLoading = true;
  String? _error;

  int _currentPage = 1;
  int _lastPage = 1;
  int _totalClientes = 0;
  bool _isFetchingMore = false;
  String _currentSort = 'recent';

  late AnimationController _fabAnimController;

  static const List<Color> _avatarColors = [
    AppTheme.ledhouseBlue,
    AppTheme.successColor,
    AppTheme.dangerColor,
    Color(0xFFFBBC05),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
    Color(0xFF607D8B),
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scrollController.addListener(_onScroll);
    _fetchClientes();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMore &&
        _currentPage < _lastPage) {
      _fetchMoreClientes();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _fetchClientes);
  }

  Future<void> _fetchClientes() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _clientes.clear();
    });
    try {
      final result = await _service.getPaginatedClientes(
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        page: 1,
        sort: _currentSort,
      );
      if (mounted) {
        setState(() {
          _clientes = result['data'] as List<LedhouseCliente>;
          _currentPage = result['current_page'];
          _lastPage = result['last_page'];
          _totalClientes = result['total'];
          _isLoading = false;
        });
        _fabAnimController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMoreClientes() async {
    if (_isFetchingMore) return;
    setState(() => _isFetchingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final result = await _service.getPaginatedClientes(
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        page: nextPage,
        sort: _currentSort,
      );
      if (mounted) {
        setState(() {
          final newClientes = result['data'] as List<LedhouseCliente>;
          _clientes.addAll(newClientes);
          _currentPage = result['current_page'];
          _lastPage = result['last_page'];
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingMore = false);
      }
    }
  }

  void _showForm([LedhouseCliente? cliente]) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => VendedorClienteFormScreen(cliente: cliente),
    ).then((updated) {
      if (updated == true) _fetchClientes();
    });
  }

  Color _avatarColor(String nombre) {
    return _avatarColors[nombre.hashCode.abs() % _avatarColors.length];
  }

  String _initials(String nombre) {
    final parts = nombre.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Container(
        color: const Color(0xFF121212), // Fondo oscuro fuera del área móvil
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ClipRRect(
              // Redondeamos los bordes para dar apariencia de dispositivo móvil si está en escritorio
              borderRadius: BorderRadius.circular(
                MediaQuery.of(context).size.width > 500 ? 20 : 0,
              ),
              child: Scaffold(
                backgroundColor: AppTheme.bgColor,

                appBar: AppBar(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  title: Text(
                    'Directorio de Clientes',
                    style: TextStyle(color: Colors.white),
                  ),
                  actions: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.sort_rounded),
                      tooltip: 'Ordenar',
                      onSelected: (String value) {
                        setState(() {
                          _currentSort = value;
                        });
                        _fetchClientes();
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'recent',
                          child: Text('Más recientes'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'name_asc',
                          child: Text('Nombre (A-Z)'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'name_desc',
                          child: Text('Nombre (Z-A)'),
                        ),
                      ],
                    ),
                  ],
                ),
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: _buildSearchBar(),
                    ),
                    if (!_isLoading && _clientes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Text(
                          'Mostrando ${_clientes.length} de $_totalClientes clientes (Página $_currentPage de $_lastPage)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Expanded(child: _buildContent()),
                  ],
                ),
                floatingActionButton: FloatingActionButton.extended(
                  onPressed: () => _showForm(),
                  backgroundColor: AppTheme.primaryBlue,
                  icon: const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Registrar cliente',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o WhatsApp...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade400,
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _fetchClientes();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppTheme.primaryBlue),
          strokeWidth: 3,
        ),
      );
    }

    if (_error != null) {
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
              onPressed: _fetchClientes,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_clientes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_alt_outlined,
                size: 48,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No se encontraron resultados'
                  : 'Aún no hay clientes',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3C4043),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Prueba con otro término de búsqueda'
                  : 'Agrega tu primer cliente usando el botón abajo',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
      itemCount: _clientes.length + (_isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _clientes.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryBlue),
                strokeWidth: 2,
              ),
            ),
          );
        }
        final c = _clientes[index];
        return _buildClienteCard(c, index);
      },
    );
  }

  Widget _buildClienteCard(LedhouseCliente c, int index) {
    final color = _avatarColor(c.nombre);
    final initials = _initials(c.nombre);
    final hasAddress = c.direccion != null && c.direccion!.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showForm(c),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: color, width: 3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              c.nombre,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (c.createdAt != null && DateTime.now().difference(c.createdAt!).inDays <= 7) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: const Text(
                                'Nuevo',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            size: 12,
                            color: const Color(0xFF25D366),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            c.whatsapp ?? '----',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      if (hasAddress) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                c.direccion!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

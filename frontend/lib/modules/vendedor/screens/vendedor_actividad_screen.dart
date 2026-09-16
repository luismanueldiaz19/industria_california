import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/constants.dart';
import '../../../core/themes/app_theme.dart';
import '../services/vendedor_cxc_service.dart';
import '../widgets/vendedor_alerta_card.dart';
import 'vendedor_cxc_detalle_screen.dart';
import '../models/vendedor_alerta_model.dart';

class VendedorActividadScreen extends StatefulWidget {
  const VendedorActividadScreen({super.key});

  @override
  State<VendedorActividadScreen> createState() =>
      _VendedorActividadScreenState();
}

class _VendedorActividadScreenState extends State<VendedorActividadScreen> {
  final _service = VendedorCxcService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  List<VendedorAlertaModel> _alertas = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  String? _error;

  // Filtros
  String _estadoFiltro = 'pendiente';
  String _tipoFiltro = 'todos';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _tiposAlerta = [
    'todos',
    'pago_recibido',
    'credito',
    'debito',
    'retencion',
    'devolucion',
    'mer_no_entregada',
    'anular',
    'diferencia',
    'informacion',
    'consulta',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMore &&
        _currentPage < _lastPage) {
      _loadMore();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _load();
    });
  }

  Future<void> _load({bool refresh = true}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _error = null;
        _alertas.clear();
      });
    } else {
      setState(() => _isFetchingMore = true);
    }

    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    try {
      final data = await _service.getMisAlertas(
        token: token,
        page: _currentPage,
        search: _searchController.text,
        estado: _estadoFiltro == 'todos' ? null : _estadoFiltro,
        tipo: _tipoFiltro == 'todos' ? null : _tipoFiltro,
        startDate: _startDate != null
            ? DateFormat('yyyy-MM-dd').format(_startDate!)
            : null,
        endDate: _endDate != null
            ? DateFormat('yyyy-MM-dd').format(_endDate!)
            : null,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _alertas = data['data'] as List<VendedorAlertaModel>;
          } else {
            _alertas.addAll(data['data'] as List<VendedorAlertaModel>);
          }
          _currentPage = data['current_page'];
          _lastPage = data['last_page'];
          _total = data['total'];
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isFetchingMore = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _loadMore() async {
    _currentPage++;
    await _load(refresh: false);
  }

  void _descargarPdf() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final queryParams = <String, String>{'token': token};

    if (_searchController.text.trim().isNotEmpty) {
      queryParams['search'] = _searchController.text.trim();
    }
    if (_estadoFiltro != 'todos') {
      queryParams['estado'] = _estadoFiltro;
    }
    if (_tipoFiltro != 'todos') {
      queryParams['tipo'] = _tipoFiltro;
    }
    if (_startDate != null) {
      queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(_startDate!);
    }
    if (_endDate != null) {
      queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(_endDate!);
    }

    final uri = Uri.parse(
      '$host/api/v1/cxc/alertas/pdf',
    ).replace(queryParameters: queryParams);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF.')),
        );
      }
    }
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtros Avanzados',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Estado de la Alerta',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _estadoFiltro,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'todos',
                        child: Text(
                          'Todos los estados',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'pendiente',
                        child: Text(
                          'Pendiente',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'revisada',
                        child: Text('Revisada', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'procesada',
                        child: Text(
                          'Procesada',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                    onChanged: (val) =>
                        setModalState(() => _estadoFiltro = val!),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tipo de Alerta',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _tipoFiltro,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    items: _tiposAlerta.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(
                          t.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setModalState(() => _tipoFiltro = val!),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Rango de Fechas',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (date != null)
                              setModalState(() => _startDate = date);
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _startDate == null
                                ? 'Inicio'
                                : DateFormat('dd/MM/yyyy').format(_startDate!),
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (date != null)
                              setModalState(() => _endDate = date);
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _endDate == null
                                ? 'Fin'
                                : DateFormat('dd/MM/yyyy').format(_endDate!),
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setModalState(() {
                              _estadoFiltro = 'pendiente';
                              _tipoFiltro = 'todos';
                              _startDate = null;
                              _endDate = null;
                              _searchController.clear();
                            });
                          },
                          child: const Text('Limpiar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _load();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Aplicar Filtros'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar por cliente o doc...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade400,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                isDense: true,
              ),
            ),
          ),
          Container(height: 30, width: 1, color: Colors.grey.shade200),
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: AppTheme.primaryBlue,
              size: 22,
            ),
            onPressed: _openFilters,
            tooltip: 'Filtros Avanzados',
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        appBar: AppBar(
          title: const Text(
            'Consulta de Alertas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
              onPressed: _descargarPdf,
              tooltip: 'Generar PDF',
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => _load(),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildSearchBar(),
            ),
            if (!_isLoading && _alertas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Text(
                      'Mostrando $_total alertas (Pag. $_currentPage/$_lastPage)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(
                          AppTheme.primaryBlue,
                        ),
                        strokeWidth: 3,
                      ),
                    )
                  : _alertas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No se encontraron alertas.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: _alertas.length + (_isFetchingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _alertas.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        final alerta = _alertas[index];
                        return VendedorAlertaCard(
                          alerta: alerta,
                          onTap: () {
                            if (alerta.cxc == null) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VendedorCxcDetalleScreen(
                                  cxcData: {
                                    'id': alerta.cxc!.id,
                                    'documento': alerta.cxc!.documento,
                                    'cliente': alerta.cxc!.cliente != null
                                        ? {
                                            'id': alerta.cxc!.cliente!.id,
                                            'nombre':
                                                alerta.cxc!.cliente!.nombre,
                                          }
                                        : null,
                                    'evidencias': alerta.cxc!.evidencias,
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

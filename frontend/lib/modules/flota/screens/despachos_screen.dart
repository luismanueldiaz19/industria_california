import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../camion_victual/models/camion_victual.dart';
import '../../camion_victual/providers/camion_victual_provider.dart';
import '../providers/chofer_provider.dart';
import '../widgets/camiones/camion_victual_form_modal.dart';
import '../widgets/despachos/despacho_camion_card.dart';
import '../widgets/despachos/despacho_camion_detalle_panel.dart';
import '../widgets/despachos/historial_viajes_modal.dart';

class DespachosScreen extends StatefulWidget {
  const DespachosScreen({super.key});

  @override
  State<DespachosScreen> createState() => _DespachosScreenState();
}

class _DespachosScreenState extends State<DespachosScreen> {
  final NumberFormat _currencyFmt = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
  );

  String _filtroEstado = 'todos';
  int? _filtroChoferId;
  String _searchQuery = '';
  int? _selectedCamionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  Future<void> _cargarDatos() async {
    final futures = [
      context.read<CamionVictualProvider>().fetchCamiones(),
      context.read<ChoferProvider>().fetchChoferes(),
    ];
    await Future.wait(futures);

    if (mounted) {
      final camiones = context.read<CamionVictualProvider>().camiones;
      if (_selectedCamionId == null && camiones.isNotEmpty) {
        setState(() {
          _selectedCamionId = camiones.first.id;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 880;
    final leftPanelWidth = screenWidth > 1300
        ? 340.0
        : (screenWidth > 1050 ? 300.0 : 270.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE31E24).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.route_outlined,
                color: Color(0xFFE31E24),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Gestión de Despachos y Camiones Virtuales',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Control y llenado de flota logística · Administración',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        shape: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        elevation: 0,
        actions: [
          // Historial de Viajes
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const HistorialViajesModal(),
              );
            },
            icon: const Icon(Icons.history, size: 16),
            label: const Text(
              'Historial Viajes',
              style: TextStyle(fontSize: 11),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Nuevo Camión Virtual
          ElevatedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const CamionVictualFormModal(),
              ).then((_) => _cargarDatos());
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Nuevo Camión', style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31E24),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF475569), size: 20),
            tooltip: 'Actualizar',
            onPressed: _cargarDatos,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<CamionVictualProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.camiones.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE31E24)),
            );
          }

          if (provider.error != null && provider.camiones.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _cargarDatos,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          // Filtrar camiones
          final camionesFiltrados = provider.camiones.where((c) {
            if (_filtroEstado != 'todos' && c.estado != _filtroEstado) {
              return false;
            }
            if (_filtroChoferId != null && c.choferID != _filtroChoferId) {
              return false;
            }
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              final matchesNombre = c.nombre.toLowerCase().contains(q);
              final matchesChofer =
                  c.choferNombre?.toLowerCase().contains(q) ?? false;
              final matchesVendedor =
                  c.vendedorNombre?.toLowerCase().contains(q) ?? false;
              if (!matchesNombre && !matchesChofer && !matchesVendedor) {
                return false;
              }
            }
            return true;
          }).toList();

          // Obtener camión seleccionado
          CamionVictual? camionSeleccionado;
          if (_selectedCamionId != null) {
            try {
              camionSeleccionado = provider.camiones.firstWhere(
                (c) => c.id == _selectedCamionId,
              );
            } catch (_) {
              if (camionesFiltrados.isNotEmpty) {
                camionSeleccionado = camionesFiltrados.first;
              }
            }
          } else if (camionesFiltrados.isNotEmpty) {
            camionSeleccionado = camionesFiltrados.first;
          }

          return Column(
            children: [
              // Barra de Métricas Superiores
              _buildMetricasGenerales(provider.camiones),

              // Contenido Principal
              Expanded(
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Panel Izquierdo: Lista de Camiones
                          SizedBox(
                            width: leftPanelWidth,
                            child: _buildListaCamiones(
                              provider.camiones,
                              camionesFiltrados,
                              camionSeleccionado,
                            ),
                          ),
                          const VerticalDivider(
                            width: 1,
                            color: Color(0xFFE2E8F0),
                          ),
                          // Panel Derecho: Detalle y Llenado del Camión
                          Expanded(
                            child: camionSeleccionado != null
                                ? DespachoCamionDetallePanel(
                                    camion: camionSeleccionado,
                                    onCamionUpdated: _cargarDatos,
                                  )
                                : _buildEmptySelectionState(),
                          ),
                        ],
                      )
                    : (camionSeleccionado != null && _selectedCamionId != null
                          ? Column(
                              children: [
                                Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => setState(
                                          () => _selectedCamionId = null,
                                        ),
                                        icon: const Icon(
                                          Icons.arrow_back,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Volver a la lista de camiones',
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF0F172A,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: DespachoCamionDetallePanel(
                                    camion: camionSeleccionado,
                                    onCamionUpdated: _cargarDatos,
                                  ),
                                ),
                              ],
                            )
                          : _buildListaCamiones(
                              provider.camiones,
                              camionesFiltrados,
                              null,
                            )),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricasGenerales(List<CamionVictual> camiones) {
    final totalCamiones = camiones.length;
    final armando = camiones.where((c) => c.estado == 'armando').length;
    final listos = camiones.where((c) => c.estado == 'listo').length;
    final enRuta = camiones.where((c) => c.estado == 'en_ruta').length;
    final montoTotalFlota = camiones.fold(0.0, (sum, c) => sum + c.montoTotal);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatChip(
              'Total Camiones',
              '$totalCamiones',
              Icons.local_shipping_outlined,
              const Color(0xFF475569),
            ),
            const SizedBox(width: 8),
            _buildStatChip(
              'En Armando',
              '$armando',
              Icons.inventory_2_outlined,
              const Color(0xFFD97706),
            ),
            const SizedBox(width: 8),
            _buildStatChip(
              'Listos p/ Salir',
              '$listos',
              Icons.check_circle_outline,
              const Color(0xFF16A34A),
            ),
            const SizedBox(width: 8),
            _buildStatChip(
              'En Ruta',
              '$enRuta',
              Icons.departure_board,
              const Color(0xFF2563EB),
            ),
            const SizedBox(width: 12),
            Container(height: 20, width: 1, color: const Color(0xFFE2E8F0)),
            const SizedBox(width: 12),
            _buildStatChip(
              'Total Facturado en Flota',
              _currencyFmt.format(montoTotalFlota),
              Icons.attach_money,
              const Color(0xFF16A34A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaCamiones(
    List<CamionVictual> todosLosCamiones,
    List<CamionVictual> camionesFiltrados,
    CamionVictual? camionSeleccionado,
  ) {
    return Column(
      children: [
        // Buscador y Selector de Chofer
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              // Search Field
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Buscar camión, chofer o vendedor...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF64748B),
                    size: 16,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFE31E24)),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Filter by Chofer Dropdown
              Consumer<ChoferProvider>(
                builder: (context, choferProv, _) {
                  return DropdownButtonFormField<int?>(
                    initialValue: _filtroChoferId,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 11,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Filtrar por Conductor',
                      labelStyle: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFE31E24)),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todos los Conductores'),
                      ),
                      ...choferProv.choferes.map((ch) {
                        return DropdownMenuItem<int?>(
                          value: ch.id,
                          child: Text(ch.name ?? 'Chofer #${ch.id}'),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _filtroChoferId = val),
                  );
                },
              ),
            ],
          ),
        ),

        // Filtros de Estado (Chips)
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('todos', 'Todos'),
                const SizedBox(width: 6),
                _buildFilterChip('armando', 'Armando'),
                const SizedBox(width: 6),
                _buildFilterChip('listo', 'Listos'),
                const SizedBox(width: 6),
                _buildFilterChip('en_ruta', 'En Ruta'),
                const SizedBox(width: 6),
                _buildFilterChip('vacio', 'Vacíos'),
                const SizedBox(width: 6),
                _buildFilterChip('cerrado', 'Cerrados'),
              ],
            ),
          ),
        ),

        // List of Truck Cards
        Expanded(
          child: camionesFiltrados.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 40,
                        color: Color(0xFFCBD5E1),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No hay camiones con estos filtros',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: camionesFiltrados.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final camion = camionesFiltrados[idx];
                    final isSelected = camion.id == camionSeleccionado?.id;

                    return DespachoCamionCard(
                      camion: camion,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedCamionId = camion.id;
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String valor, String etiqueta) {
    final isSelected = _filtroEstado == valor;
    return InkWell(
      onTap: () => setState(() => _filtroEstado = valor),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE31E24) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE31E24)
                : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          etiqueta,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySelectionState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.touch_app_outlined, size: 56, color: Color(0xFFCBD5E1)),
          SizedBox(height: 12),
          Text(
            'Selecciona un Camión Virtual a la izquierda para gestionarlo',
            style: TextStyle(
              color: Color(0xFF334155),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Podrás asignar el conductor, cargar pedidos facturados y gestionar entregas.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

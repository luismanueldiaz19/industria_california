import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chofer.dart';
import '../providers/chofer_provider.dart';
import '../widgets/choferes/chofer_form_modal.dart';

class ChoferesScreen extends StatefulWidget {
  const ChoferesScreen({super.key});

  @override
  State<ChoferesScreen> createState() => _ChoferesScreenState();
}

class _ChoferesScreenState extends State<ChoferesScreen> {
  String _searchQuery = '';
  Chofer? _selectedChofer;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChoferProvider>().fetchChoferes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isPanelOpen = _selectedChofer != null || _isCreating;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1C1E),
      appBar: AppBar(
        title: const Text(
          'Gestión de Choferes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFF2C2F33),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf,
              color: Colors.white70,
              size: 20,
            ),
            tooltip: 'Exportar PDF',
            onPressed: () {
              context.read<ChoferProvider>().generarPdf();
            },
          ),
          IconButton(
            icon: Icon(
              _isCreating ? Icons.close : Icons.person_add_alt_1,
              color: _isCreating ? const Color(0xFFE31E24) : Colors.white,
              size: 20,
            ),
            tooltip: _isCreating ? 'Cerrar Formulario' : 'Añadir Chofer',
            onPressed: () {
              setState(() {
                if (_isCreating) {
                  _isCreating = false;
                } else {
                  _selectedChofer = null;
                  _isCreating = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            onPressed: () {
              context.read<ChoferProvider>().fetchChoferes();
            },
          ),
        ],
      ),
      body: Consumer<ChoferProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE31E24)),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Text(
                'Error: ${provider.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final filteredChoferes = provider.choferes.where((c) {
            final query = _searchQuery.toLowerCase();
            return (c.name?.toLowerCase().contains(query) ?? false) ||
                (c.username?.toLowerCase().contains(query) ?? false) ||
                (c.numeroLicencia?.toLowerCase().contains(query) ?? false) ||
                (c.estado.toLowerCase().contains(query));
          }).toList();

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Panel Izquierdo: Buscador y Lista de Choferes
              Expanded(
                child: Column(
                  children: [
                    // Barra de Búsqueda
                    Container(
                      color: const Color(0xFF2C2F33),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: SizedBox(
                        height: 32,
                        child: TextField(
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Buscar por nombre, usuario, licencia o estado...',
                            hintStyle: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white54,
                              size: 16,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1A1C1E),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ),

                    // Contador / Encabezado de Lista
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      color: const Color(0xFF232529),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 14,
                            color: Colors.white54,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'CHOFERES REGISTRADOS (${filteredChoferes.length})',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Lista de Choferes (reemplaza DataTable)
                    Expanded(
                      child: RefreshIndicator(
                        color: const Color(0xFFE31E24),
                        backgroundColor: const Color(0xFF232529),
                        onRefresh: () async {
                          await provider.fetchChoferes();
                        },
                        child: filteredChoferes.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 100),
                                  Center(
                                    child: Text(
                                      'No se encontraron choferes.',
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(10),
                                itemCount: filteredChoferes.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final chofer = filteredChoferes[index];
                                  final isSelected =
                                      _selectedChofer?.id == chofer.id;
                                  final isActivo = chofer.estado == 'activo';
                                  final isVacaciones =
                                      chofer.estado == 'vacaciones';

                                  Color statusColor = Colors.grey;
                                  if (isActivo) {
                                    statusColor = const Color(0xFF4CAF50);
                                  } else if (isVacaciones) {
                                    statusColor = const Color(0xFFFF9800);
                                  }

                                  String vencimiento = '';
                                  if (chofer.vencimientoLicencia != null) {
                                    vencimiento = chofer.vencimientoLicencia!
                                        .split('T')
                                        .first;
                                  }

                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        setState(() {
                                          if (_selectedChofer?.id ==
                                                  chofer.id &&
                                              !_isCreating) {
                                            _selectedChofer = null;
                                          } else {
                                            _selectedChofer = chofer;
                                            _isCreating = false;
                                          }
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(
                                                  0xFFE31E24,
                                                ).withValues(alpha: 0.12)
                                              : const Color(0xFF2C2F33),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFFE31E24)
                                                : Colors.white10,
                                            width: isSelected ? 1.2 : 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Avatar con inicial
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? const Color(0xFFE31E24)
                                                    : const Color(0xFF1A1C1E),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? const Color(0xFFE31E24)
                                                      : Colors.white12,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  (chofer.name != null &&
                                                          chofer
                                                              .name!
                                                              .isNotEmpty)
                                                      ? chofer.name![0]
                                                            .toUpperCase()
                                                      : 'C',
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : Colors.white70,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Información del Chofer
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Fila 1: Nombre + Badge Estado
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          chofer.name ??
                                                              'Sin nombre',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: statusColor
                                                              .withValues(
                                                                alpha: 0.12,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                          border: Border.all(
                                                            color: statusColor
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          chofer.estado
                                                              .toUpperCase(),
                                                          style: TextStyle(
                                                            color: statusColor,
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),

                                                  // Fila 2: Usuario y Detalles
                                                  Wrap(
                                                    spacing: 12,
                                                    runSpacing: 4,
                                                    crossAxisAlignment:
                                                        WrapCrossAlignment
                                                            .center,
                                                    children: [
                                                      // Usuario
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .account_circle_outlined,
                                                            size: 13,
                                                            color:
                                                                Colors.white38,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            '@${chofer.username ?? 'sin_usuario'}',
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                  fontSize: 11,
                                                                ),
                                                          ),
                                                        ],
                                                      ),

                                                      // Licencia
                                                      if (chofer.numeroLicencia !=
                                                              null &&
                                                          chofer
                                                              .numeroLicencia!
                                                              .isNotEmpty)
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .badge_outlined,
                                                              size: 13,
                                                              color: Colors
                                                                  .white38,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              'Lic: ${chofer.numeroLicencia}${chofer.tipoLicencia != null && chofer.tipoLicencia!.isNotEmpty ? " (${chofer.tipoLicencia})" : ""}',
                                                              style:
                                                                  const TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                    fontSize:
                                                                        11,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),

                                                      // Vencimiento
                                                      if (vencimiento
                                                          .isNotEmpty)
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .calendar_today_outlined,
                                                              size: 12,
                                                              color: Colors
                                                                  .white38,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              'Vence: $vencimiento',
                                                              style:
                                                                  const TextStyle(
                                                                    color: Colors
                                                                        .white54,
                                                                    fontSize:
                                                                        11,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),

                                                      // Contacto Emergencia
                                                      if (chofer.contactoEmergencia !=
                                                              null &&
                                                          chofer
                                                              .contactoEmergencia!
                                                              .isNotEmpty)
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .phone_outlined,
                                                              size: 12,
                                                              color: Colors
                                                                  .white38,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              chofer
                                                                  .contactoEmergencia!,
                                                              style:
                                                                  const TextStyle(
                                                                    color: Colors
                                                                        .white54,
                                                                    fontSize:
                                                                        11,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),

                                            const SizedBox(width: 8),

                                            // Indicador de selección / acción
                                            Icon(
                                              isSelected
                                                  ? Icons.edit
                                                  : Icons.chevron_right,
                                              size: 18,
                                              color: isSelected
                                                  ? const Color(0xFFE31E24)
                                                  : Colors.white30,
                                            ),
                                          ],
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
              ),

              // Panel Derecho: Formulario Chofer (Side Panel) o Dashboard de Resumen
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: Colors.white12,
              ),
              SizedBox(
                width: 450,
                child: Material(
                  color: const Color(0xFF2C2F33),
                  child: isPanelOpen
                      ? ChoferFormWidget(
                          key: ValueKey(
                            _isCreating
                                ? 'create'
                                : 'edit_${_selectedChofer?.id}',
                          ),
                          chofer: _isCreating ? null : _selectedChofer,
                          onClose: () {
                            setState(() {
                              _selectedChofer = null;
                              _isCreating = false;
                            });
                          },
                          onSuccess: () {
                            setState(() {
                              _selectedChofer = null;
                              _isCreating = false;
                            });
                            context.read<ChoferProvider>().fetchChoferes();
                          },
                        )
                      : _buildResumenPanel(context, provider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResumenPanel(BuildContext context, ChoferProvider provider) {
    final totalChoferes = provider.choferes.length;
    final activos =
        provider.choferes.where((c) => c.estado == 'activo').length;
    final vacaciones =
        provider.choferes.where((c) => c.estado == 'vacaciones').length;
    final inactivos =
        provider.choferes.where((c) => c.estado == 'inactivo').length;
    final conLicencia = provider.choferes
        .where(
          (c) =>
              c.numeroLicencia != null && c.numeroLicencia!.trim().isNotEmpty,
        )
        .length;
    final conEmergencia = provider.choferes
        .where(
          (c) =>
              c.contactoEmergencia != null &&
              c.contactoEmergencia!.trim().isNotEmpty,
        )
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            children: [
              const Icon(
                Icons.dashboard_customize_outlined,
                color: Color(0xFFE31E24),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'PANEL DE CONTROL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white54, size: 16),
                tooltip: 'Actualizar datos',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => provider.fetchChoferes(),
              ),
            ],
          ),
          const Divider(height: 18, color: Colors.white12),

          // Tarjeta de Selección / Call to action
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE31E24).withValues(alpha: 0.10),
                  const Color(0xFF1A1C1E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFE31E24).withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE31E24).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE31E24).withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_pin_outlined,
                    color: Color(0xFFE31E24),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ningún Chofer Seleccionado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Selecciona un chofer de la lista para ver y editar sus datos, o registra uno nuevo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.person_add_alt_1,
                      size: 14,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'AÑADIR NUEVO CHOFER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedChofer = null;
                        _isCreating = true;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Título de Métricas
          const Row(
            children: [
              Icon(Icons.bar_chart_outlined, size: 14, color: Colors.white54),
              SizedBox(width: 6),
              Text(
                'MÉTRICAS DE LA FLOTA',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Tarjetas de Métricas (2x2 Grid)
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Choferes',
                  value: '$totalChoferes',
                  icon: Icons.people_alt_outlined,
                  color: const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  title: 'Activos',
                  value: '$activos',
                  subtitle: totalChoferes > 0
                      ? '${((activos / totalChoferes) * 100).toInt()}%'
                      : null,
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'En Vacaciones',
                  value: '$vacaciones',
                  icon: Icons.beach_access_outlined,
                  color: const Color(0xFFFF9800),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  title: 'Inactivos',
                  value: '$inactivos',
                  icon: Icons.pause_circle_outline,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Requisitos y Licencias
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1C1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 14,
                      color: Color(0xFF4CAF50),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'ESTADO DE REQUISITOS',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildProgressRow(
                  label: 'Licencias registradas',
                  current: conLicencia,
                  total: totalChoferes,
                  color: const Color(0xFF2196F3),
                ),
                const SizedBox(height: 8),
                _buildProgressRow(
                  label: 'Contactos de emergencia',
                  current: conEmergencia,
                  total: totalChoferes,
                  color: const Color(0xFF4CAF50),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Herramientas Rápidas
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 14,
                    color: Color(0xFFE31E24),
                  ),
                  label: const Text(
                    'EXPORTAR PDF',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white12),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () {
                    provider.generarPdf();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(
                    Icons.sync,
                    size: 14,
                    color: Colors.white70,
                  ),
                  label: const Text(
                    'SINCRONIZAR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white12),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () {
                    provider.fetchChoferes();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tip Informativo
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF232529),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Los choferes activos pueden ser asignados a los vehículos desde el módulo de Gestión de Vehículos.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow({
    required String label,
    required int current,
    required int total,
    required Color color,
  }) {
    final ratio = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            Text(
              '$current de $total',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 4,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}


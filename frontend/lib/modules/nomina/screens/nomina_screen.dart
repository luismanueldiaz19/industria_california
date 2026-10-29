import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nomina_provider.dart';
import '../widgets/nomina_escalas_tab.dart';
import '../widgets/nomina_historial_tab.dart';
import '../widgets/nomina_procesar_tab.dart';
import '../widgets/nomina_recurrentes_tab.dart';

class NominaScreen extends StatefulWidget {
  const NominaScreen({super.key});

  @override
  State<NominaScreen> createState() => _NominaScreenState();
}

class _NominaScreenState extends State<NominaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Superior ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestión de Nómina y Salarios',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Control de pagos, retenciones y préstamos de colaboradores',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<NominaProvider>(
                  builder: (context, prov, _) {
                    return Tooltip(
                      message: 'Refrescar nóminas',
                      child: InkWell(
                        onTap: prov.isLoading ? null : () => prov.loadNominas(),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              prov.isLoading
                                  ? const SizedBox(
                                      width: 13,
                                      height: 13,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF2563EB),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.refresh_rounded,
                                      size: 15,
                                      color: Color(0xFF475569),
                                    ),
                              const SizedBox(width: 6),
                              const Text(
                                'Refrescar',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Barra de Navegación por Tabs ─────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF2563EB),
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.bolt_outlined, size: 16),
                  text: 'Procesar Nómina',
                ),
                Tab(
                  icon: Icon(Icons.history_rounded, size: 16),
                  text: 'Historial de Nóminas',
                ),
                Tab(
                  icon: Icon(Icons.credit_score_outlined, size: 16),
                  text: 'Préstamos y Recurrentes',
                ),
                Tab(
                  icon: Icon(Icons.table_chart_outlined, size: 16),
                  text: 'Escala DGII & Parámetros',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // ── Contenido de los Tabs ────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const NominaProcesarTab(),
                NominaHistorialTab(
                  onSelectNomina: (id) {
                    context.read<NominaProvider>().selectNomina(id);
                    _tabController.animateTo(0);
                  },
                ),
                const NominaRecurrentesTab(),
                const NominaEscalasTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

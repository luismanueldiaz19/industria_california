import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

/// Pantalla de demostración de "Agregar Cliente" utilizando el paquete oficial [showcaseview] (v5.1+).
/// Muestra cómo registrar [ShowcaseView], envolver los widgets en [Showcase] y arrancarlo con persistencia en [SharedPreferences].
class DemoCoachMarkScreen extends StatefulWidget {
  const DemoCoachMarkScreen({super.key});

  @override
  State<DemoCoachMarkScreen> createState() => _DemoCoachMarkScreenState();
}

class _DemoCoachMarkScreenState extends State<DemoCoachMarkScreen> {
  // GlobalKeys para anclar los Showcase
  final GlobalKey _keyRnc = GlobalKey();
  final GlobalKey _keyGps = GlobalKey();
  final GlobalKey _keyDiasRuta = GlobalKey();
  final GlobalKey _keyCredito = GlobalKey();
  final GlobalKey _keyGuardar = GlobalKey();

  String _diaSeleccionado = 'Lunes y Jueves';
  bool _gpsCapturado = false;

  @override
  void initState() {
    super.initState();
    // En showcaseview 5.1+, se registra el controlador con soporte para OMITIR (skip)
    ShowcaseView.register(
      enableAutoScroll: true,
      blurValue: 1.5,
      // Opción A: Botón flotante visible en la esquina para omitir el tour en cualquier momento
      globalFloatingActionWidget: (showcaseContext) => FloatingActionWidget(
        top: 16,
        right: 16,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: TextButton.icon(
            onPressed: () => ShowcaseView.get().dismiss(),
            icon: const Icon(Icons.close, color: Colors.white, size: 14),
            label: const Text(
              'Omitir Tour',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      // Opción B: Botón de omitir dentro del mismo tooltip con Anterior y Siguiente
      globalTooltipActionConfig: const TooltipActionConfig(
        position: TooltipActionPosition.outside,
        alignment: MainAxisAlignment.spaceBetween,
        gapBetweenContentAndAction: 10,
      ),
      globalTooltipActions: const [
        TooltipActionButton(
          type: TooltipDefaultActionType.previous,
          name: 'Anterior',
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.skip,
          name: 'Omitir',
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          name: 'Siguiente',
        ),
      ],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarYEjecutarTour();
    });
  }

  /// Verifica si el usuario ya vio el tour en SharedPreferences
  Future<void> _verificarYEjecutarTour({bool forzar = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final bool yaVisto = prefs.getBool('tour_demo_cliente_v1') ?? false;

    if ((!yaVisto || forzar) && mounted) {
      ShowcaseView.get().startShowCase([
        _keyRnc,
        _keyGps,
        _keyDiasRuta,
        _keyCredito,
        _keyGuardar,
      ]);
      await prefs.setBool('tour_demo_cliente_v1', true);
    }
  }

  void _reiniciarTourManualmente() {
    ShowcaseView.get().startShowCase([
      _keyRnc,
      _keyGps,
      _keyDiasRuta,
      _keyCredito,
      _keyGuardar,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Nuevo Cliente (showcaseview)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _reiniciarTourManualmente,
            icon: const Icon(
              Icons.auto_awesome,
              color: Color(0xFFFBBF24),
              size: 18,
            ),
            label: const Text(
              'Reiniciar Tour',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner informativo
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Ejemplo con showcaseview oficial. Toca cualquier elemento resaltado para avanzar al siguiente paso.',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tarjeta 1: Datos Fiscales
                _buildSectionCard(
                  title: '1. Datos Fiscales y del Negocio',
                  icon: Icons.storefront_outlined,
                  children: [
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Nombre Comercial / Negocio',
                        hintText: 'Ej: Colmado El Progreso',
                        prefixIcon: Icon(Icons.business_outlined, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Showcase 1: RNC
                    Showcase(
                      key: _keyRnc,
                      title: '1. Validación de RNC Automática',
                      description:
                          'Ingresa el RNC o Cédula y presiona "Validar" para consultar los datos fiscales en DGII automáticamente.',
                      targetPadding: const EdgeInsets.all(4),
                      targetShapeBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'RNC o Cédula *',
                                hintText: '101-1234567-8',
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Consultando RNC en DGII...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            icon: const Icon(Icons.search, size: 16),
                            label: const Text(
                              'Validar',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Teléfono de Contacto',
                        hintText: '809-555-0199',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tarjeta 2: Ubicación & GPS
                _buildSectionCard(
                  title: '2. Ubicación y Geolocalización',
                  icon: Icons.map_outlined,
                  children: [
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Dirección física / Referencia',
                        hintText: 'C/ Duarte #12, frente al parque',
                        prefixIcon: Icon(Icons.pin_drop_outlined, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Showcase 2: GPS
                    Showcase(
                      key: _keyGps,
                      title: '2. Geolocalización del Cliente',
                      description:
                          'Captura las coordenadas frente al colmado para que los choferes y camiones ubiquen el punto de entrega en el mapa.',
                      targetPadding: const EdgeInsets.all(4),
                      targetShapeBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _gpsCapturado
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFDBEAFE),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _gpsCapturado ? Icons.check : Icons.gps_fixed,
                                color: _gpsCapturado
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF2563EB),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _gpsCapturado
                                        ? 'Coordenadas: 18.4861° N, 69.9312° W'
                                        : 'Coordenadas GPS no capturadas',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: _gpsCapturado
                                          ? const Color(0xFF166534)
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                  const Text(
                                    'Presiona para registrar la ubicación actual',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() => _gpsCapturado = !_gpsCapturado);
                              },
                              icon: const Icon(
                                Icons.location_searching,
                                size: 14,
                              ),
                              label: Text(
                                _gpsCapturado ? 'Actualizar' : 'Capturar',
                                style: const TextStyle(fontSize: 11),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                side: const BorderSide(
                                  color: Color(0xFF2563EB),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tarjeta 3: Días de Ruta
                _buildSectionCard(
                  title: '3. Frecuencia y Días de Entrega',
                  icon: Icons.local_shipping_outlined,
                  children: [
                    // Showcase 3: Días de Ruta
                    Showcase(
                      key: _keyDiasRuta,
                      title: '3. Planificación de Rutas',
                      description:
                          'Selecciona qué días de la semana debe visitar este cliente el camión victual para su distribución semanal.',
                      targetPadding: const EdgeInsets.all(4),
                      targetShapeBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Días de visita asignados para este cliente:',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children:
                                  [
                                    'Lunes y Jueves',
                                    'Martes y Viernes',
                                    'Miércoles y Sábado',
                                    'Diario',
                                  ].map((dia) {
                                    final isSel = _diaSeleccionado == dia;
                                    return ChoiceChip(
                                      label: Text(
                                        dia,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSel
                                              ? Colors.white
                                              : const Color(0xFF334155),
                                        ),
                                      ),
                                      selected: isSel,
                                      selectedColor: const Color(0xFF2563EB),
                                      backgroundColor: const Color(0xFFF1F5F9),
                                      onSelected: (val) {
                                        if (val) {
                                          setState(
                                            () => _diaSeleccionado = dia,
                                          );
                                        }
                                      },
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tarjeta 4: Condiciones Comerciales
                _buildSectionCard(
                  title: '4. Condiciones Comerciales',
                  icon: Icons.payments_outlined,
                  children: [
                    // Showcase 4: Crédito
                    Showcase(
                      key: _keyCredito,
                      title: '4. Políticas de Crédito',
                      description:
                          'Configura el límite de crédito en RD\$ y el plazo máximo de pago en días para controlar la cartera de cuentas por cobrar.',
                      targetPadding: const EdgeInsets.all(4),
                      targetShapeBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'Límite de Crédito RD\$',
                                hintText: '50,000.00',
                                prefixIcon: Icon(Icons.attach_money, size: 20),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'Días Plazo',
                                hintText: '15 días',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Showcase 5: Botón Guardar
                Showcase(
                  key: _keyGuardar,
                  title: '5. Guardar y Sincronizar',
                  description:
                      'Al confirmar, el cliente se guarda en el servidor y queda disponible de inmediato para tomar pedidos.',
                  targetPadding: const EdgeInsets.all(4),
                  targetShapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Simulación: Cliente guardado con éxito.',
                          ),
                          backgroundColor: Color(0xFF16A34A),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('GUARDAR NUEVO CLIENTE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          ...children,
        ],
      ),
    );
  }
}

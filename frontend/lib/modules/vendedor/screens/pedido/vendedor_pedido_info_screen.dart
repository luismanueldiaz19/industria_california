import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pedido_form_provider.dart';
import '../../widgets/pedido_cliente_selector.dart';
import '../../widgets/pedido_ruta_selector.dart';

import '../../../../services/gps_service.dart';

class VendedorPedidoInfoScreen extends StatefulWidget {
  final VoidCallback onNext;

  const VendedorPedidoInfoScreen({super.key, required this.onNext});

  @override
  State<VendedorPedidoInfoScreen> createState() =>
      _VendedorPedidoInfoScreenState();
}

class _VendedorPedidoInfoScreenState extends State<VendedorPedidoInfoScreen> {
  bool _isCapturingGps = false;
  late TextEditingController _latitudCtrl;
  late TextEditingController _longitudCtrl;

  @override
  void initState() {
    super.initState();
    _latitudCtrl = TextEditingController();
    _longitudCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _latitudCtrl.dispose();
    _longitudCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PedidoFormProvider>();
    final _comentarioCtrl = TextEditingController(text: provider.comentario);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Información del Cliente *', Icons.person_outline),
          const SizedBox(height: 12),
          PedidoClienteSelector(
            selected: provider.cliente,
            onChanged: (c) => provider.setCliente(c),
          ),

          const SizedBox(height: 24),
          _sectionTitle('Ruta de Entrega (opcional)', Icons.map_outlined),
          const SizedBox(height: 12),
          PedidoRutaSelector(
            selected: provider.ruta,
            onChanged: (r) => provider.setRuta(r),
          ),

          const SizedBox(height: 24),
          _sectionTitle('Comentarios o Notas (opcional)', Icons.notes_outlined),
          const SizedBox(height: 12),
          TextFormField(
            controller: _comentarioCtrl,
            maxLines: 3,
            onChanged: (v) => provider.setComentario(v),
            decoration: InputDecoration(
              hintText: 'Ej. Entregar por la tarde...',
              hintStyle: const TextStyle(fontSize: 12),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF1976D2),
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          _sectionTitle('Ubicación de Entrega', Icons.location_on_outlined),
          const SizedBox(height: 12),
          _buildUbicacionSection(provider),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.esValidoPaso1 ? widget.onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Continuar al Catálogo →',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1E3A5F)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1E3A5F),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildUbicacionSection(PedidoFormProvider provider) {
    if (provider.cliente == null) {
      return const Text(
        'Seleccione un cliente primero para gestionar la ubicación.',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    final bool tieneGpsCliente =
        provider.cliente!.latitud != null && provider.cliente!.longitud != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: provider.usarUbicacionCliente,
                onChanged: (val) => provider.toggleUsarUbicacionCliente(val!),
                activeColor: const Color(0xFF1976D2),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Usar ubicación del cliente (Predeterminado)', style: TextStyle(fontSize: 12)),
                    if (tieneGpsCliente)
                      Text(
                        '${provider.cliente!.latitud}, ${provider.cliente!.longitud}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                        ),
                      )
                    else
                      const Text(
                        'El cliente no tiene ubicación registrada.',
                        style: TextStyle(fontSize: 11, color: Colors.orange),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              Radio<bool>(
                value: false,
                groupValue: provider.usarUbicacionCliente,
                onChanged: (val) => provider.toggleUsarUbicacionCliente(val!),
                activeColor: const Color(0xFF1976D2),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: const Text(
                            'Capturar nueva ubicación para esta entrega',
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('¿Cómo llenar el GPS?'),
                                  ],
                                ),
                                content: Container(
                                  constraints: const BoxConstraints(maxWidth: 300),
                                  child: const Text(
                                    '• Si está en la oficina (Windows): Ignore el botón "Capturar". Busque la dirección en Google Maps, copie la Latitud y Longitud y péguela en las casillas.\n\n'
                                    '• Si está en la calle (Móvil): Presione "Capturar" para que el sistema obtenga su ubicación actual automáticamente.',
                                    style: TextStyle(height: 1.4),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Entendido'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                    if (!provider.usarUbicacionCliente) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Latitud',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (val) {
                                provider.setUbicacionPersonalizada(
                                  double.tryParse(val) ?? 0.0,
                                  double.tryParse(_longitudCtrl.text) ?? 0.0,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _longitudCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Longitud',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (val) {
                                provider.setUbicacionPersonalizada(
                                  double.tryParse(_latitudCtrl.text) ?? 0.0,
                                  double.tryParse(val) ?? 0.0,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (!provider.usarUbicacionCliente) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCapturingGps
                    ? null
                    : () => _capturarUbicacionPersonalizada(provider),
                icon: _isCapturingGps
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.gps_fixed),
                label: Text(
                  _isCapturingGps ? 'Capturando...' : 'Capturar GPS Ahora',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _capturarUbicacionPersonalizada(
    PedidoFormProvider provider,
  ) async {
    setState(() => _isCapturingGps = true);
    try {
      final pos = await GpsService.getCurrentPosition();
      if (pos != null) {
        provider.setUbicacionPersonalizada(pos.latitude, pos.longitude);
        _latitudCtrl.text = pos.latitude.toString();
        _longitudCtrl.text = pos.longitude.toString();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación capturada para este pedido'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo obtener GPS: $e. Puede ingresar las coordenadas manualmente.',
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCapturingGps = false);
      }
    }
  }
}

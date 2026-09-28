import re

with open("frontend/lib/modules/flota/widgets/camiones/camion_victual_pedidos_modal.dart", "r", encoding="utf-8") as f:
    code = f.read()

# 1. Imports
code = code.replace("import '../../../camion_victual/models/camion_victual.dart';", 
"""import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import '../../../camion_victual/models/camion_victual.dart';
import '../../../camion_victual/providers/camion_victual_provider.dart';""")

# 2. Build method
code = code.replace("Widget build(BuildContext context) {", 
"""Widget build(BuildContext context) {
    final provider = context.watch<CamionVictualProvider>();
    final currentCamion = provider.camiones.firstWhere((c) => c.id == camion.id, orElse: () => camion);""")
code = code.replace("final pedidos = List<CamionPedido>.from(camion.pedidos)", "final pedidos = List<CamionPedido>.from(currentCamion.pedidos)")
code = code.replace("if (camion.estado", "if (currentCamion.estado")
code = code.replace("${camion.nombre", "${currentCamion.nombre")
code = code.replace("camion.estado.toUpperCase()", "currentCamion.estado.toUpperCase()")
code = code.replace("camion.choferNombre", "currentCamion.choferNombre")
code = code.replace("camion.vendedorNombre", "currentCamion.vendedorNombre")
code = code.replace("formatCurrency.format(camion.montoTotal)", "formatCurrency.format(currentCamion.montoTotal)")

# 3. Pass parameters to _buildDetalleRow
code = code.replace("...pedidos.map((det) => _buildDetalleRow(det, formatCurrency)),", "...pedidos.map((det) => _buildDetalleRow(context, currentCamion, det, formatCurrency)),")
code = code.replace("Widget _buildDetalleRow(CamionPedido det, NumberFormat formatCurrency) {", "Widget _buildDetalleRow(BuildContext context, CamionVictual currentCamion, CamionPedido det, NumberFormat formatCurrency) {")

# 4. _buildDetalleRow UI change
# Replace ESTADO column header with a slightly wider one for actions, maybe just leave it
# Add the action to click on ESTADO or add a trailing icon

row_old = """          Expanded(
            flex: 2,
            child: Text(
              det.estadoEntrega.toUpperCase(),
              style: TextStyle(color: estadoColor, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),"""
row_new = """          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () async {
                final nuevoEstado = det.estadoEntrega == 'entregado' ? 'pendiente' : 'entregado';
                final provider = context.read<CamionVictualProvider>();
                final exito = await provider.actualizarEntrega(currentCamion.id, det.pedidoId, nuevoEstado);
                if (exito) {
                  showTopSnackBar(Overlay.of(context), const CustomSnackBar.success(message: 'Estado de entrega actualizado'));
                } else {
                  showTopSnackBar(Overlay.of(context), CustomSnackBar.error(message: provider.error ?? 'Error'));
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    det.estadoEntrega == 'entregado' ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: estadoColor,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    det.estadoEntrega.toUpperCase(),
                    style: TextStyle(color: estadoColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),"""
code = code.replace(row_old, row_new)

# 5. Add "Vaciar Camion" button under Totals
totals_block = """                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL DEL CAMIÓN:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            formatCurrency.format(currentCamion.montoTotal),
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),"""
totals_new = totals_block + """
                    const SizedBox(height: 20),
                    if (currentCamion.estado != 'vacio')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                backgroundColor: _cardColor,
                                title: const Text('Vaciar Camión', style: TextStyle(color: Colors.white)),
                                content: const Text('¿Estás seguro de vaciar este camión? Se removerán todos los pedidos.', style: TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
                                  TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Vaciar', style: TextStyle(color: Colors.redAccent))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              if (context.mounted) {
                                final provider = context.read<CamionVictualProvider>();
                                final exito = await provider.vaciarCamion(currentCamion.id);
                                if (exito) {
                                  showTopSnackBar(Overlay.of(context), const CustomSnackBar.success(message: 'Camión vaciado'));
                                  Navigator.of(context).pop();
                                } else {
                                  showTopSnackBar(Overlay.of(context), CustomSnackBar.error(message: provider.error ?? 'Error al vaciar'));
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_sweep, color: Colors.white),
                          label: const Text('Vaciar Camión', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),"""
code = code.replace(totals_block, totals_new)

with open("frontend/lib/modules/flota/widgets/camiones/camion_victual_pedidos_modal.dart", "w", encoding="utf-8") as f:
    f.write(code)


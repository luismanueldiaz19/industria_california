import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../led_house/providers/ledhouse_cliente_provider.dart';
import '../../led_house/models/ledhouse_cliente.dart';

/// Selector de cliente con búsqueda en tiempo real.
/// Responsabilidad única: seleccionar/deseleccionar un LedhouseCliente.
class PedidoClienteSelector extends StatefulWidget {
  final LedhouseCliente? selected;
  final ValueChanged<LedhouseCliente?> onChanged;

  const PedidoClienteSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<PedidoClienteSelector> createState() => _PedidoClienteSelectorState();
}

class _PedidoClienteSelectorState extends State<PedidoClienteSelector> {
  static const _accentBlue = Color(0xFF1976D2);
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<LedhouseClienteProvider>(
      builder: (ctx, provider, _) {
        if (provider.isLoading) {
          return const LinearProgressIndicator();
        }

        // Cuando ya hay un cliente seleccionado, mostrar chip con opción de quitar
        if (widget.selected != null) {
          return _buildSelectedTile(widget.selected!);
        }

        // Búsqueda + lista filtrada
        final filtrados = provider.clientes.where((c) {
          if (_search.isEmpty) return false;
          return c.nombre.toLowerCase().contains(_search.toLowerCase());
        }).toList();

        return _buildSearchField(filtrados);
      },
    );
  }

  Widget _buildSelectedTile(LedhouseCliente cliente) {
    return Container(
      decoration: _containerShadow(),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _accentBlue.withValues(alpha: 0.1),
            child: const Icon(Icons.person, color: _accentBlue, size: 20),
          ),
          title: Text(
            cliente.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            cliente.documento ?? '—',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => widget.onChanged(null),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(List<LedhouseCliente> filtrados) {
    return Container(
      decoration: _containerShadow(),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            if (_search.isNotEmpty && filtrados.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Sin resultados para "$_search"',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            if (filtrados.isNotEmpty) ...[
              const Divider(height: 1),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtrados.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 16),
                  itemBuilder: (ctx, i) {
                    final c = filtrados[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.person_outline,
                        size: 18,
                        color: _accentBlue,
                      ),
                      title: Text(
                        c.nombre,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: c.documento != null
                          ? Text(
                              c.documento!,
                              style: const TextStyle(fontSize: 11),
                            )
                          : null,
                      onTap: () {
                        setState(() => _search = '');
                        widget.onChanged(c);
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  BoxDecoration _containerShadow() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

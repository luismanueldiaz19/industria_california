import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/auth_provider.dart';
import '../../../core/app_theme.dart';
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
  List<VendedorAlertaModel> _alertas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    try {
      final data = await _service.getMisAlertas(token: token);
      setState(() {
        _alertas = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeStyle = Theme.of(context).textTheme;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        appBar: AppBar(
          title: Text(
            'Alertas',
            style: themeStyle.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,

          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => _isLoading = true);
                _load();
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _alertas.isEmpty
            ? const Center(child: Text('No has creado actividades aún.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _alertas.length,
                itemBuilder: (context, index) {
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
                                      'nombre': alerta.cxc!.cliente!.nombre,
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
    );
  }
}

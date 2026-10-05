import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/app_date_picker.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/general_header.dart';
import '../../vendedor/widgets/vendedor_mobile_wrapper.dart';
import '../models/cheque_futurista.dart';
import '../providers/cheque_list_provider.dart';
import '../services/cheque_futurista_service.dart';
import 'cheque_nuevo_flow_screen.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/cheque_futurista_button.dart';

/// Pantalla principal del módulo Cheques Futuristas.
/// Usa el GeneralHeader compartido con gradiente rojo para diferenciarse.
class ChequesFuturistasScreen extends StatefulWidget {
  const ChequesFuturistasScreen({super.key});

  @override
  State<ChequesFuturistasScreen> createState() =>
      _ChequesFuturistasScreenState();
}

class _ChequesFuturistasScreenState extends State<ChequesFuturistasScreen> {
  // Paleta roja del módulo
  static const _redDark = Color(0xFF7F0000);
  static const _redMain = Color(0xFFB71C1C);
  static const _redLight = Color(0xFFE53935);

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChequeListProvider>().fetchCheques(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ChequeListProvider>().fetchCheques();
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final provider = context.read<ChequeListProvider>();
    final initialStart =
        provider.fechaInicio ??
        DateTime.now().subtract(const Duration(days: 30));
    final initialEnd = provider.fechaFin ?? DateTime.now();

    final picked = await AppDatePicker.showRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );

    if (picked != null) {
      provider.setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChequeListProvider>();
    return MobileWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Column(
          children: [
            GeneralHeader(
              title: 'Cheques Futuristas',
              subtitle: 'Gestión de cheques a fecha futura',
              icon: Icons.account_balance_wallet_outlined,
              iconColor: Colors.white,
              showBackButton: true,
              gradientColors: const [_redDark, _redMain],
            ),

            // ── Acciones y Buscador ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  // Botones de acción
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      HeaderButton(
                        color: _redMain,
                        icon: provider.soloAtrasados
                            ? Icons.warning
                            : Icons.warning_amber_outlined,
                        tooltip: provider.soloAtrasados
                            ? 'Quitar filtro de atrasados'
                            : 'Filtrar Atrasados',
                        onTap: () => provider.toggleAtrasados(),
                      ),
                      HeaderButton(
                        color: _redMain,
                        icon: Icons.date_range,
                        tooltip: 'Filtrar por Fechas',
                        onTap: () => _pickDateRange(context),
                      ),
                      HeaderButton(
                        color: _redMain,
                        icon: Icons.add,
                        tooltip: 'Nuevo Cheque',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ChequeNuevoFlowScreen(),
                            ),
                          );
                          if (context.mounted) {
                            context.read<ChequeListProvider>().fetchCheques(
                              refresh: true,
                            );
                          }
                        },
                      ),
                      HeaderButton(
                        color: _redMain,
                        icon: Icons.refresh,
                        tooltip: 'Actualizar',
                        onTap: () {
                          context.read<ChequeListProvider>().fetchCheques(
                            refresh: true,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Campo de búsqueda
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) =>
                          context.read<ChequeListProvider>().setSearch(value),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Buscar por cliente o N° de cheque...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: const Icon(Icons.search, color: _redMain),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<String>(
                      backgroundColor: Colors.grey.shade200,
                      thumbColor: Colors.white,
                      groupValue: provider.tipoFecha,
                      padding: const EdgeInsets.all(4),
                      children: {
                        'creacion': Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'Por Creación',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: provider.tipoFecha == 'creacion' ? FontWeight.bold : FontWeight.normal,
                              color: provider.tipoFecha == 'creacion' ? _redMain : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        'deposito': Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'Por Depósito',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: provider.tipoFecha == 'deposito' ? FontWeight.bold : FontWeight.normal,
                              color: provider.tipoFecha == 'deposito' ? _redMain : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      },
                      onValueChanged: (val) {
                        if (val != null) provider.setTipoFecha(val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Cuerpo: Lista de cheques ──────────────────────
            Expanded(child: _buildBody(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ChequeListProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _redMain));
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: _redMain),
            const SizedBox(height: 16),
            Text(
              'Ocurrió un error:\n${provider.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _redMain),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetchCheques(),
              style: ElevatedButton.styleFrom(backgroundColor: _redMain),
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (provider.cheques.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _redLight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 36,
                color: _redMain,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No hay cheques registrados',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2F4C),
              ),
            ),
            if (provider.fechaInicio != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => provider.clearDateRange(),
                icon: const Icon(Icons.clear, color: _redMain),
                label: const Text(
                  'Quitar filtro de fechas',
                  style: TextStyle(color: _redMain),
                ),
              ),
            ],
            if (provider.soloAtrasados) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => provider.toggleAtrasados(),
                icon: const Icon(Icons.clear, color: _redMain),
                label: const Text(
                  'Quitar filtro de atrasados',
                  style: TextStyle(color: _redMain),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _redMain,
      onRefresh: () => provider.fetchCheques(refresh: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (provider.fechaInicio != null && provider.fechaFin != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: _redLight.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.filter_alt, size: 16, color: _redMain),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtrado desde ${DateFormat('dd/MM/yyyy').format(provider.fechaInicio!)} hasta ${DateFormat('dd/MM/yyyy').format(provider.fechaFin!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _redDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: _redMain),
                    onPressed: () => provider.clearDateRange(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          if (provider.soloAtrasados)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.orange.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Mostrando cheques con más de 20 días de atraso',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.orange,
                    ),
                    onPressed: () => provider.toggleAtrasados(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  provider.cheques.length + (provider.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == provider.cheques.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(color: _redMain),
                    ),
                  );
                }

                final cheque = provider.cheques[index];
                final color = _getColorPorEstado(cheque.estado);

                String fechaRegistro = cheque.createdAt;
                String? fechaDepositoStr;
                int diasDesdeCreacion = 0;
                int? diasDesdeDeposito;
                
                try {
                  final dtCreacion = DateTime.parse(cheque.createdAt);
                  diasDesdeCreacion = DateTime.now().difference(dtCreacion).inDays;
                  fechaRegistro = DateFormat('dd MMM yyyy').format(dtCreacion);
                  
                  if (cheque.fechaDeposito != null) {
                    final dtDeposito = DateTime.parse(cheque.fechaDeposito!);
                    diasDesdeDeposito = DateTime.now().difference(dtDeposito).inDays;
                    fechaDepositoStr = DateFormat('dd MMM yyyy').format(dtDeposito);
                  }
                } catch (_) {}

                final bool alertaMayor = diasDesdeDeposito != null && diasDesdeDeposito > 15;
                final bool alertaMenor = diasDesdeCreacion > 20;
                final bool atrasado = alertaMayor || alertaMenor;

                return Container(
                  decoration: BoxDecoration(
                    color: alertaMayor
                        ? Colors.red.withValues(alpha: 0.08)
                        : alertaMenor 
                            ? Colors.orange.withValues(alpha: 0.05)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: alertaMayor
                          ? Colors.red.withValues(alpha: 0.4)
                          : alertaMenor
                              ? Colors.orange.withValues(alpha: 0.4)
                              : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        _mostrarDocumentosDialog(context, cheque);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cheque.nombreCliente,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1E2F4C),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _estadoBadge(cheque.estado, color),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateIndicator(
                                    label: 'REGISTRO',
                                    date: fechaRegistro,
                                    icon: Icons.history,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildDateIndicator(
                                    label: 'DEPÓSITO',
                                    date: fechaDepositoStr ?? 'No definido',
                                    icon: Icons.event,
                                    color: _redMain,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.numbers,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      cheque.numCheque,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.tag,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      cheque.numPedido?.isNotEmpty == true
                                          ? cheque.numPedido!
                                          : 'Sin pedido',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.payments_outlined,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      Formatters.formatCurrency(cheque.monto),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF1E2F4C),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (atrasado) ...[
                              if (alertaMayor)
                                Container(
                                  margin: EdgeInsets.only(bottom: alertaMenor ? 6 : 0),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade700,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '🚨 Vencido: Han pasado $diasDesdeDeposito días desde el depósito programado',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (alertaMenor)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade700,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '⚠️ Precaución: Han pasado $diasDesdeCreacion días desde su registro',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ] else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Transcurridos: $diasDesdeCreacion días',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (cheque.comentario != null &&
                                cheque.comentario!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              Text(
                                cheque.comentario!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade800,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (provider.cheques.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cheques: ${provider.totalFilas}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E2F4C),
                    ),
                  ),
                  Text(
                    'Total: ${Formatters.formatCurrency(provider.montoTotal)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _redMain,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _mostrarDocumentosDialog(BuildContext context, ChequeFuturista cheque) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SizedBox(
          width: 500,
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.black12)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Documentos del Cheque',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E2F4C),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<dynamic>>(
                      future: ChequeFuturistaService().obtenerDocumentos(
                        cheque.id,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: _redMain),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        final docs = snapshot.data ?? [];
                        if (docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No hay documentos adjuntos',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final tipo = doc['tipo_archivo']
                                ?.toString()
                                .toLowerCase();
                            final isImage =
                                tipo == 'jpg' ||
                                tipo == 'jpeg' ||
                                tipo == 'png';
                            final imageUrl =
                                (isImage && doc['ruta_archivo'] != null)
                                ? "$host/storage/${doc['ruta_archivo']}"
                                : null;

                            return ListTile(
                              leading: imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.insert_drive_file,
                                      color: _redMain,
                                    ),
                              title: Text(doc['nombre_archivo'] ?? 'Documento'),
                              subtitle: Text(
                                doc['created_at'] != null
                                    ? 'Fecha: ${doc['created_at'].toString().substring(0, 10)}'
                                    : '',
                              ),
                              onTap: () {
                                if (imageUrl != null) {
                                  _mostrarImagenFullScreen(
                                    context,
                                    imageUrl,
                                    doc['nombre_archivo'],
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.black12)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ChequeFuturistaButton(
                            text: 'Subir Foto',
                            icon: Icons.upload_file,
                            color: Colors.green,

                            onPressed: () => _subirDocumento(context, cheque),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChequeFuturistaButton(
                            text: 'Estado',
                            icon: Icons.edit,
                            color: Colors.blue,
                            onPressed: () =>
                                _mostrarDialogoEstado(context, cheque),
                          ),
                        ),
                        if (context.read<AuthProvider>().isAdmin) ...[
                          const SizedBox(width: 8),
                          ChequeFuturistaButton(
                            text: 'Borrar',
                            icon: Icons.delete,
                            color: Colors.red,
                            isOutlined: true,
                            onPressed: () => _confirmarBorrar(context, cheque),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _subirDocumento(
    BuildContext context,
    ChequeFuturista cheque,
  ) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await ChequeFuturistaService().subirDocumento(
        cheque.id,
        image,
      );
      if (!context.mounted) return;
      Navigator.pop(context); // cerrar loader

      if (success) {
        Navigator.pop(context); // cerrar bottom sheet
        context.read<ChequeListProvider>().fetchCheques(refresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento subido correctamente')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // cerrar loader

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }

  void _mostrarDialogoEstado(
    BuildContext screenContext,
    ChequeFuturista cheque,
  ) {
    showDialog(
      context: screenContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cambiar Estado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEstadoOption(
                screenContext,
                dialogContext,
                cheque,
                'pendiente',
                'Pendiente',
              ),
              _buildEstadoOption(
                screenContext,
                dialogContext,
                cheque,
                'depositado',
                'Depositado',
              ),
              _buildEstadoOption(
                screenContext,
                dialogContext,
                cheque,
                'cancelado',
                'Cancelado',
              ),
              _buildEstadoOption(
                screenContext,
                dialogContext,
                cheque,
                'vencido',
                'Vencido',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEstadoOption(
    BuildContext screenContext,
    BuildContext dialogContext,
    ChequeFuturista cheque,
    String valor,
    String titulo,
  ) {
    void handleSelection(String? newValue) async {
      if (newValue != null && newValue != cheque.estado) {
        Navigator.pop(dialogContext); // Cerrar diálogo

        // Mostrar loader
        showDialog(
          context: screenContext,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        try {
          final success = await ChequeFuturistaService().actualizarEstado(
            cheque.id,
            newValue,
          );
          if (!screenContext.mounted) return;
          Navigator.pop(screenContext); // Cerrar loader

          if (success) {
            Navigator.pop(screenContext); // Cerrar bottom sheet
            screenContext.read<ChequeListProvider>().fetchCheques(
              refresh: true,
            );
            ScaffoldMessenger.of(screenContext).showSnackBar(
              const SnackBar(content: Text('Estado actualizado correctamente')),
            );
          } else {
            ScaffoldMessenger.of(screenContext).showSnackBar(
              const SnackBar(content: Text('No se pudo actualizar el estado')),
            );
          }
        } catch (e) {
          if (!screenContext.mounted) return;
          Navigator.pop(screenContext); // Cerrar loader
          ScaffoldMessenger.of(
            screenContext,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } else if (newValue == cheque.estado) {
        Navigator.pop(dialogContext); // Cerrar diálogo
      }
    }

    return ListTile(
      title: Text(titulo),
      leading: Radio<String>(
        value: valor,
        groupValue: cheque.estado,
        onChanged: handleSelection,
      ),
      onTap: () => handleSelection(valor),
    );
  }

  void _confirmarBorrar(BuildContext context, ChequeFuturista cheque) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Borrar Cheque'),
          content: const Text(
            '¿Estás seguro de que deseas borrar este cheque? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Cerrar diálogo

                // Mostrar loader
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  final success = await ChequeFuturistaService().eliminarCheque(
                    cheque.id,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context); // Cerrar loader

                  if (success) {
                    Navigator.pop(context); // Cerrar bottom sheet
                    context.read<ChequeListProvider>().fetchCheques(
                      refresh: true,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cheque borrado correctamente'),
                      ),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.pop(context); // Cerrar loader
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al borrar: $e')),
                  );
                }
              },
              child: const Text('Borrar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _mostrarImagenFullScreen(
    BuildContext context,
    String imageUrl,
    String? titulo,
  ) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(child: Image.network(imageUrl)),
              ),
            ),
            if (titulo != null) ...[
              const SizedBox(height: 8),
              Text(
                titulo,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateIndicator({
    required String label,
    required String date,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoBadge(String estado, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getColorPorEstado(String estado) {
    return switch (estado) {
      'pendiente' => const Color(0xFFFF9800),
      'depositado' => const Color(0xFF4CAF50),
      'cancelado' => Colors.grey,
      'vencido' => const Color(0xFFB71C1C),
      _ => Colors.grey,
    };
  }
}

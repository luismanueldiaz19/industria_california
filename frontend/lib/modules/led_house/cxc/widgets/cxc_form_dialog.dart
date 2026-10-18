import 'package:flutter/material.dart';
import 'package:industria_california/core/widgets/compact_snack_bar.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_theme.dart';
import '../models/cxc_model.dart';
import '../providers/cxc_provider.dart';
import '../../providers/ledhouse_cliente_provider.dart';
import '../../models/ledhouse_cliente.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../vendedor/services/vendedor_cxc_service.dart';
import '../../../../core/widgets/dialog_header.dart';
import '../../../../core/widgets/input_field.dart';
import '../../../../core/widgets/drop_down_widget.dart';

class CxcFormDialog extends StatefulWidget {
  final CxcModel? cxc;
  final int? preselectedClienteId;

  const CxcFormDialog({super.key, this.cxc, this.preselectedClienteId});

  @override
  State<CxcFormDialog> createState() => _CxcFormDialogState();
}

class _CxcFormDialogState extends State<CxcFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _documentoController = TextEditingController();
  int? _selectedClienteId;
  final _montoFacturaController = TextEditingController();
  final _montoPagadoController = TextEditingController();

  DateTime? _fechaFactura;
  DateTime _fechaVencimiento = DateTime.now();
  String _estado = 'pendiente';
  bool _isSaving = false;

  bool _isAdmin = false;
  List<dynamic> _vendedores = [];
  int? _selectedVendedorId;

  bool get _isEditing => widget.cxc != null;

  @override
  void initState() {
    super.initState();
    if (widget.cxc != null) {
      _documentoController.text = widget.cxc!.documento;
      _selectedClienteId = widget.cxc!.clienteId;
      _selectedVendedorId = widget.cxc!.vendedorId;
      _montoFacturaController.text = widget.cxc!.montoFactura.toString();
      _montoPagadoController.text = widget.cxc!.montoPagado.toString();
      _estado = widget.cxc!.estado;
      try {
        _fechaVencimiento = DateTime.parse(widget.cxc!.fechaVencimiento);
      } catch (_) {}
      try {
        if (widget.cxc!.fechaFactura != null) {
          _fechaFactura = DateTime.parse(widget.cxc!.fechaFactura!);
        }
      } catch (_) {}
    } else if (widget.preselectedClienteId != null) {
      _selectedClienteId = widget.preselectedClienteId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LedhouseClienteProvider>(
        context,
        listen: false,
      ).fetchClientes();
      _initAdmin();
    });
  }

  Future<void> _initAdmin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAdmin) {
      setState(() => _isAdmin = true);
      try {
        final vends = await VendedorCxcService().getVendedores(
          auth.token ?? '',
        );
        setState(() => _vendedores = vends);
      } catch (e) {
        debugPrint('Error loading vendors: $e');
      }
    }
  }

  @override
  void dispose() {
    _documentoController.dispose();
    _montoFacturaController.dispose();
    _montoPagadoController.dispose();
    super.dispose();
  }

  String _selectedClienteName(List<LedhouseCliente> clientes) {
    if (_selectedClienteId == null) return '';
    final match = clientes.where((c) => c.id == _selectedClienteId);
    if (match.isNotEmpty) return match.first.nombre;
    if (widget.cxc != null && widget.cxc!.clienteId == _selectedClienteId) {
      return widget.cxc!.cliente;
    }
    return '';
  }

  void _calculateFechaVencimiento() {
    if (_fechaFactura == null || _selectedClienteId == null) return;

    final provider = Provider.of<LedhouseClienteProvider>(
      context,
      listen: false,
    );
    final index = provider.clientes.indexWhere(
      (c) => c.id == _selectedClienteId,
    );

    if (index != -1) {
      final cliente = provider.clientes[index];
      final dias = cliente.diasCredito ?? 0;
      if (dias > 0) {
        setState(() {
          _fechaVencimiento = _fechaFactura!.add(Duration(days: dias));
        });
      }
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClienteId == null) {
      CompactSnackBar.showError(context, 'Debe seleccionar un cliente');
      return;
    }

    setState(() => _isSaving = true);
    final provider = Provider.of<CxcProvider>(context, listen: false);

    final data = {
      'documento': _documentoController.text.trim(),
      'cliente_id': _selectedClienteId,
      if (_selectedVendedorId != null) 'vendedor_id': _selectedVendedorId,
      'monto_factura': double.parse(_montoFacturaController.text.trim()),
      'monto_pagado': _montoPagadoController.text.isEmpty
          ? 0
          : double.parse(_montoPagadoController.text.trim()),
      if (_fechaFactura != null)
        'fecha_factura': DateFormat('yyyy-MM-dd').format(_fechaFactura!),
      'fecha_vencimiento': DateFormat('yyyy-MM-dd').format(_fechaVencimiento),
      'estado': _estado,
    };

    bool success;
    if (widget.cxc == null) {
      success = await provider.createCxc(data);
    } else {
      success = await provider.updateCxc(widget.cxc!.id!, data);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      CompactSnackBar.showError(context, 'Error: ${provider.error}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ───────────────────────────────────────────
              DialogHeader(
                title: _isEditing ? 'Editar Cuenta' : 'Nueva Cuenta',
                subtitle: _isEditing
                    ? 'Actualiza los datos de cobro'
                    : 'Completa los datos de cobro',
                icon: Icons.receipt_long_rounded,
                onClose: () => Navigator.pop(context, false),
              ),

              // ── Form ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _documentoController,
                              label: 'Documento',
                              hint: 'Ej: FAC-001',
                              icon: Icons.receipt_long_rounded,
                              iconColor: AppTheme.successColor,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Requerido'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Estado',
                              value: _estado,
                              icon: Icons.flag_rounded,
                              iconColor: AppTheme.successColor,
                              items: ['pendiente', 'pagado', 'cancelado'],
                              onChanged: (v) {
                                if (v != null) setState(() => _estado = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Consumer<LedhouseClienteProvider>(
                        builder: (context, provider, child) {
                          if (provider.isLoading && provider.clientes.isEmpty) {
                            return const SizedBox(
                              height: 56,
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }

                          final bool isFieldEnabled =
                              widget.preselectedClienteId == null &&
                              !_isEditing;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cliente',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 8),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return Autocomplete<LedhouseCliente>(
                                    displayStringForOption: (c) => c.nombre,
                                    initialValue: TextEditingValue(
                                      text: _selectedClienteName(
                                        provider.clientes,
                                      ),
                                    ),
                                    optionsBuilder:
                                        (TextEditingValue textEditingValue) {
                                          if (!isFieldEnabled) {
                                            return const Iterable<
                                              LedhouseCliente
                                            >.empty();
                                          }
                                          final query = textEditingValue.text
                                              .trim()
                                              .toLowerCase();
                                          if (query.isEmpty) {
                                            return provider.clientes.take(25);
                                          }
                                          return provider.clientes
                                              .where((c) {
                                                final nameMatch = c.nombre
                                                    .toLowerCase()
                                                    .contains(query);
                                                final docMatch =
                                                    c.documento != null &&
                                                    c.documento!
                                                        .toLowerCase()
                                                        .contains(query);
                                                final codeMatch =
                                                    c.idClienteExterno !=
                                                        null &&
                                                    c.idClienteExterno!
                                                        .toLowerCase()
                                                        .contains(query);
                                                return nameMatch ||
                                                    docMatch ||
                                                    codeMatch;
                                              })
                                              .take(25);
                                        },
                                    onSelected: (LedhouseCliente selection) {
                                      setState(() {
                                        _selectedClienteId = selection.id;
                                      });
                                      _calculateFechaVencimiento();
                                    },
                                    fieldViewBuilder:
                                        (
                                          context,
                                          textEditingController,
                                          focusNode,
                                          onFieldSubmitted,
                                        ) {
                                          final selectedName =
                                              _selectedClienteName(
                                                provider.clientes,
                                              );
                                          if (textEditingController
                                                  .text
                                                  .isEmpty &&
                                              selectedName.isNotEmpty) {
                                            textEditingController.text =
                                                selectedName;
                                          }

                                          return TextFormField(
                                            controller: textEditingController,
                                            focusNode: focusNode,
                                            enabled: isFieldEnabled,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF1F2937),
                                            ),
                                            onChanged: (val) {
                                              if (val.trim().isEmpty &&
                                                  _selectedClienteId != null) {
                                                setState(
                                                  () =>
                                                      _selectedClienteId = null,
                                                );
                                              }
                                            },
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Buscar cliente por nombre o documento...',
                                              hintStyle: TextStyle(
                                                color: Colors.grey.shade400,
                                                fontSize: 13,
                                              ),
                                              prefixIcon: Container(
                                                margin: const EdgeInsets.all(
                                                  10,
                                                ),
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.successColor
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Icons.person_rounded,
                                                  color: AppTheme.successColor,
                                                  size: 18,
                                                ),
                                              ),
                                              suffixIcon:
                                                  isFieldEnabled &&
                                                      textEditingController
                                                          .text
                                                          .isNotEmpty
                                                  ? IconButton(
                                                      icon: const Icon(
                                                        Icons.clear_rounded,
                                                        size: 18,
                                                        color: Colors.grey,
                                                      ),
                                                      tooltip:
                                                          'Limpiar selección',
                                                      onPressed: () {
                                                        textEditingController
                                                            .clear();
                                                        setState(
                                                          () =>
                                                              _selectedClienteId =
                                                                  null,
                                                        );
                                                      },
                                                    )
                                                  : const Icon(
                                                      Icons.search_rounded,
                                                      color: Colors.grey,
                                                      size: 20,
                                                    ),
                                              filled: true,
                                              fillColor: const Color(
                                                0xFFF9FAFB,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade200,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: const BorderSide(
                                                  color: AppTheme.successColor,
                                                  width: 1.5,
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 14,
                                                  ),
                                            ),
                                          );
                                        },
                                    optionsViewBuilder: (context, onSelected, options) {
                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Material(
                                          elevation: 8,
                                          shadowColor: Colors.black.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          color: Colors.white,
                                          child: Container(
                                            width: constraints.maxWidth,
                                            constraints: const BoxConstraints(
                                              maxHeight: 280,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: Colors.grey.shade200,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              child: ListView.separated(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                shrinkWrap: true,
                                                itemCount: options.length,
                                                separatorBuilder: (_, __) =>
                                                    Divider(
                                                      height: 1,
                                                      color:
                                                          Colors.grey.shade100,
                                                    ),
                                                itemBuilder: (context, index) {
                                                  final cliente = options
                                                      .elementAt(index);
                                                  final isSelected =
                                                      cliente.id ==
                                                      _selectedClienteId;
                                                  return InkWell(
                                                    onTap: () =>
                                                        onSelected(cliente),
                                                    child: Container(
                                                      color: isSelected
                                                          ? AppTheme
                                                                .successColor
                                                                .withValues(
                                                                  alpha: 0.08,
                                                                )
                                                          : null,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 14,
                                                            vertical: 10,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 16,
                                                            backgroundColor:
                                                                AppTheme
                                                                    .successColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.12,
                                                                    ),
                                                            child: const Icon(
                                                              Icons
                                                                  .person_rounded,
                                                              color: AppTheme
                                                                  .successColor,
                                                              size: 16,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  cliente
                                                                      .nombre,
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    fontWeight:
                                                                        isSelected
                                                                        ? FontWeight
                                                                              .bold
                                                                        : FontWeight
                                                                              .w600,
                                                                    color: const Color(
                                                                      0xFF1F2937,
                                                                    ),
                                                                  ),
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                                if (cliente.documento !=
                                                                        null &&
                                                                    cliente
                                                                        .documento!
                                                                        .isNotEmpty)
                                                                  Text(
                                                                    'Doc: ${cliente.documento}',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          11,
                                                                      color: Colors
                                                                          .grey
                                                                          .shade500,
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                          if (isSelected)
                                                            const Icon(
                                                              Icons
                                                                  .check_circle_rounded,
                                                              color: AppTheme
                                                                  .successColor,
                                                              size: 18,
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _montoFacturaController,
                              label: 'Monto Factura',
                              hint: '0.00',
                              icon: Icons.attach_money_rounded,
                              iconColor: AppTheme.successColor,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+(\.\d{0,2})?$'),
                                ),
                              ],
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Requerido'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              controller: _montoPagadoController,
                              label: 'Monto Pagado',
                              hint: '0.00',
                              icon: Icons.money_off_rounded,
                              iconColor: Colors.grey.shade600,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+(\.\d{0,2})?$'),
                                ),
                              ],
                              optional: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fecha Factura',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _fechaFactura ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: AppTheme.successColor,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) {
                                setState(() => _fechaFactura = date);
                                _calculateFechaVencimiento();
                              }
                            },
                            child: IgnorePointer(
                              child: TextFormField(
                                key: ValueKey(_fechaFactura),
                                initialValue: _fechaFactura != null
                                    ? DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_fechaFactura!)
                                    : '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1F2937),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Seleccione...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13,
                                  ),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(10),
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.event_available_rounded,
                                      color: AppTheme.successColor,
                                      size: 18,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: AppTheme.successColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_isAdmin) ...[
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Asignar a Vendedor',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              initialValue: _selectedVendedorId,
                              decoration: InputDecoration(
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(10),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppTheme.successColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.person_pin_rounded,
                                    color: AppTheme.successColor,
                                    size: 18,
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: AppTheme.successColor,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              hint: const Text('Selecciona el vendedor...'),
                              items: _vendedores.map((v) {
                                return DropdownMenuItem<int>(
                                  value: v['id'],
                                  child: Text(
                                    '${v['name']} (@${v['username']})',
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedVendedorId = val),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fecha Vencimiento',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),
                          IgnorePointer(
                            child: TextFormField(
                              key: ValueKey(_fechaVencimiento),
                              initialValue: DateFormat(
                                'dd/MM/yyyy',
                              ).format(_fechaVencimiento),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1F2937),
                              ),
                              decoration: InputDecoration(
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(10),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today_rounded,
                                    color: Colors.grey.shade600,
                                    size: 18,
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF3F4F6),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ── Buttons ─────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      _isEditing
                                          ? 'Guardar cambios'
                                          : 'Crear cuenta',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Color iconColor = AppTheme.successColor,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool optional = false,
  }) {
    return InputField(
      controller: controller,
      label: label,
      hint: hint,
      icon: icon,
      iconColor: iconColor,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      optional: optional,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropDownWidget<String>(
      label: label,
      value: value,
      icon: icon,
      iconColor: iconColor,
      items: items,
      onChanged: onChanged,
    );
  }
}

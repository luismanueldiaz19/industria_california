import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/services/http_service.dart';

class CxcAuditoriaScreen extends StatefulWidget {
  const CxcAuditoriaScreen({super.key});

  @override
  State<CxcAuditoriaScreen> createState() => _CxcAuditoriaScreenState();
}

class _CxcAuditoriaScreenState extends State<CxcAuditoriaScreen> {
  bool _isLoading = false;
  bool _hasRun = false;
  Map<String, dynamic>? _resultados;
  String? _error;
  String? _generadoEn;

  final _currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  static const _darkBg = AppTheme.darkBgColor;
  static const _cardDark = AppTheme.darkCardColor;

  Future<void> _runAuditoria() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await HttpService().get(
        'industria-california/cxc/auditoria',
      );
      setState(() {
        _resultados = Map<String, dynamic>.from(response['checks'] ?? {});
        _generadoEn = response['generado_en'];
        _hasRun = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _nivelColor(String nivel) {
    switch (nivel) {
      case 'danger':
        return AppTheme.dangerColor;
      case 'warning':
        return const Color(0xFFFBBC05);
      default:
        return AppTheme.successColor;
    }
  }

  IconData _nivelIcon(String nivel) {
    switch (nivel) {
      case 'danger':
        return Icons.error_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalProblemas = _resultados == null
        ? 0
        : _resultados!.values.fold(
            0,
            (sum, c) => sum + ((c['total'] as int?) ?? 0),
          );

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.bug_report_rounded, color: Colors.amberAccent, size: 22),
            SizedBox(width: 10),
            Text(
              'Auditoría de Datos CXC',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          if (_hasRun && _generadoEn != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  'Generado: ${_dateFmt.format(DateTime.tryParse(_generadoEn!) ?? DateTime.now())}',
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Banner descriptivo ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: _cardDark,
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Herramienta de Depuración',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Detecta inconsistencias, duplicados y errores en los registros de Cuentas por Cobrar. '
                        'Identifica exactamente quién, qué y cuándo ocurrió el problema.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoading
                        ? Colors.grey.shade800
                        : AppTheme.ledhouseBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isLoading ? null : _runAuditoria,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 20),
                  label: Text(
                    _isLoading
                        ? 'Analizando...'
                        : (_hasRun ? 'Re-ejecutar' : 'Ejecutar Auditoría'),
                  ),
                ),
              ],
            ),
          ),

          // ── Contenido ──
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.ledhouseBlue),
                        SizedBox(height: 16),
                        Text(
                          'Ejecutando 9 checks de calidad...',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  )
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppTheme.dangerColor,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Error al ejecutar la auditoría:\n$_error',
                            style: const TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : !_hasRun
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.manage_search_rounded,
                          color: Colors.white.withValues(alpha: 0.2),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Presiona "Ejecutar Auditoría" para\nanalizar la integridad de los datos CXC.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Resumen global ──
                      _buildResumenCard(totalProblemas),
                      const SizedBox(height: 12),
                      // ── Check cards ──
                      ...(_resultados ?? {}).entries.map((entry) {
                        final check = entry.value as Map<String, dynamic>;
                        return _buildCheckCard(check);
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCard(int totalProblemas) {
    final ok = totalProblemas == 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ok
            ? AppTheme.successColor.withValues(alpha: 0.12)
            : AppTheme.dangerColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ok
              ? AppTheme.successColor.withValues(alpha: 0.4)
              : AppTheme.dangerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.verified_rounded : Icons.report_problem_rounded,
            color: ok ? AppTheme.successColor : AppTheme.dangerColor,
            size: 36,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok
                      ? '✅ Datos en buen estado'
                      : '⚠️ Se encontraron $totalProblemas problema(s)',
                  style: TextStyle(
                    color: ok ? AppTheme.successColor : AppTheme.dangerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ok
                      ? 'Todos los 9 checks pasaron correctamente. No se detectaron irregularidades.'
                      : 'Revisa cada categoría para ver los registros afectados y tomar acción correctiva.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckCard(Map<String, dynamic> check) {
    final int total = (check['total'] as int?) ?? 0;
    final String nivel = total > 0 ? (check['nivel'] ?? 'warning') : 'ok';
    final List registros = (check['registros'] as List?) ?? [];
    final Color color = _nivelColor(nivel);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: total > 0
              ? color.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(_nivelIcon(nivel), color: color, size: 20),
          ),
          title: Text(
            check['label'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              check['descripcion'] ?? '',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: total > 0
                      ? color.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: total > 0
                        ? color.withValues(alpha: 0.5)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  total == 0 ? 'OK' : '$total',
                  style: TextStyle(
                    color: total > 0 ? color : Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white38,
                size: 20,
              ),
            ],
          ),
          children: total == 0
              ? [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.successColor,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Sin problemas detectados en esta categoría.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              : [_buildRegistrosTable(registros)],
        ),
      ),
    );
  }

  Widget _buildRegistrosTable(List registros) {
    if (registros.isEmpty) return const SizedBox.shrink();

    // Detect columns from first record
    final firstRecord = registros.first;
    Map<String, dynamic> firstMap = {};
    if (firstRecord is Map) {
      firstMap = Map<String, dynamic>.from(firstRecord);
    }

    // Columnas a mostrar en orden de preferencia
    const preferredCols = [
      'id',
      'documento',
      'cliente',
      'vendedor',
      'estado',
      'monto_factura',
      'monto_pagado',
      'monto_pendiente',
      'fecha_factura',
      'fecha_vencimiento',
      'diferencia',
      'exceso',
      'repeticiones',
      'pendiente_calculado',
    ];

    // If record has 'afectados', handle nested structure
    final bool isNested = firstMap.containsKey('afectados');

    if (isNested) {
      return _buildNestedTable(registros);
    }

    final cols = preferredCols.where((c) => firstMap.containsKey(c)).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              Colors.white.withValues(alpha: 0.05),
            ),
            dataRowColor: WidgetStateProperty.resolveWith(
              (states) => Colors.transparent,
            ),
            headingTextStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            dataTextStyle: const TextStyle(color: Colors.white, fontSize: 11),
            columnSpacing: 18,
            horizontalMargin: 14,
            dividerThickness: 0.5,
            columns: cols
                .map((c) => DataColumn(label: Text(_colLabel(c))))
                .toList(),
            rows: registros.take(30).map((r) {
              final row = r is Map
                  ? Map<String, dynamic>.from(r)
                  : <String, dynamic>{};
              return DataRow(
                cells: cols.map((c) {
                  final val = row[c];
                  return DataCell(_cellWidget(c, val));
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNestedTable(List registros) {
    return Column(
      children: registros.map((r) {
        final record = r is Map
            ? Map<String, dynamic>.from(r)
            : <String, dynamic>{};
        final afectados = (record['afectados'] as List?) ?? [];
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.file_copy_outlined,
                    color: Colors.amberAccent,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Doc: ${record['documento']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${record['repeticiones']} copias',
                      style: const TextStyle(
                        color: AppTheme.dangerColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...afectados.map((a) {
                final af = a is Map
                    ? Map<String, dynamic>.from(a)
                    : <String, dynamic>{};
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'ID:${af['id']} | ${af['cliente'] ?? 'N/A'} | ${af['vendedor'] ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        af['monto_pendiente'] != null
                            ? _currencyFmt.format(
                                double.tryParse(
                                      af['monto_pendiente'].toString(),
                                    ) ??
                                    0,
                              )
                            : '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _colLabel(String col) {
    const map = {
      'id': 'ID',
      'documento': 'Documento',
      'cliente': 'Cliente',
      'vendedor': 'Vendedor',
      'estado': 'Estado',
      'monto_factura': 'Factura',
      'monto_pagado': 'Pagado',
      'monto_pendiente': 'Pendiente',
      'fecha_factura': 'F. Factura',
      'fecha_vencimiento': 'F. Vence',
      'diferencia': 'Diferencia',
      'exceso': 'Exceso',
      'repeticiones': 'Repeticiones',
      'pendiente_calculado': 'Pend. Calc.',
    };
    return map[col] ?? col;
  }

  Widget _cellWidget(String col, dynamic val) {
    if (val == null) {
      return const Text('—', style: TextStyle(color: Colors.white30));
    }
    final str = val.toString();

    // Money columns
    if ([
      'monto_factura',
      'monto_pagado',
      'monto_pendiente',
      'diferencia',
      'exceso',
      'pendiente_calculado',
    ].contains(col)) {
      final amount = double.tryParse(str) ?? 0;
      final isNeg = amount < 0;
      return Text(
        _currencyFmt.format(amount.abs()),
        style: TextStyle(
          color: isNeg ? AppTheme.dangerColor : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // Estado badge
    if (col == 'estado') {
      Color bg;
      switch (str.toLowerCase()) {
        case 'pagado':
          bg = AppTheme.successColor;
          break;
        case 'cancelado':
          bg = Colors.grey;
          break;
        default:
          bg = const Color(0xFFFB8C00);
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: bg.withValues(alpha: 0.5)),
        ),
        child: Text(
          str.toUpperCase(),
          style: TextStyle(
            color: bg,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Text(str, style: const TextStyle(color: Colors.white70));
  }
}

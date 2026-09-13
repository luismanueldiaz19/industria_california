import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/app_theme.dart';

class CxcClienteHeaderCard extends StatelessWidget {
  final Map<String, dynamic> cliente;
  final NumberFormat currencyFormatter;
  final bool isImporting;
  final VoidCallback onNewAccount;
  final VoidCallback onImportExcel;

  const CxcClienteHeaderCard({
    super.key,
    required this.cliente,
    required this.currencyFormatter,
    required this.isImporting,
    required this.onNewAccount,
    required this.onImportExcel,
  });

  Color _avatarColor(String name) {
    final colors = [
      AppTheme.ledhouseBlue,
      AppTheme.successColor,
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEC4899), // Pink
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.length % colors.length];
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length > 1 ? 2 : 1).toUpperCase();
  }

  Widget _buildPremiumChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorderColor, width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _avatarColor(cliente['nombre'] ?? ''),
                        _avatarColor(cliente['nombre'] ?? '').withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(cliente['nombre'] ?? ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente['nombre'] ?? 'Sin Nombre',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildPremiumChip(
                            Icons.phone_rounded,
                            cliente['whatsapp'] ?? 'N/A',
                            Colors.grey.shade400,
                          ),
                          _buildPremiumChip(
                            Icons.calendar_today_rounded,
                            '${cliente['dias_credito'] ?? 0} días',
                            AppTheme.ledhouseBlue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.darkInputColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.darkBorderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Límite de Crédito',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currencyFormatter.format(
                                double.tryParse(
                                      cliente['limite_credito']?.toString() ?? '0',
                                    ) ??
                                    0,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.darkBorderColor),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: onNewAccount,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Nueva', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: isImporting ? null : onImportExcel,
                      icon: isImporting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.upload_file_rounded, size: 16),
                      label: const Text('Importar', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.darkInputColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(color: AppTheme.darkBorderColor),
                        ),
                      ),
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
}

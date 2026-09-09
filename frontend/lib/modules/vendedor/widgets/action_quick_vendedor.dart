import 'package:flutter/material.dart';

import 'build_action_button.dart';

class ActionQuickVendedor extends StatelessWidget {
  const ActionQuickVendedor({super.key, required this.styleTheme});

  final TextTheme styleTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones Rápidas',
            style: styleTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BuildActionButton(Icons.add_shopping_cart, 'Nuevo\nVenta', true),
              BuildActionButton(Icons.folder_outlined, 'Catálogo', false),
              BuildActionButton(
                Icons.people_outline,
                'Clientes',
                false,
                showBadge: true,
              ),
              BuildActionButton(Icons.bar_chart_outlined, 'Reportes', false),
            ],
          ),
        ],
      ),
    );
  }
}

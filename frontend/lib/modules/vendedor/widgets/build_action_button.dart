import 'package:flutter/material.dart';

class BuildActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool showBadge;

  const BuildActionButton(
    this.icon,
    this.label,
    this.isPrimary, {
    super.key,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: isPrimary ? Colors.blue.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: isPrimary
                    ? Colors.blue.shade700
                    : const Color(0xFF1E2F4C),
                size: 22,
              ),
            ),
            if (showBadge)
              Positioned(
                bottom: 6,
                right: 22,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

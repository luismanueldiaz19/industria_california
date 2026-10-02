import 'package:flutter/material.dart';

class ChequeFuturistaButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final Color color;
  final bool isLoading;

  const ChequeFuturistaButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.isOutlined = false,
    this.color = const Color(0xFFB71C1C), // Color rojo por defecto
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final action = isLoading ? null : onPressed;

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isOutlined ? color : Colors.white,
            ),
          )
        else if (icon != null)
          Icon(icon, color: isOutlined ? color : Colors.white, size: 20),
        if (isLoading || icon != null) const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isOutlined ? color : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );

    if (isOutlined) {
      return OutlinedButton(
        onPressed: action,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: action,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
      child: child,
    );
  }
}

import 'package:flutter/material.dart';

// Custom Clipper for the curved header
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    
    // Create a bezier curve
    path.quadraticBezierTo(
      size.width / 2, 
      size.height + 10, // Control point
      size.width, 
      size.height - 40 // End point
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

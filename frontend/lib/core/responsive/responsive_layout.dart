import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  // Breakpoints para los diferentes tamaños de pantalla
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 650 &&
      MediaQuery.sizeOf(context).width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Layout para Desktop / System Windows
        if (constraints.maxWidth >= 1100) {
          return desktop;
        } 
        // Layout para Tablet
        else if (constraints.maxWidth >= 650) {
          return tablet ?? mobile;
        } 
        // Layout para Mobile
        else {
          return mobile;
        }
      },
    );
  }
}

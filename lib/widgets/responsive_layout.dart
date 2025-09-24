import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet; // 👈 optional now
  final Widget desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet, // 👈 not required anymore
    required this.desktop,
  }) : super(key: key);

  static const int mobileMaxWidth = 600;
  static const int tabletMaxWidth = 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileMaxWidth) {
          return mobile;
        } else if (constraints.maxWidth < tabletMaxWidth) {
          return tablet ?? mobile; // 👈 fallback to mobile if tablet not given
        } else {
          return desktop;
        }
      },
    );
  }
}

import 'package:flutter/material.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String activePage;

  const Header({
    super.key,
    required this.title,
    this.activePage = '',
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF161B22),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "SecureWipe Pro",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            "Enterprise Data Security",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title, // dynamic page title
            style: const TextStyle(
              fontSize: 14,
              color: Colors.blueAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        _buildNavButton(context, "Dashboard", "/dashboard"),
        _buildNavButton(context, "Verify", "/verify"),
        _buildNavButton(context, "Offline", "/offline"),
        _buildNavButton(context, "Settings", "/settings"),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildNavButton(BuildContext context, String label, String route) {
    final bool isActive = activePage == label;

    return TextButton(
      onPressed: () {
        Navigator.pushReplacementNamed(context, route);
      },
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.blueAccent : Colors.white,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

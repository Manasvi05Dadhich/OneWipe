import 'package:flutter/material.dart';
import '../main.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String currentRoute;

  const TopNavBar({Key? key, required this.currentRoute}) : super(key: key);

  void _navigate(BuildContext context, String route) {
    final current = ModalRoute.of(context)?.settings.name ?? currentRoute;
    if (current == route) return;
    Navigator.pushReplacementNamed(context, route);
  }

  Widget _navItem(
    BuildContext context,
    String route,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final bool isActive = currentRoute == route;
    final bool isDark = theme.brightness == Brightness.dark;

    final Color activeColor = Colors.blueAccent;
    final Color inactiveColor = isDark ? Colors.white70 : Colors.black87;

    return TextButton.icon(
      onPressed: () => _navigate(context, route),
      icon: Icon(
        icon,
        color: isActive ? activeColor : inactiveColor,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isActive ? activeColor : inactiveColor,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // ---------------- MOBILE ----------------
          return AppBar(
            backgroundColor: theme.appBarTheme.backgroundColor,
            elevation: theme.appBarTheme.elevation ?? 0,
            title: const Text("SecureWipe Pro"),
            actions: [
              IconButton(
                tooltip:
                    isDark ? 'Switch to light theme' : 'Switch to dark theme',
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  MyApp.toggleTheme(context);
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _navigate(context, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: '/dashboard',
                    child: ListTile(
                      leading: Icon(Icons.dashboard),
                      title: Text("Dashboard"),
                    ),
                  ),
                  const PopupMenuItem(
                    value: '/verify',
                    child: ListTile(
                      leading: Icon(Icons.verified_user),
                      title: Text("Verify"),
                    ),
                  ),
                  const PopupMenuItem(
                    value: '/offline',
                    child: ListTile(
                      leading: Icon(Icons.usb),
                      title: Text("Offline"),
                    ),
                  ),
                  const PopupMenuItem(
                    value: '/settings',
                    child: ListTile(
                      leading: Icon(Icons.settings),
                      title: Text("Settings"),
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // ---------------- DESKTOP ----------------
          return AppBar(
            backgroundColor: theme.appBarTheme.backgroundColor,
            elevation: theme.appBarTheme.elevation ?? 0,
            title: Row(
              children: [
                const Icon(Icons.shield, color: Colors.blueAccent),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "SecureWipe Pro",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.appBarTheme.foregroundColor,
                      ),
                    ),
                    Text(
                      "Enterprise Data Security",
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            theme.appBarTheme.foregroundColor?.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              _navItem(context, '/dashboard', 'Dashboard', Icons.dashboard),
              _navItem(context, '/verify', 'Verify', Icons.verified_user),
              _navItem(context, '/offline', 'Offline', Icons.usb),
              _navItem(context, '/settings', 'Settings', Icons.settings),
              IconButton(
                tooltip:
                    isDark ? 'Switch to light theme' : 'Switch to dark theme',
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  MyApp.toggleTheme(context);
                },
              ),
              const SizedBox(width: 8),
            ],
          );
        }
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

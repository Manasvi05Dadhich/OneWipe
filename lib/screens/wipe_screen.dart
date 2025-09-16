import 'package:flutter/material.dart';
import '../widgets/top_nav_bar.dart';
import 'verify_screen.dart';
import 'offline_screen.dart';
import 'settings_screen.dart';
import '../widgets/responsive_layout.dart';

class WipeScreen extends StatefulWidget {
  const WipeScreen({Key? key}) : super(key: key);

  @override
  State<WipeScreen> createState() => _WipeScreenState();
}

class _WipeScreenState extends State<WipeScreen> {
  static const Color accentBlue = Color(0xFF2B7DF3);
  static const Color accentGreen = Color(0xFF4ADE80);
  static const Color accentPurple = Color(0xFFA855F7);

  void _navigate(String route) {
    if (route == '/dashboard') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WipeScreen()),
      );
    } else if (route == '/verify') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const VerifyScreen()),
      );
    } else if (route == '/offline') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OfflineScreen()),
      );
    } else if (route == '/settings') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: const TopNavBar(currentRoute: '/dashboard'),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(theme),
        desktop: _buildDesktopLayout(theme),
      ),
    );
  }

  // ----------------- MOBILE LAYOUT -----------------
  Widget _buildMobileLayout(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildShieldIcon(),
          const SizedBox(height: 20),
          _buildTitle(theme),
          const SizedBox(height: 40),
          _buildStatsRow(theme, isMobile: true),
          const SizedBox(height: 30),
          ConnectedDevicesSection(),
          const SizedBox(height: 30),
          _buildActionRow(isMobile: true),
        ],
      ),
    );
  }

  // ----------------- DESKTOP LAYOUT -----------------
  Widget _buildDesktopLayout(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildShieldIcon(),
          const SizedBox(height: 20),
          _buildTitle(theme),
          const SizedBox(height: 40),
          _buildStatsRow(theme),
          const SizedBox(height: 30),
          ConnectedDevicesSection(),
          const SizedBox(height: 40),
          _buildActionRow(),
        ],
      ),
    );
  }

  // ----------------- SHARED WIDGETS -----------------
  Widget _buildShieldIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [accentBlue, Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accentBlue.withOpacity(0.6),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(Icons.shield, size: 60, color: Colors.white),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Column(
      children: [
        Text(
          "Secure Data Wiping",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Military-grade data erasure with NIST 800-88 compliance.\n"
          "Completely destroy sensitive data beyond recovery.",
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatsRow(ThemeData theme, {bool isMobile = false}) {
    final stats = [
      _statCard("Devices Wiped", "1,247", "This month", Icons.devices,
          accentGreen, theme),
      _statCard("Success Rate", "99.9%", "Verified complete", Icons.verified,
          accentPurple, theme),
      _statCard("Active Wipes", "3", "In progress", Icons.autorenew, accentBlue,
          theme),
    ];

    return isMobile
        ? Column(
            children: stats
                .map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: s,
                    ))
                .toList(),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: stats,
          );
  }

  Widget _buildActionRow({bool isMobile = false}) {
    final actions = Row(
      children: const [
        Expanded(
          child: _ActionCard(
            title: "Quick Actions",
            actions: [
              {"label": "Verify Certificate", "icon": Icons.verified},
              {"label": "Offline Mode", "icon": Icons.usb},
            ],
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: _ActionCard(
            title: "Wipe Configuration",
            actions: [
              {"label": "Select a device to begin", "icon": Icons.delete},
            ],
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        children: const [
          _ActionCard(
            title: "Quick Actions",
            actions: [
              {"label": "Verify Certificate", "icon": Icons.verified},
              {"label": "Offline Mode", "icon": Icons.usb},
            ],
          ),
          SizedBox(height: 20),
          _ActionCard(
            title: "Wipe Configuration",
            actions: [
              {"label": "Select a device to begin", "icon": Icons.delete},
            ],
          ),
        ],
      );
    }

    return actions;
  }

  // --- Glowing Stat Card ---
  Widget _statCard(String title, String value, String subtext, IconData icon,
      Color color, ThemeData theme) {
    return Expanded(
      child: Container(
        height: 130,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.bodySmall),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(subtext, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

// ----------------- CONNECTED DEVICES ------------------
class ConnectedDevicesSection extends StatelessWidget {
  final List<Map<String, String>> devices = [
    {
      "name": "Samsung SSD 970 EVO",
      "os": "Windows 11 Pro",
      "storage": "1TB",
      "partitions": "4",
      "status": "READY",
      "icon": "💽"
    },
    {
      "name": "iPhone 14 Pro",
      "os": "iOS 17.2",
      "storage": "256GB",
      "partitions": "2",
      "status": "READY",
      "icon": "📱"
    },
    {
      "name": "MacBook Pro M2 SSD",
      "os": "macOS Sonoma",
      "storage": "512GB",
      "partitions": "3",
      "status": "COMPLETE",
      "icon": "💻"
    },
    {
      "name": "SanDisk USB 3.0",
      "os": "Removable Storage",
      "storage": "64GB",
      "partitions": "1",
      "status": "READY",
      "icon": "🔌"
    },
  ];

  ConnectedDevicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    // Decide number of columns based on screen width
    int crossAxisCount;
    if (width < 600) {
      crossAxisCount = 1; // mobile
    } else if (width < 1000) {
      crossAxisCount = 2; // tablet / small desktop
    } else {
      crossAxisCount = 3; // large desktop
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Connected Devices",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Auto-detected storage devices ready for secure wiping",
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: devices.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 2.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final device = devices[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device["icon"]!, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 8),
                    Text(
                      device["name"]!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      device["os"]!,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Storage: ${device["storage"]}",
                                style: theme.textTheme.bodySmall),
                            Text("Partitions: ${device["partitions"]}",
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                        Text(
                          device["status"]!,
                          style: TextStyle(
                            color: device["status"] == "COMPLETE"
                                ? Colors.purpleAccent
                                : Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

  }
}

// ----------------- ACTION CARDS ------------------
class _ActionCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> actions;

  const _ActionCard({required this.title, required this.actions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Column(
            children: actions
                .map((a) => ListTile(
                      leading: Icon(
                        a['icon'],
                        color: _WipeScreenState.accentBlue,
                        size: 22,
                      ),
                      title:
                          Text(a['label'], style: theme.textTheme.bodyMedium),
                      onTap: () {},
                    ))
                .toList(),
          )
        ],
      ),
    );
  }
}

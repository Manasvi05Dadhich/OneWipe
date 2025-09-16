import 'package:flutter/material.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/responsive_layout.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    final isMobile = width < 800;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: const TopNavBar(currentRoute: '/offline'),
      body: ResponsiveLayout(
        mobile: _buildContent(context, theme, isMobile: true),
        desktop: _buildContent(context, theme, isMobile: false),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme,
      {required bool isMobile}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Center(
            child: Column(
              children: [
                Icon(Icons.usb, size: 60, color: theme.colorScheme.primary),
                const SizedBox(height: 10),
                Text(
                  "Offline Wipe Mode",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Create a bootable USB drive for secure wiping without network connectivity",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),

          // Layout
          isMobile
              ? Column(
                  children: [
                    _buildLeftColumn(theme),
                    const SizedBox(height: 20),
                    _buildRightColumn(theme),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildLeftColumn(theme)),
                    const SizedBox(width: 20),
                    Expanded(flex: 1, child: _buildRightColumn(theme)),
                  ],
                ),
        ],
      ),
    );
  }

  // LEFT SIDE
  Widget _buildLeftColumn(ThemeData theme) {
    return Column(
      children: [
        _buildCard(
          theme,
          title: "Select ISO Version",
          icon: Icons.download,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIsoOption(theme, "SecureWipe Pro ISO",
                  "Standard bootable ISO with all wipe algorithms",
                  size: "450 MB",
                  recommended: true,
                  selected: true,
                  tags: [
                    "NIST 800-88 Support",
                    "DoD 5220.22-M",
                    "Gutmann Method",
                    "Hardware Detection",
                    "Certificate Generation",
                  ]),
              _buildIsoOption(theme, "Minimal Wipe ISO",
                  "Lightweight ISO with essential features only",
                  size: "150 MB",
                  tags: [
                    "NIST 800-88 Support",
                    "Basic Hardware Detection",
                    "Simple Reporting",
                  ]),
              _buildIsoOption(theme, "Enterprise ISO",
                  "Full-featured ISO with advanced enterprise tools",
                  size: "750 MB",
                  tags: [
                    "All Wipe Methods",
                    "RAID Support",
                    "Network Reporting",
                    "Bulk Operations",
                    "Advanced Logging",
                  ]),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildCard(
          theme,
          title: "Download SecureWipe Pro ISO",
          icon: Icons.file_download,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("File Size: 450 MB", style: theme.textTheme.bodyMedium),
              Text("Platform: x86_64 / UEFI", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: const Text("Download SecureWipe Pro ISO"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildCard(
          theme,
          title: "Step-by-Step Guide",
          icon: Icons.check_circle_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStep(theme, "1", "Download ISO",
                  "Download the SecureWipe Pro bootable ISO image"),
              _buildStep(theme, "2", "Create Bootable USB",
                  "Flash the ISO to a USB drive using recommended tools"),
              _buildStep(theme, "3", "Boot from USB",
                  "Restart the system and boot from the USB drive"),
              _buildStep(theme, "4", "Perform Secure Wipe",
                  "Follow on-screen instructions to wipe the device"),
            ],
          ),
        ),
      ],
    );
  }

  // RIGHT SIDE
  Widget _buildRightColumn(ThemeData theme) {
    return Column(
      children: [
        _buildCard(
          theme,
          title: "USB Flashing Tools",
          icon: Icons.memory,
          child: Column(
            children: [
              _buildTool(theme, "Rufus", "Windows"),
              _buildTool(theme, "Etcher", "Cross-platform"),
              _buildTool(theme, "DD Command", "Linux/macOS"),
              _buildTool(theme, "Disk Utility", "macOS"),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildCard(
          theme,
          title: "System Requirements",
          icon: Icons.computer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("✅ USB drive (4GB minimum)",
                  style: theme.textTheme.bodyMedium),
              Text("✅ x86_64 compatible system",
                  style: theme.textTheme.bodyMedium),
              Text("✅ 2GB RAM minimum", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 10),
              Text("🔶 USB boot enabled", style: theme.textTheme.bodyMedium),
              Text("🔶 Secure Boot may need disabling",
                  style: theme.textTheme.bodyMedium),
              Text("✅ Legacy and UEFI supported",
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildCard(
          theme,
          title: "Security Benefits",
          icon: Icons.security,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("✅ No network connectivity required",
                  style: theme.textTheme.bodyMedium),
              Text("✅ Air-gapped security environment",
                  style: theme.textTheme.bodyMedium),
              Text("✅ Bootable from any system",
                  style: theme.textTheme.bodyMedium),
              Text("✅ Compliance reporting included",
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildCard(
          theme,
          title: "Need Help?",
          icon: Icons.help_outline,
          child: Column(
            children: [
              _buildLink(theme, "Video Tutorial"),
              _buildLink(theme, "Documentation"),
              _buildLink(theme, "Support Center"),
            ],
          ),
        ),
      ],
    );
  }

  // CARD
  Widget _buildCard(ThemeData theme,
      {required String title,
      required IconData icon,
      required Widget child}) {
    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  // ISO option
  Widget _buildIsoOption(
    ThemeData theme,
    String title,
    String desc, {
    required String size,
    bool recommended = false,
    bool selected = false,
    List<String> tags = const [],
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.grey, width: 1),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "$title ($size)",
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (recommended)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text("RECOMMENDED",
                      style: TextStyle(fontSize: 10, color: Colors.white)),
                ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? theme.colorScheme.primary : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(desc, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: -4,
            children: tags
                .map((tag) => Chip(
                      label: Text(tag,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontSize: 10)),
                      backgroundColor:
                          theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // Step
  Widget _buildStep(ThemeData theme, String num, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary,
            child: Text(num,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(desc, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tool
  Widget _buildTool(ThemeData theme, String name, String os) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name,
          style: theme.textTheme.bodyLarge
              ?.copyWith(fontWeight: FontWeight.bold)),
      subtitle: Text(os, style: theme.textTheme.bodySmall),
      trailing: Icon(Icons.open_in_new, color: theme.colorScheme.primary),
    );
  }

  // Link
  Widget _buildLink(ThemeData theme, String label) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.open_in_new, color: theme.colorScheme.secondary),
      title: Text(label,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.primary)),
    );
  }
}

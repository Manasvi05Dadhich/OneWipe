import 'package:flutter/material.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/responsive_layout.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String selectedAlgorithm = "NIST 800-88 Rev. 1";
  bool isOnline = true;
  bool autoVerify = true;
  bool generateCertificate = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: const TopNavBar(currentRoute: '/settings'),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(theme),
        desktop: _buildDesktopLayout(theme),
      ),
    );
  }

  // ---------------- MOBILE ----------------
  Widget _buildMobileLayout(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.settings, size: 60, color: Colors.purpleAccent),
          const SizedBox(height: 12),
          Text("Settings",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 6),
          Text("Configure wipe algorithms and system preferences",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              )),
          const SizedBox(height: 24),

          // Stack vertically
          _buildWipeAlgorithmCard(theme),
          const SizedBox(height: 20),
          _buildSystemModeCard(theme),
          const SizedBox(height: 20),
          _buildAdvancedOptionsCard(theme),
          const SizedBox(height: 20),
          _buildActionsCard(theme),
          const SizedBox(height: 20),
          _buildConfigCard(theme),
        ],
      ),
    );
  }

  // ---------------- DESKTOP ----------------
  Widget _buildDesktopLayout(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.settings, size: 60, color: Colors.purpleAccent),
          const SizedBox(height: 12),
          Text("Settings",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 6),
          Text("Configure wipe algorithms and system preferences",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              )),
          const SizedBox(height: 24),

          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.2,
            ),
            children: [
              _buildWipeAlgorithmCard(theme),
              _buildSystemModeCard(theme),
              _buildAdvancedOptionsCard(theme),
              Column(
                children: [
                  Expanded(child: _buildActionsCard(theme)),
                  const SizedBox(height: 20),
                  Expanded(child: _buildConfigCard(theme)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- CARDS ----------------
  Widget _buildWipeAlgorithmCard(ThemeData theme) {
    return _cardContainer(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Wipe Algorithm",
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("Choose the data destruction method",
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          _algoTile(
            theme,
            "NIST 800-88 Rev. 1",
            "NSA-approved standard for sanitizing storage media\nPasses: 1   Method: ATA Secure Erase + Cryptographic Erase",
            selectedAlgorithm == "NIST 800-88 Rev. 1",
            recommended: true,
          ),
          _algoTile(
            theme,
            "DoD 5220.22-M",
            "US Department of Defense standard\nPasses: 3   Method: Three-pass overwrite pattern",
            selectedAlgorithm == "DoD 5220.22-M",
          ),
          _algoTile(
            theme,
            "Gutmann Method",
            "Peter Gutmann's 35-pass algorithm\nPasses: 35   Method: Multiple overwrite patterns",
            selectedAlgorithm == "Gutmann Method",
          ),
        ],
      ),
    );
  }

  Widget _buildSystemModeCard(ThemeData theme) {
    return _cardContainer(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.wifi, color: Colors.blue, size: 40),
          const SizedBox(height: 10),
          Text("System Mode",
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(isOnline ? "Online Mode" : "Offline Mode",
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            isOnline
                ? "Connected mode with cloud certificate storage"
                : "Disconnected mode, local certificate storage",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => setState(() => isOnline = !isOnline),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(isOnline ? Icons.wifi_off : Icons.wifi,
                color: Colors.white),
            label: Text(isOnline ? "Switch to Offline" : "Switch to Online"),
          )
        ],
      ),
    );
  }

  Widget _buildAdvancedOptionsCard(ThemeData theme) {
    return _cardContainer(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Advanced Options",
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text("Additional wipe configuration",
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 20),
          SwitchListTile(
            value: autoVerify,
            activeColor: Colors.blue,
            onChanged: (v) => setState(() => autoVerify = v),
            title: const Text("Automatic Verification"),
            subtitle: const Text(
                "Verify data destruction after wipe completion"),
          ),
          SwitchListTile(
            value: generateCertificate,
            activeColor: Colors.blue,
            onChanged: (v) => setState(() => generateCertificate = v),
            title: const Text("Generate Certificate"),
            subtitle: const Text("Create digital certificate upon completion"),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(ThemeData theme) {
    return _cardContainer(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("Actions",
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text("Save Settings"),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.restart_alt),
            label: const Text("Reset to Default"),
          )
        ],
      ),
    );
  }

  Widget _buildConfigCard(ThemeData theme) {
    return _cardContainer(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Current Config",
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text("Algorithm: $selectedAlgorithm"),
          Text("Mode: ${isOnline ? "Online" : "Offline"}"),
          Text("Auto Verify: ${autoVerify ? "Enabled" : "Disabled"}"),
          Text("Certificates: ${generateCertificate ? "Generate" : "Disabled"}"),
        ],
      ),
    );
  }

  // ---------------- HELPERS ----------------
  Widget _algoTile(ThemeData theme, String title, String subtitle, bool selected,
      {bool recommended = false}) {
    return InkWell(
      onTap: () => setState(() => selectedAlgorithm = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? Colors.blue : Colors.grey.shade600,
              width: selected ? 2 : 1),
          color: theme.cardColor,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Text(title, style: theme.textTheme.bodyLarge),
              if (recommended)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text("RECOMMENDED",
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                )
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: theme.textTheme.bodySmall),
        ]),
      ),
    );
  }

  Widget _cardContainer(ThemeData theme, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: child,
    );
  }
}


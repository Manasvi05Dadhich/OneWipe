import 'package:flutter/material.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/responsive_layout.dart';

class VerifyScreen extends StatelessWidget {
  const VerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    // Responsive grid columns
    int crossAxisCount;
    if (width < 600) {
      crossAxisCount = 1; // mobile
    } else if (width < 1000) {
      crossAxisCount = 2; // tablet
    } else {
      crossAxisCount = 3; // desktop
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: const TopNavBar(currentRoute: '/verify'),
      body: ResponsiveLayout(
        mobile: _buildContent(theme, crossAxisCount: 1),
        desktop: _buildContent(theme, crossAxisCount: crossAxisCount),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, {required int crossAxisCount}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.verified_user, size: 60, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            "Certificate Verification",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Verify the authenticity of secure wipe certificates using blockchain technology.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),

          // Responsive Grid
          Expanded(
            child: GridView.count(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildVerifyCard(
                  theme: theme,
                  icon: Icons.upload_file,
                  title: "Upload Certificate",
                  subtitle: "Upload JSON or PDF certificate file",
                  buttonText: "Choose File",
                  color: Colors.blueAccent,
                  onTap: () {
                    // TODO: implement file picker
                  },
                ),
                _buildVerifyCard(
                  theme: theme,
                  icon: Icons.qr_code_2,
                  title: "Verification Code",
                  subtitle: "Enter the verification code manually",
                  buttonText: "Enter Code",
                  color: Colors.purpleAccent,
                  onTap: () {
                    // TODO: show input dialog
                  },
                ),
                _buildVerifyCard(
                  theme: theme,
                  icon: Icons.qr_code_scanner,
                  title: "QR Code Scan",
                  subtitle: "Scan QR code from certificate",
                  buttonText: "Scan QR Code",
                  color: Colors.greenAccent,
                  onTap: () {
                    // TODO: integrate QR scanner
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 48),
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onTap,
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/responsive_layout.dart';

class CertificateScreen extends StatelessWidget {
  const CertificateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(currentRoute: '/verify'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Verify the authenticity of secure wipe certificates using blockchain technology",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            // Cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildVerifyCard(
                    icon: Icons.upload_file,
                    title: "Upload Certificate",
                    subtitle: "Upload JSON or PDF certificate file",
                    buttonText: "Choose File",
                    color: Colors.blue,
                    onTap: () {},
                  ),
                  _buildVerifyCard(
                    icon: Icons.qr_code_2,
                    title: "Verification Code",
                    subtitle: "Enter the verification code manually",
                    buttonText: "Enter Code",
                    color: Colors.purple,
                    onTap: () {},
                  ),
                  _buildVerifyCard(
                    icon: Icons.qr_code_scanner,
                    title: "QR Code Scan",
                    subtitle: "Scan QR code from certificate",
                    buttonText: "Scan QR Code",
                    color: Colors.green,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1C1C1C),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 40),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              onPressed: onTap,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

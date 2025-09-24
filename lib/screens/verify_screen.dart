import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/responsive_layout.dart';
import '../services/api_service.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String? _verificationResult;

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
      backgroundColor: theme.colorScheme.surface,
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
                  onTap: _handleFileUpload,
                ),
                _buildVerifyCard(
                  theme: theme,
                  icon: Icons.qr_code_2,
                  title: "Verification Code",
                  subtitle: "Enter the verification code manually",
                  buttonText: "Enter Code",
                  color: Colors.purpleAccent,
                  onTap: _handleManualVerification,
                ),
                _buildVerifyCard(
                  theme: theme,
                  icon: Icons.qr_code_scanner,
                  title: "QR Code Scan",
                  subtitle: "Scan QR code from certificate",
                  buttonText: "Scan QR Code",
                  color: Colors.greenAccent,
                  onTap: _handleQRScan,
                ),
              ],
            ),
          ),
          // Add verification result display
          if (_verificationResult != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Verification Result",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _verificationResult!,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _verificationResult = null;
                      });
                    },
                    child: const Text('Clear Result'),
                  ),
                ],
              ),
            ),
          ],
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

  Future<void> _handleFileUpload() async {
    if (_isLoading) return;
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'pdf'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _isLoading = true;
          _verificationResult = null;
        });
        
        final file = result.files.first;
        if (file.extension == 'json' && file.bytes != null) {
          await _verifyJSONFile(file.bytes!);
        } else {
          setState(() {
            _verificationResult = '❌ Only JSON certificate files are supported for verification.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _verificationResult = '❌ File upload failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _verifyJSONFile(List<int> fileBytes) async {
    try {
      final jsonString = String.fromCharCodes(fileBytes);
      final certData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Extract certificate components
      final certID = certData['certID'] as String?;
      final certJSON = certData['certJSON'] as Map<String, dynamic>?;
      final signature = certData['signatureBase64'] as String?;
      
      if (certID == null || certJSON == null || signature == null) {
        setState(() {
          _verificationResult = '❌ Invalid certificate format. Missing required fields.';
        });
        return;
      }
      
      // Verify with API
      final verifyResult = await _api.verifyCertificate(
        certID: certID,
        certJSON: certJSON,
        signatureBase64: signature,
      );
      
      if (verifyResult['success']) {
        final data = verifyResult['data'];
        final validSignature = data['validSignature'] as bool;
        final anchored = data['anchored'] as bool;
        
        if (validSignature && anchored) {
          setState(() {
            _verificationResult = '✅ Certificate is VALID\n'
                '• Digital signature verified\n'
                '• Blockchain anchoring confirmed\n'
                '• Certificate ID: $certID\n'
                '• Device: ${certJSON['device'] ?? 'Unknown'}';
          });
        } else {
          setState(() {
            _verificationResult = '❌ Certificate is INVALID\n'
                '• Signature valid: $validSignature\n'
                '• Blockchain anchored: $anchored';
          });
        }
      } else {
        setState(() {
          _verificationResult = '❌ Verification failed: ${verifyResult['error']}';
        });
      }
    } catch (e) {
      setState(() {
        _verificationResult = '❌ Certificate verification failed: $e';
      });
    }
  }
  
  Future<void> _handleManualVerification() async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Verification Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the certificate ID to verify:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Certificate ID (e.g., cert-1234567890)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      await _verifyCertificateByID(result);
    }
  }
  
  Future<void> _verifyCertificateByID(String certID) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _verificationResult = null;
    });
    
    try {
      final certDetails = await _api.getCertificate(certID);
      
      if (certDetails['success']) {
        final data = certDetails['data'];
        setState(() {
          _verificationResult = '✅ Certificate Found on Blockchain\n'
              '• Certificate ID: $certID\n'
              '• Issued by: ${data['issuer']}\n'
              '• Timestamp: ${data['timestampReadable']}\n'
              '• Transaction: ${data['txHash']}';
        });
      } else {
        setState(() {
          _verificationResult = '❌ Certificate not found: ${certDetails['error']}';
        });
      }
    } catch (e) {
      setState(() {
        _verificationResult = '❌ Verification failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _handleQRScan() async {
    // For now, show a message that QR scanning will be implemented
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Scanner'),
        content: const Text(
          'QR code scanning will be implemented with a camera plugin.\n\n'
          'For now, you can use the "Enter Code" option to manually verify certificates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
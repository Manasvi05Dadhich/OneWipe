import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/top_nav_bar.dart';
import '../services/api_service.dart';

class WipeResultScreen extends StatefulWidget {
  final String wipeId;
  final Map<String, dynamic> wipeData;

  const WipeResultScreen({
    super.key,
    required this.wipeId,
    required this.wipeData,
  });

  @override
  State<WipeResultScreen> createState() => _WipeResultScreenState();
}

class _WipeResultScreenState extends State<WipeResultScreen> {
  final ApiService _api = ApiService();
  bool _isLoadingDetails = false;
  Map<String, dynamic>? _wipeResults;

  @override
  void initState() {
    super.initState();
    _loadWipeResults();
  }

  Future<void> _loadWipeResults() async {
    setState(() {
      _isLoadingDetails = true;
    });

    try {
      final results = await _api.getWipeResults(widget.wipeId);
      if (results['success']) {
        setState(() {
          _wipeResults = results;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load wipe details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingDetails = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wipeStatus = widget.wipeData['status'] as String;
    final isCompleted = wipeStatus == 'completed';
    final certificate = widget.wipeData['certificate'];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const TopNavBar(currentRoute: '/wipe-result'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status Icon and Title
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                border: Border.all(
                  color: isCompleted ? Colors.green : Colors.orange,
                  width: 3,
                ),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.warning,
                size: 80,
                color: isCompleted ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              isCompleted ? 'Wipe Completed Successfully' : 'Wipe Operation Status',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isCompleted ? Colors.green : Colors.orange,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'Wipe ID: ${widget.wipeId}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Basic Wipe Info Card
            _buildInfoCard(
              theme: theme,
              title: 'Wipe Information',
              icon: Icons.info_outline,
              children: [
                _buildInfoRow('Target Path', widget.wipeData['targetPath'] ?? 'Unknown'),
                _buildInfoRow('Policy', widget.wipeData['policy'] ?? 'Unknown'),
                _buildInfoRow('Status', wipeStatus.toUpperCase()),
                _buildInfoRow('Start Time', _formatTimestamp(widget.wipeData['startTime'])),
                if (widget.wipeData['completedTime'] != null)
                  _buildInfoRow('Completed Time', _formatTimestamp(widget.wipeData['completedTime'])),
                if (widget.wipeData['progress'] != null)
                  _buildInfoRow('Progress', '${widget.wipeData['progress']}%'),
              ],
            ),
            const SizedBox(height: 20),

            // Certificate Card (if available)
            if (isCompleted && certificate != null && certificate['success'] == true) ...[
              _buildCertificateCard(theme, certificate['data']),
              const SizedBox(height: 20),
            ],

            // Detailed Results Card
            if (_isLoadingDetails)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading detailed results...'),
                    ],
                  ),
                ),
              )
            else if (_wipeResults != null)
              _buildDetailedResultsCard(theme),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _copyWipeId(),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy ID'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (certificate != null && certificate['success'] == true) ...[
                  ElevatedButton.icon(
                    onPressed: () => _openPolygonScan(certificate['data']['polygonscan']),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('View on Blockchain'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Back to Dashboard Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(ThemeData theme, Map<String, dynamic> certData) {
    return _buildInfoCard(
      theme: theme,
      title: 'Digital Certificate',
      icon: Icons.security,
      children: [
        _buildInfoRow('Certificate ID', certData['certID'] ?? 'Unknown'),
        _buildInfoRow('Transaction Hash', certData['txHash'] ?? 'Unknown'),
        _buildInfoRow('Certificate Hash', certData['certHashHex'] ?? 'Unknown'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Certificate anchored to blockchain',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedResultsCard(ThemeData theme) {
    final wipeDetails = _wipeResults!['wipeDetails'];
    final files = wipeDetails['files'] as List<dynamic>? ?? [];

    return _buildInfoCard(
      theme: theme,
      title: 'Wipe Details',
      icon: Icons.folder_delete,
      children: [
        _buildInfoRow('Wiped Folder', wipeDetails['folder'] ?? 'Unknown'),
        _buildInfoRow('Wipe Policy', wipeDetails['policy'] ?? 'Unknown'),
        _buildInfoRow('Files Processed', files.length.toString()),
        const SizedBox(height: 12),
        const Text(
          'Files:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...files.take(5).map((file) => Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file['name'] ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              Text(
                'Size: ${file['size_bytes']} bytes | Status: ${file['status']}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        )),
        if (files.length > 5)
          Text(
            '... and ${files.length - 5} more files',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
      ],
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  void _copyWipeId() {
    Clipboard.setData(ClipboardData(text: widget.wipeId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wipe ID copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openPolygonScan(String? url) async {
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open blockchain explorer'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
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
  Map<String, dynamic>? _greenTokenData;

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

      // Try to get Green Token data if available
      try {
        final globalStats = await _api.getSustainabilityStats();
        if (globalStats['success']) {
          // Calculate environmental impact for this wipe
          final deviceType = _detectDeviceType();
          final co2Saved = _getCO2SavingsByDeviceType(deviceType);
          
          setState(() {
            _greenTokenData = {
              'deviceType': deviceType,
              'co2SavedKg': co2Saved,
              'co2SavedTons': (co2Saved / 1000).toStringAsFixed(2),
              'equivalents': {
                'cars': (co2Saved / 4600).round(),
                'trees': (co2Saved * 16).round(),
                'homes': (co2Saved / 5).round(),
              }
            };
          });
        }
      } catch (e) {
        // Green Token service not available, skip
        print('Green Token data not available: $e');
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

            // Environmental Impact Card (if available)
            if (isCompleted && _greenTokenData != null) ...[
              _buildEnvironmentalImpactCard(theme),
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

  Widget _buildEnvironmentalImpactCard(ThemeData theme) {
    final greenData = _greenTokenData!;
    final deviceType = greenData['deviceType'] as String;
    final co2SavedKg = greenData['co2SavedKg'] as int;
    final co2SavedTons = greenData['co2SavedTons'] as String;
    final equivalents = greenData['equivalents'] as Map<String, dynamic>;

    return _buildInfoCard(
      theme: theme,
      title: 'Environmental Impact',
      icon: Icons.eco,
      children: [
        // Main impact display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.eco,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CO₂ Prevented from Atmosphere',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By recycling this ${deviceType.toUpperCase()} instead of discarding',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        '${co2SavedKg}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'kg CO₂',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                  ),
                  Column(
                    children: [
                      Text(
                        co2SavedTons,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        'tons CO₂',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Impact comparisons
        Text(
          'That\'s equivalent to:',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        _buildImpactComparisonRow(
          theme,
          Icons.car_repair,
          'Removing ${equivalents['cars']} cars from roads',
          'for 1 year',
          Colors.red,
        ),
        const SizedBox(height: 8),
        
        _buildImpactComparisonRow(
          theme,
          Icons.park,
          'Planting ${equivalents['trees']} trees',
          'carbon absorption equivalent',
          Colors.green,
        ),
        const SizedBox(height: 8),
        
        _buildImpactComparisonRow(
          theme,
          Icons.home,
          'Powering ${equivalents['homes']} homes',
          'for 1 year (clean energy)',
          Colors.blue,
        ),
        
        const SizedBox(height: 16),
        
        // Call to action
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber),
          ),
          child: Row(
            children: [
              Icon(Icons.celebration, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Congratulations! You\'ve contributed to the circular economy!',
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildImpactComparisonRow(
    ThemeData theme,
    IconData icon,
    String mainText,
    String subText,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mainText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
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

  String _detectDeviceType() {
    final targetPath = widget.wipeData['targetPath']?.toLowerCase() ?? '';
    final deviceName = widget.wipeData['deviceName']?.toLowerCase() ?? '';
    
    // Simple device detection logic
    if (deviceName.contains('laptop') || targetPath.contains('users')) {
      return 'laptop';
    } else if (deviceName.contains('desktop') || deviceName.contains('pc')) {
      return 'desktop';
    } else if (deviceName.contains('phone') || deviceName.contains('mobile')) {
      return 'smartphone';
    } else if (deviceName.contains('tablet') || deviceName.contains('ipad')) {
      return 'tablet';
    } else if (deviceName.contains('server')) {
      return 'server';
    } else if (targetPath.contains('hdd') || deviceName.contains('hard drive')) {
      return 'hdd';
    } else if (targetPath.contains('ssd') || deviceName.contains('solid state')) {
      return 'ssd';
    } else if (deviceName.contains('monitor') || deviceName.contains('display')) {
      return 'monitor';
    } else if (deviceName.contains('printer')) {
      return 'printer';
    } else if (deviceName.contains('router') || deviceName.contains('network')) {
      return 'router';
    }
    
    // Default fallback based on path analysis
    return 'laptop';
  }

  int _getCO2SavingsByDeviceType(String deviceType) {
    // CO₂ savings in kg - based on manufacturing + disposal impact avoided
    const co2Mappings = {
      'laptop': 200,
      'desktop': 300,
      'smartphone': 70,
      'tablet': 100,
      'hdd': 50,
      'ssd': 40,
      'server': 500,
      'monitor': 150,
      'printer': 80,
      'router': 30,
    };
    
    return co2Mappings[deviceType] ?? 50; // Default fallback
  }
}

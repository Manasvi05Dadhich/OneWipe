import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  final ApiService _api = ApiService();
  String _status = 'Ready to test APIs';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OneWipe API Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _loading ? null : _testBackendHealth,
              child: _loading 
                ? const CircularProgressIndicator()
                : const Text('Test Backend Health'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _loading ? null : _testBlockchainHealth,
              child: const Text('Test Blockchain Health'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _loading ? null : _testGetStats,
              child: const Text('Get Service Statistics'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _loading ? null : _testStartDryWipe,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Test Dry-Run Wipe'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _loading ? null : _testCertificateGeneration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Test Certificate Generation'),
            ),
          ],
        ),
      ),
    );
  }

  void _setStatus(String status) {
    setState(() {
      _status = status;
    });
  }

  void _setLoading(bool loading) {
    setState(() {
      _loading = loading;
    });
  }

  Future<void> _testBackendHealth() async {
    _setLoading(true);
    try {
      final result = await _api.getBackendHealth();
      _setStatus('✅ Backend Health: ${result['status']}');
    } catch (e) {
      _setStatus('❌ Backend Health Failed: $e');
    }
    _setLoading(false);
  }

  Future<void> _testBlockchainHealth() async {
    _setLoading(true);
    try {
      final result = await _api.getBlockchainHealth();
      _setStatus('✅ Blockchain Health: ${result['status']}\\n'
          'Network: ${result['network']}\\n'
          'Contract: ${result['contractAddress']}\\n'
          'Reachable: ${result['contractReachable']}');
    } catch (e) {
      _setStatus('❌ Blockchain Health Failed: $e');
    }
    _setLoading(false);
  }

  Future<void> _testGetStats() async {
    _setLoading(true);
    try {
      final result = await _api.getStats();
      final data = result['data'];
      _setStatus('✅ Service Stats:\\n'
          'Total Certificates: ${data['totalCertificates']}\\n'
          'Unique Issuers: ${data['uniqueissuers']}\\n'
          'Last Issued: ${data['lastIssued']}');
    } catch (e) {
      _setStatus('❌ Stats Failed: $e');
    }
    _setLoading(false);
  }

  Future<void> _testStartDryWipe() async {
    _setLoading(true);
    try {
      final result = await _api.startWipe(
        targetPath: 'C:\\\\temp',
        policy: 'clear',
        dryRun: true,
        force: true,
      );
      
      if (result['success']) {
        final wipeId = result['wipeId'];
        _setStatus('✅ Dry-Run Wipe Started!\\n'
            'Wipe ID: $wipeId\\n'
            'Status: ${result['status']}\\n'
            'Estimated Time: ${result['estimatedTime']}');
        
        // Poll status for a few seconds
        await Future.delayed(const Duration(seconds: 2));
        final status = await _api.getWipeStatus(wipeId);
        _setStatus(_status + '\\n\\nStatus Update: ${status['status']}');
      }
    } catch (e) {
      _setStatus('❌ Dry-Run Wipe Failed: $e');
    }
    _setLoading(false);
  }

  Future<void> _testCertificateGeneration() async {
    _setLoading(true);
    try {
      final certID = 'flutter-test-${DateTime.now().millisecondsSinceEpoch}';
      final certJSON = {
        'device': 'Flutter Test Device',
        'wipedBy': 'Flutter Demo App',
        'timestamp': DateTime.now().toIso8601String(),
        'policy': 'Demo Test',
        'note': 'Generated from Flutter app demo'
      };
      
      _setStatus('🔄 Generating certificate: $certID\\nThis may take 30+ seconds...');
      
      final result = await _api.signAndAnchor(
        certID: certID,
        certJSON: certJSON,
      );
      
      if (result['success']) {
        _setStatus('✅ Certificate Generated Successfully!\\n'
            'Cert ID: $certID\\n'
            'TX Hash: ${result['data']['txHash']}\\n'
            'Polygonscan: ${result['data']['polygonscan']}');
      } else {
        // Handle timeout case (HTTP 202)
        _setStatus('⏰ Certificate Generation Timed Out\\n'
            'Cert ID: $certID\\n'
            'TX Hash: ${result['data']?['txHash']}\\n'
            'Status: ${result['data']?['status']}\\n'
            'Check Polygonscan: ${result['data']?['polygonscan']}');
      }
    } catch (e) {
      _setStatus('❌ Certificate Generation Failed: $e');
    }
    _setLoading(false);
  }
}
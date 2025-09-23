import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://localhost:3000/api';
  static const String _blockchainUrl = 'http://localhost:3000/api/blockchain';
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Common headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // =================== WIPE OPERATIONS ===================
  
  /// Start a new wipe operation
  Future<Map<String, dynamic>> startWipe({
    required String targetPath,
    String policy = 'clear', // 'clear' or 'dod'
    bool dryRun = false,
    bool force = true,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/wipe/start'),
      headers: _headers,
      body: jsonEncode({
        'targetPath': targetPath,
        'policy': policy,
        'dryRun': dryRun,
        'force': force,
      }),
    );
    
    return _handleResponse(response);
  }

  /// Get wipe operation status
  Future<Map<String, dynamic>> getWipeStatus(String wipeId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/wipe/status/$wipeId'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }

  /// Get detailed wipe results
  Future<Map<String, dynamic>> getWipeResults(String wipeId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/wipe/results/$wipeId'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }

  /// List all wipe operations
  Future<Map<String, dynamic>> listWipes() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/wipe/list'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }

  // =================== CERTIFICATE OPERATIONS ===================
  
  /// Sign and anchor certificate to blockchain
  Future<Map<String, dynamic>> signAndAnchor({
    required String certID,
    required Map<String, dynamic> certJSON,
  }) async {
    final response = await http.post(
      Uri.parse('$_blockchainUrl/signAndAnchor'),
      headers: _headers,
      body: jsonEncode({
        'certID': certID,
        'certJSON': certJSON,
      }),
    );
    
    return _handleResponse(response);
  }

  /// Verify certificate authenticity
  Future<Map<String, dynamic>> verifyCertificate({
    required String certID,
    required Map<String, dynamic> certJSON,
    required String signatureBase64,
  }) async {
    final response = await http.post(
      Uri.parse('$_blockchainUrl/verifyFull'),
      headers: _headers,
      body: jsonEncode({
        'certID': certID,
        'certJSON': certJSON,
        'signatureBase64': signatureBase64,
      }),
    );
    
    return _handleResponse(response);
  }

  /// Batch verify multiple certificates
  Future<Map<String, dynamic>> batchVerifyCertificates(
    List<Map<String, dynamic>> certificates,
  ) async {
    final response = await http.post(
      Uri.parse('$_blockchainUrl/batchVerify'),
      headers: _headers,
      body: jsonEncode({'certificates': certificates}),
    );
    
    return _handleResponse(response);
  }

  /// Get certificate details
  Future<Map<String, dynamic>> getCertificate(String certID) async {
    final response = await http.get(
      Uri.parse('$_blockchainUrl/getCert/$certID'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }

  /// Check transaction status
  Future<Map<String, dynamic>> getTransactionStatus(String certID) async {
    final response = await http.get(
      Uri.parse('$_blockchainUrl/txStatus/$certID'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }

  // =================== SYSTEM OPERATIONS ===================
  
  /// Check backend health
  Future<Map<String, dynamic>> getBackendHealth() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/status'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }

  /// Check blockchain service health
  Future<Map<String, dynamic>> getBlockchainHealth() async {
    final response = await http.get(
      Uri.parse('$_blockchainUrl/health'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }

  /// Get service statistics
  Future<Map<String, dynamic>> getStats() async {
    final response = await http.get(
      Uri.parse('$_blockchainUrl/stats'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }

  // =================== DOCUMENT GENERATION ===================
  
  /// Get QR code for certificate
  Future<List<int>> getQRCode(String certID) async {
    final response = await http.get(
      Uri.parse('$_blockchainUrl/qrcode/$certID'),
    );
    
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to get QR code: ${response.statusCode}');
    }
  }

  /// Generate PDF certificate
  Future<List<int>> generatePDF({
    required String certID,
    required Map<String, dynamic> certJSON,
    required String signatureBase64,
  }) async {
    final response = await http.post(
      Uri.parse('$_blockchainUrl/generatePdf'),
      headers: _headers,
      body: jsonEncode({
        'certID': certID,
        'certJSON': certJSON,
        'signatureBase64': signatureBase64,
      }),
    );
    
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to generate PDF: ${response.statusCode}');
    }
  }

  // =================== HELPER METHODS ===================
  
  /// Handle HTTP response and parse JSON
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 429) {
      throw RateLimitException(
        'Rate limit exceeded. Please wait before making more requests.',
      );
    } else {
      final error = jsonDecode(response.body);
      throw ApiException(
        message: error['error'] ?? 'Unknown error occurred',
        statusCode: response.statusCode,
        details: error,
      );
    }
  }

  /// Poll wipe status until completion
  Stream<Map<String, dynamic>> pollWipeStatus(String wipeId, {
    Duration interval = const Duration(seconds: 3),
  }) async* {
    while (true) {
      try {
        final status = await getWipeStatus(wipeId);
        yield status;
        
        if (status['status'] == 'completed' || status['status'] == 'failed') {
          break;
        }
        
        await Future.delayed(interval);
      } catch (e) {
        yield {'success': false, 'error': e.toString()};
        break;
      }
    }
  }
}

// =================== CUSTOM EXCEPTIONS ===================

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? details;
  
  const ApiException({
    required this.message,
    required this.statusCode,
    this.details,
  });
  
  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class RateLimitException implements Exception {
  final String message;
  
  const RateLimitException(this.message);
  
  @override
  String toString() => 'RateLimitException: $message';
}

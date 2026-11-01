import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// HTTP API service for communicating with the EcoVision AI FastAPI backend.
/// Follows offline-first architecture with graceful 5-second timeouts and fallback.
class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
  static const Duration _timeout = Duration(seconds: 5);
  static String? _authToken;

  /// Current session authentication token
  static String? get authToken => _authToken;

  /// Set or clear the auth bearer token
  static void setToken(String? token) {
    _authToken = token;
  }

  /// Construct HTTP headers with optional Bearer auth
  static Map<String, String> _buildHeaders({bool isJson = true}) {
    final headers = <String, String>{};
    if (isJson) {
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
    }
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ==========================================
  // AUTH METHODS
  // ==========================================

  /// Authenticate user with email and password
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/login');
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(isJson: true),
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['access_token'] ?? data['token'];
        if (token != null && token is String) {
          _authToken = token;
        }
        return data;
      }
      debugPrint('[ApiService] Login failed with status: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('[ApiService] Login error (offline fallback): $e');
      return null;
    }
  }

  /// Register new user account
  static Future<Map<String, dynamic>?> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/register');
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(isJson: true),
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim(),
              'password': password,
              'role': role.toLowerCase(),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['access_token'] ?? data['token'];
        if (token != null && token is String) {
          _authToken = token;
        }
        return data;
      }
      debugPrint('[ApiService] Register failed with status: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('[ApiService] Register error (offline fallback): $e');
      return null;
    }
  }

  // ==========================================
  // SCANNER METHODS
  // ==========================================

  /// Predict waste classification for an uploaded image file
  static Future<Map<String, dynamic>?> predictWaste(File imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl/scanner/predict');
      final request = http.MultipartRequest('POST', uri);

      if (_authToken != null && _authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      final stream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'file',
        stream,
        length,
        filename: imageFile.path.split(Platform.pathSeparator).last,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('[ApiService] PredictWaste failed with status: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('[ApiService] PredictWaste error (offline fallback): $e');
      return null;
    }
  }

  /// Get historical scans for the authenticated user
  static Future<List<dynamic>> getScanHistory() async {
    try {
      final uri = Uri.parse('$baseUrl/scanner/history');
      final response = await http
          .get(uri, headers: _buildHeaders(isJson: true))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return data['items'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('[ApiService] GetScanHistory error: $e');
      return [];
    }
  }

  // ==========================================
  // REPORTS METHODS
  // ==========================================

  /// Submit an environmental issue report (with optional image attachment)
  static Future<bool> submitReport({
    required Map<String, dynamic> data,
    File? image,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/reports');

      if (image != null && await image.exists()) {
        final request = http.MultipartRequest('POST', uri);
        if (_authToken != null && _authToken!.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $_authToken';
        }

        // Add text fields
        data.forEach((key, val) {
          if (val != null) {
            request.fields[key] = val.toString();
          }
        });

        // Add file
        final stream = http.ByteStream(image.openRead());
        final length = await image.length();
        final multipartFile = http.MultipartFile(
          'image',
          stream,
          length,
          filename: image.path.split(Platform.pathSeparator).last,
        );
        request.files.add(multipartFile);

        final streamed = await request.send().timeout(_timeout);
        final res = await http.Response.fromStream(streamed);
        return res.statusCode >= 200 && res.statusCode < 300;
      } else {
        final res = await http
            .post(
              uri,
              headers: _buildHeaders(isJson: true),
              body: jsonEncode(data),
            )
            .timeout(_timeout);
        return res.statusCode >= 200 && res.statusCode < 300;
      }
    } catch (e) {
      debugPrint('[ApiService] SubmitReport error (saved locally): $e');
      return false;
    }
  }

  /// Retrieve all environmental reports
  static Future<List<dynamic>> getReports() async {
    try {
      final uri = Uri.parse('$baseUrl/reports');
      final response = await http
          .get(uri, headers: _buildHeaders(isJson: true))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data['reports'] is List) return data['reports'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('[ApiService] GetReports error: $e');
      return [];
    }
  }

  // ==========================================
  // MAPS & HOTSPOTS
  // ==========================================

  /// Fetch environmental hotspot geo-coordinates and metadata
  static Future<List<dynamic>> getHotspots() async {
    try {
      final uri = Uri.parse('$baseUrl/maps/hotspots');
      final response = await http
          .get(uri, headers: _buildHeaders(isJson: true))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data['hotspots'] is List) return data['hotspots'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('[ApiService] GetHotspots error: $e');
      return [];
    }
  }

  // ==========================================
  // REWARDS & LEADERBOARD
  // ==========================================

  /// Retrieve user points and badge metrics
  static Future<Map<String, dynamic>?> getPoints() async {
    try {
      final uri = Uri.parse('$baseUrl/rewards/points');
      final response = await http
          .get(uri, headers: _buildHeaders(isJson: true))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService] GetPoints error: $e');
      return null;
    }
  }

  /// Retrieve campus / regional eco leaderboard
  static Future<List<dynamic>> getLeaderboard() async {
    try {
      final uri = Uri.parse('$baseUrl/rewards/leaderboard');
      final response = await http
          .get(uri, headers: _buildHeaders(isJson: true))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data['leaderboard'] is List) {
          return data['leaderboard'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      debugPrint('[ApiService] GetLeaderboard error: $e');
      return [];
    }
  }

  // ==========================================
  // ANALYTICS
  // ==========================================

  /// Retrieve summary statistics for dashboard and impact calculation
  static Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final uri = Uri.parse('$baseUrl/analytics/dashboard');
      final response = await http
          .get(uri, headers: _buildHeaders(isJson: true))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService] GetDashboardStats error: $e');
      return null;
    }
  }

  // ==========================================
  // CHAT / ECO ADVISOR
  // ==========================================

  /// Send prompt messages to EcoAdvisor LLM and receive reply
  static Future<String?> sendChatMessage(List<Map<String, dynamic>> messages) async {
    try {
      final uri = Uri.parse('$baseUrl/chat');
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(isJson: true),
            body: jsonEncode({'messages': messages}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['reply'] != null) {
          return data['reply'].toString();
        }
        if (data is String) return data;
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService] SendChatMessage error: $e');
      return null;
    }
  }
}

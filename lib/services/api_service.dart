import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti dengan IP lokal komputer Anda jika test di HP asli
  // IP komputer saat ini: 172.31.1.105
  // Pastikan jalankan API backend dengan `php artisan serve --host=0.0.0.0`
  static const String baseUrl =
      'http://192.168.1.6:8000/api';
  static const String storageUrl =
      'http://192.168.1.6:8000/storage';
  static const Duration _timeout = Duration(seconds: 15);

  /// Build full image URL from a path.
  /// If path already starts with http, return as-is.
  /// Otherwise prepend storageUrl.
  static String buildImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Remove leading slash if present to avoid double slashes
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$storageUrl/$cleanPath';
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ==================== AUTH ====================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/register'),
          headers: _headers(),
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
            'password_confirmation': passwordConfirmation,
          }),
        )
        .timeout(_timeout);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/login'),
          headers: _headers(),
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(_timeout);
    return jsonDecode(response.body);
  }

  static Future<void> logout() async {
    final token = await getToken();
    await http
        .post(Uri.parse('$baseUrl/logout'), headers: _headers(token: token))
        .timeout(_timeout);
    await removeToken();
  }

  // ==================== REPORTS ====================

  static Future<Map<String, dynamic>> createReport({
    required File image,
    required String deskripsi,
    required double latitude,
    required double longitude,
  }) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/reports');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['deskripsi'] = deskripsi;
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();

    final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
    final mimeParts = mimeType.split('/');

    request.files.add(
      await http.MultipartFile.fromPath(
        'foto_before',
        image.path,
        contentType: MediaType(mimeParts[0], mimeParts[1]),
      ),
    );

    final streamedResponse = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getReports() async {
    final token = await getToken();
    final response = await http
        .get(Uri.parse('$baseUrl/reports'), headers: _headers(token: token))
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Server mereturn status ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    if (data is Map) {
      if (data.containsKey('data')) return data['data'];
      if (data.containsKey('reports')) return data['reports'];
    }
    if (data is List) return data;
    return [];
  }

  static Future<Map<String, dynamic>> getReportDetail(int id) async {
    final token = await getToken();
    final response = await http
        .get(Uri.parse('$baseUrl/reports/$id'), headers: _headers(token: token))
        .timeout(_timeout);
    return jsonDecode(response.body);
  }

  // ==================== NOTIFICATIONS ====================

  static Future<List<dynamic>> getNotifications() async {
    final token = await getToken();
    final response = await http
        .get(
          Uri.parse('$baseUrl/notifications'),
          headers: _headers(token: token),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Server mereturn status ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    if (data is Map) {
      if (data.containsKey('data')) return data['data'];
      if (data.containsKey('notifications')) return data['notifications'];
    }
    if (data is List) return data;
    return [];
  }

  static Future<void> markNotificationRead(int id) async {
    final token = await getToken();
    await http
        .put(
          Uri.parse('$baseUrl/notifications/$id/read'),
          headers: _headers(token: token),
        )
        .timeout(_timeout);
  }

  // ==================== USER PROFILE ====================

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    final response = await http
        .get(Uri.parse('$baseUrl/user'), headers: _headers(token: token))
        .timeout(_timeout);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
  }) async {
    final token = await getToken();
    final body = <String, dynamic>{};
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (email != null && email.isNotEmpty) body['email'] = email;

    final response = await http
        .post(
          Uri.parse('$baseUrl/user/update'),
          headers: _headers(token: token),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return jsonDecode(response.body);
  }
}

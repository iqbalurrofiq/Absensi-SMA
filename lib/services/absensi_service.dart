import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AbsensiService {
  static const String baseUrl =
      'https://api.smaunggul1.com'; // Same as AuthService

  // Get current subject and teacher
  Future<Map<String, dynamic>> getCurrentSubject(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/current-subject'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get current subject: ${response.body}');
    }
  }

  // Send face image for recognition
  Future<Map<String, dynamic>> recognizeFace(
    String token,
    File imageFile,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/face-recognition'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Face recognition failed: ${response.body}');
    }
  }

  // Get attendance history
  Future<List<dynamic>> getAttendanceHistory(
    String token, {
    String? filter,
    String? month,
  }) async {
    var url = '$baseUrl/api/attendance-history';
    if (filter != null) {
      url += '?filter=$filter';
      if (month != null) {
        url += '&month=$month';
      }
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get attendance history: ${response.body}');
    }
  }
}

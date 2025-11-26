import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class NilaiService {
  static const String baseUrl =
      'https://api.smaunggul1.com'; // Same as AuthService

  // Get list of assignments
  Future<List<dynamic>> getAssignments(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/assignments'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get assignments: ${response.body}');
    }
  }

  // Submit assignment with file
  Future<Map<String, dynamic>> submitAssignment(
    String token,
    int assignmentId,
    File file,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/assignments/$assignmentId/submit'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: file.path.split('/').last,
        contentType: _getMediaType(file.path),
      ),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to submit assignment: ${response.body}');
    }
  }

  // Get grade summary
  Future<Map<String, dynamic>> getGradeSummary(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/grades/summary'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get grade summary: ${response.body}');
    }
  }

  MediaType _getMediaType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType(
          'application',
          'vnd.openxmlformats-officedocument.wordprocessingml.document',
        );
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}

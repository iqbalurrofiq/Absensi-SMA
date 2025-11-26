import 'dart:convert';
import 'package:http/http.dart' as http;

class TeacherService {
  static const String baseUrl =
      'https://api.smaunggul1.com'; // Same as AuthService

  // Get teacher dashboard data
  Future<Map<String, dynamic>> getDashboardData(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/teacher/dashboard'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get dashboard data: ${response.body}');
    }
  }

  // Get teacher's classes
  Future<List<dynamic>> getTeacherClasses(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/teacher/classes'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get classes: ${response.body}');
    }
  }

  // Get class attendance for a specific date
  Future<List<dynamic>> getClassAttendance(
    String token,
    int classId,
    String date,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/teacher/classes/$classId/attendance?date=$date'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get attendance: ${response.body}');
    }
  }

  // Get teacher's assignments
  Future<List<dynamic>> getTeacherAssignments(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/teacher/assignments'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get assignments: ${response.body}');
    }
  }

  // Get assignment submissions
  Future<List<dynamic>> getAssignmentSubmissions(
    String token,
    int assignmentId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/teacher/assignments/$assignmentId/submissions'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get submissions: ${response.body}');
    }
  }

  // Grade a submission
  Future<void> gradeSubmission(
    String token,
    int submissionId,
    int grade,
    String feedback,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/teacher/submissions/$submissionId/grade'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'grade': grade, 'feedback': feedback}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to grade submission: ${response.body}');
    }
  }

  // Get teacher profile
  Future<Map<String, dynamic>> getTeacherProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/teacher/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get profile: ${response.body}');
    }
  }

  // Update teacher profile photo
  Future<Map<String, dynamic>> updateProfilePhoto(
    String token,
    dynamic imageFile,
  ) async {
    // Implementation similar to ProfilService
    final response = await http.post(
      Uri.parse('$baseUrl/api/teacher/profile/photo'),
      headers: {'Authorization': 'Bearer $token'},
      body: {}, // Add multipart file handling
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update photo: ${response.body}');
    }
  }
}

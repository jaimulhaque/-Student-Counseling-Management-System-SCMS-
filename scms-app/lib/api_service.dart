import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

class ApiService {
  static const int _timeoutSeconds = 15;

  // ================= USER ID =================
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userIdStr = prefs.getString('user_id');
    return userIdStr != null ? int.tryParse(userIdStr) : null;
  }

  // ================= LOGIN =================
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Constants.baseUrl}/login.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: _timeoutSeconds));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ================= REGISTER =================
  static Future<Map<String, dynamic>> register(
      String name, String email, String password, String studentId, String role,
      {String department = ''}) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Constants.baseUrl}/register.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'student_id': studentId,
              'role': role,
              'department': department,
            }),
          )
          .timeout(const Duration(seconds: _timeoutSeconds));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ================= GET CATEGORIES =================
  static Future<List<dynamic>> getCategories() async {
    try {
      final response = await http
          .get(Uri.parse('${Constants.baseUrl}/get_categories.php'))
          .timeout(const Duration(seconds: _timeoutSeconds));

      final data = jsonDecode(response.body);
      return data['categories'] ?? [];
    } catch (e) {
      throw Exception('Categories error: $e');
    }
  }

  // ================= SUBMIT REQUEST =================
  static Future<Map<String, dynamic>> submitRequest(
      String categoryId,
      String description,
      String priority, {
        int? counselorId,
      }) async {
    final studentId = await getUserId();

    if (studentId == null) {
      return {'success': false, 'message': 'User not logged in'};
    }

    try {
      final body = {
        'student_id': studentId,
        'category_id': categoryId,
        'description': description,
        'priority': priority,
      };

      if (counselorId != null) {
        body['counselor_id'] = counselorId;
      }

      final response = await http
          .post(
            Uri.parse('${Constants.baseUrl}/submit_request.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: _timeoutSeconds));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ================= MY APPOINTMENTS (student) =================
  static Future<Map<String, dynamic>> getMyAppointments() async {
    final studentId = await getUserId();
    if (studentId == null) return {'upcoming': [], 'completed': []};
    try {
      final response = await http
          .get(Uri.parse('${Constants.baseUrl}/get_my_appointments.php?student_id=$studentId'))
          .timeout(const Duration(seconds: _timeoutSeconds));
      final data = jsonDecode(response.body);
      return {
        'upcoming':  data['upcoming']  ?? [],
        'completed': data['completed'] ?? [],
      };
    } catch (e) {
      throw Exception('Appointments error: $e');
    }
  }

  // ================= MY REQUESTS =================
  static Future<List<dynamic>> getMyRequests() async {
    final studentId = await getUserId();
    if (studentId == null) return [];

    try {
      final response = await http
          .get(Uri.parse('${Constants.baseUrl}/get_my_requests.php?student_id=$studentId'))
          .timeout(const Duration(seconds: _timeoutSeconds));

      final data = jsonDecode(response.body);
      return data['requests'] ?? [];
    } catch (e) {
      return [];
    }
  }

  // ================= PENDING REQUESTS =================
  static Future<List<dynamic>> getPendingRequests() async {
    try {
      final response = await http
          .get(Uri.parse('${Constants.baseUrl}/get_pending_requests.php'))
          .timeout(const Duration(seconds: _timeoutSeconds));

      final data = jsonDecode(response.body);
      return data['requests'] ?? [];
    } catch (e) {
      return [];
    }
  }

  // ================= APPROVE REQUEST =================
  static Future<Map<String, dynamic>> approveRequest(int requestId) async {
    final counselorId = await getUserId();
    if (counselorId == null) {
      return {'success': false, 'message': 'Counselor not logged in'};
    }

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/approve_request.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'request_id': requestId,
          'counselor_id': counselorId
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ================= REJECT REQUEST =================
  static Future<Map<String, dynamic>> rejectRequest(int requestId) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/reject_request.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'request_id': requestId}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ================= UPDATE PROFILE =================
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phone,
    required String department,
    required String intake,
    required String section,
    required String studentId,
    String? designation,
    String? availableSchedule,
  }) async {
    final userId = await getUserId();
    if (userId == null) {
      return {'success': false, 'message': 'User not logged in'};
    }

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/update_profile.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'name': name ?? '',
          'email': email ?? '',
          'phone': phone ?? '',
          'department': department,
          'intake': intake,
          'section': section,
          'student_id': studentId,
          'designation': designation ?? '',
          'available_schedule': availableSchedule ?? '',
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ================= GET COUNSELORS =================
  static Future<List<dynamic>> getCounselors() async {
    try {
      final response = await http
          .get(Uri.parse('${Constants.baseUrl}/get_counselors.php'))
          .timeout(const Duration(seconds: _timeoutSeconds));

      final data = jsonDecode(response.body);
      return data['counselors'] ?? [];
    } catch (e) {
      throw Exception('Counselors fetch error: $e');
    }
  }

  // ================= GET COUNSELORS BY DEPARTMENT (student filtered) =================
  static Future<List<dynamic>> getCounselorsByDept(String department) async {
    try {
      final encodedDept = Uri.encodeComponent(department);
      final response = await http
          .get(Uri.parse('${Constants.baseUrl}/get_counselors.php?department=$encodedDept'))
          .timeout(const Duration(seconds: _timeoutSeconds));

      final data = jsonDecode(response.body);
      return data['counselors'] ?? [];
    } catch (e) {
      throw Exception('Counselors fetch error: $e');
    }
  }

  // ================= CHANGE PASSWORD =================
  static Future<Map<String, dynamic>> changePassword(
      int userId, String oldPassword, String newPassword) async {
    try {
      final response = await http
          .post(
        Uri.parse('${Constants.baseUrl}/change_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      )
          .timeout(const Duration(seconds: _timeoutSeconds));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ================= GET MY SCHEDULE (counselor) =================
  static Future<List<dynamic>> getCounselorSchedule() async {
    final counselorId = await getUserId();
    if (counselorId == null) return [];
    try {
      final response = await http
          .get(Uri.parse('${Constants.baseUrl}/get_schedule.php?counselor_id=$counselorId'))
          .timeout(const Duration(seconds: _timeoutSeconds));
      final data = jsonDecode(response.body);
      return data['slots'] ?? [];
    } catch (e) {
      throw Exception('Schedule fetch error: $e');
    }
  }

  // ================= ADD SCHEDULE SLOT =================
  static Future<Map<String, dynamic>> addScheduleSlot(
      String day, String startTime, String endTime, String roomNumber) async {
    final counselorId = await getUserId();
    if (counselorId == null) return {'success': false, 'message': 'Not logged in'};
    try {
      final response = await http
          .post(
        Uri.parse('${Constants.baseUrl}/add_schedule_slot.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'counselor_id': counselorId,
          'day': day,
          'start_time': startTime,
          'end_time': endTime,
          'room_number': roomNumber,
        }),
      )
          .timeout(const Duration(seconds: _timeoutSeconds));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ================= DELETE SCHEDULE SLOT =================
  static Future<Map<String, dynamic>> deleteScheduleSlot(String slotId) async {
    try {
      final response = await http
          .post(
        Uri.parse('${Constants.baseUrl}/delete_schedule_slot.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'slot_id': slotId}),
      )
          .timeout(const Duration(seconds: _timeoutSeconds));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ================= GET COUNSELOR SLOTS (student view) =================
  static Future<List<dynamic>> getCounselorSlots(String counselorId) async {
    try {
      final response = await http
          .get(Uri.parse('${Constants.baseUrl}/get_schedule.php?counselor_id=$counselorId'))
          .timeout(const Duration(seconds: _timeoutSeconds));
      final data = jsonDecode(response.body);
      return data['slots'] ?? [];
    } catch (e) {
      throw Exception('Slots fetch error: $e');
    }
  }

  // ================= GET AVAILABLE SLOTS FOR DATE =================
  static Future<List<dynamic>> getAvailableSlots(
      String counselorId, String date) async {
    try {
      final response = await http
          .get(Uri.parse(
          '${Constants.baseUrl}/get_available_slots.php?counselor_id=$counselorId&date=$date'))
          .timeout(const Duration(seconds: _timeoutSeconds));
      final data = jsonDecode(response.body);
      return data['available_slots'] ?? [];
    } catch (e) {
      throw Exception('Available slots error: $e');
    }
  }

  // ================= BOOK APPOINTMENT =================
  static Future<Map<String, dynamic>> bookAppointment({
    required String counselorId,
    required String slotId,
    required String date,
    String categoryId = '1',
    String description = 'Appointment booking',
    String priority = 'normal',
  }) async {
    final studentId = await getUserId();
    if (studentId == null) return {'success': false, 'message': 'Not logged in'};
    try {
      final response = await http
          .post(
        Uri.parse('${Constants.baseUrl}/book_appointment.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': studentId,
          'counselor_id': counselorId,
          'slot_id': slotId,
          'date': date,
          'category_id': categoryId,
          'description': description,
          'priority': priority,
        }),
      )
          .timeout(const Duration(seconds: _timeoutSeconds));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }


  // ================= STATISTICS (counselor) =================
  static Future<Map<String, dynamic>> getStatistics() async {
    final counselorId = await getUserId();
    if (counselorId == null) return {};
    try {
      final response = await http
          .get(Uri.parse('${Constants.baseUrl}/get_statistics.php?counselor_id=$counselorId'))
          .timeout(const Duration(seconds: _timeoutSeconds));
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Statistics error: $e');
    }
  }

  // ================= WEEKLY SCHEDULE (counselor) =================
  static Future<List<dynamic>> getWeeklySchedule() async {
    final counselorId = await getUserId();
    if (counselorId == null) return [];
    try {
      final response = await http
          .get(Uri.parse('${Constants.baseUrl}/get_weekly_schedule.php?counselor_id=$counselorId'))
          .timeout(const Duration(seconds: _timeoutSeconds));
      final data = jsonDecode(response.body);
      return data['appointments'] ?? [];
    } catch (e) {
      throw Exception('Weekly schedule error: $e');
    }
  }

  // ================= REJECT APPOINTMENT (counselor, with reason) =================
  static Future<Map<String, dynamic>> rejectAppointment({
    required int appointmentId,
    required String reason,
  }) async {
    final counselorId = await getUserId();
    if (counselorId == null) return {'success': false, 'message': 'Not logged in'};
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/reject_appointment.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'appointment_id': appointmentId,
          'counselor_id': counselorId,
          'reason': reason,
        }),
      ).timeout(const Duration(seconds: _timeoutSeconds));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ================= GET NOTIFICATIONS =================
  static Future<List<dynamic>> getNotifications() async {
    final userId = await getUserId();
    if (userId == null) return [];
    try {
      final response = await http
          .get(Uri.parse('${Constants.baseUrl}/get_notifications.php?user_id=$userId'))
          .timeout(const Duration(seconds: _timeoutSeconds));
      final data = jsonDecode(response.body);
      return data['notifications'] ?? [];
    } catch (e) {
      return [];
    }
  }

  // ================= MARK NOTIFICATIONS READ =================
  static Future<void> markNotificationsRead() async {
    final userId = await getUserId();
    if (userId == null) return;
    try {
      await http.post(
        Uri.parse('${Constants.baseUrl}/mark_notifications_read.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      ).timeout(const Duration(seconds: _timeoutSeconds));
    } catch (_) {}
  }

  // ================= LOGOUT =================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
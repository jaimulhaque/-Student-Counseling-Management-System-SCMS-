class CounselingRequest {
  final int id;
  final String studentName;
  final String category;
  final String description;
  final String priority;
  final String status;
  final String? requestedAt;
  final String? appointmentTime;
  final String? roomName;
  // Student details (used by counselor in pending requests)
  final String? studentDepartment;
  final String? studentNumber;
  final String? studentIntake;
  final String? studentSection;
  final String? studentPhone;
  final String? rejectionReason;

  CounselingRequest({
    required this.id,
    required this.studentName,
    required this.category,
    required this.description,
    required this.priority,
    required this.status,
    this.requestedAt,
    this.appointmentTime,
    this.roomName,
    this.studentDepartment,
    this.studentNumber,
    this.studentIntake,
    this.studentSection,
    this.studentPhone,
    this.rejectionReason,
  });

  factory CounselingRequest.fromJson(Map<String, dynamic> json) {
    return CounselingRequest(
      id: int.tryParse(json['id'].toString()) ?? 0,
      studentName: json['student_name']?.toString() ?? 'Unknown Student',
      category: json['category']?.toString() ?? 'Unknown',
      description: json['description']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'normal',
      status: json['status']?.toString() ?? 'pending',
      requestedAt: json['requested_at']?.toString(),
      appointmentTime: json['appointment_time']?.toString(),
      roomName: json['room_name']?.toString(),
      studentDepartment: json['student_department']?.toString(),
      studentNumber: json['student_number']?.toString(),
      studentIntake: json['student_intake']?.toString(),
      studentSection: json['student_section']?.toString(),
      studentPhone: json['student_phone']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_name': studentName,
      'category': category,
      'description': description,
      'priority': priority,
      'status': status,
      'requested_at': requestedAt,
      'appointment_time': appointmentTime,
      'room_name': roomName,
    };
  }
}
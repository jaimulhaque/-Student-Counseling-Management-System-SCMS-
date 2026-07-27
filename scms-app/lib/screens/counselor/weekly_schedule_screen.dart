import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../api_service.dart';

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  List<dynamic> _appointments = [];
  bool _isLoading = true;
  String? _error;

  final List<String> _dayOrder = [
    'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'
  ];

  // Group by day-of-week label
  Map<String, List<dynamic>> get _byDay {
    final Map<String, List<dynamic>> grouped = {};
    for (final a in _appointments) {
      final day = a['day']?.toString() ?? 'Unknown';
      grouped.putIfAbsent(day, () => []).add(a);
    }
    return grouped;
  }

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final appts = await ApiService.getWeeklySchedule();
      setState(() { _appointments = appts; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load: $e'; _isLoading = false; });
    }
  }

  String _fmtTime(String t) {
    try {
      final p = t.split(':');
      int h = int.parse(p[0]);
      final m = p[1];
      final s = h >= 12 ? 'PM' : 'AM';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      return '$h:$m $s';
    } catch (_) { return t; }
  }

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return '—';
    try { return DateFormat('dd MMM yyyy').format(DateTime.parse(d)); }
    catch (_) { return d; }
  }

  // ── Reject dialog ──
  Future<void> _showRejectDialog(Map<String, dynamic> appt) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 22),
          SizedBox(width: 8),
          Text('Reject Appointment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(appt['student_name'] ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827))),
                const SizedBox(height: 2),
                Text('${appt['category'] ?? '—'} • ${_fmtDate(appt['date'])} ${_fmtTime(appt['start_time'] ?? '')}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ]),
            ),
            const SizedBox(height: 16),
            const Text('Reason for rejection *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: reasonCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                decoration: InputDecoration(
                  hintText: 'e.g. Unavailable due to meeting...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) {
                Fluttertoast.showToast(msg: 'Please enter a reason');
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _doReject(appt, reasonCtrl.text.trim());
    }
  }

  Future<void> _doReject(Map<String, dynamic> appt, String reason) async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.rejectAppointment(
        appointmentId: int.parse(appt['appointment_id'].toString()),
        reason: reason,
      );
      if (result['success'] == true) {
        Fluttertoast.showToast(
          msg: 'Appointment rejected & slot released',
          backgroundColor: const Color(0xFF22C55E),
          textColor: Colors.white,
        );
        _load();
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? 'Rejection failed',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e', backgroundColor: Colors.red, textColor: Colors.white);
      setState(() => _isLoading = false);
    }
  }

  // ── Detail bottom sheet ──
  void _showDetail(Map<String, dynamic> appt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (__, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 20),

              // Student avatar + name
              Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)]),
                  ),
                  child: Center(child: Text(
                    (appt['student_name'] ?? 'S')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                  )),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(appt['student_name'] ?? '—',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(appt['category'] ?? 'General',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1A73E8))),
                  ),
                ]),
              ]),
              const SizedBox(height: 24),

              _sectionLabel('Appointment'),
              _detailTile(Icons.calendar_today_rounded, 'Date', _fmtDate(appt['date']), const Color(0xFF1A73E8)),
              _detailTile(Icons.access_time_rounded, 'Time',
                  '${_fmtTime(appt['start_time'] ?? '')} – ${_fmtTime(appt['end_time'] ?? '')}',
                  const Color(0xFF8B5CF6)),
              if ((appt['room_number'] ?? '').isNotEmpty)
                _detailTile(Icons.meeting_room_outlined, 'Room', appt['room_number'], const Color(0xFFF59E0B)),

              const SizedBox(height: 16),
              _sectionLabel('Student Info'),
              _detailTile(Icons.badge_outlined, 'Student ID',
                  appt['student_number']?.isNotEmpty == true ? appt['student_number'] : '—', const Color(0xFF1A73E8)),
              _detailTile(Icons.business_outlined, 'Department',
                  appt['student_department']?.isNotEmpty == true ? appt['student_department'] : '—', const Color(0xFF8B5CF6)),
              _detailTile(Icons.numbers_rounded, 'Intake',
                  appt['student_intake']?.isNotEmpty == true ? appt['student_intake'] : '—', const Color(0xFF22C55E)),
              _detailTile(Icons.group_outlined, 'Section',
                  appt['student_section']?.isNotEmpty == true ? appt['student_section'] : '—', const Color(0xFFF59E0B)),
              _detailTile(Icons.phone_outlined, 'Phone',
                  appt['student_phone']?.isNotEmpty == true ? appt['student_phone'] : 'Not provided', const Color(0xFFEC4899)),

              const SizedBox(height: 16),
              _sectionLabel('Concern'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  appt['description']?.isNotEmpty == true ? appt['description'] : 'No description provided',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Reject Appointment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showRejectDialog(appt);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280), letterSpacing: 0.5)),
  );

  Widget _detailTile(IconData icon, String label, String value, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      ]),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final grouped = _byDay;
    final orderedDays = _dayOrder.where((d) => grouped.containsKey(d)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(children: [
        Container(height: 180, decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
              begin: Alignment.topLeft, end: Alignment.bottomRight))),
        SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                ),
                const Text('Weekly Schedule',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              ]),
              Row(children: [
                if (!_isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text('${_appointments.length} sessions',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _load,
                  child: Container(width: 38, height: 38,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20)),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 12),

          Expanded(child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A73E8)))
                : _error != null
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8), foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Retry')),
                      ]))
                    : _appointments.isEmpty
                        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.calendar_month_outlined, size: 72, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text('No upcoming appointments',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                            const SizedBox(height: 6),
                            Text('Your weekly schedule is clear', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                          ]))
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: const Color(0xFF1A73E8),
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                              children: orderedDays.map((day) {
                                final dayAppts = grouped[day]!;
                                final dayColor = _dayColor(day);
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Day header
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10, top: 4),
                                      child: Row(children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: dayColor,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(day,
                                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                                        ),
                                        const SizedBox(width: 10),
                                        Text('${dayAppts.length} appointment${dayAppts.length > 1 ? 's' : ''}',
                                            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                      ]),
                                    ),

                                    // Appointment cards for this day
                                    ...dayAppts.map((appt) => _buildCard(appt, dayColor)),
                                    const SizedBox(height: 12),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
          )),
        ])),
      ]),
    );
  }

  Widget _buildCard(Map<String, dynamic> appt, Color accent) {
    return GestureDetector(
      onTap: () => _showDetail(appt),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          // Left accent bar
          Container(
            width: 6, height: 90,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18)),
            ),
          ),
          const SizedBox(width: 14),

          // Time icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.access_time_rounded, color: accent, size: 22),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_fmtTime(appt['start_time'] ?? '')} – ${_fmtTime(appt['end_time'] ?? '')}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
              const SizedBox(height: 3),
              Text(appt['student_name'] ?? '—',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              const SizedBox(height: 2),
              Text('${appt['category'] ?? '—'} • ${_fmtDate(appt['date'])}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ]),
          )),

          // Reject button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showRejectDialog(appt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.25)),
                ),
                child: const Text('Reject',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Color _dayColor(String day) {
    const colors = {
      'Sunday':    Color(0xFFEF4444),
      'Monday':    Color(0xFF1A73E8),
      'Tuesday':   Color(0xFF8B5CF6),
      'Wednesday': Color(0xFF22C55E),
      'Thursday':  Color(0xFFF59E0B),
      'Friday':    Color(0xFFEC4899),
      'Saturday':  Color(0xFF0D47A1),
    };
    return colors[day] ?? const Color(0xFF1A73E8);
  }
}

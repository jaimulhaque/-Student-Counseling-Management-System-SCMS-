import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../../../api_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> counselor;
  final String categoryId;
  final String description;

  const BookAppointmentScreen({
    super.key,
    required this.counselor,
    required this.categoryId,
    required this.description,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  bool _isLoading = false;
  bool _isFetchingSlots = false;

  List<Map<String, dynamic>> _allSlots = [];
  List<Map<String, dynamic>> _availableSlots = [];

  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _loadCounselorSlots();
  }

  Future<void> _loadCounselorSlots() async {
    setState(() => _isFetchingSlots = true);
    try {
      final slots = await ApiService.getCounselorSlots(
          widget.counselor['id'].toString());
      setState(() => _allSlots = List<Map<String, dynamic>>.from(slots));
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to load schedule: $e");
    } finally {
      setState(() => _isFetchingSlots = false);
      _fetchAvailableSlots();
    }
  }

  Future<void> _fetchAvailableSlots() async {
    setState(() { _isFetchingSlots = true; _selectedSlot = null; });
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final slots = await ApiService.getAvailableSlots(
          widget.counselor['id'].toString(), dateStr);
      setState(() =>
          _availableSlots = List<Map<String, dynamic>>.from(slots));
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      if (mounted) setState(() => _isFetchingSlots = false);
    }
  }

  // Single confirmation — saves everything together
  Future<void> _confirmAppointment() async {
    if (_selectedSlot == null) {
      Fluttertoast.showToast(msg: "Please select a time slot");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final result = await ApiService.bookAppointment(
        counselorId: widget.counselor['id'].toString(),
        slotId: _selectedSlot!['id'].toString(),
        date: dateStr,
        // Pass the category and description from the previous screen
        categoryId: widget.categoryId,
        description: widget.description,
        priority: 'normal',
      );

      if (result['success'] == true) {
        final room = result['room_number'] ?? '';
        final startTime = result['start_time'] ?? '';
        final endTime = result['end_time'] ?? '';

        String msg = "Appointment confirmed!";
        if (startTime.isNotEmpty) msg += " Time: $startTime – $endTime.";
        if (room.isNotEmpty) msg += " Room: $room.";
        msg += " Waiting for counselor approval.";

        Fluttertoast.showToast(
            msg: msg,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            toastLength: Toast.LENGTH_LONG);

        if (mounted) {
          // Pop back to home (pop twice to exit counselor detail too)
          Navigator.pop(context);
          Navigator.pop(context);
        }
      } else {
        Fluttertoast.showToast(
            msg: result['message'] ?? "Booking failed",
            backgroundColor: Colors.red,
            textColor: Colors.white);
        _fetchAvailableSlots();
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _displayTime(String t) {
    try {
      final parts = t.split(':');
      int h = int.parse(parts[0]);
      final m = parts[1];
      final suffix = h >= 12 ? 'PM' : 'AM';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      return '$h:$m $suffix';
    } catch (_) { return t; }
  }

  Set<String> get _scheduledDays =>
      _allSlots.map((s) => s['day']?.toString() ?? '').toSet();

  String _dayName(DateTime d) => DateFormat('EEEE').format(d);

  bool _hasScheduleOnDate(DateTime d) =>
      _scheduledDays.contains(_dayName(d));

  @override
  Widget build(BuildContext context) {
    final counselorName = widget.counselor['name'] ?? 'Counselor';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(children: [
        Container(
            height: 200,
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight))),
        Positioned(
            top: -40, right: -40,
            child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06)))),

        SafeArea(child: Column(children: [
          // Header
          Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(children: [
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20)),
                const Text("Book Appointment",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ])),
          const SizedBox(height: 8),

          // Counselor mini card
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.25)),
                      child: Center(child: Text(counselorName[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w800,
                              color: Colors.white, fontSize: 18)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(counselorName,
                            style: const TextStyle(fontWeight: FontWeight.w700,
                                color: Colors.white, fontSize: 14)),
                        Text(widget.counselor['department'] ?? 'N/A',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 12)),
                      ])),
                ]),
              )),
          const SizedBox(height: 12),

          Expanded(child: Container(
            decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28))),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                // ── Request summary banner ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF1A73E8).withOpacity(0.25))),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.assignment_outlined,
                              color: Color(0xFF1A73E8), size: 16),
                          const SizedBox(width: 6),
                          const Text("Your Request Summary",
                              style: TextStyle(fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A73E8))),
                        ]),
                        const SizedBox(height: 8),
                        Text(widget.description,
                            style: TextStyle(fontSize: 13,
                                color: Colors.blue[800], height: 1.4)),
                        const SizedBox(height: 6),
                        Text(
                          "Select a time slot below to finalize your appointment. "
                          "Everything will be saved in one step.",
                          style: TextStyle(fontSize: 11,
                              color: Colors.blue[600], height: 1.4),
                        ),
                      ]),
                ),
                const SizedBox(height: 16),

                // ── Date picker card ──
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12)]),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                              color: const Color(0xFF1A73E8).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.calendar_today_rounded,
                              color: Color(0xFF1A73E8), size: 18)),
                      const SizedBox(width: 10),
                      const Text("Select Date",
                          style: TextStyle(fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827))),
                    ]),
                    const SizedBox(height: 14),

                    SizedBox(
                      height: 72,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 14,
                        itemBuilder: (ctx, i) {
                          final date =
                              DateTime.now().add(Duration(days: i));
                          final isSelected =
                              DateFormat('yyyy-MM-dd').format(date) ==
                              DateFormat('yyyy-MM-dd').format(_selectedDate);
                          final hasSchedule = _hasScheduleOnDate(date);

                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedDate = date);
                              _fetchAvailableSlots();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 52,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF1A73E8)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF1A73E8)
                                          : hasSchedule
                                              ? const Color(0xFF1A73E8)
                                                  .withOpacity(0.3)
                                              : const Color(0xFFE5E7EB))),
                              child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(DateFormat('EEE').format(date),
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey[500])),
                                    const SizedBox(height: 4),
                                    Text(DateFormat('d').format(date),
                                        style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF111827))),
                                    if (hasSchedule && !isSelected)
                                      Container(
                                          width: 5, height: 5,
                                          margin: const EdgeInsets.only(top: 3),
                                          decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF1A73E8))),
                                  ]),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.circle, size: 8, color: Color(0xFF1A73E8)),
                      const SizedBox(width: 5),
                      Text("Blue dot = counselor has schedule that day",
                          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ]),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Available slots card ──
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12)]),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                      Row(children: [
                        Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.access_time_rounded,
                                color: Color(0xFF22C55E), size: 18)),
                        const SizedBox(width: 10),
                        const Text("Available Slots",
                            style: TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827))),
                      ]),
                      Text(
                          DateFormat('EEE, d MMM').format(_selectedDate),
                          style: const TextStyle(fontSize: 12,
                              color: Color(0xFF1A73E8),
                              fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 14),

                    if (_isFetchingSlots)
                      const Center(child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                              color: Color(0xFF1A73E8))))
                    else if (_availableSlots.isEmpty)
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(14)),
                          child: Column(children: [
                            const Icon(Icons.event_busy_rounded,
                                color: Color(0xFFF59E0B), size: 36),
                            const SizedBox(height: 8),
                            const Text("No available slots",
                                style: TextStyle(fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827))),
                            const SizedBox(height: 4),
                            Text("Try selecting a different date",
                                style: TextStyle(fontSize: 12,
                                    color: Colors.grey[500])),
                          ]))
                    else
                      Wrap(
                          spacing: 10, runSpacing: 10,
                          children: _availableSlots.map((slot) {
                            final isSelected =
                                _selectedSlot?['id'] == slot['id'];
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedSlot = slot),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF1A73E8)
                                        : const Color(0xFFF0F7FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF1A73E8)
                                            : const Color(0xFF1A73E8)
                                                .withOpacity(0.3))),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                  Icon(Icons.access_time_rounded, size: 14,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF1A73E8)),
                                  const SizedBox(width: 6),
                                  Text(
                                      "${_displayTime(slot['start_time'])} – "
                                      "${_displayTime(slot['end_time'])}",
                                      style: TextStyle(fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF1A73E8))),
                                ]),
                              ),
                            );
                          }).toList()),
                  ]),
                ),

                // Selected slot summary
                if (_selectedSlot != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: const Color(0xFFEFFAF1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF22C55E).withOpacity(0.3))),
                    child: Row(children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF22C55E), size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text("Selected Appointment",
                            style: TextStyle(fontWeight: FontWeight.w700,
                                fontSize: 13, color: Color(0xFF111827))),
                        Text(
                            "${DateFormat('EEEE, d MMM yyyy').format(_selectedDate)} • "
                            "${_displayTime(_selectedSlot!['start_time'])} – "
                            "${_displayTime(_selectedSlot!['end_time'])}",
                            style: const TextStyle(fontSize: 12,
                                color: Color(0xFF22C55E),
                                fontWeight: FontWeight.w600)),
                      ])),
                    ]),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Confirm button — single save ──
                SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: (_isLoading || _selectedSlot == null)
                          ? null
                          : _confirmAppointment,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text("Confirm Appointment",
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                    )),
              ]),
            ),
          )),
        ])),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../api_service.dart';

class ScheduleManagerScreen extends StatefulWidget {
  const ScheduleManagerScreen({super.key});

  @override
  State<ScheduleManagerScreen> createState() => _ScheduleManagerScreenState();
}

class _ScheduleManagerScreenState extends State<ScheduleManagerScreen> {
  bool _isLoading = false;
  bool _isFetching = true;

  // Each slot: {day, start_time, end_time}
  List<Map<String, String>> _slots = [];

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isFetching = true);
    try {
      final data = await ApiService.getCounselorSchedule();
      setState(() {
        _slots = List<Map<String, String>>.from(
          (data as List).map((s) => {
            'id': s['id']?.toString() ?? '',
            'day': s['day']?.toString() ?? '',
            'start_time': s['start_time']?.toString() ?? '',
            'end_time': s['end_time']?.toString() ?? '',
            'room_number': s['room_number']?.toString() ?? '',
          }),
        );
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to load schedule: $e");
    } finally {
      setState(() => _isFetching = false);
    }
  }

  Future<void> _addSlot() async {
    String? selectedDay = _days[0];
    TimeOfDay startTime = const TimeOfDay(hour: 10, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 11, minute: 0);
    final roomController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Add Time Slot",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Day", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedDay,
                      isExpanded: true,
                      items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (v) => setDlg(() => selectedDay = v),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Start Time", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final t = await showTimePicker(context: ctx, initialTime: startTime);
                        if (t != null) setDlg(() => startTime = t);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1A73E8)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF1A73E8)),
                          const SizedBox(width: 6),
                          Text(startTime.format(ctx), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A73E8))),
                        ]),
                      ),
                    ),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("End Time", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final t = await showTimePicker(context: ctx, initialTime: endTime);
                        if (t != null) setDlg(() => endTime = t);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1A73E8)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF1A73E8)),
                          const SizedBox(width: 6),
                          Text(endTime.format(ctx), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A73E8))),
                        ]),
                      ),
                    ),
                  ])),
                ]),
                const SizedBox(height: 16),

                const Text("Room Number", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: TextField(
                    controller: roomController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "e.g. B1/602",
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                      prefixIcon: const Icon(Icons.meeting_room_outlined, color: Color(0xFF9CA3AF), size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await _saveSlot(selectedDay!, startTime, endTime, roomController.text.trim());
              },
              child: const Text("Add Slot"),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  String _displayTime(String t) {
    // Convert "HH:mm:ss" to "hh:mm AM/PM"
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

  Future<void> _saveSlot(String day, TimeOfDay start, TimeOfDay end, String roomNumber) async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.addScheduleSlot(day, _formatTime(start), _formatTime(end), roomNumber);
      if (result['success'] == true) {
        Fluttertoast.showToast(msg: "Slot added!", backgroundColor: Colors.green, textColor: Colors.white);
        _loadSchedule();
      } else {
        Fluttertoast.showToast(msg: result['message'] ?? "Failed", backgroundColor: Colors.red, textColor: Colors.white);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSlot(String slotId) async {
    try {
      final result = await ApiService.deleteScheduleSlot(slotId);
      if (result['success'] == true) {
        Fluttertoast.showToast(msg: "Slot removed", backgroundColor: Colors.orange, textColor: Colors.white);
        _loadSchedule();
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  // Group slots by day
  Map<String, List<Map<String, String>>> get _slotsByDay {
    final Map<String, List<Map<String, String>>> grouped = {};
    for (final slot in _slots) {
      final day = slot['day'] ?? 'Unknown';
      grouped.putIfAbsent(day, () => []).add(slot);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSlot,
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Add Slot", style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Stack(children: [
        Container(height: 180, decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                begin: Alignment.topLeft, end: Alignment.bottomRight))),
        Positioned(top: -40, right: -40, child: Container(width: 160, height: 160,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),

        SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(8, 8, 20, 0), child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                IconButton(onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
                const Text("My Schedule", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
              GestureDetector(onTap: _loadSchedule,
                  child: Container(width: 38, height: 38,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18))),
            ],
          )),

          // Info banner
          Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Students can only book slots you define here",
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12))),
                ]),
              )),
          const SizedBox(height: 12),

          Expanded(child: Container(
            decoration: const BoxDecoration(color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
            child: _isFetching
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A73E8)))
                : _slots.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.calendar_month_outlined, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              const Text("No schedule yet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              const SizedBox(height: 4),
              Text("Tap '+ Add Slot' to define your availability", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ]))
                : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              children: _slotsByDay.entries.map((entry) {
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
                      child: Row(children: [
                        Container(width: 8, height: 8,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1A73E8))),
                        const SizedBox(width: 8),
                        Text(entry.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                        const SizedBox(width: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF1A73E8).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text("${entry.value.length} slot${entry.value.length > 1 ? 's' : ''}",
                                style: const TextStyle(fontSize: 11, color: Color(0xFF1A73E8), fontWeight: FontWeight.w600))),
                      ])),
                  ...entry.value.map((slot) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(width: 42, height: 42,
                          decoration: BoxDecoration(color: const Color(0xFF1A73E8).withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.access_time_rounded, color: Color(0xFF1A73E8), size: 20)),
                      title: Text(
                          "${_displayTime(slot['start_time']!)} – ${_displayTime(slot['end_time']!)}",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                      subtitle: slot['room_number'] != null && slot['room_number']!.isNotEmpty
                          ? Row(children: [
                        const Icon(Icons.meeting_room_outlined, size: 13, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        Text("Room: ${slot['room_number']}", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ])
                          : Text("No room set", style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                        onPressed: () => _deleteSlot(slot['id']!),
                      ),
                    ),
                  )),
                  const SizedBox(height: 8),
                ]);
              }).toList(),
            ),
          )),
        ])),
      ]),
    );
  }
}
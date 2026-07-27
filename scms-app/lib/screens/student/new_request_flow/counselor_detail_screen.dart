import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../api_service.dart';
import 'book_appointment_screen.dart';

class CounselorDetailScreen extends StatefulWidget {
  final Map<String, dynamic> counselor;
  const CounselorDetailScreen({super.key, required this.counselor});

  @override
  State<CounselorDetailScreen> createState() => _CounselorDetailScreenState();
}

class _CounselorDetailScreenState extends State<CounselorDetailScreen> {
  List<dynamic> _slots = [];
  bool _isLoadingSlots = true;

  // Form fields
  String? _selectedCategory;
  final _descriptionController = TextEditingController();
  List<dynamic> _categories = [];

  final List<String> _dayOrder = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  Map<String, List<dynamic>> get _slotsByDay {
    final Map<String, List<dynamic>> grouped = {};
    for (final slot in _slots) {
      final day = slot['day']?.toString() ?? 'Unknown';
      grouped.putIfAbsent(day, () => []).add(slot);
    }
    return grouped;
  }

  @override
  void initState() {
    super.initState();
    _loadSlots();
    _loadCategories();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    try {
      final slots = await ApiService.getCounselorSlots(
          widget.counselor['id'].toString());
      setState(() { _slots = slots; _isLoadingSlots = false; });
    } catch (e) {
      setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.getCategories();
      setState(() {
        _categories = cats;
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories[0]['id'].toString();
        }
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to load categories: $e");
    }
  }

  // Validate and go to booking screen — NO submission yet
  void _proceedToBooking() {
    if (_selectedCategory == null) {
      Fluttertoast.showToast(msg: "Please select a category");
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Please describe your concern");
      return;
    }
    if (_slots.isEmpty) {
      Fluttertoast.showToast(
        msg: "This counselor has no available time slots yet",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    // Navigate to booking screen, passing category + description
    // The actual submission happens only after the student confirms a time slot
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookAppointmentScreen(
          counselor: widget.counselor,
          categoryId: _selectedCategory!,
          description: _descriptionController.text.trim(),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final counselorName = widget.counselor['name'] ?? 'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(children: [
        Container(
            height: 280,
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight))),
        Positioned(
            top: -40, right: -40,
            child: Container(
                width: 180, height: 180,
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
                const Text("Counselor Profile",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ])),
          const SizedBox(height: 16),

          // Avatar + name
          Center(child: Column(children: [
            Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4), width: 2.5)),
                child: Center(child: Text(counselorName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 32,
                        fontWeight: FontWeight.w800, color: Colors.white)))),
            const SizedBox(height: 10),
            Text(counselorName,
                style: const TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w800, color: Colors.white)),
            if (widget.counselor['designation'] != null) ...[
              const SizedBox(height: 4),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(widget.counselor['designation'],
                      style: const TextStyle(color: Colors.white,
                          fontSize: 12, fontWeight: FontWeight.w600))),
            ],
          ])),
          const SizedBox(height: 20),

          // Scrollable content
          Expanded(child: Container(
            decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28))),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(children: [

                // Counselor info
                _sectionCard(children: [
                  _infoRow(Icons.business_outlined, "Department",
                      widget.counselor['department'] ?? 'Not set',
                      const Color(0xFF1A73E8)),
                  _divider(),
                  _infoRow(Icons.mail_outline_rounded, "Email",
                      widget.counselor['email'] ?? 'N/A',
                      const Color(0xFF8B5CF6)),
                  _divider(),
                  _infoRow(Icons.phone_outlined, "Phone",
                      widget.counselor['phone'] ?? 'Not set',
                      const Color(0xFF22C55E)),
                ]),
                const SizedBox(height: 16),

                // Schedule
                _sectionCard(children: [
                  Row(children: [
                    Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.calendar_month_rounded,
                            color: Color(0xFFF59E0B), size: 22)),
                    const SizedBox(width: 12),
                    const Text("Counseling Schedule",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                            color: Color(0xFF111827))),
                  ]),
                  const SizedBox(height: 16),

                  if (_isLoadingSlots)
                    const Center(child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(color: Color(0xFF1A73E8))))
                  else if (_slots.isEmpty)
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3))),
                        child: Row(children: [
                          const Icon(Icons.info_outline_rounded,
                              color: Color(0xFFF59E0B), size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                              "No schedule set yet. You can still submit a request.",
                              style: TextStyle(color: Colors.orange[800],
                                  fontSize: 13, height: 1.4))),
                        ]))
                  else
                    Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB))),
                        child: Column(children: [
                          // Table header
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: const BoxDecoration(
                                  color: Color(0xFF1A73E8),
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(11),
                                      topRight: Radius.circular(11))),
                              child: Row(children: [
                                const SizedBox(width: 80,
                                    child: Text("Day", style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12))),
                                const Expanded(child: Text("Time",
                                    style: TextStyle(color: Colors.white,
                                        fontWeight: FontWeight.w700, fontSize: 12))),
                                const SizedBox(width: 80,
                                    child: Text("Room", textAlign: TextAlign.right,
                                        style: TextStyle(color: Colors.white,
                                            fontWeight: FontWeight.w700, fontSize: 12))),
                              ])),

                          ..._dayOrder
                              .where((d) => _slotsByDay.containsKey(d))
                              .map((day) {
                            final daySlots = _slotsByDay[day]!;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                  color: _dayOrder.indexOf(day) % 2 == 0
                                      ? Colors.white : const Color(0xFFF9FAFB),
                                  border: const Border(
                                      top: BorderSide(color: Color(0xFFE5E7EB)))),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: daySlots.map((slot) {
                                    final room = slot['room_number'] ?? '';
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(children: [
                                        SizedBox(width: 80,
                                            child: Text(day,
                                                style: const TextStyle(fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF374151)))),
                                        Expanded(child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                                color: const Color(0xFF1A73E8).withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                    color: const Color(0xFF1A73E8).withOpacity(0.2))),
                                            child: Text(
                                                "${_displayTime(slot['start_time'])} – "
                                                "${_displayTime(slot['end_time'])}",
                                                style: const TextStyle(fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1A73E8))))),
                                        SizedBox(width: 80,
                                            child: Text(
                                                room.isNotEmpty ? room : '—',
                                                textAlign: TextAlign.right,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: room.isNotEmpty
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                    color: room.isNotEmpty
                                                        ? const Color(0xFF374151)
                                                        : Colors.grey[400]))),
                                      ]),
                                    );
                                  }).toList()),
                            );
                          }),
                        ])),
                ]),
                const SizedBox(height: 16),

                // ── Request Form ──
                _sectionCard(children: [
                  Row(children: [
                    Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                            color: const Color(0xFF1A73E8).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.send_rounded,
                            color: Color(0xFF1A73E8), size: 20)),
                    const SizedBox(width: 12),
                    const Text("Send a Counseling Request",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                            color: Color(0xFF111827))),
                  ]),
                  const SizedBox(height: 18),

                  // Category
                  _fieldLabel("Category"),
                  const SizedBox(height: 6),
                  Container(
                      decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB))),
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            prefixIcon: Icon(Icons.category_outlined,
                                color: Color(0xFF9CA3AF), size: 18)),
                        items: _categories.map((cat) => DropdownMenuItem<String>(
                            value: cat['id'].toString(),
                            child: Text(cat['name'] ?? 'Unknown',
                                style: const TextStyle(fontSize: 14)))).toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v),
                      )),
                  const SizedBox(height: 14),

                  // Description
                  _fieldLabel("Describe Your Concern"),
                  const SizedBox(height: 6),
                  Container(
                      decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB))),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 14,
                            color: Color(0xFF111827)),
                        decoration: InputDecoration(
                            hintText: "Explain your concern in detail...",
                            hintStyle: TextStyle(
                                color: Colors.grey[400], fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(14)),
                      )),
                  const SizedBox(height: 20),

                  // Info note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF1A73E8).withOpacity(0.2))),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Color(0xFF1A73E8), size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                          "After clicking Submit, you will select your preferred time slot. "
                          "Everything will be saved together in one step.",
                          style: TextStyle(fontSize: 12,
                              color: Colors.blue[700], height: 1.4))),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Submit → goes to booking screen
                  SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: const Text("Submit Request & Book Slot",
                            style: TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A73E8),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                        onPressed: _proceedToBooking,
                      )),
                ]),
              ]),
            ),
          )),
        ])),
      ]),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 16)]),
        padding: const EdgeInsets.all(20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children));
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(width: 36, height: 36,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11,
                color: Colors.grey[500], fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          ]),
        ]));
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFFF3F4F6));

  Widget _fieldLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: Color(0xFF374151)));
}

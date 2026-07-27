import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../../../api_service.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _upcoming  = [];
  List<dynamic> _completed = [];
  bool   _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ApiService.getMyAppointments();
      setState(() {
        _upcoming  = data['upcoming']  as List<dynamic>;
        _completed = data['completed'] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
      Fluttertoast.showToast(msg: "Failed to load: $e", backgroundColor: Colors.red, textColor: Colors.white);
    }
  }

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return '—';
    try { return DateFormat('dd MMM yyyy').format(DateTime.parse(d)); }
    catch (_) { return d; }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(children: [
        Container(height: 200, decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              begin: Alignment.topLeft, end: Alignment.bottomRight))),

        SafeArea(child: Column(children: [
          // Header
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("My Appointments",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              GestureDetector(
                onTap: _load,
                child: Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20)),
              ),
            ])),
          const SizedBox(height: 12),

          // Tab bar
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: const Color(0xFF6D28D9),
                unselectedLabelColor: Colors.white,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: "Upcoming (${_upcoming.length})"),
                  Tab(text: "Completed (${_completed.length})"),
                ],
              ),
            )),
          const SizedBox(height: 12),

          // Content
          Expanded(child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
                : _error != null
                    ? _buildError()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(_upcoming, isUpcoming: true),
                          _buildList(_completed, isUpcoming: false),
                        ],
                      ),
          )),
        ])),
      ]),
    );
  }

  Widget _buildError() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
    const SizedBox(height: 12),
    Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
    const SizedBox(height: 16),
    ElevatedButton(onPressed: _load,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Retry')),
  ]));

  Widget _buildList(List<dynamic> items, {required bool isUpcoming}) {
    if (items.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(isUpcoming ? Icons.calendar_today_rounded : Icons.history_rounded,
            size: 72, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(isUpcoming ? "No upcoming appointments" : "No completed appointments",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        Text(isUpcoming ? "Book a session from Find Counselor" : "Completed sessions will appear here",
            style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF8B5CF6),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildCard(items[i], isUpcoming: isUpcoming),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> a, {required bool isUpcoming}) {
    final accent = isUpcoming ? const Color(0xFF8B5CF6) : const Color(0xFF22C55E);
    final statusLabel = isUpcoming ? 'UPCOMING' : 'COMPLETED';
    final statusColor = isUpcoming ? const Color(0xFF8B5CF6) : const Color(0xFF22C55E);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top color bar + status
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.06),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            border: Border(bottom: BorderSide(color: accent.withOpacity(0.12))),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            // Date + time
            Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.calendar_today_rounded, color: accent, size: 20)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_fmtDate(a['date']),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: accent)),
                Text('${_fmtTime(a['start_time'] ?? '')} – ${_fmtTime(a['end_time'] ?? '')}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ]),
            ]),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(statusLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor)),
            ),
          ]),
        ),

        // Counselor info
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Counselor row
          Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent, accent.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(
                (a['counselor_name'] ?? 'C')[0].toUpperCase(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a['counselor_name'] ?? '—',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              Text('${a['counselor_designation'] ?? 'Counselor'} • ${a['counselor_department'] ?? '—'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ])),
          ]),
          const SizedBox(height: 14),

          // Details grid
          Row(children: [
            Expanded(child: _detailChip(Icons.school_outlined, 'Category',
                a['category'] ?? 'General', const Color(0xFF1A73E8))),
            const SizedBox(width: 10),
            Expanded(child: _detailChip(Icons.meeting_room_outlined, 'Room',
                (a['room_number'] ?? '').isNotEmpty ? a['room_number'] : 'TBA',
                const Color(0xFFF59E0B))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _detailChip(Icons.calendar_month_outlined, 'Day',
                a['day'] ?? '—', const Color(0xFF8B5CF6))),
            const SizedBox(width: 10),
            Expanded(child: _detailChip(Icons.access_time_rounded, 'Time',
                _fmtTime(a['start_time'] ?? ''), accent)),
          ]),

          // Description if exists
          if ((a['description'] ?? '').isNotEmpty && a['description'] != 'Appointment booking') ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.notes_rounded, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Expanded(child: Text(a['description'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4))),
              ]),
            ),
          ],
        ])),
      ]),
    );
  }

  Widget _detailChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
              overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }
}
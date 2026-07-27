import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../api_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ApiService.getStatistics();
      setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return '—';
    try { return DateFormat('dd MMM yyyy').format(DateTime.parse(d)); }
    catch (_) { return d; }
  }

  @override
  Widget build(BuildContext context) {
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
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
                const Text("Statistics",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
              GestureDetector(
                onTap: _load,
                child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20)),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(child: Container(
            decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28), topRight: Radius.circular(28))),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A73E8)))
                : _error != null
                ? _buildError()
                : _buildContent(),
          )),
        ])),
      ]),
    );
  }

  Widget _buildError() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
    const SizedBox(height: 12),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
    ),
    const SizedBox(height: 16),
    ElevatedButton(onPressed: _load,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8), foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Retry')),
  ]));

  Widget _buildContent() {
    final d = _data!;

    final totalRequests = d['total_requests'] ?? 0;
    final pending       = d['pending']        ?? 0;
    final approved      = d['approved']       ?? 0;
    final rejected      = d['rejected']       ?? 0;
    final completed     = d['completed']      ?? 0;
    final today         = d['today']          ?? 0;
    final thisWeek      = d['this_week']      ?? 0;

    final List<dynamic> daily       = d['daily_this_week'] ?? [0,0,0,0,0,0,0];
    final List<dynamic> categories  = d['categories']      ?? [];
    final List<dynamic> topSlots    = d['top_slots']       ?? [];
    final List<dynamic> topStudents = d['top_students']    ?? [];
    final List<dynamic> recent      = d['recent']          ?? [];

    final maxY = (daily.fold<num>(0, (p, v) => v > p ? v : p) + 2).toDouble();

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF1A73E8),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Section: Overview ──────────────────────────────────
          _sectionTitle("Overview", Icons.dashboard_rounded, const Color(0xFF1A73E8)),
          const SizedBox(height: 12),

          // Row 1: Total + Today
          Row(children: [
            Expanded(child: _statCard("Total Requests", totalRequests.toString(),
                Icons.psychology_rounded, const Color(0xFF1A73E8))),
            const SizedBox(width: 12),
            Expanded(child: _statCard("Today", today.toString(),
                Icons.today_rounded, const Color(0xFF22C55E))),
          ]),
          const SizedBox(height: 12),

          // Row 2: This Week + Completed
          Row(children: [
            Expanded(child: _statCard("This Week", thisWeek.toString(),
                Icons.calendar_view_week_rounded, const Color(0xFF06B6D4))),
            const SizedBox(width: 12),
            Expanded(child: _statCard("Completed", completed.toString(),
                Icons.check_circle_outline_rounded, const Color(0xFF8B5CF6))),
          ]),
          const SizedBox(height: 12),

          // Row 3: Pending + Approved + Rejected
          Row(children: [
            Expanded(child: _statCard("Pending", pending.toString(),
                Icons.pending_actions_rounded, const Color(0xFFF59E0B))),
            const SizedBox(width: 6),
            Expanded(child: _statCard("Approved", approved.toString(),
                Icons.thumb_up_alt_outlined, const Color(0xFF22C55E))),
            const SizedBox(width: 6),
            Expanded(child: _statCard("Rejected", rejected.toString(),
                Icons.cancel_outlined, const Color(0xFFEF4444))),
          ]),
          const SizedBox(height: 24),

          // ── Section: Weekly Activity ───────────────────────────
          _sectionTitle("Weekly Activity", Icons.bar_chart_rounded, const Color(0xFF1A73E8)),
          const SizedBox(height: 12),
          _buildBarChart(daily, maxY),
          const SizedBox(height: 24),

          // ── Section: Category Breakdown ────────────────────────
          if (categories.isNotEmpty) ...[
            _sectionTitle("Category Breakdown", Icons.pie_chart_rounded, const Color(0xFF8B5CF6)),
            const SizedBox(height: 12),
            _buildCategoryChart(categories),
            const SizedBox(height: 24),
          ],

          // ── Section: Top Time Slots ────────────────────────────
          if (topSlots.isNotEmpty) ...[
            _sectionTitle("Most Booked Slots", Icons.access_time_rounded, const Color(0xFF06B6D4)),
            const SizedBox(height: 12),
            _buildTopSlots(topSlots),
            const SizedBox(height: 24),
          ],

          // ── Section: Most Active Students ─────────────────────
          if (topStudents.isNotEmpty) ...[
            _sectionTitle("Most Active Students", Icons.people_rounded, const Color(0xFFF59E0B)),
            const SizedBox(height: 12),
            _buildTopStudents(topStudents),
            const SizedBox(height: 24),
          ],

          // ── Section: Recent Appointments ──────────────────────
          if (recent.isNotEmpty) ...[
            _sectionTitle("Recent Appointments", Icons.history_rounded, const Color(0xFF8B5CF6)),
            const SizedBox(height: 12),
            _buildRecent(recent),
          ],
        ]),
      ),
    );
  }

  // ── Bar Chart ──────────────────────────────────────────────────
  Widget _buildBarChart(List<dynamic> daily, double maxY) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16)]),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Appointments per day this week",
            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: BarChart(BarChartData(
            maxY: maxY < 4 ? 4 : maxY,
            barGroups: List.generate(7, (i) => BarChartGroupData(
              x: i,
              barRods: [BarChartRodData(
                toY: (daily[i] as num).toDouble(),
                color: (daily[i] as num) > 0
                    ? const Color(0xFF1A73E8)
                    : const Color(0xFFE5E7EB),
                width: 20,
                borderRadius: BorderRadius.circular(6),
              )],
            )),
            gridData: FlGridData(show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                const FlLine(color: Color(0xFFF3F4F6), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24,
                  getTitlesWidget: (v, _) => v % 1 == 0
                      ? Text(v.toInt().toString(), style: TextStyle(fontSize: 10, color: Colors.grey[400]))
                      : const SizedBox())),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i > 6) return const SizedBox();
                    return Text(days[i], style: TextStyle(fontSize: 10, color: Colors.grey[500]));
                  })),
            ),
          )),
        ),
      ]),
    );
  }

  // ── Pie Chart for Categories ──────────────────────────────────
  Widget _buildCategoryChart(List<dynamic> categories) {
    final colors = [
      const Color(0xFF1A73E8),
      const Color(0xFF8B5CF6),
      const Color(0xFF22C55E),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF06B6D4),
    ];
    final total = categories.fold<int>(0, (s, c) => s + (c['count'] as int));

    return Container(
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16)]),
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        // Pie chart
        SizedBox(
          width: 130, height: 130,
          child: PieChart(PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 32,
            sections: List.generate(categories.length, (i) {
              final cat = categories[i] as Map<String, dynamic>;
              final pct = total > 0 ? (cat['count'] as int) / total * 100 : 0.0;
              return PieChartSectionData(
                color: colors[i % colors.length],
                value: (cat['count'] as int).toDouble(),
                title: '${pct.toStringAsFixed(0)}%',
                titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                radius: 45,
              );
            }),
          )),
        ),
        const SizedBox(width: 20),
        // Legend
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(categories.length, (i) {
            final cat = categories[i] as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 8),
                Expanded(child: Text(cat['name'] ?? '—',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w500))),
                Text(cat['count'].toString(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors[i % colors.length])),
              ]),
            );
          }),
        )),
      ]),
    );
  }

  // ── Top Slots ─────────────────────────────────────────────────
  Widget _buildTopSlots(List<dynamic> slots) {
    return Container(
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16)]),
      padding: const EdgeInsets.all(20),
      child: Column(children: List.generate(slots.length, (i) {
        final s = slots[i] as Map<String, dynamic>;
        final maxCount = (slots[0] as Map<String, dynamic>)['count'] as int;
        final count    = s['count'] as int;
        final pct      = maxCount > 0 ? count / maxCount : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(s['time'] ?? '—',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              Text('$count booking${count != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF06B6D4), fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: const Color(0xFFF3F4F6),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF06B6D4)),
              ),
            ),
          ]),
        );
      })),
    );
  }

  // ── Top Students ──────────────────────────────────────────────
  Widget _buildTopStudents(List<dynamic> students) {
    return Container(
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16)]),
      padding: const EdgeInsets.all(20),
      child: Column(children: List.generate(students.length, (i) {
        final s = students[i] as Map<String, dynamic>;
        final colors = [
          const Color(0xFF1A73E8), const Color(0xFF8B5CF6),
          const Color(0xFF22C55E), const Color(0xFFF59E0B), const Color(0xFFEF4444),
        ];
        final color = colors[i % colors.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Center(child: Text(
                (s['name'] ?? 'S')[0].toUpperCase(),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(s['name'] ?? '—',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text('${s['count']} session${(s['count'] as int) != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            ),
          ]),
        );
      })),
    );
  }

  // ── Recent Appointments ───────────────────────────────────────
  Widget _buildRecent(List<dynamic> recent) {
    return Container(
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16)]),
      padding: const EdgeInsets.all(20),
      child: Column(children: recent.map((r) {
        final appt = r as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Container(width: 38, height: 38,
                decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(
                  (appt['student_name'] ?? 'S')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A73E8)),
                ))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(appt['student_name'] ?? '—',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              Text('${appt['category'] ?? 'General'} • ${_fmtDate(appt['date'])}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(appt['start_time'] ?? '—',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF22C55E))),
            ),
          ]),
        );
      }).toList()),
    );
  }

  // ── Stat Card ─────────────────────────────────────────────────
  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(children: [
        Container(width: 38, height: 38,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 19)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ])),
      ]),
    );
  }

  // ── Section Title ─────────────────────────────────────────────
  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(children: [
      Container(width: 32, height: 32,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 17)),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
    ]);
  }
}
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../api_service.dart';
import 'counselor_detail_screen.dart';

class CounselorSearchScreen extends StatefulWidget {
  const CounselorSearchScreen({super.key});

  @override
  State<CounselorSearchScreen> createState() => _CounselorSearchScreenState();
}

class _CounselorSearchScreenState extends State<CounselorSearchScreen> {
  List<dynamic> _counselors = [];
  List<dynamic> _filtered   = [];
  String  _search     = '';
  String? _studentDept;        // loaded from SharedPreferences
  bool    _isLoading  = true;

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    // Load the student's department first, then fetch counselors
    final prefs = await SharedPreferences.getInstance();
    _studentDept = prefs.getString('department') ?? '';
    await _loadCounselors();
  }

  Future<void> _loadCounselors() async {
    setState(() => _isLoading = true);
    try {
      // If student has a department set, fetch only that dept's counselors
      final list = (_studentDept != null && _studentDept!.isNotEmpty)
          ? await ApiService.getCounselorsByDept(_studentDept!)
          : await ApiService.getCounselors();

      setState(() {
        _counselors = list;
        _filtered   = list;
        _isLoading  = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: "Failed to load counselors: $e");
    }
  }

  void _applySearch() {
    setState(() {
      _filtered = _counselors.where((c) {
        final name = (c['name'] ?? '').toLowerCase().contains(_search.toLowerCase());
        final id   = (c['id']   ?? '').toString().contains(_search);
        return name || id;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(children: [
        Container(height: 220, decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
              begin: Alignment.topLeft, end: Alignment.bottomRight))),
        Positioned(top: -40, right: -40, child: Container(width: 160, height: 160,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),

        SafeArea(child: Column(children: [
          // Header
          Padding(padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                IconButton(onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
                const Text("Find a Counselor",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
              if (_studentDept != null && _studentDept!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.business_outlined, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(_studentDept!,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
            ])),
          const SizedBox(height: 8),

          // Department info banner
          if (_studentDept != null && _studentDept!.isNotEmpty)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.white, size: 15),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    "Showing $_studentDept department counselors only",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  )),
                ]),
              )),
          const SizedBox(height: 10),

          // Search bar
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)]),
              child: TextField(
                onChanged: (v) { _search = v; _applySearch(); },
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Search by name or ID",
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            )),
          const SizedBox(height: 12),

          // List
          Expanded(child: Container(
            decoration: const BoxDecoration(color: Color(0xFFF5F7FA),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A73E8)))
                : _filtered.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.person_search_rounded, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          _studentDept != null && _studentDept!.isNotEmpty
                              ? "No $_studentDept counselors found"
                              : "No counselors found",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                              color: Color(0xFF374151))),
                        const SizedBox(height: 6),
                        if (_studentDept != null && _studentDept!.isNotEmpty)
                          Text("Only $_studentDept dept counselors are shown",
                              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _loadCounselors,
                        color: const Color(0xFF1A73E8),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            final c = _filtered[i];
                            final initial = (c['name'] ?? '?')[0].toUpperCase();
                            final colors = [
                              const Color(0xFF1A73E8), const Color(0xFF22C55E),
                              const Color(0xFF8B5CF6), const Color(0xFFF59E0B)
                            ];
                            final color = colors[i % colors.length];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(width: 48, height: 48,
                                  decoration: BoxDecoration(color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(14)),
                                  child: Center(child: Text(initial,
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)))),
                                title: Text(c['name'] ?? 'Unknown',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827))),
                                subtitle: Padding(padding: const EdgeInsets.only(top: 2),
                                  child: Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(c['department'] ?? 'N/A',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                                    ),
                                    const SizedBox(width: 6),
                                    Text("ID: ${c['id']}",
                                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                  ])),
                                trailing: Container(width: 32, height: 32,
                                  decoration: BoxDecoration(color: const Color(0xFF1A73E8).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.arrow_forward_ios_rounded, size: 14,
                                      color: Color(0xFF1A73E8))),
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => CounselorDetailScreen(counselor: c))),
                              ),
                            );
                          },
                        ),
                      ),
          )),
        ])),
      ]),
    );
  }
}
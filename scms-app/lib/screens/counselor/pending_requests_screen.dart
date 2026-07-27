import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../../../api_service.dart';
import '../../models/request_model.dart';
import '../../widgets/status_badge.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  List<CounselingRequest> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() { super.initState(); _loadPendingRequests(); }

  Future<void> _loadPendingRequests() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final rawList = await ApiService.getPendingRequests();
      setState(() {
        _requests = rawList.map((j) => CounselingRequest.fromJson(j)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _errorMessage = "Failed to load: $e"; _isLoading = false; });
      Fluttertoast.showToast(msg: _errorMessage!, backgroundColor: Colors.red, textColor: Colors.white);
    }
  }

  Future<void> _approve(int id) async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.approveRequest(id);
      if (result['success'] == true) {
        Fluttertoast.showToast(msg: "Request approved", backgroundColor: Colors.green, textColor: Colors.white);
        _loadPendingRequests();
      } else {
        Fluttertoast.showToast(msg: result['message'] ?? "Approval failed", backgroundColor: Colors.red, textColor: Colors.white);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e", backgroundColor: Colors.red, textColor: Colors.white);
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _reject(int id) async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.rejectRequest(id);
      if (result['success'] == true) {
        Fluttertoast.showToast(msg: "Request rejected", backgroundColor: Colors.orange, textColor: Colors.white);
        _loadPendingRequests();
      } else {
        Fluttertoast.showToast(msg: result['message'] ?? "Rejection failed", backgroundColor: Colors.red, textColor: Colors.white);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e", backgroundColor: Colors.red, textColor: Colors.white);
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  String _formatDate(String? d) {
    if (d == null) return "—";
    try { return DateFormat("dd MMM yyyy • hh:mm a").format(DateTime.parse(d)); } catch (_) { return d; }
  }

  void _showStudentProfile(CounselingRequest req) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 20),

            // Avatar + name header
            Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)])),
                child: Center(child: Text(
                    req.studentName.isNotEmpty ? req.studentName[0].toUpperCase() : 'S',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white))),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(req.studentName,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text("Student",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1A73E8))),
                ),
              ]),
            ]),
            const SizedBox(height: 24),

            const Text("Student Details",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280), letterSpacing: 0.5)),
            const SizedBox(height: 14),

            _studentDetailTile(
                Icons.badge_outlined, "Student ID",
                req.studentNumber?.isNotEmpty == true ? req.studentNumber! : 'Not provided',
                const Color(0xFF1A73E8)),
            _studentDetailTile(
                Icons.business_outlined, "Department",
                req.studentDepartment?.isNotEmpty == true ? req.studentDepartment! : 'Not provided',
                const Color(0xFF8B5CF6)),
            _studentDetailTile(
                Icons.numbers_rounded, "Intake",
                req.studentIntake?.isNotEmpty == true ? req.studentIntake! : 'Not provided',
                const Color(0xFF22C55E)),
            _studentDetailTile(
                Icons.group_outlined, "Section",
                req.studentSection?.isNotEmpty == true ? req.studentSection! : 'Not provided',
                const Color(0xFFF59E0B)),
            _studentDetailTile(
                Icons.phone_outlined, "Phone",
                req.studentPhone?.isNotEmpty == true ? req.studentPhone! : 'Not provided',
                const Color(0xFFEC4899)),

            const SizedBox(height: 20),
            const Divider(color: Color(0xFFF3F4F6)),
            const SizedBox(height: 14),

            // Request info
            const Text("Request Details",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280), letterSpacing: 0.5)),
            const SizedBox(height: 12),

            Row(children: [
              _chip(req.category, const Color(0xFF1A73E8)),
              const SizedBox(width: 8),
              _chip(req.priority.toUpperCase(),
                  req.priority == 'emergency' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
            ]),
            const SizedBox(height: 10),
            Text(req.description,
                style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _studentDetailTile(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(width: 38, height: 38,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        ]),
      ]),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          Container(height: 180,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight))),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Pending Requests",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                      GestureDetector(
                        onTap: _loadPendingRequests,
                        child: Container(width: 40, height: 40,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A73E8)))
                        : _errorMessage != null
                            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
                                const SizedBox(height: 12),
                                Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                ElevatedButton(onPressed: _loadPendingRequests,
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8), foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                    child: const Text("Retry")),
                              ]))
                            : _requests.isEmpty
                                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.green[300]),
                                    const SizedBox(height: 12),
                                    const Text("No pending requests", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                                    const SizedBox(height: 4),
                                    Text("All caught up!", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                                  ]))
                                : RefreshIndicator(
                                    onRefresh: _loadPendingRequests,
                                    color: const Color(0xFF1A73E8),
                                    child: ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                                      itemCount: _requests.length,
                                      itemBuilder: (context, index) {
                                        final req = _requests[index];
                                        final isEmergency = req.priority == 'emergency';
                                        return FadeInRight(
                                          delay: Duration(milliseconds: index * 60),
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(18),
                                                border: isEmergency
                                                    ? Border.all(color: const Color(0xFFEF4444).withOpacity(0.3), width: 1.5)
                                                    : null,
                                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))]),
                                            child: Padding(
                                              padding: const EdgeInsets.all(18),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Student name + status
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(child: Text(
                                                          req.studentName.isNotEmpty ? req.studentName : "Student #${req.id}",
                                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)))),
                                                      StatusBadge(status: req.status),
                                                    ],
                                                  ),

                                                  // ── Student profile info ──
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    padding: const EdgeInsets.all(10),
                                                    decoration: BoxDecoration(
                                                        color: const Color(0xFFF8FAFF),
                                                        borderRadius: BorderRadius.circular(10),
                                                        border: Border.all(color: const Color(0xFFE5E7EB))),
                                                    child: Column(
                                                      children: [
                                                        Row(children: [
                                                          _infoChip(Icons.badge_outlined, "ID",
                                                              req.studentNumber?.isNotEmpty == true ? req.studentNumber! : '—',
                                                              const Color(0xFF1A73E8)),
                                                          const SizedBox(width: 12),
                                                          _infoChip(Icons.business_outlined, "Dept",
                                                              req.studentDepartment?.isNotEmpty == true ? req.studentDepartment! : '—',
                                                              const Color(0xFF8B5CF6)),
                                                        ]),
                                                        const SizedBox(height: 8),
                                                        Row(children: [
                                                          _infoChip(Icons.numbers_rounded, "Intake",
                                                              req.studentIntake?.isNotEmpty == true ? req.studentIntake! : '—',
                                                              const Color(0xFF22C55E)),
                                                          const SizedBox(width: 12),
                                                          _infoChip(Icons.group_outlined, "Section",
                                                              req.studentSection?.isNotEmpty == true ? req.studentSection! : '—',
                                                              const Color(0xFFF59E0B)),
                                                        ]),
                                                        const SizedBox(height: 8),
                                                        Row(children: [
                                                          _infoChip(Icons.phone_outlined, "Phone",
                                                              req.studentPhone?.isNotEmpty == true ? req.studentPhone! : '—',
                                                              const Color(0xFFEC4899)),
                                                        ]),
                                                      ],
                                                    ),
                                                  ),

                                                  // Category
                                                  const SizedBox(height: 10),
                                                  Text(req.category,
                                                      style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.w500, fontSize: 13)),
                                                  const SizedBox(height: 6),
                                                  Text(req.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),

                                                  // Appointment date & time
                                                  if (req.appointmentTime != null && req.appointmentTime!.isNotEmpty) ...[
                                                    const SizedBox(height: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                                      decoration: BoxDecoration(
                                                          color: const Color(0xFFEFF6FF),
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(color: const Color(0xFF1A73E8).withOpacity(0.2))),
                                                      child: Row(children: [
                                                        const Icon(Icons.event_rounded, size: 14, color: Color(0xFF1A73E8)),
                                                        const SizedBox(width: 6),
                                                        Text("Appointment: ${_formatDate(req.appointmentTime)}",
                                                            style: const TextStyle(fontSize: 12,
                                                                color: Color(0xFF1A73E8),
                                                                fontWeight: FontWeight.w600)),
                                                      ]),
                                                    ),
                                                  ],

                                                  const SizedBox(height: 12),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          decoration: BoxDecoration(
                                                              color: (isEmergency ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)).withOpacity(0.1),
                                                              borderRadius: BorderRadius.circular(8)),
                                                          child: Text(req.priority.toUpperCase(),
                                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                                                  color: isEmergency ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)))),
                                                      Text(_formatDate(req.requestedAt),
                                                          style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 14),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      // View full profile button
                                                      TextButton.icon(
                                                        icon: const Icon(Icons.person_outline_rounded, size: 15),
                                                        label: const Text("View Profile", style: TextStyle(fontSize: 12)),
                                                        style: TextButton.styleFrom(
                                                            foregroundColor: const Color(0xFF1A73E8),
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                                                        onPressed: () => _showStudentProfile(req),
                                                      ),
                                                      Row(children: [
                                                        OutlinedButton.icon(
                                                            icon: const Icon(Icons.close_rounded, size: 16),
                                                            label: const Text("Reject", style: TextStyle(fontSize: 13)),
                                                            style: OutlinedButton.styleFrom(
                                                                foregroundColor: const Color(0xFFEF4444),
                                                                side: const BorderSide(color: Color(0xFFEF4444)),
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                                                            onPressed: _isLoading ? null : () => _reject(req.id)),
                                                        const SizedBox(width: 10),
                                                        ElevatedButton.icon(
                                                            icon: const Icon(Icons.check_rounded, size: 16),
                                                            label: const Text("Approve", style: TextStyle(fontSize: 13)),
                                                            style: ElevatedButton.styleFrom(
                                                                backgroundColor: const Color(0xFF22C55E),
                                                                foregroundColor: Colors.white,
                                                                elevation: 0,
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                                                            onPressed: _isLoading ? null : () => _approve(req.id)),
                                                      ]),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Row(children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Flexible(child: RichText(text: TextSpan(
          children: [
            TextSpan(text: "$label: ", style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
            TextSpan(text: value, style: const TextStyle(fontSize: 11, color: Color(0xFF111827), fontWeight: FontWeight.w600)),
          ],
        ))),
      ]),
    );
  }
}
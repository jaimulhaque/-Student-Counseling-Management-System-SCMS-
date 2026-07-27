import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../../../api_service.dart';
import '../../models/request_model.dart';
import '../../widgets/status_badge.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  List<CounselingRequest> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMyRequests();
  }

  Future<void> _loadMyRequests() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final rawList = await ApiService.getMyRequests();
      setState(() {
        _requests = rawList.map((json) => CounselingRequest.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _errorMessage = "Failed to load requests: $e"; _isLoading = false; });
      Fluttertoast.showToast(msg: _errorMessage!, backgroundColor: Colors.red, textColor: Colors.white);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "—";
    try { return DateFormat("dd MMM yyyy • hh:mm a").format(DateTime.parse(dateStr)); }
    catch (_) { return dateStr; }
  }

  Color _priorityColor(String p) => p == 'emergency' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);

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
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("My Requests",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                      GestureDetector(
                        onTap: _loadMyRequests,
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
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                    ),
                    child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A73E8)))
                      : _errorMessage != null
                        ? _buildError()
                        : _requests.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: _loadMyRequests,
                              color: const Color(0xFF1A73E8),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                                itemCount: _requests.length,
                                itemBuilder: (context, index) {
                                  final req = _requests[index];
                                  return FadeInUp(
                                    delay: Duration(milliseconds: index * 60),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(18),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(child: Text(req.category,
                                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)))),
                                                StatusBadge(status: req.status),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(req.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                                              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _priorityColor(req.priority).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(req.priority.toUpperCase(),
                                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _priorityColor(req.priority))),
                                                ),
                                                Text(_formatDate(req.requestedAt),
                                                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                              ],
                                            ),
                                            if (req.appointmentTime != null) ...[
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF1A73E8)),
                                                  const SizedBox(width: 5),
                                                  Text("Appointment: ${_formatDate(req.appointmentTime)}",
                                                    style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.w500, fontSize: 12)),
                                                ],
                                              ),
                                            ],
                                            if (req.roomName != null && req.roomName!.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  const Icon(Icons.meeting_room_rounded, size: 13, color: Color(0xFF8B5CF6)),
                                                  const SizedBox(width: 5),
                                                  Text("Room: ${req.roomName}",
                                                    style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.w500, fontSize: 12)),
                                                ],
                                              ),
                                            ],
                                            if (req.status == 'rejected' && req.rejectionReason != null && req.rejectionReason!.isNotEmpty) ...[
                                              const SizedBox(height: 10),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFEF2F2),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.25)),
                                                ),
                                                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                                                  const SizedBox(width: 6),
                                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                    const Text('Rejection Reason',
                                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                                                    const SizedBox(height: 2),
                                                    Text(req.rejectionReason!,
                                                      style: TextStyle(fontSize: 12, color: Colors.red[700], height: 1.4)),
                                                  ])),
                                                ]),
                                              ),
                                            ],
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

  Widget _buildError() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.error_outline_rounded, size: 72, color: Colors.red[300]),
    const SizedBox(height: 16),
    Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
    const SizedBox(height: 20),
    ElevatedButton.icon(icon: const Icon(Icons.refresh), label: const Text("Retry"),
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      onPressed: _loadMyRequests),
  ]));

  Widget _buildEmpty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.inbox_rounded, size: 72, color: Colors.grey[300]),
    const SizedBox(height: 16),
    const Text("No requests yet", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
    const SizedBox(height: 6),
    Text("Submit your first request from home screen", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
  ]));
}
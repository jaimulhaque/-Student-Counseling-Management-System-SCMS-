import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../api_service.dart';
import '../common/profile_screen.dart';
import 'my_requests_screen.dart';
import 'my_appointments_screen.dart';
import 'new_request_flow/counselor_search_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final String userName;
  const StudentHomeScreen({super.key, required this.userName});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;


  @override
  void initState() {
    super.initState();
    _checkNotifications();
  }

  Future<void> _checkNotifications() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    try {
      final notifications = await ApiService.getNotifications();
      final unread = notifications
          .where((n) => n['is_read'] == 0 || n['is_read'] == '0')
          .toList();
      if (unread.isNotEmpty && mounted) {
        _showNotificationPopup(unread);
        ApiService.markNotificationsRead();
      }
    } catch (_) {}
  }

  void _showNotificationPopup(List<dynamic> notifications) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.notifications_rounded,
                color: Color(0xFFEF4444), size: 20),
          ),
          const SizedBox(width: 10),
          const Text('New Notifications',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: notifications.map((n) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.25)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.cancel_outlined,
                          size: 14, color: Color(0xFFEF4444)),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(
                            n['title']?.toString() ?? 'Notification',
                            style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEF4444)),
                          )),
                    ]),
                    const SizedBox(height: 6),
                    Text(n['message']?.toString() ?? '',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                            height: 1.4)),
                  ]),
            )).toList(),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('OK, Got it'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    final pages = [
      _buildHome(),
      const MyRequestsScreen(),
      const MyAppointmentsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF1A73E8).withOpacity(0.12),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF1A73E8)), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt_rounded, color: Color(0xFF1A73E8)), label: 'Requests'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded, color: Color(0xFF8B5CF6)), label: 'Appointments'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF1A73E8)), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildHome() {
    return Stack(
      children: [
        // Blue header background
        Container(
          height: 260,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Decorative circles
        Positioned(top: -40, right: -40,
            child: Container(width: 180, height: 180,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
        Positioned(top: 60, right: 30,
            child: Container(width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)))),

        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                FadeInDown(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Hello, ${widget.userName.split(' ').first} 👋",
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text("How can we help you today?",
                                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75))),
                          ],
                        ),
                        Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.school_rounded, color: Colors.white, size: 26),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Main action card
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Quick Actions",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(child: _actionBtn(Icons.search_rounded, "Find Counselor", const Color(0xFF1A73E8), () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const CounselorSearchScreen()));
                              })),
                              const SizedBox(width: 12),
                              Expanded(child: _actionBtn(Icons.list_alt_rounded, "My Requests", const Color(0xFF22C55E), () {
                                setState(() => _selectedIndex = 1);
                              })),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _actionBtn(Icons.calendar_today_rounded, "My Appointments", const Color(0xFF8B5CF6), () {
                                setState(() => _selectedIndex = 2);
                              })),
                              const SizedBox(width: 12),
                              Expanded(child: _actionBtn(Icons.person_outline_rounded, "My Profile", const Color(0xFFF59E0B), () {
                                setState(() => _selectedIndex = 3);
                              })),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Info section
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 12),
                          child: Text("About SCMS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                        ),
                        _infoCard(Icons.psychology_rounded, "Professional Support", "Connect with trained counselors for academic, personal, and career guidance.", const Color(0xFF1A73E8)),
                        const SizedBox(height: 12),
                        _infoCard(Icons.lock_outline_rounded, "Confidential & Safe", "All sessions are private and handled with full confidentiality.", const Color(0xFF22C55E)),
                        const SizedBox(height: 12),
                        _infoCard(Icons.schedule_rounded, "Flexible Scheduling", "Book sessions at times that work for you.", const Color(0xFFF59E0B)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827))),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
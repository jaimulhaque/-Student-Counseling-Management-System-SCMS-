import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pending_requests_screen.dart';
import '../common/profile_screen.dart';
import 'weekly_schedule_screen.dart';
import 'statistics_screen.dart';
import 'schedule_manager_screen.dart';

class CounselorHomeScreen extends StatefulWidget {
  final String userName;
  const CounselorHomeScreen({super.key, required this.userName});

  @override
  State<CounselorHomeScreen> createState() => _CounselorHomeScreenState();
}

class _CounselorHomeScreenState extends State<CounselorHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    final pages = [_buildDashboard(), const PendingRequestsScreen(), const ProfileScreen()];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)]),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF1A73E8).withOpacity(0.12),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF1A73E8)), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.pending_actions_outlined), selectedIcon: Icon(Icons.pending_actions, color: Color(0xFF1A73E8)), label: 'Pending'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF1A73E8)), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Stack(
      children: [
        Container(height: 260,
            decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight))),
        Positioned(top: -40, right: -40,
            child: Container(width: 180, height: 180,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
        Positioned(top: 70, right: 30,
            child: Container(width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)))),

        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                // Header
                FadeInDown(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text("Hello, ${widget.userName.split(' ').first} 👋",
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text("New counseling requests waiting", style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75))),
                        ]),
                        Container(width: 46, height: 46,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 26)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Cards
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
                          const Text("Quick Actions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                          const SizedBox(height: 18),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.3,
                            children: [
                              _actionCard(Icons.calendar_month_rounded, "My Schedule", const Color(0xFF1A73E8), () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleManagerScreen()));
                              }),
                              _actionCard(Icons.pending_actions_rounded, "Pending Requests", const Color(0xFF8B5CF6), () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingRequestsScreen()));
                              }),
                              _actionCard(Icons.analytics_rounded, "Statistics", const Color(0xFF0D47A1), () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen()));
                              }),
                              _actionCard(Icons.view_week_rounded, "Weekly Schedule", const Color(0xFF22C55E), () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const WeeklyScheduleScreen()));
                              }),
                            ],
                          ),
                        ],
                      ),
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

  Widget _actionCard(IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}
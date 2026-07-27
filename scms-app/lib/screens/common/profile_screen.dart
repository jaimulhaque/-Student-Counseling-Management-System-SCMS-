import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../auth/login_screen.dart';
import '../student/edit_profile_screen.dart';
import '../common/change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _name;
  String? _role;
  String? _email;
  String? _phone;
  String? _department;
  String? _studentId;
  String? _intake;
  String? _section;
  String? _designation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('name') ?? 'User';
      _role = prefs.getString('role') ?? 'unknown';
      _email = prefs.getString('email') ?? '';
      _phone = prefs.getString('phone') ?? '';
      _department = prefs.getString('department') ?? '';
      _studentId = prefs.getString('student_id') ?? '';
      _intake = prefs.getString('intake') ?? '';
      _section = prefs.getString('section') ?? '';
      _designation = prefs.getString('designation') ?? '';
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Fluttertoast.showToast(msg: "Logged out successfully");
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  void _showPersonalInfo() {
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
            Center(
              child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 20),
            const Text("Personal Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
            const SizedBox(height: 20),
            _infoTile(Icons.person_outline_rounded, "Full Name", _name ?? 'N/A', const Color(0xFF1A73E8)),
            _infoTile(Icons.mail_outline_rounded, "Email", _email ?? 'N/A', const Color(0xFF8B5CF6)),
            if (_phone != null && _phone!.isNotEmpty)
              _infoTile(Icons.phone_outlined, "Phone", _phone!, const Color(0xFF22C55E)),
            if (_role == 'student') ...[
              _infoTile(Icons.badge_outlined, "Student ID", _studentId?.isNotEmpty == true ? _studentId! : 'Not set', const Color(0xFFF59E0B)),
              _infoTile(Icons.business_outlined, "Department", _department?.isNotEmpty == true ? _department! : 'Not set', const Color(0xFFEF4444)),
              _infoTile(Icons.numbers_rounded, "Intake", _intake?.isNotEmpty == true ? _intake! : 'Not set', const Color(0xFF06B6D4)),
              _infoTile(Icons.group_outlined, "Section", _section?.isNotEmpty == true ? _section! : 'Not set', const Color(0xFF8B5CF6)),
            ],
            if (_role == 'counselor') ...[
              _infoTile(Icons.business_outlined, "Department", _department?.isNotEmpty == true ? _department! : 'Not set', const Color(0xFFEF4444)),
              _infoTile(Icons.work_outline_rounded, "Designation", _designation?.isNotEmpty == true ? _designation! : 'Not set', const Color(0xFFF59E0B)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          ]),
        ],
      ),
    );
  }

  IconData get _roleIcon => _role == 'student'
      ? Icons.school_rounded
      : _role == 'counselor'
          ? Icons.psychology_rounded
          : Icons.admin_panel_settings_rounded;

  String get _roleLabel => (_role ?? 'unknown').toUpperCase();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF1A73E8))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          Container(
              height: 240,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight))),
          Positioned(
              top: -40, right: -40,
              child: Container(width: 180, height: 180,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06)))),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Profile",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                        Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.settings_outlined, color: Colors.white, size: 20)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 2.5),
                        ),
                        child: Icon(_roleIcon, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 12),
                      Text(_name ?? "User",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(_roleLabel,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16)
                          ]),
                      child: Column(
                        children: [
                          _menuTile(Icons.person_outline_rounded, "Personal Information",
                              const Color(0xFF1A73E8), _showPersonalInfo),
                          _divider(),
                          _menuTile(Icons.lock_outline_rounded, "Change Password",
                              const Color(0xFF8B5CF6), () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                          }),
                          _divider(),
                          if (_role == 'student' || _role == 'counselor') ...[
                            _menuTile(Icons.edit_note_rounded, "Edit Account Information",
                                const Color(0xFF22C55E), () async {
                              await Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                              // Reload data after returning from edit screen
                              _loadUserData();
                            }),
                            _divider(),
                          ],
                          _menuTile(Icons.info_outline_rounded, "About SCMS",
                              const Color(0xFFF59E0B), () {
                            showAboutDialog(
                              context: context,
                              applicationName: "SCMS",
                              applicationVersion: "1.0.0",
                              children: [
                                const Text(
                                  "Mobile Application-Based Student Counseling Management System\n"
                                  "Developed for BUBT by Code & Cry Team\n\n"
                                  "Team Members:\n"
                                  "• Hassan Ferdous Amil (20234103246)\n"
                                  "• SM Akhlakur Meraj (20234103245)\n"
                                  "• Md. Jainul Haque (20234103251)\n"
                                  "• Ezabul Alam (20234103256)\n\n"
                                  "Supervised by: Maruf Billah, Lecturer\n"
                                  "CSE 300 SDP-3 Project - April 2026",
                                )
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity, height: 54,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                        label: const Text("Log Out",
                            style: TextStyle(color: Color(0xFFEF4444), fontSize: 15, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: const Color(0xFFEF4444).withOpacity(0.05),
                        ),
                        onPressed: _logout,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, indent: 72, endIndent: 20, color: Color(0xFFF3F4F6));
}

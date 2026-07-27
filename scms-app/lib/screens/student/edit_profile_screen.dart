import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String? _role;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _intakeController = TextEditingController();
  final _sectionController = TextEditingController();
  final _designationController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() { super.initState(); _loadUserData(); }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role') ?? 'student';
      _nameController.text = prefs.getString('name') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _phoneController.text = prefs.getString('phone') ?? '';
      _studentIdController.text = prefs.getString('student_id') ?? '';
      _departmentController.text = prefs.getString('department') ?? '';
      _intakeController.text = prefs.getString('intake') ?? '';
      _sectionController.text = prefs.getString('section') ?? '';
      _designationController.text = prefs.getString('designation') ?? '';
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        department: _departmentController.text.trim(),
        intake: _intakeController.text.trim(),
        section: _sectionController.text.trim(),
        studentId: _studentIdController.text.trim(),
        designation: _role == 'counselor' ? _designationController.text.trim() : null,
      );
      if (result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('name', _nameController.text.trim());
        await prefs.setString('email', _emailController.text.trim());
        await prefs.setString('phone', _phoneController.text.trim());
        await prefs.setString('department', _departmentController.text.trim());
        await prefs.setString('intake', _intakeController.text.trim());
        await prefs.setString('section', _sectionController.text.trim());
        await prefs.setString('student_id', _studentIdController.text.trim());
        if (_role == 'counselor') await prefs.setString('designation', _designationController.text.trim());
        // If API returns updated user, sync all fields
        if (result['user'] != null) {
          final u = result['user'] as Map<String, dynamic>;
          if (u['name'] != null) await prefs.setString('name', u['name'].toString());
          if (u['email'] != null) await prefs.setString('email', u['email'].toString());
          if (u['phone'] != null) await prefs.setString('phone', u['phone'].toString());
          if (u['department'] != null) await prefs.setString('department', u['department'].toString());
          if (u['intake'] != null) await prefs.setString('intake', u['intake'].toString());
          if (u['section'] != null) await prefs.setString('section', u['section'].toString());
          if (u['student_id'] != null) await prefs.setString('student_id', u['student_id'].toString());
          if (u['designation'] != null) await prefs.setString('designation', u['designation'].toString());
        }
        Fluttertoast.showToast(msg: "Profile updated successfully!", backgroundColor: Colors.green, textColor: Colors.white, toastLength: Toast.LENGTH_LONG);
        if (mounted) Navigator.pop(context);
      } else {
        Fluttertoast.showToast(msg: result['message'] ?? "Update failed", backgroundColor: Colors.red, textColor: Colors.white);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e", backgroundColor: Colors.red, textColor: Colors.white);
    } finally { if (mounted) setState(() => _isLoading = false); }
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
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                  child: Row(
                    children: [
                      IconButton(onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
                      const Text("Edit Account Information",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16)],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(width: 40, height: 40,
                                decoration: BoxDecoration(color: const Color(0xFF1A73E8).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.edit_note_rounded, color: Color(0xFF1A73E8), size: 22)),
                              const SizedBox(width: 12),
                              const Text("Account Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                            ]),
                            const SizedBox(height: 24),

                            // ── Common fields (both roles) ──
                            _buildLabel("Full Name"),
                            const SizedBox(height: 8),
                            _buildField(_nameController, "e.g. John Doe", Icons.person_outline_rounded),
                            const SizedBox(height: 16),
                            _buildLabel("Email Address"),
                            const SizedBox(height: 8),
                            _buildField(_emailController, "e.g. you@email.com", Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 16),

                            if (_role == 'student') ...[
                              _buildLabel("Student ID"),
                              const SizedBox(height: 8),
                              _buildField(_studentIdController, "e.g. 20234103246", Icons.badge_outlined, keyboardType: TextInputType.number),
                              const SizedBox(height: 16),
                              _buildLabel("Department"),
                              const SizedBox(height: 8),
                              _buildField(_departmentController, "e.g. Computer Science", Icons.business_outlined),
                              const SizedBox(height: 16),
                              _buildLabel("Intake"),
                              const SizedBox(height: 8),
                              _buildField(_intakeController, "e.g. 49", Icons.numbers_rounded),
                              const SizedBox(height: 16),
                              _buildLabel("Section"),
                              const SizedBox(height: 8),
                              _buildField(_sectionController, "e.g. A", Icons.group_outlined),
                              const SizedBox(height: 16),
                              _buildLabel("Phone Number"),
                              const SizedBox(height: 8),
                              _buildField(_phoneController, "e.g. +8801XXXXXXXXX", Icons.phone_outlined, keyboardType: TextInputType.phone),
                            ],

                            if (_role == 'counselor') ...[
                              _buildLabel("Department"),
                              const SizedBox(height: 8),
                              _buildField(_departmentController, "e.g. Student Affairs", Icons.business_outlined),
                              const SizedBox(height: 16),
                              _buildLabel("Designation"),
                              const SizedBox(height: 8),
                              _buildField(_designationController, "e.g. Senior Counselor", Icons.work_outline_rounded),
                              const SizedBox(height: 16),
                              _buildLabel("Phone Number"),
                              const SizedBox(height: 8),
                              _buildField(_phoneController, "e.g. +8801XXXXXXXXX", Icons.phone_outlined, keyboardType: TextInputType.phone),
                            ],

                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity, height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A73E8),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _isLoading
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildLabel(String text) => Text(text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)));

  Widget _buildField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
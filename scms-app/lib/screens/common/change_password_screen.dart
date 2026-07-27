import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _changePassword() async {
    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      Fluttertoast.showToast(msg: "All fields are required"); return;
    }
    if (newPass != confirmPass) {
      Fluttertoast.showToast(msg: "New passwords do not match"); return;
    }
    if (newPass.length < 6) {
      Fluttertoast.showToast(msg: "New password must be at least 6 characters"); return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) { Fluttertoast.showToast(msg: "Session expired. Please login again"); return; }

      final result = await ApiService.changePassword(int.parse(userId), oldPass, newPass);
      if (result['success'] == true) {
        Fluttertoast.showToast(msg: "Password changed successfully!", backgroundColor: Colors.green, textColor: Colors.white);
        if (mounted) Navigator.pop(context);
      } else {
        Fluttertoast.showToast(msg: result['message'] ?? "Failed to change password", backgroundColor: Colors.red, textColor: Colors.white);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
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
                      const Text("Change Password",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
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
                                child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF1A73E8), size: 22)),
                              const SizedBox(width: 12),
                              const Text("Update Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                            ]),
                            const SizedBox(height: 8),
                            Text("Choose a strong password with at least 6 characters", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                            const SizedBox(height: 24),

                            _buildLabel("Current Password"),
                            const SizedBox(height: 8),
                            _buildField(_oldPasswordController, "Enter current password", _obscureOld,
                              () => setState(() => _obscureOld = !_obscureOld)),
                            const SizedBox(height: 16),

                            _buildLabel("New Password"),
                            const SizedBox(height: 8),
                            _buildField(_newPasswordController, "Enter new password", _obscureNew,
                              () => setState(() => _obscureNew = !_obscureNew)),
                            const SizedBox(height: 16),

                            _buildLabel("Confirm New Password"),
                            const SizedBox(height: 8),
                            _buildField(_confirmPasswordController, "Re-enter new password", _obscureConfirm,
                              () => setState(() => _obscureConfirm = !_obscureConfirm)),
                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity, height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _changePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A73E8),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _isLoading
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : const Text("Change Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

  Widget _buildField(TextEditingController controller, String hint, bool obscure, VoidCallback toggle) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF9CA3AF), size: 20),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFFB0B7C3), size: 20),
            onPressed: toggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _idController       = TextEditingController();

  String  _selectedRole = 'student';
  String? _selectedDept;
  bool    _isLoading       = false;
  bool    _obscurePassword = true;

  static const List<String> _departments = [
    'CSE', 'BBA', 'EEE', 'LLB', 'LLM',
    'Textile', 'English', 'Economics', 'Civil',
  ];

  String get _idLabel => _selectedRole == 'counselor' ? 'Counselor ID' : 'Student ID';
  String get _idHint  => _selectedRole == 'counselor' ? 'e.g. CNSL001' : 'e.g. 20234103246';

  Future<void> _handleRegister() async {
    final name     = _nameController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final id       = _idController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(msg: "All fields are required"); return;
    }
    if (id.isEmpty) {
      Fluttertoast.showToast(msg: "$_idLabel is required"); return;
    }
    if (_selectedDept == null) {
      Fluttertoast.showToast(msg: "Please select your department"); return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      Fluttertoast.showToast(msg: "Please enter a valid email"); return;
    }
    if (password.length < 6) {
      Fluttertoast.showToast(msg: "Password must be at least 6 characters"); return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.register(
        name, email, password, id, _selectedRole,
        department: _selectedDept!,
      );
      if (result['success'] == true) {
        Fluttertoast.showToast(
          msg: "Registration successful! Please login.",
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        if (mounted) Navigator.pop(context);
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? "Registration failed",
          backgroundColor: Colors.red, textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Connection error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      body: Stack(children: [
        Container(decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)]))),
        Positioned(top: -60, right: -60, child: Container(width: 200, height: 200,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
        Positioned(top: 60, right: 40, child: Container(width: 90, height: 90,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)))),

        SafeArea(child: Column(children: [
          // Header
          FadeInDown(duration: const Duration(milliseconds: 700),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(width: 42, height: 42,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18)),
                ),
                const SizedBox(height: 16),
                const Padding(padding: EdgeInsets.only(left: 8),
                  child: Text("Sign up", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800,
                      color: Colors.white, letterSpacing: -0.6))),
                const SizedBox(height: 4),
                Padding(padding: const EdgeInsets.only(left: 8),
                  child: Row(children: [
                    Text("Already have an account? ",
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                    GestureDetector(onTap: () => Navigator.pop(context),
                      child: const Text("Login",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                  ])),
                const SizedBox(height: 20),
              ]),
            )),

          // White card
          Expanded(child: FadeInUp(duration: const Duration(milliseconds: 700),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(36), topRight: Radius.circular(36)),
                boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 30, offset: Offset(0, -6))],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Full Name
                  _buildLabel("Full Name"),
                  const SizedBox(height: 8),
                  _buildTextField(controller: _nameController,
                      hint: "e.g. Hassan Ferdous", icon: Icons.person_outline_rounded),
                  const SizedBox(height: 18),

                  // Email
                  _buildLabel("Email"),
                  const SizedBox(height: 8),
                  _buildTextField(controller: _emailController,
                      hint: "yourname@email.com", icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 18),

                  // Role selector
                  _buildLabel("Select Role"),
                  const SizedBox(height: 10),
                  _buildRoleSelector(),
                  const SizedBox(height: 18),

                  // Department dropdown
                  _buildLabel("Department"),
                  const SizedBox(height: 8),
                  _buildDeptDropdown(),
                  const SizedBox(height: 18),

                  // ID field
                  _buildLabel(_idLabel),
                  const SizedBox(height: 8),
                  _buildTextField(controller: _idController, hint: _idHint, icon: Icons.badge_outlined),
                  const SizedBox(height: 18),

                  // Password
                  _buildLabel("Set Password"),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _passwordController,
                    hint: "Min. 6 characters",
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscurePassword,
                    suffix: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFFB0B7C3), size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Register button
                  SizedBox(width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF1A73E8).withOpacity(0.65),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text("Register",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text("Already have an account? ",
                        style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                    GestureDetector(onTap: () => Navigator.pop(context),
                      child: const Text("Login", style: TextStyle(
                          color: Color(0xFF1A73E8), fontWeight: FontWeight.w700, fontSize: 14))),
                  ])),
                ]),
              ),
            ),
          )),
        ])),
      ]),
    );
  }

  Widget _buildDeptDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButtonFormField<String>(
        value: _selectedDept,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          prefixIcon: Icon(Icons.business_outlined, color: Color(0xFF9CA3AF), size: 20),
        ),
        hint: Text("Select your department",
            style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        items: _departments.map((d) => DropdownMenuItem(
          value: d,
          child: Text(d, style: const TextStyle(fontSize: 14, color: Color(0xFF111827))),
        )).toList(),
        onChanged: (v) => setState(() => _selectedDept = v),
        dropdownColor: Colors.white,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF)),
      ),
    );
  }

  Widget _buildRoleSelector() {
    final roles = [
      {'value': 'student',   'label': 'Student',   'icon': Icons.school_rounded},
      {'value': 'counselor', 'label': 'Counselor', 'icon': Icons.psychology_rounded},
    ];
    return Row(children: roles.map((r) {
      final value    = r['value']  as String;
      final label    = r['label']  as String;
      final icon     = r['icon']   as IconData;
      final selected = _selectedRole == value;
      return Expanded(child: GestureDetector(
        onTap: () => setState(() {
          _selectedRole = value;
          _idController.clear();
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(right: value != 'counselor' ? 8 : 0),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1A73E8) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFF1A73E8) : const Color(0xFFE5E7EB),
              width: selected ? 1.8 : 1),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 22, color: selected ? Colors.white : Colors.grey[400]),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[500])),
          ]),
        ),
      ));
    }).toList());
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: Color(0xFF374151), letterSpacing: 0.2));

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        ),
      ),
    );
  }
}
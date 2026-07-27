import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../api_service.dart';

class RequestFormScreen extends StatefulWidget {
  const RequestFormScreen({super.key});

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  String? _selectedCategory;
  final _descriptionController = TextEditingController();
  String _priority = 'normal';
  bool _isLoading = false;
  List<dynamic> _categories = [];

  @override
  void initState() { super.initState(); _loadCategories(); }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.getCategories();
      setState(() {
        _categories = cats;
        if (_categories.isNotEmpty) _selectedCategory = _categories[0]['id'].toString();
      });
    } catch (e) { Fluttertoast.showToast(msg: "Failed to load categories: $e"); }
  }

  Future<void> _submitRequest() async {
    if (_selectedCategory == null || _descriptionController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Please select category and write description");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.submitRequest(_selectedCategory!, _descriptionController.text.trim(), _priority);
      if (result['success'] == true) {
        Fluttertoast.showToast(msg: "Request submitted successfully!", backgroundColor: Colors.green, textColor: Colors.white);
        if (mounted) Navigator.pop(context);
      } else {
        Fluttertoast.showToast(msg: result['message'] ?? "Submission failed", backgroundColor: Colors.red, textColor: Colors.white);
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
          Container(height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                begin: Alignment.topLeft, end: Alignment.bottomRight))),
          Positioned(top: -40, right: -40,
            child: Container(width: 160, height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                  child: Row(
                    children: [
                      IconButton(onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
                      const Text("New Counseling Request",
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
                      child: FadeInUp(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16)],
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("What kind of support do you need?",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                                  const SizedBox(height: 18),

                                  _buildLabel("Counseling Category"),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedCategory,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        prefixIcon: Icon(Icons.category_outlined, color: Color(0xFF9CA3AF), size: 20),
                                      ),
                                      items: _categories.map((cat) => DropdownMenuItem<String>(
                                        value: cat['id'].toString(),
                                        child: Text(cat['name'] ?? 'Unknown', style: const TextStyle(fontSize: 14)),
                                      )).toList(),
                                      onChanged: _isLoading ? null : (v) => setState(() => _selectedCategory = v),
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  _buildLabel("Describe Your Concern"),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: TextField(
                                      controller: _descriptionController,
                                      maxLines: 5,
                                      enabled: !_isLoading,
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                                      decoration: InputDecoration(
                                        hintText: "Please explain in detail so we can help you better...",
                                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.all(16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  _buildLabel("Priority Level"),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(child: _priorityOption("normal", "Normal", Icons.flag_outlined, const Color(0xFF22C55E))),
                                      const SizedBox(width: 12),
                                      Expanded(child: _priorityOption("emergency", "Emergency", Icons.warning_amber_rounded, const Color(0xFFEF4444))),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 28),

                            SizedBox(
                              width: double.infinity, height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitRequest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A73E8),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(0xFF1A73E8).withOpacity(0.6),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: _isLoading
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : const Text("Submit Request", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

  Widget _priorityOption(String value, String label, IconData icon, Color color) {
    final selected = _priority == value;
    return GestureDetector(
      onTap: _isLoading ? null : () => setState(() => _priority = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : const Color(0xFFE5E7EB), width: selected ? 1.8 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? color : Colors.grey[400]),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
              color: selected ? color : Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
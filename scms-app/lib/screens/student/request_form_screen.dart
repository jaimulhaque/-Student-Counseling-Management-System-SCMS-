import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../api_service.dart';
import '../../../constants.dart';
import '../../widgets/status_badge.dart'; // imported for consistency (not used here)

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
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.getCategories();
      setState(() {
        _categories = cats;
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories[0]['id'].toString();
        }
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to load categories: $e");
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedCategory == null || _descriptionController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Please select category and write description");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.submitRequest(
        _selectedCategory!,
        _descriptionController.text.trim(),
        _priority,
      );

      if (result['success'] == true) {
        Fluttertoast.showToast(
          msg: "Request submitted successfully!",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        if (mounted) Navigator.pop(context);
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? "Submission failed",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error submitting request: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Counseling Request"),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF8FAFC),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeInUp(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "What kind of support do you need?",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: "Counseling Category",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: _categories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat['id'].toString(),
                              child: Text(cat['name'] ?? 'Unknown'),
                            );
                          }).toList(),
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() => _selectedCategory = value);
                                },
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 5,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: "Describe your concern",
                            hintText: "Please explain in detail so we can help you better...",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          "Priority",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text("Normal"),
                                value: "normal",
                                groupValue: _priority,
                                onChanged: _isLoading ? null : (val) => setState(() => _priority = val!),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text("Emergency"),
                                value: "emergency",
                                groupValue: _priority,
                                onChanged: _isLoading ? null : (val) => setState(() => _priority = val!),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text("SUBMIT REQUEST", style: TextStyle(fontSize: 17)),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
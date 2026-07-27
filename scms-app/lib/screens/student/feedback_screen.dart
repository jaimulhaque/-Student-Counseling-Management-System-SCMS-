import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../api_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitFeedback() async {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      Fluttertoast.showToast(msg: "Please write your feedback");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // You can create new backend endpoint feedback.php later
      // For now, simulate success
      await Future.delayed(const Duration(seconds: 1));
      Fluttertoast.showToast(msg: "Feedback submitted! Thank you.");
      if (mounted) Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Submit Feedback")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _feedbackController,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: "Your Feedback",
                hintText: "Tell us how we can improve the system...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitFeedback,
                      child: const Text("SUBMIT FEEDBACK"),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
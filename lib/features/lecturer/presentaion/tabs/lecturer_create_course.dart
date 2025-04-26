import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/provider/user_provider.dart';

class LecturerCreateCourseTab extends StatefulWidget {
  const LecturerCreateCourseTab({super.key});

  @override
  State<LecturerCreateCourseTab> createState() => _LecturerCreateCourseTabState();
}

class _LecturerCreateCourseTabState extends State<LecturerCreateCourseTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _codeController = TextEditingController();
  final _descController = TextEditingController();
  String _semester = 'First';

  bool _isLoading = false;

  Future<void> _submitCourse() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;

      await FirebaseFirestore.instance.collection('courses').add({
        'title': _titleController.text.trim(),
        'code': _codeController.text.trim(),
        'description': _descController.text.trim(),
        'semester': _semester,
        'createdBy': user?.name ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Course created successfully!")),
      );

      _formKey.currentState!.reset();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Course")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Course Title"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: "Course Code"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _semester,
                items: ['First', 'Second']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _semester = val!),
                decoration: const InputDecoration(labelText: "Semester"),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _submitCourse,
                child: const Text("Create Course"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

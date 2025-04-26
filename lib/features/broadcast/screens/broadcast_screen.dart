import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/user_model.dart';
import 'package:provider/provider.dart';
import '../../auth/provider/user_provider.dart';

class BroadcastFormScreen extends StatefulWidget {
  const BroadcastFormScreen({super.key});

  @override
  State<BroadcastFormScreen> createState() => _BroadcastFormScreenState();
}

class _BroadcastFormScreenState extends State<BroadcastFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  void _submitBroadcast() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.user;

      if (currentUser == null) throw Exception('User not loaded');

      await FirebaseFirestore.instance.collection('broadcasts').add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'sender': currentUser.name,
        'role': currentUser.role,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broadcast sent successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Send Broadcast")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (value) =>
                value!.isEmpty ? "Please enter a title" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(labelText: "Message"),
                maxLines: 4,
                validator: (value) =>
                value!.isEmpty ? "Please enter a message" : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _submitBroadcast,
                child: const Text("Send Broadcast"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

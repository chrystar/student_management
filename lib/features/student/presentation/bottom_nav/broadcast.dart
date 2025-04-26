// features/student/screens/student_broadcast_tab.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentBroadcastTab extends StatelessWidget {
  const StudentBroadcastTab({super.key});

  @override
    Widget build(BuildContext context) {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('broadcasts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No broadcasts yet'));
          }

          final broadcasts = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: broadcasts.length,
            itemBuilder: (context, index) {
              final doc = broadcasts[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(data['title'] ?? 'No Title'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['message'] ?? 'No Message'),
                      const SizedBox(height: 4),
                      Text('By: ${data['sender'] ?? 'Unknown'}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }



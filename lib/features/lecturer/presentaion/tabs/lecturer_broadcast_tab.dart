import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../auth/provider/user_provider.dart';
import 'package:provider/provider.dart';

import '../../../broadcast/screens/broadcast_screen.dart';

class LecturerBroadcastTab extends StatelessWidget {
  const LecturerBroadcastTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Broadcasts")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('broadcasts')
            .where('sender', isEqualTo: user.name)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No broadcasts yet"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.campaign),
                title: Text(data['title'] ?? 'No Title'),
                subtitle: Text(data['message'] ?? 'No Message'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('broadcasts')
                        .doc(docs[index].id)
                        .delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Broadcast deleted')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BroadcastFormScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

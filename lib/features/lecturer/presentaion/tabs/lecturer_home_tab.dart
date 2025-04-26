import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LecturerHomeTab extends StatefulWidget {
  const LecturerHomeTab({super.key});

  @override
  State<LecturerHomeTab> createState() => _LecturerHomeTabState();
}

class _LecturerHomeTabState extends State<LecturerHomeTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome, Lecturer!",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            "Here's an overview of available courses:",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('courses').orderBy('title').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error fetching courses: ${snapshot.error}"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No courses available yet."));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final courseData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              courseData['title'] ?? 'No Title',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text("Code: ${courseData['code'] ?? 'No Code'}"),
                            Text("Semester: ${courseData['semester'] ?? 'Unknown'}"),
                            if (courseData['description'] != null && courseData['description'].isNotEmpty)
                              Text("Description: ${courseData['description']}"),
                            Text(
                              "Created by: ${courseData['createdBy'] ?? 'N/A'}",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              "Created at: ${courseData['timestamp'] != null ? (courseData['timestamp'] as Timestamp).toDate().toString() : 'N/A'}",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to the create course screen/tab
              // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => LecturerCreateCourseTab()));
              print("Navigate to Create Course");
            },
            icon: const Icon(Icons.add),
            label: const Text("Create New Course"),
          ),
        ],
      ),
    );
  }
}
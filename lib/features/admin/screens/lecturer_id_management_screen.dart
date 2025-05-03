import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LecturerIdManagementScreen extends StatefulWidget {
  const LecturerIdManagementScreen({super.key});

  @override
  State<LecturerIdManagementScreen> createState() =>
      _LecturerIdManagementScreenState();
}

class _LecturerIdManagementScreenState extends State<LecturerIdManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecturer ID Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Generated IDs'),
            Tab(text: 'Generate New ID'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIdListTab(),
          _buildGenerateIdTab(),
        ],
      ),
    );
  }

  Widget _buildIdListTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lecturer_ids')
          .orderBy('generatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final ids = snapshot.data?.docs ?? [];

        if (ids.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.vpn_key_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No lecturer IDs have been generated yet'),
                SizedBox(height: 24),
                Text(
                  'Switch to the "Generate New ID" tab to create one',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Summary cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildSummaryCard(
                    context,
                    'Total',
                    ids.length.toString(),
                    Icons.vpn_key,
                    Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    context,
                    'Active',
                    ids
                        .where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final isUsed = data['isUsed'] ?? false;
                          final validUntil = data['validUntil'] as Timestamp?;
                          final isExpired = validUntil != null &&
                              validUntil.toDate().isBefore(DateTime.now());
                          return !isUsed && !isExpired;
                        })
                        .length
                        .toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    context,
                    'Expired',
                    ids
                        .where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final validUntil = data['validUntil'] as Timestamp?;
                          return validUntil != null &&
                              validUntil.toDate().isBefore(DateTime.now());
                        })
                        .length
                        .toString(),
                    Icons.timer_off,
                    Colors.red,
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by name, ID or department',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // Implement search functionality
                },
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Lecturer IDs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: ids.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final idData = ids[index].data() as Map<String, dynamic>;
                  final isUsed = idData['isUsed'] ?? false;
                  final validUntil = idData['validUntil'] as Timestamp?;
                  final isExpired = validUntil != null &&
                      validUntil.toDate().isBefore(DateTime.now());
                  final generatedAt = idData['generatedAt'] as Timestamp?;

                  String dateText = '';
                  if (generatedAt != null) {
                    final date = generatedAt.toDate();
                    dateText = '${date.day}/${date.month}/${date.year}';
                  }

                  String expiryText = '';
                  if (validUntil != null) {
                    final date = validUntil.toDate();
                    expiryText = '${date.day}/${date.month}/${date.year}';
                  }

                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isUsed
                            ? Colors.green.withOpacity(0.3)
                            : isExpired
                                ? Colors.red.withOpacity(0.3)
                                : Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: isUsed
                            ? Colors.green.withOpacity(0.1)
                            : isExpired
                                ? Colors.red.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                        child: Icon(
                          isUsed
                              ? Icons.check
                              : isExpired
                                  ? Icons.timer_off
                                  : Icons.vpn_key,
                          color: isUsed
                              ? Colors.green
                              : isExpired
                                  ? Colors.red
                                  : Colors.blue,
                        ),
                      ),
                      title: Text(
                        idData['name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${idData['department']} • Created: $dateText',
                        style: TextStyle(
                          color: isExpired ? Colors.grey : null,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isUsed
                              ? Colors.green.withOpacity(0.1)
                              : isExpired
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isUsed
                              ? 'Used'
                              : isExpired
                                  ? 'Expired'
                                  : 'Active',
                          style: TextStyle(
                            color: isUsed
                                ? Colors.green
                                : isExpired
                                    ? Colors.red
                                    : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lecturer ID:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        idData['id'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    tooltip: 'Copy to clipboard',
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(
                                          text: idData['id'] ?? ''));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('ID copied to clipboard')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Email:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                            idData['email'] ?? 'Not specified'),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Expires on:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          expiryText,
                                          style: TextStyle(
                                            color:
                                                isExpired ? Colors.red : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (isUsed && idData['userId'] != null) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Used by user:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(idData['userId'] ?? 'Unknown user'),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!isUsed && !isExpired)
                                    OutlinedButton(
                                      onPressed: () {
                                        // Resend ID functionality
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Email sharing will be implemented soon'),
                                          ),
                                        );
                                      },
                                      child: const Text('SHARE ID'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateIdTab() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final departmentController = TextEditingController();

    // List of common departments for dropdown
    final departments = [
      'Computer Science',
      'Electrical Engineering',
      'Mechanical Engineering',
      'Civil Engineering',
      'Mathematics',
      'Physics',
      'Chemistry',
      'Biology',
      'Economics',
      'Business Administration',
      'Medicine',
      'Law',
      'Education',
      'Arts',
      'Other'
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generate Lecturer ID',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a unique ID that will be required for lecturer registration. This ID will be linked to the lecturer\'s details for verification.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // Lecturer name field
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Lecturer Full Name',
                hintText: 'Enter the lecturer\'s full name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            // Email field
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter the lecturer\'s email address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Department dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              hint: const Text('Select department'),
              items: departments.map((String department) {
                return DropdownMenuItem<String>(
                  value: department,
                  child: Text(department),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  departmentController.text = value;
                }
              },
            ),

            const SizedBox(height: 32),

            // Button to generate ID
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (nameController.text.isEmpty ||
                      emailController.text.isEmpty ||
                      departmentController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields')),
                    );
                    return;
                  }

                  _generateLecturerId(
                    context,
                    nameController.text,
                    departmentController.text,
                    emailController.text,
                  );

                  // Clear the fields after generating
                  nameController.clear();
                  emailController.clear();
                  departmentController.clear();

                  // Switch to the first tab to see the new ID
                  _tabController.animateTo(0);
                },
                child: const Text('GENERATE LECTURER ID'),
              ),
            ),

            const SizedBox(height: 16),

            // Help text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Important Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Generated IDs are valid for 30 days\n'
                    '• Each ID can only be used once\n'
                    '• The ID must be provided to the lecturer for registration\n'
                    '• You can view all generated IDs in the "Generated IDs" tab',
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generate lecturer ID and save to Firestore
  void _generateLecturerId(
      BuildContext context, String name, String department, String email) {
    // Generate a unique lecturer ID (you can customize this format)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final deptCode =
        department.substring(0, min(3, department.length)).toUpperCase();
    final randomCode =
        (100 + Random().nextInt(900)).toString(); // 3-digit random number

    // Format: DEPT-RANDOM-TIMESTAMP (shortened for readability)
    final lecturerId = 'LEC-$deptCode-$randomCode-${(timestamp % 10000)}';

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating ID, please wait...')),
    );

    // Save to Firestore
    FirebaseFirestore.instance.collection('lecturer_ids').add({
      'id': lecturerId,
      'name': name,
      'department': department,
      'email': email,
      'isUsed': false,
      'generatedAt': FieldValue.serverTimestamp(),
      'validUntil': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 30)), // Valid for 30 days
      ),
    }).then((_) {
      // Clear any existing snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show success dialog with the generated ID
      _showGeneratedIdDialog(context, lecturerId, email);
    }).catchError((error) {
      // Clear any existing snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating ID: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  // Show dialog with the generated ID
  void _showGeneratedIdDialog(
      BuildContext context, String lecturerId, String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Lecturer ID Generated'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'The following ID has been generated and is valid for 30 days:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      lecturerId,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy to clipboard',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: lecturerId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ID copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please provide this ID to the lecturer. They will need to enter it during registration.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('CLOSE'),
          ),
          ElevatedButton(
            onPressed: () {
              // Here you could implement email sending functionality
              // For now, just show a success message
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('ID sharing feature will be implemented soon')),
              );
            },
            child: const Text('SHARE ID'),
          ),
        ],
      ),
    );
  }
}

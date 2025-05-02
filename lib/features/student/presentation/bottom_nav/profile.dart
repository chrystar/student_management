import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/provider/user_provider.dart';

class StudentProfileTab extends StatefulWidget {
  const StudentProfileTab({super.key});

  @override
  State<StudentProfileTab> createState() => _StudentProfileTabState();
}

class _StudentProfileTabState extends State<StudentProfileTab> {
  final auth = FirebaseAuth.instance;
  bool _isLoading = false;
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _departmentController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF3E64FF),
          ),
        ),
      );
    }

    // For bottom sheet display, we'll use a different layout
    // Calculate the available height (80% of screen height)
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.9;

    return Container(
      height: modalHeight,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Handle indicator
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 60,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(5),
            ),
          ),

          // Profile header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF3E64FF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
                // Profile avatar and name
                Center(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          child: Text(
                            _getInitials(user.name),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3E64FF),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.department.isNotEmpty && user.level != null
                            ? "${user.department} - ${user.level} Level"
                            : "Student",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      if (user.department.isEmpty || user.level == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextButton.icon(
                            onPressed: () => _showEditProfileDialog(user),
                            icon: const Icon(Icons.warning,
                                color: Colors.amber, size: 16),
                            label: const Text(
                              "Complete your profile",
                              style: TextStyle(color: Colors.amber),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.black.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                children: [
                  // Stats section
                  _buildStatsSection(user),

                  const SizedBox(height: 24),

                  // Info cards
                  _buildInfoCard("Personal Information", Icons.person, [
                    _buildInfoRow("Name", user.name),
                    _buildInfoRow("Email", user.email),
                    _buildInfoRow("Matric Number", user.matricNumber),
                    _buildInfoRow(
                        "Department",
                        user.department.isNotEmpty
                            ? user.department
                            : "Not set"),
                    _buildInfoRow(
                        "Level",
                        user.level != null && user.level!.isNotEmpty
                            ? "${user.level}"
                            : "Not set"),
                  ]),

                  const SizedBox(height: 16),

                  _buildSettingsSection(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(user) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('course_registrations')
            .where('studentId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          int courseCount = 0;
          if (snapshot.hasData) {
            courseCount = snapshot.data!.docs.length;
          }

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.menu_book,
                    value: courseCount.toString(),
                    label: "Courses",
                    color: Colors.green,
                  ),
                  _buildDivider(),
                  _buildStatItem(
                    icon: Icons.assignment_turned_in,
                    value: "85%",
                    label: "Attendance",
                    color: Colors.orange,
                  ),
                  _buildDivider(),
                  _buildStatItem(
                    icon: Icons.school,
                    value: "3.8",
                    label: "CGPA",
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.withOpacity(0.3),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF3E64FF),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E64FF),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Column(
        children: [
          _buildSettingTile(
            "Edit Profile",
            Icons.edit,
            () {
              final user =
                  Provider.of<UserProvider>(context, listen: false).user;
              if (user != null) {
                _showEditProfileDialog(user);
              }
            },
          ),
          _buildSettingTile(
            "Change Password",
            Icons.lock,
            () {
              // Navigate to change password page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Change password feature coming soon')),
              );
            },
          ),
          _buildSettingTile(
            "Help & Support",
            Icons.help,
            () {
              // Navigate to help page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & support coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF3E64FF),
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    String initials = '';

    if (nameParts.length > 1) {
      // Get first letter of first and last name
      initials = nameParts[0][0] + nameParts[nameParts.length - 1][0];
    } else if (nameParts.length == 1) {
      // If only one name, get first letter
      initials = nameParts[0][0];
    }

    return initials.toUpperCase();
  }

  void _logout() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.logout();
      Navigator.of(context).pop(); // Close the bottom sheet
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEditProfileDialog(user) {
    // Initialize controllers with current values
    _departmentController.text = user.department ?? '';
    _levelController.text = user.level ?? '';

    final List<String> departments = [
      'Computer Science',
      'Electrical Engineering',
      'Mechanical Engineering',
      'Civil Engineering',
      'Medicine',
      'Pharmacy',
      'Business Administration',
      'Economics',
      'Law',
    ];

    final List<String> levels = [
      '100',
      '200',
      '300',
      '400',
      '500',
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Edit Profile",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Department Dropdown
                DropdownButtonFormField<String>(
                  value: _departmentController.text.isNotEmpty
                      ? _departmentController.text
                      : null,
                  decoration: InputDecoration(
                    labelText: "Department",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.business),
                  ),
                  items: departments.map((String department) {
                    return DropdownMenuItem<String>(
                      value: department,
                      child: Text(department),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _departmentController.text = value;
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your department';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Level Dropdown
                DropdownButtonFormField<String>(
                  value: _levelController.text.isNotEmpty
                      ? _levelController.text
                      : null,
                  decoration: InputDecoration(
                    labelText: "Level",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.school),
                  ),
                  items: levels.map((String level) {
                    return DropdownMenuItem<String>(
                      value: level,
                      child: Text(level),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _levelController.text = value;
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your level';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _updateProfile();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3E64FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Save"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user == null) return;

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'department': _departmentController.text,
        'level': _levelController.text,
      });

      // Reload user data
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUserData();

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

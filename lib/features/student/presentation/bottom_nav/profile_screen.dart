import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/provider/user_provider.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen>
    with SingleTickerProviderStateMixin {
  final auth = FirebaseAuth.instance;
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.blue,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.blue),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOutQuad,
              )),
              child: FadeTransition(
                opacity: _animationController,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 30.0, top: 20),
                  child: Column(
                    children: [
                      // Profile avatar and name
                      Center(
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.blue.shade50,
                                child: Text(
                                  _getInitials(user.name),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
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
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Student - ${user.level} Level",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Stats section
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.5, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOutQuad,
              )),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStatsSection(user),
              ),
            ),

            const SizedBox(height: 24),

            // Profile information sections
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-0.5, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOutQuad,
              )),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildProfileSections(user),
              ),
            ),

            const SizedBox(height: 24),

            // Settings options
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOutQuad,
              )),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSettingsSection(),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
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
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
            shadowColor: Colors.black26,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.menu_book,
                    value: courseCount.toString(),
                    label: "Courses",
                    color: Colors.blue,
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
      height: 45,
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
          padding: const EdgeInsets.all(12),
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
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSections(user) {
    return Column(
      children: [
        _buildInfoCard("Personal Information", Icons.person, [
          _buildInfoRow("Name", user.name),
          _buildInfoRow("Email", user.email),
          _buildInfoRow("Matric Number", user.matricNumber),
          _buildInfoRow("Level", "${user.level}"),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard("Academic Information", Icons.school, [
          _buildInfoRow("Faculty", "Science & Technology"),
          _buildInfoRow("Department", "Computer Science"),
          _buildInfoRow("Advisor", "Dr. James Wilson"),
        ]),
      ],
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, thickness: 1),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Column(
        children: [
          _buildSettingTile(
            "Edit Profile",
            Icons.edit,
            () {
              // Navigate to edit profile page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Edit profile feature coming soon'),
                    backgroundColor: Colors.blue),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildSettingTile(
            "Change Password",
            Icons.lock_outline,
            () {
              // Navigate to change password page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Change password feature coming soon'),
                    backgroundColor: Colors.blue),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildSettingTile(
            "Notifications",
            Icons.notifications_outlined,
            () {
              // Navigate to notifications settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Notification settings coming soon'),
                    backgroundColor: Colors.blue),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildSettingTile(
            "Help & Support",
            Icons.help_outline,
            () {
              // Navigate to help page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Help & support coming soon'),
                    backgroundColor: Colors.blue),
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
      borderRadius: BorderRadius.circular(20),
      splashColor: Colors.blue.withOpacity(0.1),
      highlightColor: Colors.blue.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.blue,
                size: 22,
              ),
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
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.blue.withOpacity(0.7),
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
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

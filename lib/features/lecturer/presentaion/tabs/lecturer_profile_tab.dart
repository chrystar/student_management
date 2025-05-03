import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/provider/user_provider.dart';
import 'package:student_management/features/admin/presentation/news/manage_news_screen.dart';

class LecturerProfileTab extends StatefulWidget {
  const LecturerProfileTab({super.key});

  @override
  State<LecturerProfileTab> createState() => _LecturerProfileTabState();
}

class _LecturerProfileTabState extends State<LecturerProfileTab> {
  final auth = FirebaseAuth.instance;
  bool _isLoading = false;

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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3E64FF),
        title: Text(
          "Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF3E64FF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 30.0, top: 10),
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
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Text(
                              _getInitials(user.name),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3E64FF),
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
                          user.role,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildStatsSection(user),
            ),

            const SizedBox(height: 24),

            // Profile information sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildProfileSections(user),
            ),

            const SizedBox(height: 24),

            // Settings options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSettingsSection(),
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
            .collection('news')
            .where('authorId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, newsSnapshot) {
          // Count of news posts by this lecturer
          int newsCount = 0;
          if (newsSnapshot.hasData) {
            newsCount = newsSnapshot.data!.docs.length;
          }

          return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('news')
                  .where('authorId', isEqualTo: user.uid)
                  .where('featured', isEqualTo: true)
                  .snapshots(),
              builder: (context, featuredSnapshot) {
                // Count of featured news posts by this lecturer
                int featuredCount = 0;
                if (featuredSnapshot.hasData) {
                  featuredCount = featuredSnapshot.data!.docs.length;
                }

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          icon: Icons.newspaper,
                          value: newsCount.toString(),
                          label: "Posts",
                          color: Colors.blue,
                        ),
                        _buildDivider(),
                        _buildStatItem(
                          icon: Icons.star,
                          value: featuredCount.toString(),
                          label: "Featured",
                          color: Colors.amber,
                        ),
                        _buildDivider(),
                        _buildInfoStatItem(
                          icon: Icons.post_add,
                          label: "Create News",
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ManageNewsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              });
        });
  }

  // New method for interactive statistics item
  Widget _buildInfoStatItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
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

  Widget _buildProfileSections(user) {
    return Column(
      children: [
        _buildInfoCard("Personal Information", Icons.person, [
          _buildInfoRow("Name", user.name),
          _buildInfoRow("Email", user.email),
          _buildInfoRow("ID", user.matricNumber),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard("Academic Information", Icons.school, [
          _buildInfoRow("Role", user.role),
          _buildInfoRow("Department", "Computer Science"),
          _buildInfoRow("Office", "Faculty Building, Room 405"),
        ]),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
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
              // Navigate to edit profile page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Edit profile feature coming soon')),
              );
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
            "Notifications",
            Icons.notifications,
            () {
              // Navigate to notifications settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Notification settings coming soon')),
              );
            },
          ),
          _buildSettingTile(
            "Privacy Policy",
            Icons.privacy_tip,
            () {
              // Show privacy policy
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy policy coming soon')),
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Icon(
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

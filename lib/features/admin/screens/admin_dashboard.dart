import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import '../../auth/provider/user_provider.dart';
import 'manage_users_screen.dart';
import '../presentation/news/news_list_screen.dart'; // Added news list screen import
import 'manage_result_screen.dart';
import 'system_stats_screen.dart';
import 'matric_verification/matric_verification_screen.dart';
import 'course_assignment_screen.dart'; // Added import for the course assignment screen
import 'lecturer_id_management_screen.dart'; // Import for lecturer ID management screen

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  bool _isExpanded = true;

  // Function to navigate to matric verification screen
  void _navigateToMatricVerification() {
    setState(() {
      _selectedIndex = 5; // Updated index because we're adding another page
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width <= 600;
    final isTablet = screenSize.width > 768;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // Sidebar navigation - only show on non-mobile devices
          if (!isMobile)
            NavigationRail(
              extended: _isExpanded && isTablet,
              minExtendedWidth: 200,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people),
                  label: Text('Manage Users'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.book),
                  label: Text('Course Assignment'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.assignment),
                  label: Text('Manage Results'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons
                      .newspaper_rounded), // Changed icon from campaign to newspaper
                  label: Text('News'), // Changed label from Broadcasts to News
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.badge),
                  label: Text('Matric Verification'),
                ),
              ],
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              leading: IconButton(
                icon: Icon(_isExpanded ? Icons.menu_open : Icons.menu),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
            ),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // App bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Remove menu button for mobile
                      Text(
                        _getPageTitle(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          // Show notifications
                        },
                      ),
                      if (!isMobile) ...[
                        const SizedBox(width: 8),
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      PopupMenuButton(
                        icon: const Icon(Icons.arrow_drop_down),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'profile',
                            child: Text('Profile'),
                          ),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Text('Logout'),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'logout') {
                            // Handle logout
                            Navigator.pushReplacementNamed(context, '/login');
                          } else if (value == 'profile') {
                            // Navigate to profile
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Content area
                Expanded(
                  child: _getPage(),
                ),
              ],
            ),
          ),
        ],
      ),
      // Add bottom navigation for mobile
      bottomNavigationBar: isMobile ? _buildBottomNavBar() : null,
      // Add drawer for mobile menu
      drawer: isMobile ? _buildDrawer(user) : null,
    );
  }

  // Bottom navigation bar for mobile devices
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex > 4 ? 4 : _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: false,
      showSelectedLabels: false,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_alt_rounded),
          label: 'Users',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book_rounded),
          label: 'Courses',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_rounded),
          label: 'Results',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons
              .newspaper_rounded), // Changed icon from campaign to newspaper
          label: 'News', // Changed label from Broadcasts to News
        ),
      ],
    );
  }

  // Drawer for mobile navigation
  Widget _buildDrawer(user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.green,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user.email,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(0, 'Dashboard', Icons.dashboard),
          _buildDrawerItem(1, 'Manage Users', Icons.people),
          _buildDrawerItem(2, 'Course Assignment', Icons.book),
          _buildDrawerItem(3, 'Manage Results', Icons.assignment),
          _buildDrawerItem(
              4,
              'News',
              Icons
                  .newspaper), // Changed from Announcements to News with new icon
          _buildDrawerItem(5, 'Matric Verification', Icons.badge),
          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: const Text('Lecturer IDs'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LecturerIdManagementScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(6, 'System Settings', Icons.settings),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              // Handle logout
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  // Helper method to build drawer items
  Widget _buildDrawerItem(int index, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: _selectedIndex == index ? Colors.green : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight:
              _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
          color: _selectedIndex == index ? Colors.green : null,
        ),
      ),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context); // Close the drawer
      },
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'Manage Users';
      case 2:
        return 'Course Assignment';
      case 3:
        return 'Manage Results';
      case 4:
        return 'News Management'; // Changed from Announcements to News Management
      case 5:
        return 'Matric Verification';
      case 6:
        return 'System Settings';
      default:
        return 'Admin Dashboard';
    }
  }

  Widget _getPage() {
    switch (_selectedIndex) {
      case 0:
        return DashboardHome(
            navigateToMatricVerification: _navigateToMatricVerification);
      case 1:
        return const ManageUsersScreen();
      case 2:
        return const CourseAssignmentScreen();
      case 3:
        return const ManageResultScreen();
      case 4:
        return const NewsListScreen(); // Changed from AdminBroadcastsScreen to NewsListScreen
      case 5:
        return const MatricVerificationScreen();
      case 6:
        return const SystemStatsScreen();
      default:
        return DashboardHome(
            navigateToMatricVerification: _navigateToMatricVerification);
    }
  }
}

class DashboardHome extends StatelessWidget {
  final VoidCallback navigateToMatricVerification;

  const DashboardHome({super.key, required this.navigateToMatricVerification});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview cards
            const SizedBox(height: 16),
            _buildOverviewSection(context),

            const SizedBox(height: 24),

            // Recent activities
            const Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRecentActivitiesCard(context),

            const SizedBox(height: 24),

            // Quick actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickActionsGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive crossAxisCount based on screen width
    final crossAxisCount = screenWidth < 600
        ? 1
        : screenWidth < 960
            ? 2
            : 3;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: 2.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatsCard(
          context,
          title: 'Total Students',
          count: 0,
          icon: Icons.school,
          color: Colors.green,
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'Student')
              .snapshots(),
        ),
        _buildStatsCard(
          context,
          title: 'Total Lecturers',
          count: 0,
          icon: Icons.person,
          color: Colors.green,
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'Lecturer')
              .snapshots(),
        ),
        _buildStatsCard(
          context,
          title: 'Active Courses',
          count: 0,
          icon: Icons.book,
          color: Colors.green,
          stream: FirebaseFirestore.instance.collection('courses').snapshots(),
        ),
      ],
    );
  }

  Widget _buildStatsCard(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Stream<QuerySnapshot> stream,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        int itemCount = 0;
        if (snapshot.hasData) {
          itemCount = snapshot.data!.docs.length;
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        itemCount.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivitiesCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('student_activities')
              .orderBy('timestamp', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final activities = snapshot.data?.docs ?? [];

            if (activities.isEmpty) {
              return const Center(
                child: Text('No recent activities to display'),
              );
            }

            return Column(
              children: activities.map((doc) {
                final activity = doc.data() as Map<String, dynamic>;
                final timestamp = activity['timestamp'] as Timestamp?;
                final date = timestamp != null
                    ? DateFormat('MMM dd, yyyy - HH:mm')
                        .format(timestamp.toDate())
                    : 'Unknown date';

                return ListTile(
                  leading: _getActivityIcon(activity['type'] ?? 'general'),
                  title: Text(
                    activity['title'] ?? 'Untitled Activity',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  subtitle: Text(
                    '${activity['studentName'] ?? 'Unknown Student'} • $date',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    // View activity details
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _getActivityIcon(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'attendance':
        icon = Icons.calendar_today;
        color = Colors.green;
        break;
      case 'submission':
        icon = Icons.assignment_turned_in;
        color = Colors.green;
        break;
      case 'exam':
        icon = Icons.quiz;
        color = Colors.purple;
        break;
      case 'registration':
        icon = Icons.school;
        color = Colors.orange;
        break;
      default:
        icon = Icons.event_note;
        color = Colors.grey;
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive crossAxisCount based on screen width
    final crossAxisCount = screenWidth < 600
        ? 2 // Show 2 columns on very small screens
        : screenWidth < 960
            ? 3 // Show 3 columns on medium screens
            : 5; // Show all 5 buttons in a row on large screens

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2, // Adjust aspect ratio for better fit
      children: [
        _buildQuickActionButton(
          context,
          icon: Icons.newspaper, // Changed from campaign to newspaper
          label: 'Create News', // Changed from New Announcement to Create News
          onTap: () {
            // Navigate to create news
          },
        ),
        _buildQuickActionButton(
          context,
          icon: Icons.person_add,
          label: 'Add User',
          onTap: () {
            // Navigate to add user
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageUsersScreen(),
              ),
            );
          },
        ),
        _buildQuickActionButton(
          context,
          icon: Icons.badge,
          label: 'Matric Verification',
          onTap: navigateToMatricVerification,
        ),
        _buildQuickActionButton(
          context,
          icon: Icons.vpn_key,
          label: 'Lecturer IDs',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LecturerIdManagementScreen(),
              ),
            );
          },
        ),
        _buildQuickActionButton(
          context,
          icon: Icons.assignment,
          label: 'Reports',
          onTap: () {
            // Navigate to reports
          },
        ),
      ],
    );
  }

  // Helper method to build quick action button
  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Lecturer ID Generation Dialog
  void _showLecturerIdGenerationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        // Form controllers
        final nameController = TextEditingController();
        final departmentController = TextEditingController();
        final emailController = TextEditingController();

        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.vpn_key, color: Colors.green),
              SizedBox(width: 8),
              Text('Generate Lecturer ID'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Generate a unique ID that will be required for lecturer registration. This ID will be linked to the lecturer\'s details for verification.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Lecturer Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    departmentController.text.isNotEmpty &&
                    emailController.text.isNotEmpty) {
                  _generateLecturerId(
                    context,
                    nameController.text,
                    departmentController.text,
                    emailController.text,
                  );
                  Navigator.pop(context);
                } else {
                  // Show error for empty fields
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                }
              },
              child: const Text('GENERATE ID'),
            ),
          ],
        );
      },
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
      // Show success dialog with the generated ID
      _showGeneratedIdDialog(context, lecturerId, email);
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating ID: $error')),
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

  // View all generated lecturer IDs (add this method to make the feature complete)
  void _viewLecturerIds(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Lecturer ID Management')),
          body: StreamBuilder<QuerySnapshot>(
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
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: ids.length,
                itemBuilder: (context, index) {
                  final idData = ids[index].data() as Map<String, dynamic>;
                  final isUsed = idData['isUsed'] ?? false;
                  final validUntil = idData['validUntil'] as Timestamp?;
                  final isExpired = validUntil != null &&
                      validUntil.toDate().isBefore(DateTime.now());

                  return ListTile(
                    title: Text(idData['name'] ?? 'Unknown'),
                    subtitle: Text(
                      '${idData['id']} - ${idData['department']}',
                      style: TextStyle(
                        color: isExpired ? Colors.red : null,
                        decoration:
                            isExpired ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isUsed
                          ? Colors.green.withOpacity(0.1)
                          : isExpired
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
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
                                : Colors.green,
                      ),
                    ),
                    trailing: Text(
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
                                : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _showLecturerIdGenerationDialog(context);
            },
            child: const Icon(Icons.add),
            tooltip: 'Generate New ID',
          ),
        ),
      ),
    );
  }
}

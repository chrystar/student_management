import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../auth/provider/user_provider.dart';
import 'manage_users_screen.dart';
import 'admin_broadcasts_screen.dart';
import 'manage_result_screen.dart';
import 'system_stats_screen.dart';
import 'matric_verification/matric_verification_screen.dart';
import 'course_assignment_screen.dart'; // Added import for the course assignment screen

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
                  icon: Icon(Icons.campaign),
                  label: Text('Announcements'),
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
      selectedItemColor: Colors.blue,
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
          icon: Icon(Icons.campaign_rounded),
          label: 'Broadcasts',
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
              color: Colors.blue,
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
                      color: Colors.blue.shade800,
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
          _buildDrawerItem(4, 'Announcements', Icons.campaign),
          _buildDrawerItem(5, 'Matric Verification', Icons.badge),
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
      leading: Icon(icon, color: _selectedIndex == index ? Colors.blue : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight:
              _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
          color: _selectedIndex == index ? Colors.blue : null,
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
        return 'Announcements';
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
        return const AdminBroadcastsScreen();
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
          color: Colors.blue,
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
          color: Colors.blue,
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
          color: Colors.blue,
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
        color = Colors.blue;
        break;
      case 'submission':
        icon = Icons.assignment_turned_in;
        color = Colors.blue;
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
          icon: Icons.campaign,
          label: 'New Announcement',
          onTap: () {
            // Navigate to create announcement
          },
        ),
        _buildQuickActionButton(
          context,
          icon: Icons.person_add,
          label: 'Add User',
          onTap: () {
            // Navigate to add user
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
          icon: Icons.book,
          label: 'Add Course',
          onTap: () {
            // Navigate to add course
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

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

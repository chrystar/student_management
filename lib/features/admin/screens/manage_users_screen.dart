import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(constraints.maxWidth * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search and filters row
                  if (isSmallScreen)
                    Column(
                      children: [
                        _buildSearchField(),
                        SizedBox(height: constraints.maxHeight * 0.02),
                        SizedBox(
                          width: double.infinity,
                          child: _buildAddButton(),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(child: _buildSearchField()),
                        SizedBox(width: constraints.maxWidth * 0.02),
                        _buildAddButton(),
                      ],
                    ),

                  SizedBox(height: constraints.maxHeight * 0.02),

                  // Tab bar with modern style
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'All Users'),
                        Tab(text: 'Students'),
                        Tab(text: 'Lecturers'),
                      ],
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      indicator: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(constraints.maxWidth * 0.01),
                    ),
                  ),

                  SizedBox(height: constraints.maxHeight * 0.02),

                  // Tab content
                  SizedBox(
                    height: constraints.maxHeight * 0.8,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildUsersList(null),
                        _buildUsersList('Student'),
                        _buildUsersList('Lecturer'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search users...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        fillColor: Colors.grey.shade50,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: () {
        _showAddUserDialog(context);
      },
      icon: const Icon(Icons.add),
      label: const Text('Add User'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildUsersList(String? role) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width <= 600;

    Query usersQuery = FirebaseFirestore.instance.collection('users');

    if (role != null) {
      usersQuery = usersQuery.where('role', isEqualTo: role);
    }

    if (_searchQuery.isNotEmpty) {
      // Search implementation (client-side filtering)
    }

    return StreamBuilder<QuerySnapshot>(
      stream: usersQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data?.docs ?? [];

        // Client-side filtering for search
        final filteredUsers = _searchQuery.isEmpty
            ? users
            : users.where((doc) {
                final userData = doc.data() as Map<String, dynamic>;
                final name = userData['name'] as String? ?? '';
                final email = userData['email'] as String? ?? '';
                final query = _searchQuery.toLowerCase();
                return name.toLowerCase().contains(query) ||
                    email.toLowerCase().contains(query);
              }).toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Try adjusting your search',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final userData =
                filteredUsers[index].data() as Map<String, dynamic>;
            final userId = filteredUsers[index].id;

            final name = userData['name'] as String? ?? 'No Name';
            final email = userData['email'] as String? ?? 'No Email';
            final userRole = userData['role'] as String? ?? 'Unknown';
            final timestamp = userData['createdAt'] as Timestamp?;
            final createdAt = timestamp != null
                ? DateFormat('MMM dd, yyyy').format(timestamp.toDate())
                : 'Unknown';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showUserDetails(context, userId, userData),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      if (isMobile)
                        // Mobile layout - stacked with larger avatar
                        Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor:
                                      _getRoleColor(userRole).withOpacity(0.2),
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: _getRoleColor(userRole),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        email,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getRoleColor(userRole)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          userRole,
                                          style: TextStyle(
                                            color: _getRoleColor(userRole),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () => _showUserActions(
                                      context, userId, userData),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined,
                                          size: 14, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Joined: $createdAt',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('Edit'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () => _showEditUserDialog(
                                      context, userId, userData),
                                ),
                              ],
                            )
                          ],
                        )
                      else
                        // Desktop layout - horizontal
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  _getRoleColor(userRole).withOpacity(0.2),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: _getRoleColor(userRole),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(userRole).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                userRole,
                                style: TextStyle(
                                  color: _getRoleColor(userRole),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Row(
                              children: [
                                _buildActionButton(
                                  icon: Icons.edit_outlined,
                                  label: 'Edit',
                                  onTap: () => _showEditUserDialog(
                                      context, userId, userData),
                                ),
                                const SizedBox(width: 8),
                                _buildActionButton(
                                  icon: Icons.delete_outline,
                                  label: 'Delete',
                                  color: Colors.red,
                                  onTap: () => _showDeleteConfirmation(
                                      context, userId, name),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showUserDetails(
      BuildContext context, String userId, Map<String, dynamic> userData) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width <= 600;

    // On mobile, show a bottom sheet instead of a dialog for a more native feel
    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          // Use 80% of screen height
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        _getRoleColor(userData['role'] ?? 'Unknown')
                            .withOpacity(0.2),
                    child: Text(
                      userData['name'] != null &&
                              userData['name'].toString().isNotEmpty
                          ? userData['name'][0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: _getRoleColor(userData['role'] ?? 'Unknown'),
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData['name'] ?? 'Unknown User',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(userData['role'] ?? 'Unknown')
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            userData['role'] ?? 'Unknown Role',
                            style: TextStyle(
                              color:
                                  _getRoleColor(userData['role'] ?? 'Unknown'),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'User Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    _buildDetailTile(
                        'Email',
                        userData['email'] ?? 'Not provided',
                        Icons.email_outlined),
                    _buildDetailTile(
                        'Role',
                        userData['role'] ?? 'Not specified',
                        Icons.badge_outlined),
                    if (userData['role'] == 'Student') ...[
                      _buildDetailTile(
                          'Level',
                          '${userData['level'] ?? 'Not specified'} Level',
                          Icons.school_outlined),
                      _buildDetailTile(
                          'Matric Number',
                          userData['matricNumber'] ?? 'Not provided',
                          Icons.badge_outlined),
                    ],
                    _buildDetailTile(
                      'Account Created',
                      userData['createdAt'] != null
                          ? DateFormat('MMMM dd, yyyy').format(
                              (userData['createdAt'] as Timestamp).toDate())
                          : 'Unknown',
                      Icons.calendar_today_outlined,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditUserDialog(context, userId, userData);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmation(
                              context, userId, userData['name']);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Desktop dialog implementation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('User Details: ${userData['name']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Email', userData['email'] ?? 'Not provided'),
                _buildDetailRow('Role', userData['role'] ?? 'Not specified'),
                if (userData['role'] == 'Student') ...[
                  _buildDetailRow(
                      'Level', '${userData['level'] ?? 'Not specified'} Level'),
                  _buildDetailRow('Matric Number',
                      userData['matricNumber'] ?? 'Not provided'),
                ],
                _buildDetailRow(
                    'Account Created',
                    userData['createdAt'] != null
                        ? DateFormat('MMMM dd, yyyy').format(
                            (userData['createdAt'] as Timestamp).toDate())
                        : 'Unknown'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showEditUserDialog(context, userId, userData);
              },
              child: const Text('Edit'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDetailTile(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label),
      subtitle: Text(
        value,
        style: TextStyle(
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color ?? Colors.blue),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Student':
        return Colors.blue;
      case 'Lecturer':
        return Colors.green;
      case 'Admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showUserActions(
      BuildContext context, String userId, Map<String, dynamic> userData) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit User'),
              onTap: () {
                Navigator.pop(context);
                _showEditUserDialog(context, userId, userData);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete User',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, userId, userData['name']);
              },
            ),
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Reset Password'),
              onTap: () {
                Navigator.pop(context);
                _showResetPasswordConfirmation(context, userData['email']);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String role = 'Student';
    String level = '100';
    String matricNumber = '';
    String password = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter name';
                    }
                    return null;
                  },
                  onChanged: (value) => name = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  onChanged: (value) => email = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  onChanged: (value) => password = value,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.work),
                  ),
                  value: role,
                  items: const [
                    DropdownMenuItem(value: 'Student', child: Text('Student')),
                    DropdownMenuItem(
                        value: 'Lecturer', child: Text('Lecturer')),
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  ],
                  onChanged: (value) {
                    role = value!;
                  },
                ),
                const SizedBox(height: 16),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: role == 'Student'
                      ? Column(
                          children: [
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Level',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.school),
                              ),
                              value: level,
                              items: const [
                                DropdownMenuItem(
                                    value: '100', child: Text('100 Level')),
                                DropdownMenuItem(
                                    value: '200', child: Text('200 Level')),
                                DropdownMenuItem(
                                    value: '300', child: Text('300 Level')),
                                DropdownMenuItem(
                                    value: '400', child: Text('400 Level')),
                                DropdownMenuItem(
                                    value: '500', child: Text('500 Level')),
                              ],
                              onChanged: (value) {
                                level = value!;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Matric Number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.badge),
                              ),
                              validator: role == 'Student'
                                  ? (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter matric number';
                                      }
                                      return null;
                                    }
                                  : null,
                              onChanged: (value) => matricNumber = value,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  // This would typically use Firebase Auth to create the user
                  // For now, we'll just add to Firestore
                  final userData = {
                    'name': name,
                    'email': email,
                    'role': role,
                    'createdAt': Timestamp.now(),
                  };

                  if (role == 'Student') {
                    userData['level'] = level;
                    userData['matricNumber'] = matricNumber;
                  }

                  await FirebaseFirestore.instance
                      .collection('users')
                      .add(userData);

                  // Close loading dialog
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User $name added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  // Close loading dialog
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding user: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add User'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(
      BuildContext context, String userId, Map<String, dynamic> userData) {
    final formKey = GlobalKey<FormState>();
    String name = userData['name'] ?? '';
    String email = userData['email'] ?? '';
    String role = userData['role'] ?? 'Student';
    String level = userData['level'] ?? '100';
    String matricNumber = userData['matricNumber'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter name';
                    }
                    return null;
                  },
                  onChanged: (value) => name = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: email,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.email),
                    helperText: 'Changing email requires password reset',
                    helperStyle:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  onChanged: (value) => email = value,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.work),
                  ),
                  value: role,
                  items: const [
                    DropdownMenuItem(value: 'Student', child: Text('Student')),
                    DropdownMenuItem(
                        value: 'Lecturer', child: Text('Lecturer')),
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  ],
                  onChanged: (value) {
                    role = value!;
                  },
                ),
                const SizedBox(height: 16),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: role == 'Student'
                      ? Column(
                          children: [
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Level',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.school),
                              ),
                              value: level,
                              items: const [
                                DropdownMenuItem(
                                    value: '100', child: Text('100 Level')),
                                DropdownMenuItem(
                                    value: '200', child: Text('200 Level')),
                                DropdownMenuItem(
                                    value: '300', child: Text('300 Level')),
                                DropdownMenuItem(
                                    value: '400', child: Text('400 Level')),
                                DropdownMenuItem(
                                    value: '500', child: Text('500 Level')),
                              ],
                              onChanged: (value) {
                                level = value!;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: matricNumber,
                              decoration: InputDecoration(
                                labelText: 'Matric Number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.badge),
                              ),
                              validator: role == 'Student'
                                  ? (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter matric number';
                                      }
                                      return null;
                                    }
                                  : null,
                              onChanged: (value) => matricNumber = value,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  final updatedData = {
                    'name': name,
                    'email': email,
                    'role': role,
                    'updatedAt': Timestamp.now(),
                  };

                  if (role == 'Student') {
                    updatedData['level'] = level;
                    updatedData['matricNumber'] = matricNumber;
                  } else {
                    // Remove student-specific fields if role is changed
                    updatedData['level'] = FieldValue.delete();
                    updatedData['matricNumber'] = FieldValue.delete();
                  }

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .update(updatedData);

                  // Close loading dialog
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User $name updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  // Close loading dialog
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating user: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Are you sure you want to delete $userName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Delete user implementation
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User $userName has been deleted')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting user: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordConfirmation(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send password reset email to $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Password reset implementation
              // This would typically use Firebase Auth passwordResetEmail
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Password reset link sent to $email')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

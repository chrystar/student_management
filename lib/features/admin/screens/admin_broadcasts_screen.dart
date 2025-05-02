import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../auth/provider/user_provider.dart';

class AdminBroadcastsScreen extends StatefulWidget {
  const AdminBroadcastsScreen({super.key});

  @override
  State<AdminBroadcastsScreen> createState() => _AdminBroadcastsScreenState();
}

class _AdminBroadcastsScreenState extends State<AdminBroadcastsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width <= 600;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and add broadcast row - stacked on mobile
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchField(),
                const SizedBox(height: 12),
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
                const SizedBox(width: 16),
                _buildAddButton(),
              ],
            ),

          const SizedBox(height: 16),

          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Students'),
              Tab(text: 'Lecturers'),
            ],
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            // Make labels more compact on mobile
            labelStyle: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBroadcastsList(null, isMobile),
                _buildBroadcastsList('Student', isMobile),
                _buildBroadcastsList('Lecturer', isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search announcements...',
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
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
        _showCreateBroadcastDialog(context);
      },
      icon: const Icon(Icons.add),
      label: const Text('New Announcement'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildBroadcastsList(String? targetRole, bool isMobile) {
    Query announcementsQuery = FirebaseFirestore.instance
        .collection('broadcasts')
        .orderBy('timestamp', descending: true);

    if (targetRole != null) {
      announcementsQuery =
          announcementsQuery.where('targetRole', isEqualTo: targetRole);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: announcementsQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final broadcasts = snapshot.data?.docs ?? [];

        // Client-side filtering for search
        final filteredBroadcasts = _searchQuery.isEmpty
            ? broadcasts
            : broadcasts.where((doc) {
                final broadcastData = doc.data() as Map<String, dynamic>;
                final title = broadcastData['title'] as String? ?? '';
                final message = broadcastData['message'] as String? ?? '';
                final query = _searchQuery.toLowerCase();
                return title.toLowerCase().contains(query) ||
                    message.toLowerCase().contains(query);
              }).toList();

        if (filteredBroadcasts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No announcements found',
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
          itemCount: filteredBroadcasts.length,
          itemBuilder: (context, index) {
            final broadcastData =
                filteredBroadcasts[index].data() as Map<String, dynamic>;
            final broadcastId = filteredBroadcasts[index].id;

            final title = broadcastData['title'] as String? ?? 'Untitled';
            final message = broadcastData['message'] as String? ?? 'No message';
            final sender = broadcastData['senderName'] as String? ?? 'Admin';
            final targetRoleText =
                broadcastData['targetRole'] as String? ?? 'All';
            final timestamp = broadcastData['timestamp'] as Timestamp?;
            final date = timestamp != null
                ? DateFormat('MMM dd, yyyy - HH:mm').format(timestamp.toDate())
                : 'Unknown date';

            // Different card styles for mobile and desktop
            if (isMobile) {
              // Modern mobile card with optimized layout
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 1,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with colored stripe based on target audience
                    Container(
                      color:
                          _getTargetRoleColor(targetRoleText).withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            _getTargetRoleIcon(targetRoleText),
                            size: 18,
                            color: _getTargetRoleColor(targetRoleText),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'For $targetRoleText',
                            style: TextStyle(
                              color: _getTargetRoleColor(targetRoleText),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('MMM dd')
                                .format(timestamp?.toDate() ?? DateTime.now()),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content area
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _showAnnouncementOptions(
                                    context, broadcastId, broadcastData),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            message,
                            style: const TextStyle(fontSize: 15),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (message.split('\n').length > 4 ||
                              message.length > 120)
                            TextButton(
                              onPressed: () => _showFullMessageDialog(
                                  context, title, message),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                alignment: Alignment.centerLeft,
                              ),
                              child: Text(
                                'Read more',
                                style: TextStyle(
                                  color: _getTargetRoleColor(targetRoleText),
                                ),
                              ),
                            ),

                          const Divider(height: 24),

                          // Footer with action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor:
                                          Colors.blue.withOpacity(0.1),
                                      child: const Icon(
                                        Icons.person_outline,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        sender,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  _buildMobileActionButton(
                                    icon: Icons.edit_outlined,
                                    color: Colors.blue,
                                    onTap: () => _showEditBroadcastDialog(
                                        context, broadcastId, broadcastData),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildMobileActionButton(
                                    icon: Icons.delete_outline,
                                    color: Colors.red,
                                    onTap: () => _showDeleteConfirmation(
                                        context, broadcastId, title),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Desktop card with horizontal layout
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: Colors.blue),
                                tooltip: 'Edit Announcement',
                                onPressed: () {
                                  _showEditBroadcastDialog(
                                      context, broadcastId, broadcastData);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                tooltip: 'Delete Announcement',
                                onPressed: () {
                                  _showDeleteConfirmation(
                                      context, broadcastId, title);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'From: $sender',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(
                          'To: $targetRoleText',
                          style: TextStyle(
                            color: _getTargetRoleColor(targetRoleText),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: _getTargetRoleColor(targetRoleText)
                            .withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildMobileActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  IconData _getTargetRoleIcon(String targetRole) {
    switch (targetRole) {
      case 'Student':
        return Icons.school;
      case 'Lecturer':
        return Icons.person_pin;
      case 'Admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.groups;
    }
  }

  void _showAnnouncementOptions(BuildContext context, String broadcastId,
      Map<String, dynamic> broadcastData) {
    final title = broadcastData['title'] as String? ?? 'Untitled';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.blue),
                title: const Text('View Full Announcement'),
                onTap: () {
                  Navigator.pop(context);
                  final message = broadcastData['message'] as String? ?? '';
                  _showFullMessageDialog(context, title, message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Announcement'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditBroadcastDialog(context, broadcastId, broadcastData);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Announcement',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, broadcastId, title);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullMessageDialog(
      BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCreateBroadcastDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedTargetRole = 'All';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Announcement'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.title),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: messageController,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.message),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (value) =>
                      value!.isEmpty ? 'Message is required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTargetRole,
                  decoration: InputDecoration(
                    labelText: 'Target Audience',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.people),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                  items: ['All', 'Student', 'Lecturer', 'Admin']
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          ))
                      .toList(),
                  onChanged: (val) => selectedTargetRole = val!,
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
                borderRadius: BorderRadius.circular(10),
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

                final user =
                    Provider.of<UserProvider>(context, listen: false).user;

                try {
                  await FirebaseFirestore.instance
                      .collection('broadcasts')
                      .add({
                    'title': titleController.text.trim(),
                    'message': messageController.text.trim(),
                    'targetRole': selectedTargetRole,
                    'senderId': user?.uid ?? 'admin',
                    'senderName': user?.name ?? 'Admin',
                    'senderRole': 'Admin',
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  // Close loading dialog
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Announcement created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  // Close loading dialog
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error creating announcement: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Color _getTargetRoleColor(String targetRole) {
    switch (targetRole) {
      case 'Student':
        return Colors.blue;
      case 'Lecturer':
        return Colors.green;
      case 'Admin':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  void _showEditBroadcastDialog(BuildContext context, String broadcastId,
      Map<String, dynamic> broadcastData) {
    final formKey = GlobalKey<FormState>();
    final titleController =
        TextEditingController(text: broadcastData['title'] ?? '');
    final messageController =
        TextEditingController(text: broadcastData['message'] ?? '');
    String selectedTargetRole = broadcastData['targetRole'] ?? 'All';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Announcement'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (value) =>
                      value!.isEmpty ? 'Message is required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTargetRole,
                  decoration: const InputDecoration(
                    labelText: 'Target Audience',
                    border: OutlineInputBorder(),
                  ),
                  items: ['All', 'Student', 'Lecturer', 'Admin']
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          ))
                      .toList(),
                  onChanged: (val) => selectedTargetRole = val!,
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);

                try {
                  await FirebaseFirestore.instance
                      .collection('broadcasts')
                      .doc(broadcastId)
                      .update({
                    'title': titleController.text.trim(),
                    'message': messageController.text.trim(),
                    'targetRole': selectedTargetRole,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Announcement updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating announcement: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, String broadcastId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await FirebaseFirestore.instance
                    .collection('broadcasts')
                    .doc(broadcastId)
                    .delete();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Announcement "$title" has been deleted')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting announcement: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

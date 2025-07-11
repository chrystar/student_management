import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../auth/provider/user_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Unread'),
                ],
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildNotificationsList(user.uid, false),
                  _buildNotificationsList(user.uid, true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(String userId, bool unreadOnly) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _isLoading = true;
        });
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
      child: StreamBuilder<QuerySnapshot>(
        stream: unreadOnly
            ? FirebaseFirestore.instance
                .collection('notifications')
                .where('recipientId', isEqualTo: userId)
                .where('read', isEqualTo: false)
                .snapshots()
            : FirebaseFirestore.instance
                .collection('notifications')
                .where('recipientId', isEqualTo: userId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {            // Check if error is related to Firestore index
            final errorMsg = snapshot.error.toString();
            if (errorMsg.contains('FAILED_PRECONDITION') &&
                errorMsg.contains('index')) {
              // Check specifically for "index is building" case
              final bool isIndexBuilding = errorMsg.contains('cannot be used yet');
              
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isIndexBuilding ? Icons.hourglass_bottom : Icons.build_circle,
                      color: isIndexBuilding ? Colors.amber : Colors.blue,
                      size: 48
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isIndexBuilding
                          ? "Almost ready..."
                          : "Setting up notifications...",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isIndexBuilding
                          ? "The notification system is being optimized. This usually takes 1-2 minutes. Please wait..."
                          : "We're preparing your notifications. This should only take a minute or two.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isIndexBuilding ? Colors.amber : Colors.blue,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }

          final notifications = snapshot.data?.docs ?? [];
          
          // Sort notifications by timestamp manually
          notifications.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTimestamp = aData['timestamp'] as Timestamp?;
            final bTimestamp = bData['timestamp'] as Timestamp?;
            
            if (aTimestamp == null && bTimestamp == null) return 0;
            if (aTimestamp == null) return 1;
            if (bTimestamp == null) return -1;
            
            return bTimestamp.compareTo(aTimestamp); // Descending order
          });

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    unreadOnly
                        ? 'No unread notifications'
                        : 'No notifications yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification =
                  notifications[index].data() as Map<String, dynamic>;
              final notificationId = notifications[index].id;
              final bool isRead = notification['read'] ?? false;
              final timestamp = notification['timestamp'] as Timestamp?;
              final date = timestamp != null
                  ? DateFormat('MMM dd, yyyy • hh:mm a')
                      .format(timestamp.toDate())
                  : 'Unknown date';

              return Card(
                elevation: isRead ? 0 : 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isRead
                        ? Colors.transparent
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                    width: 1,
                  ),
                ),
                color: isRead ? Colors.white : Colors.blue.shade50,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // Mark notification as read
                    if (!isRead) {
                      FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(notificationId)
                          .update({'read': true});
                    }

                    // Show notification details
                    _showNotificationDetails(context, notification, date);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _getNotificationColor(notification['type'])
                                .withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              _getNotificationIcon(notification['type']),
                              color:
                                  _getNotificationColor(notification['type']),
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification['title'] ?? 'No Title',
                                      style: TextStyle(
                                        fontWeight: isRead
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification['message'] ?? 'No message',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                date,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'news':
        return Icons.feed_outlined;
      case 'assignment':
        return Icons.assignment_outlined;
      case 'grade':
        return Icons.grade_outlined;
      case 'course':
        return Icons.book_outlined;
      case 'message':
        return Icons.message_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'news':
        return Colors.blue;
      case 'assignment':
        return Colors.orange;
      case 'grade':
        return Colors.green;
      case 'course':
        return Colors.purple;
      case 'message':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _showNotificationDetails(
      BuildContext context, Map<String, dynamic> notification, String date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification['type'])
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getNotificationIcon(notification['type']),
                    color: _getNotificationColor(notification['type']),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    notification['title'] ?? 'Notification',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getNotificationColor(notification['type'])
                    .withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getNotificationColor(notification['type'])
                      .withOpacity(0.2),
                ),
              ),
              child: Text(
                notification['message'] ?? 'No message content',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (notification['actionUrl'] != null)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Handle action URL
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getNotificationColor(notification['type']),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.open_in_new),
                label: const Text('View Details'),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

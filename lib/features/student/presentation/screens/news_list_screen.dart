import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:student_management/core/theme/app_theme.dart';
import '../../../auth/provider/user_provider.dart';

class NewsListScreen extends StatelessWidget {
  final String category;
  const NewsListScreen({super.key, required this.category});

  Stream<QuerySnapshot> _getFilteredNewsStream(String? userDepartment) {
    final isAllNews = category == 'All News';
    
    if (isAllNews) {
      return FirebaseFirestore.instance
          .collection('news')
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('news')
          .where('category', isEqualTo: category)
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
  }

  bool _shouldShowNews(Map<String, dynamic> newsData, String? userDepartment) {
    // If user department is null (shouldn't happen), show only global news
    if (userDepartment == null) {
      return newsData['isGlobal'] == true;
    }

    // Show global news
    if (newsData['isGlobal'] == true) {
      return true;
    }

    // Show department-specific news if user's department is in target departments
    final targetDepartments = List<String>.from(newsData['targetDepartments'] ?? []);
    return targetDepartments.contains(userDepartment);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userDepartment = userProvider.user?.department;

    final isAllNews = category == 'All News';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAllNews ? 'All News' : '$category News'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getFilteredNewsStream(userDepartment),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading news'));
          }
          
          final allNews = snapshot.data?.docs ?? [];
          
          // Filter news based on user's department
          final filteredNews = allNews.where((newsDoc) {
            final newsData = newsDoc.data() as Map<String, dynamic>;
            return _shouldShowNews(newsData, userDepartment);
          }).toList();
          
          if (filteredNews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.newspaper,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No news available for your department',
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
            itemCount: filteredNews.length,
            itemBuilder: (context, index) {
              final data = filteredNews[index].data() as Map<String, dynamic>;
              final timestamp = data['timestamp'] as Timestamp?;
              final date = timestamp != null
                  ? DateFormat('MMM dd, yyyy').format(timestamp.toDate())
                  : 'Unknown date';
              
              // Add department indicator for non-global news
              final isGlobal = data['isGlobal'] == true;
              final targetDepartments = List<String>.from(data['targetDepartments'] ?? []);
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Department indicator banner (if not global)
                    if (!isGlobal && targetDepartments.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            topRight: Radius.circular(14),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.group,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'For: ${targetDepartments.join(', ')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ListTile(
                      leading: data['imageUrl'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                data['imageUrl'],
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.image, color: Colors.grey),
                              ),
                            )
                          : Icon(Icons.newspaper, color: AppTheme.primaryColor),
                      title: Text(
                        data['title'] ?? 'No Title',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(date),
                          if (!isGlobal)
                            Text(
                              'Department specific',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (data['imageUrl'] != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          data['imageUrl'],
                                          width: double.infinity,
                                          height: 180,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                    Text(
                                      data['title'] ?? 'No Title',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(date, style: TextStyle(color: Colors.grey[700])),
                                        if (!isGlobal) ...[
                                          const SizedBox(width: 16),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Department News',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    Text(
                                      data['content'] ?? 'No content available.',
                                      style: const TextStyle(fontSize: 16, height: 1.6),
                                    ),
                                    const SizedBox(height: 24),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryColor,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

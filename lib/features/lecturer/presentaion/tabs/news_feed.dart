import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NewsFeed extends StatefulWidget {
  const NewsFeed({super.key});

  @override
  State<NewsFeed> createState() => _NewsFeedState();
}

class _NewsFeedState extends State<NewsFeed> {
  bool _isLoading = true;
  List<NewsItem> _newsItems = [];

  @override
  void initState() {
    super.initState();
    _fetchNewsItems();
  }

  Future<void> _fetchNewsItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('news')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _newsItems = snapshot.docs
            .map((doc) => NewsItem.fromMap(doc.data(), doc.id))
            .toList();
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching news: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchNewsItems,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _newsItems.isEmpty
                ? _buildEmptyState()
                : _buildNewsFeed(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNewsDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Post News',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_news.png',
            height: 120,
            width: 120,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.feed_outlined, size: 80, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text(
            'No news yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'News and announcements from lecturers will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsFeed() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _newsItems.length,
      itemBuilder: (context, index) {
        final item = _newsItems[index];
        return NewsCard(
          newsItem: item,
          onDelete: () => _deleteNewsItem(item.id),
        );
      },
    );
  }

  void _showAddNewsDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post New Announcement'),
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter content';
                    }
                    return null;
                  },
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
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _addNewsItem(
                  title: titleController.text,
                  content: contentController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewsItem({
    required String title,
    required String content,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('news').add({
        'title': title,
        'content': content,
        'authorName': 'Dr. John Doe', // Replace with actual user data
        'authorDepartment': 'Computer Science', // Replace with actual user data
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('News posted successfully')),
      );

      _fetchNewsItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post news: $e')),
      );
    }
  }

  Future<void> _deleteNewsItem(String id) async {
    try {
      await FirebaseFirestore.instance.collection('news').doc(id).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('News deleted successfully')),
      );

      _fetchNewsItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete news: $e')),
      );
    }
  }
}

class NewsCard extends StatelessWidget {
  final NewsItem newsItem;
  final VoidCallback onDelete;

  const NewsCard({
    Key? key,
    required this.newsItem,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with author info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade200,
                  child: Text(
                    newsItem.authorName.substring(0, 1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        newsItem.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        newsItem.authorDepartment,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                ),
              ],
            ),
          ),

          // News content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  newsItem.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  newsItem.content,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(newsItem.timestamp),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}

class NewsItem {
  final String id;
  final String title;
  final String content;
  final String authorName;
  final String authorDepartment;
  final Timestamp? timestamp;

  NewsItem({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    required this.authorDepartment,
    this.timestamp,
  });

  factory NewsItem.fromMap(Map<String, dynamic> map, String id) {
    return NewsItem(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      authorName: map['authorName'] ?? 'Unknown',
      authorDepartment: map['authorDepartment'] ?? '',
      timestamp: map['timestamp'],
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class News {
  final String id;
  final String title;
  final String content;
  final String category;
  final String authorId;
  final String authorName;
  final String authorRole;
  final DateTime timestamp;
  final String? imageUrl;
  final bool featured;
  final List<String> targetAudience; // e.g., ['student', 'lecturer']

  News({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.timestamp,
    this.imageUrl,
    this.featured = false,
    required this.targetAudience,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
      'featured': featured,
      'targetAudience': targetAudience,
    };
  }

  factory News.fromMap(String id, Map<String, dynamic> map) {
    return News(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      category: map['category'] ?? 'General',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? 'Unknown',
      authorRole: map['authorRole'] ?? 'staff',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      imageUrl: map['imageUrl'],
      featured: map['featured'] ?? false,
      targetAudience: List<String>.from(map['targetAudience'] ?? ['student']),
    );
  }

  News copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    String? authorId,
    String? authorName,
    String? authorRole,
    DateTime? timestamp,
    String? imageUrl,
    bool? featured,
    List<String>? targetAudience,
  }) {
    return News(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      featured: featured ?? this.featured,
      targetAudience: targetAudience ?? this.targetAudience,
    );
  }
}

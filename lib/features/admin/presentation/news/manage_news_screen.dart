import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../models/news.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../auth/provider/user_provider.dart';

class ManageNewsScreen extends StatefulWidget {
  final String? newsId; // If editing existing news

  const ManageNewsScreen({super.key, this.newsId});

  @override
  State<ManageNewsScreen> createState() => _ManageNewsScreenState();
}

class _ManageNewsScreenState extends State<ManageNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'General';
  List<String> _targetAudience = ['student']; // Default to targeting students
  bool _isFeatured = false;
  bool _isLoading = false;
  bool _isEdit = false;
  File? _imageFile;
  String? _existingImageUrl;
  News? _existingNews;

  final List<String> _categories = [
    'General',
    'Academic',
    'School Events',
    'Announcements',
    'Faculty News',
    'Sports',
    'Deadlines',
  ];

  final List<String> _audienceOptions = [
    'student',
    'lecturer',
  ];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.newsId != null;
    if (_isEdit) {
      _loadExistingNews();
    }
  }

  Future<void> _loadExistingNews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.newsId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        _existingNews = News.fromMap(docSnapshot.id, data);

        _titleController.text = _existingNews!.title;
        _contentController.text = _existingNews!.content;
        _selectedCategory = _existingNews!.category;
        _targetAudience = _existingNews!.targetAudience;
        _isFeatured = _existingNews!.featured;
        _existingImageUrl = _existingNews!.imageUrl;
      }
    } catch (e) {
      showCustomSnackBar(context, 'Error loading news: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _existingImageUrl;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('news_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(_imageFile!);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      showCustomSnackBar(
        context,
        'Error uploading image: $e',
        isError: true,
      );
      return null;
    }
  }

  Future<void> _saveNews() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user == null) {
        showCustomSnackBar(context, 'User not authenticated', isError: true);
        return;
      }

      final String? imageUrl = await _uploadImage();

      final newsCollection = FirebaseFirestore.instance.collection('news');

      final news = News(
        id: _isEdit ? widget.newsId! : '',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        authorId: user.uid,
        authorName: user.name,
        authorRole: user.role,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        featured: _isFeatured,
        targetAudience: _targetAudience,
      );

      if (_isEdit) {
        await newsCollection.doc(widget.newsId).update(news.toMap());
      } else {
        final docRef = await newsCollection.add(news.toMap());

        // Send notifications to all target audiences
        await _sendNewsNotifications(
          newsId: docRef.id,
          title: news.title,
          message: news.content.length > 100
              ? '${news.content.substring(0, 100)}...'
              : news.content,
          targetAudience: news.targetAudience,
          category: news.category,
        );
      }

      // ignore: use_build_context_synchronously
      showCustomSnackBar(
        context,
        _isEdit ? 'News updated successfully!' : 'News published successfully!',
      );

      // ignore: use_build_context_synchronously
      Navigator.pop(context, true);
    } catch (e) {
      showCustomSnackBar(
        context,
        'Error saving news: $e',
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendNewsNotifications({
    required String newsId,
    required String title,
    required String message,
    required List<String> targetAudience,
    required String category,
  }) async {
    try {
      // Get all users to send notifications
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: targetAudience)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      final notificationsRef =
          FirebaseFirestore.instance.collection('notifications');

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;

        final notificationDoc = notificationsRef.doc();
        batch.set(notificationDoc, {
          'recipientId': userId,
          'type': 'news',
          'title': title,
          'message': message,
          'sender': 'News System',
          'read': false,
          'timestamp': FieldValue.serverTimestamp(),
          'actionUrl': '/news/$newsId',
          'category': category,
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error sending notifications: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit News' : 'Create News'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image section
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : _existingImageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_existingImageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                          child: _imageFile == null && _existingImageUrl == null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add Cover Image',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'News Title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Target audience
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target Audience',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          children: _audienceOptions.map((String audience) {
                            return FilterChip(
                              label: Text(audience),
                              selected: _targetAudience.contains(audience),
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    _targetAudience.add(audience);
                                  } else {
                                    // Don't allow removing the last audience
                                    if (_targetAudience.length > 1) {
                                      _targetAudience.remove(audience);
                                    }
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Featured news toggle
                    SwitchListTile(
                      title: const Text('Feature this news'),
                      subtitle: const Text(
                          'Featured news will be highlighted on the home screen'),
                      value: _isFeatured,
                      activeColor: Colors.blue,
                      onChanged: (bool value) {
                        setState(() {
                          _isFeatured = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Content field
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Content',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 10,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some content';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveNews,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_isEdit ? 'Update News' : 'Publish News'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete News'),
        content: const Text(
            'Are you sure you want to delete this news? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              try {
                await FirebaseFirestore.instance
                    .collection('news')
                    .doc(widget.newsId)
                    .delete();

                // If there's an image, delete it from storage
                if (_existingImageUrl != null) {
                  try {
                    await FirebaseStorage.instance
                        .refFromURL(_existingImageUrl!)
                        .delete();
                  } catch (e) {
                    print('Error deleting image: $e');
                  }
                }

                // ignore: use_build_context_synchronously
                showCustomSnackBar(
                  context,
                  'News deleted successfully',
                );

                // ignore: use_build_context_synchronously
                Navigator.pop(context, true);
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });
                showCustomSnackBar(
                  context,
                  'Error deleting news: $e',
                  isError: true,
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

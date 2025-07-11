import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseAssignmentScreen extends StatefulWidget {
  const CourseAssignmentScreen({super.key});

  @override
  State<CourseAssignmentScreen> createState() => _CourseAssignmentScreenState();
}

class _CourseAssignmentScreenState extends State<CourseAssignmentScreen> {
  String? selectedDepartment;
  String? selectedLevel;
  bool isLoading = false;
  List<String> departments = [
    'Computer Science',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil Engineering'
  ];
  List<String> levels = ['100', '200', '300', '400'];
  List<Map<String, dynamic>> assignedCourses = [];

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _courseCodeController = TextEditingController();
  final _courseTitleController = TextEditingController();
  final _creditUnitsController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _courseCodeController.dispose();
    _courseTitleController.dispose();
    _creditUnitsController.dispose();
    super.dispose();
  }

  Future<void> fetchAssignedCourses() async {
    if (selectedDepartment == null || selectedLevel == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final coursesSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('department', isEqualTo: selectedDepartment)
          .where('level', isEqualTo: selectedLevel)
          .get();

      setState(() {
        assignedCourses = coursesSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'courseCode': data['courseCode'] ?? '',
            'courseTitle': data['courseTitle'] ?? '',
            'creditUnits': data['creditUnits'] ?? 0,
            'semester': data['semester'] ?? '',
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching assigned courses: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load courses: $e')),
      );
    }
  }

  void _showAddCourseDialog() {
    String? semester;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: LayoutBuilder(
          builder: (context, dialogConstraints) {
            final dialogWidth = dialogConstraints.maxWidth;
            final isWideDialog = dialogWidth >= 400;

            return Container(
              width: isWideDialog ? dialogWidth * 0.8 : dialogWidth,
              padding: EdgeInsets.all(dialogWidth * 0.04),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add New Course',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: dialogConstraints.maxHeight * 0.02),
                  Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _courseCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Course Code',
                              hintText: 'e.g., CSC101',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter course code';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: dialogConstraints.maxHeight * 0.02),
                          TextFormField(
                            controller: _courseTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Course Title',
                              hintText: 'e.g., Introduction to Computer Science',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter course title';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: dialogConstraints.maxHeight * 0.02),
                          TextFormField(
                            controller: _creditUnitsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Credit Units',
                              hintText: 'e.g., 3',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter credit units';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: dialogConstraints.maxHeight * 0.02),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Semester',
                              border: OutlineInputBorder(),
                            ),
                            value: semester,
                            items: const [
                              DropdownMenuItem(
                                value: 'First',
                                child: Text('First Semester'),
                              ),
                              DropdownMenuItem(
                                value: 'Second',
                                child: Text('Second Semester'),
                              ),
                            ],
                            onChanged: (value) {
                              semester = value;
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a semester';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: dialogConstraints.maxHeight * 0.03),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _courseCodeController.clear();
                          _courseTitleController.clear();
                          _creditUnitsController.clear();
                        },
                        child: const Text('CANCEL'),
                      ),
                      SizedBox(width: dialogWidth * 0.02),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate() &&
                              selectedDepartment != null &&
                              selectedLevel != null &&
                              semester != null) {
                            _addCourse(
                              courseCode: _courseCodeController.text.trim(),
                              courseTitle: _courseTitleController.text.trim(),
                              creditUnits: int.parse(_creditUnitsController.text.trim()),
                              semester: semester!,
                            );
                            Navigator.of(context).pop();
                            _courseCodeController.clear();
                            _courseTitleController.clear();
                            _creditUnitsController.clear();
                          } else if (selectedDepartment == null || selectedLevel == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please select department and level first')),
                            );
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('ADD COURSE'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _addCourse({
    required String courseCode,
    required String courseTitle,
    required int creditUnits,
    required String semester,
  }) async {
    if (selectedDepartment == null || selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select department and level first')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Check if course code already exists for this department and level
      final existingCourse = await FirebaseFirestore.instance
          .collection('courses')
          .where('courseCode', isEqualTo: courseCode)
          .where('department', isEqualTo: selectedDepartment)
          .where('level', isEqualTo: selectedLevel)
          .get();

      if (existingCourse.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Course code already exists for this department and level')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Add new course
      await FirebaseFirestore.instance.collection('courses').add({
        'courseCode': courseCode,
        'courseTitle': courseTitle,
        'creditUnits': creditUnits,
        'semester': semester,
        'department': selectedDepartment,
        'level': selectedLevel,
        'createdAt': FieldValue.serverTimestamp(),
      });

      fetchAssignedCourses();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course added successfully')),
      );
    } catch (e) {
      print('Error adding course: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add course: $e')),
      );
    }
  }

  Future<void> _deleteCourse(String id) async {
    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('courses').doc(id).delete();

      fetchAssignedCourses();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course deleted successfully')),
      );
    } catch (e) {
      print('Error deleting course: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete course: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Assignment'),
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth >= 600;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(constraints.maxWidth * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: EdgeInsets.all(constraints.maxWidth * 0.03),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assign Courses to Department & Level',
                            style: TextStyle(
                              fontSize: isWideScreen ? 20 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: constraints.maxHeight * 0.02),                          if (isWideScreen) ...[
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'Department',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 14),
                                      ),
                                      value: selectedDepartment,
                                      items: departments.map((dept) {
                                        return DropdownMenuItem(
                                          value: dept,
                                          child: Text(dept),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedDepartment = value;
                                        });
                                        fetchAssignedCourses();
                                      },
                                    ),
                                  ),
                                  SizedBox(width: constraints.maxWidth * 0.02),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'Level',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 14),
                                      ),
                                      value: selectedLevel,
                                      items: levels.map((level) {
                                        return DropdownMenuItem(
                                          value: level,
                                          child: Text('$level Level'),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedLevel = value;
                                        });
                                        fetchAssignedCourses();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[                            Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Department',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                  ),
                                  value: selectedDepartment,
                                  items: departments.map((dept) {
                                    return DropdownMenuItem(
                                      value: dept,
                                      child: Text(dept),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedDepartment = value;
                                    });
                                    fetchAssignedCourses();
                                  },
                                ),
                                SizedBox(height: constraints.maxHeight * 0.02),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Level',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                  ),
                                  value: selectedLevel,
                                  items: levels.map((level) {
                                    return DropdownMenuItem(
                                      value: level,
                                      child: Text('$level Level'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedLevel = value;
                                    });
                                    fetchAssignedCourses();
                                  },
                                ),
                              ],
                            ),
                          ],
                          SizedBox(height: constraints.maxHeight * 0.02),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  selectedDepartment != null && selectedLevel != null
                                      ? _showAddCourseDialog
                                      : null,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Course'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: constraints.maxHeight * 0.015,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.02),
                  Text(
                    'Assigned Courses',
                    style: TextStyle(
                      fontSize: isWideScreen ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.01),
                  SizedBox(
                    height: constraints.maxHeight * 0.6,
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : assignedCourses.isEmpty
                            ? _buildEmptyState()
                            : _buildCourseList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.school_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No courses assigned yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedDepartment == null || selectedLevel == null
                ? 'Please select a department and level'
                : 'Add courses using the button above',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseList() {
    return ListView.builder(
      itemCount: assignedCourses.length,
      itemBuilder: (context, index) {
        final course = assignedCourses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Text(
                  course['courseCode'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${course['creditUnits']} Units',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(course['courseTitle']),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${course['semester']} Semester',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(course['id']),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(String courseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: const Text(
          'Are you sure you want to delete this course? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCourse(courseId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageResultScreen extends StatefulWidget {
  const ManageResultScreen({super.key});

  @override
  State<ManageResultScreen> createState() => _ManageResultScreenState();
}

class _ManageResultScreenState extends State<ManageResultScreen> {
  String? selectedDepartment;
  String? selectedLevel;
  String? selectedCourse;
  bool isLoading = false;
  List<String> departments = [
    'Computer Science',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil Engineering'
  ];
  List<String> levels = ['100', '200', '300', '400'];
  List<String> courses = [];
  List<Map<String, dynamic>> students = [];
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  Future<void> fetchCourses() async {
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
        courses = coursesSnapshot.docs
            .map((doc) => doc.data()['courseCode'] as String)
            .toList();
        selectedCourse = courses.isNotEmpty ? courses[0] : null;
        isLoading = false;
      });

      if (selectedCourse != null) {
        fetchStudents();
      }
    } catch (e) {
      print('Error fetching courses: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load courses: $e')),
      );
    }
  }

  Future<void> fetchStudents() async {
    if (selectedDepartment == null || selectedLevel == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('department', isEqualTo: selectedDepartment)
          .where('level', isEqualTo: selectedLevel)
          .get();

      setState(() {
        students = studentsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown',
            'matricNumber': data['matricNumber'] ?? 'N/A',
            'score': 0,
            'grade': '',
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching students: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load students: $e')),
      );
    }
  }

  String calculateGrade(int score) {
    if (score >= 70) return 'A';
    if (score >= 60) return 'B';
    if (score >= 50) return 'C';
    if (score >= 45) return 'D';
    if (score >= 40) return 'E';
    return 'F';
  }

  Future<void> saveResults() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (var student in students) {
        final resultRef =
            FirebaseFirestore.instance.collection('results').doc();
        batch.set(resultRef, {
          'studentId': student['id'],
          'studentName': student['name'],
          'matricNumber': student['matricNumber'],
          'department': selectedDepartment,
          'level': selectedLevel,
          'course': selectedCourse,
          'score': student['score'],
          'grade': student['grade'],
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Results uploaded successfully')),
      );
    } catch (e) {
      print('Error saving results: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload results: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Student Results'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Course Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
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
                                selectedCourse = null;
                                courses = [];
                              });
                              fetchCourses();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
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
                                selectedCourse = null;
                                courses = [];
                              });
                              fetchCourses();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Course',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      value: selectedCourse,
                      items: courses.map((course) {
                        return DropdownMenuItem(
                          value: course,
                          child: Text(course),
                        );
                      }).toList(),
                      onChanged: courses.isEmpty
                          ? null
                          : (value) {
                              setState(() {
                                selectedCourse = value;
                              });
                              fetchStudents();
                            },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : students.isEmpty
                      ? _buildEmptyState()
                      : _buildStudentResultList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: students.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: saveResults,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Upload Results',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No students found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedDepartment == null || selectedLevel == null
                ? 'Please select a department and level'
                : 'No students enrolled for the selected criteria',
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

  Widget _buildStudentResultList() {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Student',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Matric No',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Score',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Grade',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: students.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey[300]),
              itemBuilder: (context, index) {
                final student = students[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          student['name'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          student['matricNumber'],
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          initialValue: student['score']?.toString() ?? '',
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final score = int.tryParse(value);
                            if (score == null) {
                              return 'Invalid';
                            }
                            if (score < 0 || score > 100) {
                              return 'Invalid';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            final score = int.tryParse(value) ?? 0;
                            setState(() {
                              students[index]['score'] = score;
                              students[index]['grade'] = calculateGrade(score);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getGradeColor(student['grade'] ?? ''),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            student['grade'] ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green[700]!;
      case 'B':
        return Colors.blue[700]!;
      case 'C':
        return Colors.orange[700]!;
      case 'D':
        return Colors.deepOrange[700]!;
      case 'E':
        return Colors.deepOrange[900]!;
      case 'F':
        return Colors.red[700]!;
      default:
        return Colors.grey[600]!;
    }
  }
}

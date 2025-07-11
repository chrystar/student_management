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
  bool _isBulkSaving = false;

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
          .where('role', isEqualTo: 'Student') // Changed from 'student' to 'Student'
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

  Future<void> saveStudentResult(Map<String, dynamic> student) async {
    if (selectedCourse == null) return;

    try {
      final resultRef = FirebaseFirestore.instance
          .collection('results')
          .doc('${student['id']}_${selectedCourse}');

      await resultRef.set({
        'studentId': student['id'],
        'studentName': student['name'],
        'matricNumber': student['matricNumber'],
        'department': selectedDepartment,
        'level': selectedLevel,
        'course': selectedCourse,
        'score': student['score'],
        'grade': student['grade'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Result saved successfully')),
      );
    } catch (e) {
      print('Error saving result: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save result: $e')),
      );
    }
  }

  // Bulk save all results at once
  Future<void> bulkSaveResults() async {
    if (selectedCourse == null || students.isEmpty) return;

    setState(() {
      _isBulkSaving = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      int savedCount = 0;

      for (final student in students) {
        if (student['score'] > 0) { // Only save students with scores
          final resultRef = FirebaseFirestore.instance
              .collection('results')
              .doc('${student['id']}_${selectedCourse}');

          batch.set(resultRef, {
            'studentId': student['id'],
            'studentName': student['name'],
            'matricNumber': student['matricNumber'],
            'department': selectedDepartment,
            'level': selectedLevel,
            'course': selectedCourse,
            'score': student['score'],
            'grade': student['grade'],
            'semester': _getCurrentSemester(),
            'academicYear': _getCurrentAcademicYear(),
            'uploadedBy': 'Admin', // You can get actual admin name if needed
            'updatedAt': FieldValue.serverTimestamp(),
          });
          savedCount++;
        }
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully saved $savedCount results')),
      );
    } catch (e) {
      print('Error bulk saving results: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save results: $e')),
      );
    } finally {
      setState(() {
        _isBulkSaving = false;
      });
    }
  }

  // Helper methods for semester and academic year
  String _getCurrentSemester() {
    final month = DateTime.now().month;
    return month >= 9 || month <= 1 ? 'First Semester' : 'Second Semester';
  }

  String _getCurrentAcademicYear() {
    final year = DateTime.now().year;
    final month = DateTime.now().month;
    return month >= 9 ? '$year/${year + 1}' : '${year - 1}/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Student Results'),
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(constraints.maxWidth * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: LayoutBuilder(
                        builder: (context, cardConstraints) {
                          final isWideScreen = cardConstraints.maxWidth >= 600;
                          return Column(
                            children: [
                              if (isWideScreen)
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: selectedDepartment,
                                        decoration: const InputDecoration(
                                            labelText: 'Department'),
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
                                            courses.clear();
                                            fetchCourses();
                                          });
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                        width: cardConstraints.maxWidth * 0.02),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: selectedLevel,
                                        decoration:
                                            const InputDecoration(labelText: 'Level'),
                                        items: levels.map((level) {
                                          return DropdownMenuItem(
                                            value: level,
                                            child: Text(level),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedLevel = value;
                                            selectedCourse = null;
                                            courses.clear();
                                            fetchCourses();
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    DropdownButtonFormField<String>(
                                      value: selectedDepartment,
                                      decoration: const InputDecoration(
                                          labelText: 'Department'),
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
                                          courses.clear();
                                          fetchCourses();
                                        });
                                      },
                                    ),
                                    SizedBox(height: 16),
                                    DropdownButtonFormField<String>(
                                      value: selectedLevel,
                                      decoration: const InputDecoration(
                                          labelText: 'Level'),
                                      items: levels.map((level) {
                                        return DropdownMenuItem(
                                          value: level,
                                          child: Text(level),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedLevel = value;
                                          selectedCourse = null;
                                          courses.clear();
                                          fetchCourses();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: selectedCourse,
                                decoration: const InputDecoration(labelText: 'Course'),
                                items: courses.map((course) {
                                  return DropdownMenuItem(
                                    value: course,
                                    child: Text(course),
                                  );
                                }).toList(),
                                onChanged: courses.isEmpty ? null : (value) {
                                  setState(() {
                                    selectedCourse = value;
                                    fetchStudents();
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.02),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (students.isNotEmpty) ...[
                    Card(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Matric Number')),
                            DataColumn(label: Text('Score')),
                            DataColumn(label: Text('Grade')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: students.map((student) {
                            return DataRow(
                              cells: [
                                DataCell(Text(student['name'])),
                                DataCell(Text(student['matricNumber'])),
                                DataCell(
                                  SizedBox(
                                    width: 80,
                                    child: TextFormField(
                                      initialValue: student['score'].toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      onChanged: (value) {
                                        final score = int.tryParse(value) ?? 0;
                                        setState(() {
                                          student['score'] = score;
                                          student['grade'] = calculateGrade(score);
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getGradeColor(student['grade']),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      student['grade'].toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  ElevatedButton(
                                    onPressed: () => saveStudentResult(student),
                                    child: const Text('Save'),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.02),
                    // Bulk actions card
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Bulk Save Results',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _isBulkSaving ? null : bulkSaveResults,
                              child: _isBulkSaving
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.0,
                                    )
                                  : const Text('Save All Results'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]
                  else if (selectedDepartment != null && selectedLevel != null)
                    const Center(
                      child: Text('No students found for the selected criteria.'),
                    ),
                  SizedBox(height: constraints.maxHeight * 0.02),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Bulk Save Results',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isBulkSaving ? null : bulkSaveResults,
                            child: _isBulkSaving
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  )
                                : const Text('Save All Results'),
                          ),
                        ],
                      ),
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

  String calculateGrade(int score) {
    if (score >= 70) return 'A';
    if (score >= 60) return 'B';
    if (score >= 50) return 'C';
    if (score >= 45) return 'D';
    if (score >= 40) return 'E';
    return 'F';
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.yellow[700]!;
      case 'D':
        return Colors.orange;
      case 'E':
        return Colors.red[300]!;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

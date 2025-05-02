import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../../features/auth/provider/user_provider.dart';

class CourseRegistration extends StatefulWidget {
  const CourseRegistration({super.key});

  @override
  State<CourseRegistration> createState() => _CourseRegistrationState();
}

class _CourseRegistrationState extends State<CourseRegistration>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  List<Map<String, dynamic>> availableCourses = [];
  List<Map<String, dynamic>> registeredCourses = [];
  late TabController _tabController;
  String? department;
  String? level;
  int totalCreditUnits = 0;
  final int maxCreditUnits = 24;
  String _debugMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeUserData() {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      print(
          'DEBUG: User data found: ${user.name}, ${user.department}, ${user.level}');
      setState(() {
        department = user.department;
        level = user.level;
        if (department == null || department!.isEmpty) {
          _debugMessage = 'Your department is not set. Please contact admin.';
        } else if (level == null || level!.isEmpty) {
          _debugMessage = 'Your level is not set. Please contact admin.';
        }
      });

      // Add a slight delay to ensure Firestore is ready
      Future.delayed(const Duration(milliseconds: 300), () {
        _fetchAvailableCourses();
        _fetchRegisteredCourses();
      });
    } else {
      print('DEBUG: User data is null');
      setState(() {
        isLoading = false;
        _debugMessage =
            'Unable to load user data. Please try logging in again.';
      });
    }
  }

  Future<void> _fetchAvailableCourses() async {
    if (department == null ||
        department!.isEmpty ||
        level == null ||
        level!.isEmpty) {
      print('DEBUG: Department or level is null/empty, cannot fetch courses');
      setState(() {
        isLoading = false;
        if (_debugMessage.isEmpty) {
          _debugMessage = 'Missing department or level information';
        }
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      print(
          'DEBUG: Fetching courses for department: $department, level: $level');

      final snapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('department', isEqualTo: department)
          .where('level', isEqualTo: level)
          .get();

      print('DEBUG: Found ${snapshot.docs.length} courses');

      final courses = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'courseCode': data['courseCode'] ?? '',
          'courseTitle': data['courseTitle'] ?? '',
          'creditUnits': data['creditUnits'] ?? 0,
          'semester': data['semester'] ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          availableCourses = courses;
          isLoading = false;
          if (courses.isEmpty) {
            _debugMessage = 'No courses found for $department, level $level';
          } else {
            _debugMessage = '';
          }
        });
      }
    } catch (e) {
      print('Error fetching available courses: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          _debugMessage = 'Error loading courses: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load courses: $e')),
        );
      }
    }
  }

  Future<void> _fetchRegisteredCourses() async {
    if (department == null || level == null) return;

    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('registrations')
          .where('studentId', isEqualTo: user.uid)
          .where('level', isEqualTo: level)
          .get();

      final List<Map<String, dynamic>> registeredList = [];
      int totalUnits = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final courseId = data['courseId'];

        // Get course details
        final courseDoc = await FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .get();

        if (courseDoc.exists) {
          final courseData = courseDoc.data()!;
          final credits = courseData['creditUnits'] as num ?? 0;
          totalUnits += credits.toInt();

          registeredList.add({
            'id': doc.id,
            'courseId': courseId,
            'courseCode': courseData['courseCode'] ?? '',
            'courseTitle': courseData['courseTitle'] ?? '',
            'creditUnits': credits,
            'semester': courseData['semester'] ?? '',
            'registrationDate': data['timestamp'],
          });
        }
      }

      setState(() {
        registeredCourses = registeredList;
        totalCreditUnits = totalUnits;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching registered courses: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _registerCourse(
      String courseId, int creditUnits, String courseCode) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;

    // Check if exceeding max credit units
    if (totalCreditUnits + creditUnits > maxCreditUnits) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Cannot register more than $maxCreditUnits credit units')),
      );
      return;
    }

    // Check if already registered
    final existingCourse =
        registeredCourses.any((course) => course['courseId'] == courseId);
    if (existingCourse) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are already registered for $courseCode')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('registrations').add({
        'studentId': user.uid,
        'studentName': user.name,
        'matricNumber': user.matricNumber,
        'department': department,
        'level': level,
        'courseId': courseId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully registered for $courseCode')),
      );

      _fetchRegisteredCourses();
    } catch (e) {
      print('Error registering for course: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to register for course: $e')),
      );
    }
  }

  Future<void> _dropCourse(
      String registrationId, String courseCode, int creditUnits) async {
    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('registrations')
          .doc(registrationId)
          .delete();

      setState(() {
        totalCreditUnits -= creditUnits;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully dropped $courseCode')),
      );

      _fetchRegisteredCourses();
    } catch (e) {
      print('Error dropping course: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to drop course: $e')),
      );
    }
  }

  void _showDropConfirmation(
      String registrationId, String courseCode, int creditUnits) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Drop Course'),
        content: Text('Are you sure you want to drop $courseCode?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _dropCourse(registrationId, courseCode, creditUnits);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DROP'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Registration'),
        automaticallyImplyLeading: false,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Available Courses'),
            Tab(text: 'Registered Courses'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _debugMessage.isNotEmpty
              ? _buildErrorMessage()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAvailableCoursesTab(),
                    _buildRegisteredCoursesTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 80,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              'Information Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _debugMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeUserData,
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableCoursesTab() {
    if (availableCourses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.school_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'No courses available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No courses have been assigned to your department and level yet.\nPlease check back later.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Maximum: $maxCreditUnits units. Registered: $totalCreditUnits units',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: availableCourses.length,
            itemBuilder: (context, index) {
              final course = availableCourses[index];
              final bool isRegistered = registeredCourses.any(
                (regCourse) => regCourse['courseId'] == course['id'],
              );

              return _buildCourseCard(
                course: course,
                isRegistered: isRegistered,
                onPressed: isRegistered
                    ? null
                    : () => _registerCourse(
                          course['id'],
                          course['creditUnits'],
                          course['courseCode'],
                        ),
                buttonText: isRegistered ? 'Registered' : 'Register',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRegisteredCoursesTab() {
    if (registeredCourses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'No registered courses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                availableCourses.isEmpty
                    ? 'No courses have been assigned to your department and level yet.'
                    : 'Go to Available Courses tab to register for courses.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Total: $totalCreditUnits of $maxCreditUnits credit units',
                  style: const TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: registeredCourses.length,
            itemBuilder: (context, index) {
              final course = registeredCourses[index];
              final timestamp = course['registrationDate'] as Timestamp?;
              final registrationDate = timestamp != null
                  ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}'
                  : 'Recently';

              return _buildCourseCard(
                course: course,
                isRegistered: true,
                registrationDate: registrationDate,
                onPressed: () => _showDropConfirmation(
                  course['id'],
                  course['courseCode'],
                  course['creditUnits'],
                ),
                buttonText: 'Drop Course',
                isDropButton: true,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard({
    required Map<String, dynamic> course,
    required bool isRegistered,
    String? registrationDate,
    required VoidCallback? onPressed,
    required String buttonText,
    bool isDropButton = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  course['courseCode'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildChip(
                  text: '${course['creditUnits'] ?? 0} Units',
                  bgColor: Colors.blue.shade50,
                  textColor: Colors.blue.shade700,
                ),
                _buildChip(
                  text: '${course['semester'] ?? ''} Sem',
                  bgColor: course['semester'] == 'First'
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  textColor: course['semester'] == 'First'
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              course['courseTitle'] ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            if (registrationDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Registered on: $registrationDate',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (isDropButton)
              OutlinedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: Text(buttonText),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              )
            else
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRegistered
                      ? Colors.grey.shade300
                      : Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    color: isRegistered ? Colors.grey.shade700 : Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String text,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
        ),
      ),
    );
  }
}

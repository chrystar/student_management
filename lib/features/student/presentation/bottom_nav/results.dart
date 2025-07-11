import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../auth/provider/user_provider.dart';

class Results extends StatefulWidget {
  const Results({super.key});

  @override
  State<Results> createState() => _ResultsState();
}

class _ResultsState extends State<Results> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedSemester = 'All Semesters';
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasNoResults = false;
  Map<String, List<Map<String, dynamic>>> _resultsBySemester = {};
  double _gpa = 0.0;
  Map<String, double> _gradeDistribution = {
    'A': 0,
    'B': 0,
    'C': 0,
    'D': 0,
    'E': 0,
    'F': 0,
  };
  List<String> _semesters = ['All Semesters', 'First Semester', 'Second Semester'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Delay to allow the widget to fully build
    Future.delayed(Duration.zero, () {
      _fetchResults();
    });
    
    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchResults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasNoResults = false;
    });

    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User data not available. Please log in again.';
        });
        return;
      }

      // First, get all course registrations for this student
      final registrationsSnapshot = await FirebaseFirestore.instance
          .collection('registrations')
          .where('studentId', isEqualTo: user.uid)
          .get();

      if (registrationsSnapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasNoResults = true;
        });
        return;
      }

      // Extract registered course codes and create a map with semester and credit units
      final registrationMap = <String, Map<String, dynamic>>{};
      for (var doc in registrationsSnapshot.docs) {
        final data = doc.data();
        final courseCode = data['courseCode'] as String;
        registrationMap[courseCode] = {
          'semester': data['semester'] as String? ?? 'Unknown',
          'creditUnits': data['creditUnits'] as int? ?? 0,
        };
      }

      final registeredCourseCodes = registrationMap.keys.toSet();

      // Now get results for this student
      final resultsSnapshot = await FirebaseFirestore.instance
          .collection('results')
          .where('studentId', isEqualTo: user.uid)
          .get();

      if (resultsSnapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasNoResults = true;
        });
        return;
      }

      // Filter results to only include registered courses
      final validResults = resultsSnapshot.docs.where((doc) {
        final data = doc.data();
        final courseCode = data['courseCode'] as String? ?? data['course'] as String?;
        return courseCode != null && registeredCourseCodes.contains(courseCode);
      }).toList();

      if (validResults.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasNoResults = true;
        });
        return;
      }

      // Process results
      Map<String, List<Map<String, dynamic>>> resultsBySemester = {
        'All Semesters': [],
        'First Semester': [],
        'Second Semester': [],
      };

      // Process each valid result
      for (var doc in validResults) {
        final data = doc.data();
        final courseCode = data['courseCode'] as String? ?? data['course'] as String? ?? 'Unknown';
        
        // Get registration data for this course
        final registrationData = registrationMap[courseCode];
        final semester = registrationData?['semester'] ?? 'Unknown';
        final creditUnits = registrationData?['creditUnits'] ?? 0;

        // Debug print to check data
        print('Course: $courseCode, Registration Semester: $semester, Result Semester: ${data['semester']}, Credit Units: $creditUnits');

        final resultMap = {
          'id': doc.id,
          'courseCode': courseCode,
          'courseTitle': data['courseTitle'] ?? 'Unknown Course',
          'creditUnits': creditUnits,
          'score': data['score'] ?? 0,
          'grade': data['grade'] ?? 'F',
          'semester': semester,
          'academicYear': data['academicYear'] ?? 'Unknown',
        };

        // Add to all semesters list
        resultsBySemester['All Semesters']!.add(resultMap);

        // Add to specific semester list
        if (semester == 'First Semester') {
          resultsBySemester['First Semester']!.add(resultMap);
        } else if (semester == 'Second Semester') {
          resultsBySemester['Second Semester']!.add(resultMap);
        }
      }

      // Calculate GPA and grade distribution for all semesters initially
      _calculateStats(resultsBySemester['All Semesters']!);

      setState(() {
        _resultsBySemester = resultsBySemester;
        _isLoading = false;
        _animationController.forward();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch results: ${e.toString()}';
      });
    }
  }

  void _calculateStats(List<Map<String, dynamic>> results) {
    if (results.isEmpty) {
      _gpa = 0.0;
      return;
    }

    // Reset grade distribution
    _gradeDistribution = {
      'A': 0,
      'B': 0,
      'C': 0,
      'D': 0,
      'E': 0,
      'F': 0,
    };

    int totalPoints = 0;
    int totalUnits = 0;

    for (var result in results) {
      final grade = result['grade'];
      final units = result['creditUnits'] as int? ?? 0;

      // Update grade distribution
      if (_gradeDistribution.containsKey(grade)) {
        _gradeDistribution[grade] = (_gradeDistribution[grade] ?? 0) + 1;
      }

      // Calculate GPA points
      int points;
      switch (grade) {
        case 'A':
          points = 5;
          break;
        case 'B':
          points = 4;
          break;
        case 'C':
          points = 3;
          break;
        case 'D':
          points = 2;
          break;
        case 'E':
          points = 1;
          break;
        case 'F':
          points = 0;
          break;
        default:
          points = 0;
      }

      totalPoints += points * units;
      totalUnits += units;
    }

    _gpa = totalUnits > 0 ? totalPoints / totalUnits : 0.0;
  }

  void _onSemesterChanged(String? value) {
    if (value != null && value != _selectedSemester) {
      setState(() {
        _selectedSemester = value;
        final selectedResults = _resultsBySemester[_selectedSemester] ?? [];
        _calculateStats(selectedResults);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Academic Results',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _hasNoResults
              ? _buildSimpleNoResultsView()
              : _errorMessage != null
                  ? _buildErrorView()
                  : _buildResultsView(),
    );
  }

  Widget _buildErrorView() {
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
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchResults,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleNoResultsView() {
    return RefreshIndicator(
      onRefresh: _fetchResults,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              
              // Animated icon
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + (_animationController.value * 0.2),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        size: 80,
                        color: Colors.green,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              
              // Main title
              Text(
                'No Results Yet',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              
              // Encouraging message
              Text(
                'Register for courses to see your results here!',
                style: TextStyle(
                  fontSize: 18,
                  color:  Colors.green,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Information message
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.green,
                      size: 32,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'What happens next?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '• Register for courses in the Registration tab\n'
                      '• Attend classes and take your exams\n'
                      '• Results will appear here after grading\n'
                      '• Only courses you registered for will show results',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Action button
              ElevatedButton.icon(
                onPressed: () {
                  _animationController.reset();
                  _fetchResults();
                  _animationController.forward();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Check Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Footer tip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.green.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: Pull down to refresh this page anytime to check for new results.',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 14,
                        ),
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
  }

  Widget _buildResultsView() {
    final currentResults = _resultsBySemester[_selectedSemester] ?? [];
    final hasResults = currentResults.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _fetchResults,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSemesterSelector(),
            const SizedBox(height: 24),
            if (hasResults) ...[
              _buildResultsList(),
            ] else
              _buildNoResultsForSemester(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterSelector() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuad,
      )),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Semester',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedSemester,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              items: _semesters.map((String semester) {
                return DropdownMenuItem<String>(
                  value: semester,
                  child: Text(semester),
                );
              }).toList(),
              onChanged: _onSemesterChanged,
            ),
          ],
        ),
      ),
    );
  }


 
  Color _getGpaColor(double gpa) {
    if (gpa >= 4.5) return Colors.purple;
    if (gpa >= 3.5) return Colors.green;
    if (gpa >= 2.5) return Colors.blue;
    if (gpa >= 1.5) return Colors.orange;
    return Colors.red;
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.purple;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.green;
      case 'D':
        return Colors.orange;
      case 'E':
        return Colors.amber;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildResultsList() {
    final results = _resultsBySemester[_selectedSemester] ?? [];

    if (results.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'No results available for this semester',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutQuad),
      )),
      child: FadeTransition(
        opacity: _animationController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Course Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Grading scale info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Grading Scale: A (70-100) • B (60-69) • C (50-59) • D (45-49) • E (40-44) • F (0-39)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                  headingRowHeight: 56,
                  dataRowHeight: 64,
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  dataTextStyle: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  columnSpacing: 20,
                  horizontalMargin: 16,
                  dividerThickness: 1,
                  border: TableBorder.all(
                    color: Colors.grey.shade200,
                    width: 1,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  columns: [
                    const DataColumn(label: Text('Course Code')),
                    const DataColumn(label: Text('Course Title')),
                    const DataColumn(label: Text('Units')),
                    const DataColumn(label: Text('Score')),
                    const DataColumn(label: Text('Grade')),
                    const DataColumn(label: Text('Remark')),
                    if (_selectedSemester == 'All Semesters')
                      const DataColumn(label: Text('Semester')),
                  ],
                  rows: results.map((result) {
                    final courseCode = result['courseCode'];
                    final courseTitle = result['courseTitle'];
                    final grade = result['grade'];
                    final score = result['score'];
                    final creditUnits = result['creditUnits'];
                    final semester = result['semester'];

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            courseCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: Text(
                              courseTitle,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$creditUnits',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '$score%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(score),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _getGradeColor(grade).withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getGradeColor(grade),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              grade,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getGradeColor(grade),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getGradeColor(grade).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getGradeDescription(grade),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getGradeColor(grade),
                              ),
                            ),
                          ),
                        ),
                        if (_selectedSemester == 'All Semesters')
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                semester.replaceAll(' Semester', ''),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Summary section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    'Total Courses',
                    '${results.length}',
                    Icons.menu_book,
                    Colors.blue,
                  ),
                  _buildSummaryItem(
                    'Total Units',
                    '${results.fold<int>(0, (sum, result) => sum + (result['creditUnits'] as int? ?? 0))}',
                    Icons.grain,
                    Colors.green,
                  ),
                  _buildSummaryItem(
                    'Average Score',
                    '${results.isEmpty ? 0 : (results.fold<int>(0, (sum, result) => sum + (result['score'] as int? ?? 0)) / results.length).round()}%',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                  _buildSummaryItem(
                    'GPA',
                    _gpa.toStringAsFixed(2),
                    Icons.star,
                    _getGpaColor(_gpa),
                  ),
                ],
              ),
            ),
          ],
        ),
      ));
  }

  String _getGradeDescription(String grade) {
    switch (grade) {
      case 'A':
        return 'Excellent';
      case 'B':
        return 'Very Good';
      case 'C':
        return 'Good';
      case 'D':
        return 'Satisfactory';
      case 'E':
        return 'Pass';
      case 'F':
        return 'Fail';
      default:
        return '';
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 50) return Colors.orange;
    if (score >= 45) return Colors.amber;
    return Colors.red;
  }

  Widget _buildNoResultsForSemester() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          Text(
            'No Results for ${_selectedSemester}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          // Message
          Text(
            _selectedSemester == 'All Semesters'
                ? 'You haven\'t received any results yet. Make sure you are registered for courses.'
                : 'Results for ${_selectedSemester.toLowerCase()} haven\'t been uploaded yet.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Information box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'What to do next?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedSemester == 'All Semesters'
                      ? '• Register for courses in the Registration tab\n• Attend classes and complete assessments\n• Check back after exams are completed'
                      : '• Check with your lecturers about result upload timeline\n• Results typically appear 2-4 weeks after exams\n• Switch to "All Semesters" to see available results',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Refresh button
          ElevatedButton.icon(
            onPressed: () {
              _fetchResults();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh Results'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

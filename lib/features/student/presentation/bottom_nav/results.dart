import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../auth/provider/user_provider.dart';
import 'package:fl_chart/fl_chart.dart';

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
  List<String> _semesters = ['All Semesters'];

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

      final snapshot = await FirebaseFirestore.instance
          .collection('results')
          .where('studentId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No results found.';
        });
        return;
      }

      // Process results
      Map<String, List<Map<String, dynamic>>> resultsBySemester = {
        'All Semesters': [],
      };

      // Track unique semesters
      Set<String> semestersSet = {};

      // Process each result
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final semester = data['semester'] as String? ?? 'Unknown';
        semestersSet.add(semester);

        final resultMap = {
          'id': doc.id,
          'courseCode': data['courseCode'] ?? 'Unknown',
          'courseTitle': data['courseTitle'] ?? 'Unknown Course',
          'creditUnits': data['creditUnits'] ?? 0,
          'score': data['score'] ?? 0,
          'grade': data['grade'] ?? 'F',
          'semester': semester,
          'academicYear': data['academicYear'] ?? 'Unknown',
        };

        // Add to all semesters list
        resultsBySemester['All Semesters']!.add(resultMap);

        // Add to specific semester list
        if (!resultsBySemester.containsKey(semester)) {
          resultsBySemester[semester] = [];
        }
        resultsBySemester[semester]!.add(resultMap);
      }

      // Convert set to list and sort semesters
      List<String> semesters = ['All Semesters', ...semestersSet.toList()];
      semesters.sort((a, b) {
        if (a == 'All Semesters') return -1;
        if (b == 'All Semesters') return 1;
        return a.compareTo(b);
      });

      // Calculate GPA and grade distribution for all semesters
      _calculateStats(resultsBySemester['All Semesters']!);

      setState(() {
        _resultsBySemester = resultsBySemester;
        _semesters = semesters;
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
        _calculateStats(_resultsBySemester[_selectedSemester] ?? []);
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

  Widget _buildResultsView() {
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
            _buildPerformanceCards(),
            const SizedBox(height: 24),
            _buildGradeDistributionChart(),
            const SizedBox(height: 24),
            _buildResultsList(),
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

  Widget _buildPerformanceCards() {
    final results = _resultsBySemester[_selectedSemester] ?? [];
    final totalCourses = results.length;
    final passedCourses = results.where((r) => r['grade'] != 'F').length;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutQuad),
      )),
      child: FadeTransition(
        opacity: _animationController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'GPA',
                    value: _gpa.toStringAsFixed(2),
                    icon: Icons.star,
                    color: _getGpaColor(_gpa),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Courses',
                    value: '$totalCourses',
                    icon: Icons.menu_book,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Success Rate',
                    value: totalCourses > 0
                        ? '${(passedCourses / totalCourses * 100).round()}%'
                        : '0%',
                    icon: Icons.timeline,
                    color: Colors.green,
                  ),
                ),
              ],
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGradeDistributionChart() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOutQuad),
      )),
      child: FadeTransition(
        opacity: _animationController,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.pie_chart,
                      color: Colors.deepPurple,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Grade Distribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: _buildBarChart(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final results = _resultsBySemester[_selectedSemester] ?? [];
    if (results.isEmpty) {
      return const Center(
        child: Text(
          'No data available for this semester',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: _gradeDistribution.entries.map((entry) {
          final index = ['A', 'B', 'C', 'D', 'E', 'F'].indexOf(entry.key);
          final color = _getGradeColor(entry.key);

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: color,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final grades = ['A', 'B', 'C', 'D', 'E', 'F'];
                return Text(
                  grades[value.toInt()],
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
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
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                final courseCode = result['courseCode'];
                final courseTitle = result['courseTitle'];
                final grade = result['grade'];
                final score = result['score'];
                final creditUnits = result['creditUnits'];
                final semester = result['semester'];
                final academicYear = result['academicYear'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    courseCode,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    courseTitle,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '$creditUnits Units',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (_selectedSemester == 'All Semesters')
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.purple.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            semester,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.purple,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color:
                                        _getGradeColor(grade).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _getGradeColor(grade),
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    grade,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: _getGradeColor(grade),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$score%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _getScoreColor(score),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(color: Colors.grey.withOpacity(0.2)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              academicYear,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              _getGradeDescription(grade),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getGradeColor(grade),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
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
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/provider/user_provider.dart';

class LecturerRegistrationsTab extends StatelessWidget {
  const LecturerRegistrationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF3E64FF),
          ),
        ),
      );
    }

    // Debug print the user info
    print("RegistrationsTab - User name: ${user.name}");

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF3E64FF),
          title: const Text(
            'Course Registrations',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xDDFFFFFF),
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(
                icon: Icon(Icons.book),
                text: 'My Courses',
              ),
              Tab(
                icon: Icon(Icons.people),
                text: 'Students',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Courses Tab with enhanced UI
            _buildCoursesTab(user, context),

            // Students Tab with enhanced UI
            _buildStudentsTab(user, context),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesTab(dynamic user, BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: const BoxDecoration(
            color: Color(0xFF3E64FF),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.school, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                "Course Enrollment Summary",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  // Remove the filter here and do client-side filtering
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF3E64FF)),
                        SizedBox(height: 16),
                        Text("Loading your courses...",
                            style: TextStyle(
                                color: Color(0xFF3E64FF),
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.content_paste_off,
                            size: 80, color: Colors.grey.withOpacity(0.6)),
                        const SizedBox(height: 16),
                        const Text(
                          "No courses available yet",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            "Create new courses in the Home tab to see enrollment data",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter courses manually to match the user name
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['createdBy'] == user.name;
                }).toList();

                print(
                    "RegistrationsTab - Found ${filteredDocs.length} courses for ${user.name}");

                // Get the list of course IDs for the summary calculation
                final List<String> courseIds =
                    filteredDocs.map((doc) => doc.id).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.content_paste_off,
                            size: 80, color: Colors.grey.withOpacity(0.6)),
                        const SizedBox(height: 16),
                        const Text(
                          "You haven't created any courses yet",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            "Create courses in the Home tab to see enrollment data",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Enrollment Summary Card
                    _buildEnrollmentSummaryCard(courseIds, context),

                    const SizedBox(height: 16),

                    // Courses List
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final course = filteredDocs[index];
                          final courseData =
                              course.data() as Map<String, dynamic>;

                          // Generate a color based on the index for visual variety
                          final List<Color> courseColors = [
                            const Color(0xFF4CAF50), // Green
                            const Color(0xFFF44336), // Red
                            const Color(0xFF9C27B0), // Purple
                            const Color(0xFF2196F3), // Blue
                            const Color(0xFFFF9800), // Orange
                          ];

                          final color =
                              courseColors[index % courseColors.length];

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.8),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child:
                                            Icon(Icons.menu_book, color: color),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              courseData['title'] ?? 'No Title',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              "Code: ${courseData['code'] ?? 'No Code'}",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Semester: ${courseData['semester'] ?? 'Unknown'}",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('course_registrations')
                                            .where('courseId',
                                                isEqualTo: course.id)
                                            .snapshots(),
                                        builder: (context, regSnapshot) {
                                          final count = regSnapshot.hasData
                                              ? regSnapshot.data!.docs.length
                                              : 0;

                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 16),
                                            decoration: BoxDecoration(
                                              color: count > 0
                                                  ? Colors.green
                                                      .withOpacity(0.1)
                                                  : Colors.grey
                                                      .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: count > 0
                                                    ? Colors.green
                                                        .withOpacity(0.3)
                                                    : Colors.grey
                                                        .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  "Enrolled Students",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: count > 0
                                                        ? Colors.green
                                                        : Colors.grey,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Text(
                                                    count.toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentSummaryCard(
      List<String> courseIds, BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('course_registrations')
          .where('courseId', whereIn: courseIds.isEmpty ? ['dummy'] : courseIds)
          .snapshots(),
      builder: (context, snapshot) {
        final totalStudents = snapshot.hasData ? snapshot.data!.docs.length : 0;
        final totalCourses = courseIds.length;

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  "Enrollment Summary",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E64FF),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      icon: Icons.menu_book,
                      value: totalCourses.toString(),
                      label: "Courses",
                      color: Colors.blue,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    _buildSummaryItem(
                      icon: Icons.people,
                      value: totalStudents.toString(),
                      label: "Students",
                      color: Colors.green,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    _buildSummaryItem(
                      icon: Icons.bar_chart,
                      value: totalCourses > 0
                          ? (totalStudents / totalCourses).toStringAsFixed(1)
                          : "0",
                      label: "Avg/Course",
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
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
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsTab(dynamic user, BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: const BoxDecoration(
            color: Color(0xFF3E64FF),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.people, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                "Enrolled Students",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  // Use no filter here
                  .snapshots(),
              builder: (context, coursesSnapshot) {
                if (!coursesSnapshot.hasData) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF3E64FF)),
                        SizedBox(height: 16),
                        Text("Loading enrollments...",
                            style: TextStyle(
                                color: Color(0xFF3E64FF),
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }

                // Filter courses to those created by this lecturer
                final filteredCourses = coursesSnapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['createdBy'] == user.name;
                }).toList();

                final courseIds = filteredCourses.map((doc) => doc.id).toList();

                if (courseIds.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined,
                            size: 80, color: Colors.grey.withOpacity(0.6)),
                        const SizedBox(height: 16),
                        const Text(
                          "No courses created yet",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('course_registrations')
                      .where('courseId', whereIn: courseIds)
                      .snapshots(),
                  builder: (context, registrationsSnapshot) {
                    if (!registrationsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (registrationsSnapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_outlined,
                                size: 80, color: Colors.grey.withOpacity(0.6)),
                            const SizedBox(height: 16),
                            const Text(
                              "No students registered",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32.0),
                              child: Text(
                                "Students will appear here after they enroll in your courses",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: registrationsSnapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final registration =
                            registrationsSnapshot.data!.docs[index].data()
                                as Map<String, dynamic>;

                        final registrationDate =
                            (registration['registeredAt'] as Timestamp)
                                .toDate();

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      const Color(0xFF3E64FF).withOpacity(0.8),
                                  radius: 24,
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        registration['studentName'] ??
                                            'Unknown Student',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3E64FF)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFF3E64FF)
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.book,
                                              size: 16,
                                              color: Color(0xFF3E64FF),
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                '${registration['courseTitle']} (${registration['courseCode']})',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF3E64FF),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time,
                                                  size: 16, color: Colors.grey),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Registered: ${_formatDate(registrationDate)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            _formatTime(registrationDate),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  String _formatTime(DateTime date) {
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
}

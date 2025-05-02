class Course {
  final String id;
  final String name;
  final String lecturerId;
  final String description;
  final List<String> enrolledStudents;
  final List<String> assignments;
  final Map<String, List<Attendance>> attendanceRecords;

  Course({
    required this.id,
    required this.name,
    required this.lecturerId,
    required this.description,
    this.enrolledStudents = const [],
    this.assignments = const [],
    this.attendanceRecords = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lecturerId': lecturerId,
        'description': description,
        'enrolledStudents': enrolledStudents,
        'assignments': assignments,
        'attendanceRecords': attendanceRecords,
      };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'],
        name: json['name'],
        lecturerId: json['lecturerId'],
        description: json['description'],
        enrolledStudents: List<String>.from(json['enrolledStudents'] ?? []),
        assignments: List<String>.from(json['assignments'] ?? []),
        attendanceRecords:
            Map<String, List<Attendance>>.from(json['attendanceRecords'] ?? {}),
      );
}

class Assignment {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final DateTime dueDate;
  final int maxPoints;
  final Map<String, int> studentSubmissions;

  Assignment({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.maxPoints,
    this.studentSubmissions = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'title': title,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'maxPoints': maxPoints,
        'studentSubmissions': studentSubmissions,
      };

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        id: json['id'],
        courseId: json['courseId'],
        title: json['title'],
        description: json['description'],
        dueDate: DateTime.parse(json['dueDate']),
        maxPoints: json['maxPoints'],
        studentSubmissions:
            Map<String, int>.from(json['studentSubmissions'] ?? {}),
      );
}

class Attendance {
  final String studentId;
  final DateTime timestamp;
  final bool present;

  Attendance({
    required this.studentId,
    required this.timestamp,
    required this.present,
  });

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'timestamp': timestamp.toIso8601String(),
        'present': present,
      };

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        studentId: json['studentId'],
        timestamp: DateTime.parse(json['timestamp']),
        present: json['present'],
      );
}

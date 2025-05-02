// Model for Assignment
class AssignmentModel {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final int maxPoints;
  final DateTime dueDate;
  final DateTime createdAt;
  final Map<String, dynamic> submissions;

  AssignmentModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.maxPoints,
    required this.dueDate,
    required this.createdAt,
    required this.submissions,
  });

  factory AssignmentModel.fromMap(String id, Map<String, dynamic> map) {
    return AssignmentModel(
      id: id,
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      maxPoints: map['maxPoints'] ?? 0,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'])
          : DateTime.now().add(const Duration(days: 7)),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as DateTime)
          : DateTime.now(),
      submissions: map['submissions'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'maxPoints': maxPoints,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt,
      'submissions': submissions,
    };
  }
}

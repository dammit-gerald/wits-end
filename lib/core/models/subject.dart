class Subject {
  final String id;
  final String title;
  final String description;
  final String? category;
  final String? iconCode;

  Subject({
    required this.id,
    required this.title,
    required this.description,
    this.category,
    this.iconCode,
  });

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      title: map['title'] ?? map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'],
      iconCode: map['icon_code'],
    );
  }
}

class Topic {
  final String id;
  final String subjectId;
  final String title;
  final int orderIndex;

  Topic({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.orderIndex,
  });

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: map['id'],
      subjectId: map['subject_id'],
      title: map['title'],
      orderIndex: map['order_index'] ?? 0,
    );
  }
}

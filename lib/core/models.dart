import 'dart:convert';

enum DrillType { matching, mcq, frq }

enum Criticality { high, medium, low }

enum StudyIntensity { high, balanced, completionist }

extension CriticalityExtension on Criticality {
  int get weight {
    switch (this) {
      case Criticality.high:
        return 3;
      case Criticality.medium:
        return 2;
      case Criticality.low:
        return 1;
    }
  }

  static Criticality fromString(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return Criticality.high;
      case 'medium':
        return Criticality.medium;
      case 'low':
      default:
        return Criticality.low;
    }
  }
}

abstract class DrillItem {
  final String id;
  final String unit;
  final Criticality criticality;
  final DrillType type;
  final String crashCourse; // New v1.2 field

  DrillItem({
    required this.id,
    required this.unit,
    required this.criticality,
    required this.type,
    required this.crashCourse,
  });

  Map<String, dynamic> toMap();
}

class MatchingItem extends DrillItem {
  final String term;
  final String definition;

  MatchingItem({
    required super.id,
    required super.unit,
    required super.criticality,
    required super.crashCourse,
    required this.term,
    required this.definition,
  }) : super(type: DrillType.matching);

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unit': unit,
      'type': 'matching',
      'criticality': criticality.name,
      'term': term,
      'definition': definition,
      'crash_course': crashCourse,
    };
  }

  factory MatchingItem.fromMap(Map<String, dynamic> map) {
    return MatchingItem(
      id: map['id'] ?? '',
      unit: map['unit'] ?? 'General',
      criticality: CriticalityExtension.fromString(map['criticality'] ?? 'low'),
      crashCourse: map['crash_course'] ?? map['crashCourse'] ?? 'No tactical intel available for this unit.',
      term: map['term'] ?? 'Missing Term',
      definition: map['definition'] ?? 'Missing Definition',
    );
  }
}

class MCQItem extends DrillItem {
  final String stimulus;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  MCQItem({
    required super.id,
    required super.unit,
    required super.criticality,
    required super.crashCourse,
    required this.stimulus,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  }) : super(type: DrillType.mcq);

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unit': unit,
      'type': 'mcq',
      'criticality': criticality.name,
      'stimulus': stimulus,
      'question': question,
      'options': jsonEncode(options),
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'crash_course': crashCourse,
    };
  }

  factory MCQItem.fromMap(Map<String, dynamic> map) {
    dynamic optionsData = map['options'];
    List<String> parsedOptions = [];
    if (optionsData is String) {
      parsedOptions = List<String>.from(jsonDecode(optionsData));
    } else if (optionsData is List) {
      parsedOptions = List<String>.from(optionsData);
    }

    return MCQItem(
      id: map['id'] ?? '',
      unit: map['unit'] ?? 'General',
      criticality: CriticalityExtension.fromString(map['criticality'] ?? 'low'),
      crashCourse: map['crash_course'] ?? map['crashCourse'] ?? 'No tactical intel available for this unit.',
      stimulus: map['stimulus'] ?? '',
      question: map['question'] ?? 'Missing Question',
      options: parsedOptions,
      correctAnswer: map['correctAnswer'] ?? map['correct_answer'] ?? 'A',
      explanation: map['explanation'] ?? '',
    );
  }
}

class FRQItem extends DrillItem {
  final String prompt;
  final List<String> rubricBulletPoints;

  FRQItem({
    required super.id,
    required super.unit,
    required super.criticality,
    required super.crashCourse,
    required this.prompt,
    required this.rubricBulletPoints,
  }) : super(type: DrillType.frq);

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unit': unit,
      'type': 'frq',
      'criticality': criticality.name,
      'prompt': prompt,
      'rubricBulletPoints': jsonEncode(rubricBulletPoints),
      'crash_course': crashCourse,
    };
  }

  factory FRQItem.fromMap(Map<String, dynamic> map) {
    dynamic rubricData = map['rubricBulletPoints'] ?? map['rubric_bullet_points'];
    List<String> parsedRubric = [];
    
    if (rubricData is String) {
      parsedRubric = List<String>.from(jsonDecode(rubricData));
    } else if (rubricData is List) {
      parsedRubric = List<String>.from(rubricData);
    } else if (map['rubric'] != null) {
      parsedRubric = [map['rubric']];
    }

    return FRQItem(
      id: map['id'] ?? '',
      unit: map['unit'] ?? 'General',
      criticality: CriticalityExtension.fromString(map['criticality'] ?? 'low'),
      crashCourse: map['crash_course'] ?? map['crashCourse'] ?? 'No tactical intel available for this unit.',
      prompt: map['prompt'] ?? 'Missing Prompt',
      rubricBulletPoints: parsedRubric,
    );
  }
}

class FeedbackBank {
  final String persona;
  final List<String> positive;
  final List<String> negative;

  FeedbackBank({
    required this.persona,
    required this.positive,
    required this.negative,
  });

  factory FeedbackBank.fromJson(Map<String, dynamic> json) {
    return FeedbackBank(
      persona: json['persona'],
      positive: List<String>.from(json['feedback_banks']['positive']),
      negative: List<String>.from(json['feedback_banks']['negative']),
    );
  }
}

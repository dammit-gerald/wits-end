import 'enums.dart';
import 'drill_item.dart';

class SessionSettings {
  final List<String> units;
  final List<DrillType> types;
  final int questionLimit;
  final StudyIntensity intensity;
  final bool cramMode;

  SessionSettings({
    required this.units,
    required this.types,
    required this.questionLimit,
    required this.intensity,
    this.cramMode = false,
  });

  Map<Criticality, int> get criticalityWeights {
    if (cramMode) {
      return {Criticality.high: 90, Criticality.medium: 9, Criticality.low: 1};
    }
    switch (intensity) {
      case StudyIntensity.high:
        return {Criticality.high: 80, Criticality.medium: 15, Criticality.low: 5};
      case StudyIntensity.balanced:
        return {Criticality.high: 33, Criticality.medium: 33, Criticality.low: 34};
      case StudyIntensity.completionist:
        return {Criticality.high: 20, Criticality.medium: 30, Criticality.low: 50};
    }
  }
}

class UnitStats {
  int correct = 0;
  int total = 0;
  double get accuracy => total == 0 ? 0 : (correct / total) * 100;
}

class StudyState {
  final DrillItem? currentDrill;
  final bool isAnswered;
  final bool isCorrect;
  final String? lastFeedback;
  final int totalAnswered;
  final int correctCount;
  final int sessionAnswered;
  final int sessionCorrect;
  final bool sessionComplete;
  final Map<String, UnitStats> globalUnitStats;
  final Map<String, UnitStats> sessionUnitStats;
  final List<String> matchingOptions;
  final List<String> mcqOptions;
  final SessionSettings? settings;
  final int retirementThreshold;
  final int cooldownHours;

  StudyState({
    this.currentDrill,
    this.isAnswered = false,
    this.isCorrect = false,
    this.lastFeedback,
    this.totalAnswered = 0,
    this.correctCount = 0,
    this.sessionAnswered = 0,
    this.sessionCorrect = 0,
    this.sessionComplete = false,
    this.globalUnitStats = const {},
    this.sessionUnitStats = const {},
    this.matchingOptions = const [],
    this.mcqOptions = const [],
    this.settings,
    this.retirementThreshold = 3,
    this.cooldownHours = 0,
  });

  StudyState copyWith({
    DrillItem? Function()? currentDrill,
    bool? isAnswered,
    bool? isCorrect,
    String? Function()? lastFeedback,
    int? totalAnswered,
    int? correctCount,
    int? sessionAnswered,
    int? sessionCorrect,
    bool? sessionComplete,
    Map<String, UnitStats>? globalUnitStats,
    Map<String, UnitStats>? sessionUnitStats,
    List<String>? matchingOptions,
    List<String>? mcqOptions,
    SessionSettings? settings,
    int? retirementThreshold,
    int? cooldownHours,
  }) {
    return StudyState(
      currentDrill: currentDrill != null ? currentDrill() : this.currentDrill,
      isAnswered: isAnswered ?? this.isAnswered,
      isCorrect: isCorrect ?? this.isCorrect,
      lastFeedback: lastFeedback != null ? lastFeedback() : this.lastFeedback,
      totalAnswered: totalAnswered ?? this.totalAnswered,
      correctCount: correctCount ?? this.correctCount,
      sessionAnswered: sessionAnswered ?? this.sessionAnswered,
      sessionCorrect: sessionCorrect ?? this.sessionCorrect,
      sessionComplete: sessionComplete ?? this.sessionComplete,
      globalUnitStats: globalUnitStats ?? this.globalUnitStats,
      sessionUnitStats: sessionUnitStats ?? this.sessionUnitStats,
      matchingOptions: matchingOptions ?? this.matchingOptions,
      mcqOptions: mcqOptions ?? this.mcqOptions,
      settings: settings ?? this.settings,
      retirementThreshold: retirementThreshold ?? this.retirementThreshold,
      cooldownHours: cooldownHours ?? this.cooldownHours,
    );
  }
}

import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_service.dart';
import 'models.dart';

class SessionSettings {
  final List<String> units;
  final List<DrillType> types;
  final int questionLimit;
  final StudyIntensity intensity;

  SessionSettings({
    required this.units,
    required this.types,
    required this.questionLimit,
    required this.intensity,
  });

  Map<Criticality, int> get criticalityWeights {
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
  final List<String> matchingOptions; // Moved shuffling here
  final List<String> mcqOptions; // Moved shuffling here
  final SessionSettings? settings;

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
    );
  }
}

class StudyNotifier extends Notifier<StudyState> {
  final DatabaseService _db = DatabaseService();
  FeedbackBank? _feedbackBank;

  @override
  StudyState build() {
    _init();
    return StudyState();
  }

  Future<void> _init() async {
    final totalAnswered = (await _db.getStat('total_answered')).toInt();
    final correctCount = (await _db.getStat('correct_count')).toInt();
    _feedbackBank = await _db.getFeedbackBank();
    final globalStats = await _loadGlobalUnitStats();
    
    state = state.copyWith(
      totalAnswered: totalAnswered,
      correctCount: correctCount,
      globalUnitStats: globalStats,
    );
  }

  Future<Map<String, UnitStats>> _loadGlobalUnitStats() async {
    final stats = await _db.getAllUnitStats();
    return stats.map((unit, data) {
      final us = UnitStats();
      us.correct = data['correct']!;
      us.total = data['total']!;
      return MapEntry(unit, us);
    });
  }

  Future<List<String>> getAvailableUnits() => _db.getUnits();

  Future<void> startSession(SessionSettings settings) async {
    state = state.copyWith(
      settings: settings,
      sessionAnswered: 0,
      sessionCorrect: 0,
      sessionUnitStats: {},
      sessionComplete: false,
    );
    await nextDrill();
  }

  Future<void> nextDrill() async {
    if (state.settings != null && state.sessionAnswered >= state.settings!.questionLimit) {
      state = state.copyWith(
        sessionComplete: true,
        currentDrill: () => null,
      );
      return;
    }

    try {
      final next = await _db.getRandomDrill(
        units: state.settings?.units,
        types: state.settings?.types,
        excludedIds: [], // We could track excluded IDs in state if needed
        weights: state.settings?.criticalityWeights,
      );

      List<String> matchingOptions = [];
      List<String> mcqOptions = [];

      if (next is MatchingItem) {
        final distractors = await _db.getMatchingDefinitions(
          unit: next.unit,
          exclude: next.definition,
        );
        matchingOptions = [next.definition, ...distractors]..shuffle();
      } else if (next is MCQItem) {
        mcqOptions = List<String>.from(next.options)..shuffle();
      }

      state = state.copyWith(
        currentDrill: () => next,
        isAnswered: false,
        isCorrect: false,
        lastFeedback: () => null,
        matchingOptions: matchingOptions,
        mcqOptions: mcqOptions,
      );
    } catch (e) {
      state = state.copyWith(
        sessionComplete: true,
        currentDrill: () => null,
      );
    }
  }

  void submitAnswer(bool isCorrect) {
    if (state.isAnswered || state.currentDrill == null) return;
    
    final unit = state.currentDrill!.unit;
    
    // Update Global Unit Stats
    final newGlobalStats = Map<String, UnitStats>.from(state.globalUnitStats);
    newGlobalStats.putIfAbsent(unit, () => UnitStats());
    newGlobalStats[unit]!.total++;
    if (isCorrect) newGlobalStats[unit]!.correct++;

    // Update Session Unit Stats
    final newSessionStats = Map<String, UnitStats>.from(state.sessionUnitStats);
    newSessionStats.putIfAbsent(unit, () => UnitStats());
    newSessionStats[unit]!.total++;
    if (isCorrect) newSessionStats[unit]!.correct++;

    state = state.copyWith(
      isAnswered: true,
      isCorrect: isCorrect,
      totalAnswered: state.totalAnswered + 1,
      correctCount: isCorrect ? state.correctCount + 1 : state.correctCount,
      sessionAnswered: state.sessionAnswered + 1,
      sessionCorrect: isCorrect ? state.sessionCorrect + 1 : state.sessionCorrect,
      globalUnitStats: newGlobalStats,
      sessionUnitStats: newSessionStats,
      lastFeedback: () => _generateFeedback(isCorrect),
    );

    _db.updateStat('total_answered', state.totalAnswered.toDouble());
    _db.updateStat('correct_count', state.correctCount.toDouble());
    _db.updateUnitStat(unit, isCorrect);
  }

  void overrideCorrect() {
    if (!state.isAnswered || state.isCorrect || state.currentDrill == null) return;
    
    // Block override for MCQ and Matching (as per user request)
    // "removing 'i was right' on multiple choice (but keep for anything they type, like FRQ and matching)"
    // Wait, the user said "matching" should KEEP it. 
    // Matching is not typed in this app, but if they want to keep it, I will.
    // "but keep for anything they type, like FRQ and matching"
    if (state.currentDrill!.type == DrillType.mcq) return;

    final unit = state.currentDrill!.unit;

    final newGlobalStats = Map<String, UnitStats>.from(state.globalUnitStats);
    newGlobalStats[unit]!.correct++;

    final newSessionStats = Map<String, UnitStats>.from(state.sessionUnitStats);
    newSessionStats[unit]!.correct++;

    state = state.copyWith(
      isCorrect: true,
      correctCount: state.correctCount + 1,
      sessionCorrect: state.sessionCorrect + 1,
      globalUnitStats: newGlobalStats,
      sessionUnitStats: newSessionStats,
      lastFeedback: () => _generateFeedback(true),
    );

    _db.updateStat('correct_count', state.correctCount.toDouble());
    _db.updateUnitStat(unit, true, isOverride: true);
  }

  Future<void> resetStats() async {
    await _db.resetStats();
    state = state.copyWith(
      totalAnswered: 0,
      correctCount: 0,
      globalUnitStats: {},
    );
  }

  String? _generateFeedback(bool isCorrect) {
    if (_feedbackBank == null) return null;
    final random = Random();
    final bank = isCorrect ? _feedbackBank!.positive : _feedbackBank!.negative;
    return bank[random.nextInt(bank.length)];
  }
}

final studyProvider = NotifierProvider<StudyNotifier, StudyState>(() {
  return StudyNotifier();
});

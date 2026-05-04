import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_service.dart';
import 'supabase_service.dart';
import 'persona_notifier.dart';
import 'models/models.dart';
import 'session_service.dart';

class StudyNotifier extends Notifier<StudyState> {
  final DatabaseService _localDb = DatabaseService();
  late final SupabaseService _supabase;
  late final SessionService _sessionService;
  
  List<DrillItem> _sessionPool = [];
  List<Topic> _availableTopics = [];

  @override
  StudyState build() {
    _supabase = ref.watch(supabaseServiceProvider);
    _sessionService = ref.watch(sessionServiceProvider);
    _init();
    return StudyState();
  }

  Future<void> _init() async {
    final totalAnswered = (await _localDb.getStat('total_answered')).toInt();
    final correctCount = (await _localDb.getStat('correct_count')).toInt();
    final globalStats = await _loadGlobalUnitStats();

    final userId = _supabase.currentUser?.id;
    if (userId != null) {
      final settings = await _supabase.getUserSettings(userId);
      state = state.copyWith(
        retirementThreshold: settings['retirement_threshold'],
        cooldownHours: settings['cooldown_hours'],
      );
    }
    
    state = state.copyWith(
      totalAnswered: totalAnswered,
      correctCount: correctCount,
      globalUnitStats: globalStats,
    );
  }

  Future<Map<String, UnitStats>> _loadGlobalUnitStats() async {
    final stats = await _localDb.getAllUnitStats();
    return stats.map((unit, data) {
      final us = UnitStats();
      us.correct = data['correct']!;
      us.total = data['total']!;
      return MapEntry(unit, us);
    });
  }

  Future<List<String>> getAvailableUnits({List<String>? subjectIds}) async {
    final ids = subjectIds ?? ['32b3925b-cd01-421a-988a-27e1dc4cee5a'];
    _availableTopics = [];
    for (var id in ids) {
      final topics = await _supabase.getTopics(id);
      _availableTopics.addAll(topics);
    }
    return _availableTopics.map((e) => e.title).toList();
  }

  Future<void> startSession(SessionSettings settings) async {
    state = state.copyWith(
      settings: settings,
      sessionAnswered: 0,
      sessionCorrect: 0,
      sessionUnitStats: {},
      sessionComplete: false,
    );

    final selectedTopicIds = _availableTopics
        .where((t) => settings.units.contains(t.title))
        .map((t) => t.id)
        .toList();

    _sessionPool = await _supabase.getDrillPool(
      topicIds: selectedTopicIds,
      types: settings.types,
    );

    final userId = _supabase.currentUser?.id;
    if (userId != null) {
      final retiredIds = await _supabase.getRetiredDrillIds(
        userId, 
        state.retirementThreshold, 
        state.cooldownHours
      );
      _sessionPool.removeWhere((d) => retiredIds.contains(d.id));
    }

    await nextDrill();
  }

  Future<void> nextDrill() async {
    if (state.settings != null && state.sessionAnswered >= state.settings!.questionLimit) {
      state = state.copyWith(sessionComplete: true, currentDrill: () => null);
      return;
    }

    if (_sessionPool.isEmpty) {
       state = state.copyWith(sessionComplete: true, currentDrill: () => null);
      return;
    }

    try {
      final next = _sessionService.weightedPick(_sessionPool, state.settings?.criticalityWeights);

      List<String> matchingOptions = [];
      List<String> mcqOptions = [];

      if (next is MatchingItem) {
        matchingOptions = _sessionService.buildMatchingOptions(next, _sessionPool);
      } else if (next is MCQItem) {
        mcqOptions = _sessionService.buildMCQOptions(next);
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
      state = state.copyWith(sessionComplete: true, currentDrill: () => null);
    }
  }

  void submitAnswer(bool isCorrect) {
    if (state.isAnswered || state.currentDrill == null) return;
    
    final unit = state.currentDrill!.unit;
    
    final newGlobalStats = Map<String, UnitStats>.from(state.globalUnitStats);
    newGlobalStats.putIfAbsent(unit, () => UnitStats());
    newGlobalStats[unit]!.total++;
    if (isCorrect) newGlobalStats[unit]!.correct++;

    final newSessionStats = Map<String, UnitStats>.from(state.sessionUnitStats);
    newSessionStats.putIfAbsent(unit, () => UnitStats());
    newSessionStats[unit]!.total++;
    if (isCorrect) newSessionStats[unit]!.correct++;

    final persona = ref.read(personaProvider).current;

    state = state.copyWith(
      isAnswered: true,
      isCorrect: isCorrect,
      totalAnswered: state.totalAnswered + 1,
      correctCount: isCorrect ? state.correctCount + 1 : state.correctCount,
      sessionAnswered: state.sessionAnswered + 1,
      sessionCorrect: isCorrect ? state.sessionCorrect + 1 : state.sessionCorrect,
      globalUnitStats: newGlobalStats,
      sessionUnitStats: newSessionStats,
      lastFeedback: () => _sessionService.generateFeedback(isCorrect, persona),
    );

    _localDb.updateStat('total_answered', state.totalAnswered.toDouble());
    _localDb.updateStat('correct_count', state.correctCount.toDouble());
    _localDb.updateUnitStat(unit, isCorrect);

    final userId = _supabase.currentUser?.id;
    if (userId != null && state.currentDrill?.id != null) {
      _supabase.updateDrillProgress(userId, state.currentDrill!.id, isCorrect);
    }
  }

  void overrideCorrect() {
    if (!state.isAnswered || state.isCorrect || state.currentDrill == null) return;
    if (state.currentDrill!.type == DrillType.mcq) return;

    final unit = state.currentDrill!.unit;

    final newGlobalStats = Map<String, UnitStats>.from(state.globalUnitStats);
    newGlobalStats[unit]!.correct++;

    final newSessionStats = Map<String, UnitStats>.from(state.sessionUnitStats);
    newSessionStats[unit]!.correct++;

    final persona = ref.read(personaProvider).current;

    state = state.copyWith(
      isCorrect: true,
      correctCount: state.correctCount + 1,
      sessionCorrect: state.sessionCorrect + 1,
      globalUnitStats: newGlobalStats,
      sessionUnitStats: newSessionStats,
      lastFeedback: () => _sessionService.generateFeedback(true, persona),
    );

    _localDb.updateStat('correct_count', state.correctCount.toDouble());
    _localDb.updateUnitStat(unit, true, isOverride: true);

    final userId = _supabase.currentUser?.id;
    if (userId != null && state.currentDrill?.id != null) {
      _supabase.updateDrillProgress(userId, state.currentDrill!.id, true);
    }
  }

  Future<void> updateSettings({int? threshold, int? cooldown}) async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return;

    final newThreshold = threshold ?? state.retirementThreshold;
    final newCooldown = cooldown ?? state.cooldownHours;

    state = state.copyWith(
      retirementThreshold: newThreshold,
      cooldownHours: newCooldown,
    );

    await _supabase.updateUserSettings(userId, {
      'retirement_threshold': newThreshold,
      'cooldown_hours': newCooldown,
    });
  }

  Future<void> resetStats() async {
    await _localDb.resetStats();
    state = state.copyWith(
      totalAnswered: 0,
      correctCount: 0,
      globalUnitStats: {},
    );
  }
}

final studyProvider = NotifierProvider<StudyNotifier, StudyState>(() {
  return StudyNotifier();
});

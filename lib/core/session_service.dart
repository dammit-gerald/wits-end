import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/models.dart';

class SessionService {
  final Random _random = Random();

  DrillItem weightedPick(List<DrillItem> pool, Map<Criticality, int>? customWeights) {
    if (pool.isEmpty) throw Exception("Empty pool");

    final weights = customWeights ?? {
      Criticality.high: 50,
      Criticality.medium: 33,
      Criticality.low: 17,
    };

    final grouped = <Criticality, List<DrillItem>>{};
    for (var item in pool) {
      grouped.putIfAbsent(item.criticality, () => []).add(item);
    }

    final availableWeights = <Criticality, int>{};
    int totalAvailableWeight = 0;
    for (var entry in weights.entries) {
      if (grouped.containsKey(entry.key) && grouped[entry.key]!.isNotEmpty) {
        availableWeights[entry.key] = entry.value;
        totalAvailableWeight += entry.value;
      }
    }

    if (totalAvailableWeight == 0) {
      return pool[_random.nextInt(pool.length)];
    }

    int r = _random.nextInt(totalAvailableWeight);
    int current = 0;
    for (var entry in availableWeights.entries) {
      current += entry.value;
      if (r < current) {
        final categoryPool = grouped[entry.key]!;
        return categoryPool[_random.nextInt(categoryPool.length)];
      }
    }

    return pool.first;
  }

  List<String> buildMatchingOptions(MatchingItem current, List<DrillItem> pool) {
    final topicDrills = pool.whereType<MatchingItem>().toList();
    final distractors = topicDrills
        .where((d) => d.definition != current.definition)
        .map((d) => d.definition)
        .toList();
    
    distractors.shuffle();
    return [current.definition, ...distractors.take(3)]..shuffle();
  }

  List<String> buildMCQOptions(MCQItem current) {
    return List<String>.from(current.options)..shuffle();
  }

  String? generateFeedback(bool isCorrect, Persona persona) {
    final bank = isCorrect ? persona.positiveFeedback : persona.negativeFeedback;
    if (bank.isEmpty) return null;
    return bank[_random.nextInt(bank.length)];
  }
}

final sessionServiceProvider = Provider((ref) => SessionService());

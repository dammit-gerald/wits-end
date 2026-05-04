import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/models.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<List<Subject>> getSubjects() async {
    final response = await _supabase.from('subjects').select();
    return (response as List).map((e) => Subject.fromMap(e)).toList();
  }

  Future<List<Persona>> getPersonas() async {
    final response = await _supabase.from('personas').select();
    return (response as List).map((e) => Persona.fromMap(e)).toList();
  }

  Future<void> updatePersona(String userId, String personaId) async {
    await _supabase.from('user_profiles').upsert({
      'id': userId,
      'persona_id': personaId,
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return await _supabase.from('user_profiles').select().eq('id', userId).maybeSingle();
  }

  Future<Map<String, dynamic>> getUserSettings(String userId) async {
    final response = await _supabase.from('user_settings').select().eq('user_id', userId).maybeSingle();
    if (response == null) {
      // Default settings
      return {
        'retirement_threshold': 3,
        'cooldown_hours': 0, // 0 = permanent
      };
    }
    return response;
  }

  Future<void> updateUserSettings(String userId, Map<String, dynamic> settings) async {
    await _supabase.from('user_settings').upsert({
      'user_id': userId,
      ...settings,
    });
  }

  Future<void> updateDrillProgress(String userId, String drillId, bool isCorrect) async {
    // Get existing progress
    final existing = await _supabase
        .from('user_progress')
        .select()
        .eq('user_id', userId)
        .eq('drill_id', drillId)
        .maybeSingle();

    if (existing == null) {
      await _supabase.from('user_progress').insert({
        'user_id': userId,
        'drill_id': drillId,
        'mastery_count': isCorrect ? 1 : 0,
        'last_seen_at': DateTime.now().toIso8601String(),
      });
    } else {
      int newMastery = isCorrect ? (existing['mastery_count'] as int) + 1 : 0;
      await _supabase.from('user_progress').update({
        'mastery_count': newMastery,
        'last_seen_at': DateTime.now().toIso8601String(),
      }).eq('id', existing['id']);
    }
  }

  Future<List<String>> getRetiredDrillIds(String userId, int threshold, int cooldownHours) async {
    var query = _supabase
        .from('user_progress')
        .select('drill_id')
        .eq('user_id', userId)
        .gte('mastery_count', threshold);

    if (cooldownHours > 0) {
      final cutoff = DateTime.now().subtract(Duration(hours: cooldownHours)).toIso8601String();
      query = query.gt('last_seen_at', cutoff);
    }

    final response = await query;
    return (response as List).map((e) => e['drill_id'] as String).toList();
  }

  Future<List<Topic>> getTopics(String subjectId) async {
    final response = await _supabase
        .from('topics')
        .select()
        .eq('subject_id', subjectId)
        .order('order_index');
    return (response as List).map((e) => Topic.fromMap(e)).toList();
  }

  Future<List<DrillItem>> getDrillPool({
    required List<String> topicIds,
    List<DrillType>? types,
  }) async {
    var query = _supabase
        .from('drills')
        .select('*, topics(title)')
        .filter('topic_id', 'in', topicIds);

    if (types != null && types.isNotEmpty) {
      query = query.filter('type', 'in', types.map((e) => e.name).toList());
    }

    final response = await query;
    
    return (response as List).map((e) {
      final unit = e['topics']['title'];
      final type = e['type'];
      final content = e['content'];
      content['id'] = e['id'];
      content['unit'] = unit;
      content['criticality'] = e['criticality'];

      switch (type) {
        case 'matching':
          return MatchingItem.fromMap(content);
        case 'mcq':
          return MCQItem.fromMap(content);
        case 'frq':
          return FRQItem.fromMap(content);
        default:
          throw Exception('Unknown type $type');
      }
    }).toList();
  }

  Future<List<String>> getMatchingDistractors({
    required String topicId,
    required String excludeDefinition,
    int limit = 3,
  }) async {
    // In a real app, we might want to pull from the whole subject, but topic-specific is safer for context
    final response = await _supabase
        .from('drills')
        .select('content')
        .eq('topic_id', topicId)
        .eq('type', 'matching')
        .limit(20); // Get a small pool to pick from

    final List<String> defs = (response as List)
        .map((e) => e['content']['definition'] as String)
        .where((d) => d != excludeDefinition)
        .toList();
    
    defs.shuffle();
    return defs.take(limit).toList();
  }

  Future<AuthResponse> signIn(String email, String password) {
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password) {
    return _supabase.auth.signUp(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback/',
    );
  }

  Future<void> signOut() {
    return _supabase.auth.signOut();
  }
}

final supabaseServiceProvider = Provider((ref) => SupabaseService());

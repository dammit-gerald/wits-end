import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/models.dart';
import 'supabase_service.dart';

class PersonaState {
  final Persona current;
  final List<Persona> available;
  final bool isLoading;

  PersonaState({
    required this.current,
    this.available = const [],
    this.isLoading = false,
  });

  PersonaState copyWith({
    Persona? current,
    List<Persona>? available,
    bool? isLoading,
  }) {
    return PersonaState(
      current: current ?? this.current,
      available: available ?? this.available,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PersonaNotifier extends StateNotifier<PersonaState> {
  final SupabaseService _supabase;

  PersonaNotifier(this._supabase) : super(PersonaState(current: Persona.gerald())) {
    loadPersonas();
  }

  Future<void> loadPersonas() async {
    state = state.copyWith(isLoading: true);
    try {
      final personas = await _supabase.getPersonas();
      if (personas.isNotEmpty) {
        Persona current = personas.firstWhere((p) => p.id == 'gerald', orElse: () => personas.first);
        
        // Try to load user preference from profile
        final userId = _supabase.currentUser?.id;
        if (userId != null) {
          try {
            final profile = await _supabase.getUserProfile(userId);
            if (profile != null && profile['persona_id'] != null) {
              current = personas.firstWhere((p) => p.id == profile['persona_id'], orElse: () => current);
            }
          } catch (e) {
            // Profile load failed, keep default 'gerald'
          }
        }

        state = state.copyWith(
          available: personas,
          current: current,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> setPersona(String personaId) async {
    final persona = state.available.firstWhere((p) => p.id == personaId, orElse: () => state.current);
    state = state.copyWith(current: persona);

    // Persist to Supabase
    final userId = _supabase.currentUser?.id;
    if (userId != null) {
      try {
        await _supabase.updatePersona(userId, personaId);
      } catch (e) {
        // Silently fail persistence, state is still updated
      }
    }
  }
}

final personaProvider = StateNotifierProvider<PersonaNotifier, PersonaState>((ref) {
  return PersonaNotifier(ref.watch(supabaseServiceProvider));
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/supabase_service.dart';

class LibraryState {
  final List<Subject> allSubjects;
  final Set<String> starredSubjectIds;
  final Set<String> selectedSubjectIds;
  final bool isLoading;
  final String searchQuery;

  LibraryState({
    this.allSubjects = const [],
    this.starredSubjectIds = const {},
    this.selectedSubjectIds = const {},
    this.isLoading = false,
    this.searchQuery = '',
  });

  LibraryState copyWith({
    List<Subject>? allSubjects,
    Set<String>? starredSubjectIds,
    Set<String>? selectedSubjectIds,
    bool? isLoading,
    String? searchQuery,
  }) {
    return LibraryState(
      allSubjects: allSubjects ?? this.allSubjects,
      starredSubjectIds: starredSubjectIds ?? this.starredSubjectIds,
      selectedSubjectIds: selectedSubjectIds ?? this.selectedSubjectIds,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Subject> get filteredSubjects {
    if (searchQuery.isEmpty) return allSubjects;
    return allSubjects.where((s) => 
      s.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
      (s.category?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  List<Subject> get starredSubjects {
    return allSubjects.where((s) => starredSubjectIds.contains(s.id)).toList();
  }
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  final SupabaseService _supabase;

  LibraryNotifier(this._supabase) : super(LibraryState()) {
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    state = state.copyWith(isLoading: true);
    try {
      final subjects = await _supabase.getSubjects();
      state = state.copyWith(allSubjects: subjects, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void toggleStar(String subjectId) {
    final newStarred = Set<String>.from(state.starredSubjectIds);
    if (newStarred.contains(subjectId)) {
      newStarred.remove(subjectId);
    } else {
      newStarred.add(subjectId);
    }
    state = state.copyWith(starredSubjectIds: newStarred);
  }

  void toggleSelect(String subjectId) {
    final newSelected = Set<String>.from(state.selectedSubjectIds);
    if (newSelected.contains(subjectId)) {
      newSelected.remove(subjectId);
    } else {
      newSelected.add(subjectId);
    }
    state = state.copyWith(selectedSubjectIds: newSelected);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSelection() {
    state = state.copyWith(selectedSubjectIds: {});
  }
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier(ref.watch(supabaseServiceProvider));
});

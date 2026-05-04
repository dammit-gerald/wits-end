import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'library_notifier.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/audio_service.dart';
import '../../core/persona_notifier.dart';
import '../../core/models/models.dart';

class CourseDiscoveryScreen extends ConsumerWidget {
  const CourseDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);
    final notifier = ref.read(libraryProvider.notifier);
    final persona = ref.watch(personaProvider).current;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(persona.getLabel('discovery_title', 'DISCOVER COURSES')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, notifier, state, persona),
            Expanded(
              child: state.isLoading 
                ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
                : _buildSubjectList(context, state, notifier, persona),
            ),
            if (state.selectedSubjectIds.isNotEmpty)
              _buildSelectionFooter(context, state, notifier, persona),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LibraryNotifier notifier, LibraryState state, Persona persona) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: TextField(
              onChanged: notifier.setSearchQuery,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: Colors.white38),
                hintText: "Search by subject or category...",
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
          ).animate().fadeIn().slideX(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildSubjectList(BuildContext context, LibraryState state, LibraryNotifier notifier, Persona persona) {
    final subjects = state.filteredSubjects;
    
    if (subjects.isEmpty) {
      return const Center(
        child: Text("NO COURSES FOUND", style: TextStyle(color: Colors.white38, letterSpacing: 2)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final isStarred = state.starredSubjectIds.contains(subject.id);
        final isSelected = state.selectedSubjectIds.contains(subject.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () {
              AudioService.playStart();
              notifier.toggleSelect(subject.id);
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected 
                  ? Colors.greenAccent.withValues(alpha: 0.1) 
                  : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.greenAccent : Colors.white10,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  _buildIcon(subject.iconCode, isSelected),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (subject.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              subject.category!.toUpperCase(),
                              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white54),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          subject.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subject.description,
                          style: const TextStyle(fontSize: 12, color: Colors.white54),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isStarred ? Icons.star : Icons.star_border,
                      color: isStarred ? Colors.orangeAccent : Colors.white24,
                    ),
                    onPressed: () {
                      notifier.toggleStar(subject.id);
                    },
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1),
        );
      },
    );
  }

  Widget _buildIcon(String? iconCode, bool isSelected) {
    IconData iconData;
    switch (iconCode) {
      case 'history': iconData = Icons.history_edu; break;
      case 'geography': iconData = Icons.public; break;
      case 'science': iconData = Icons.biotech; break;
      default: iconData = Icons.school;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.greenAccent : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: isSelected ? Colors.black : Colors.white38,
      ),
    );
  }

  Widget _buildSelectionFooter(BuildContext context, LibraryState state, LibraryNotifier notifier, Persona persona) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${state.selectedSubjectIds.length} ${persona.getLabel('discovery_footer_selected', 'COURSE(S) SELECTED')}",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54),
              ),
              TextButton(
                onPressed: () {
                  notifier.clearSelection();
                },
                child: Text(persona.getLabel('discovery_footer_clear', 'CLEAR'), style: const TextStyle(color: Colors.redAccent, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Return selected subjects to whoever called this
                Navigator.pop(context, state.selectedSubjectIds.toList());
              },
              child: Text(persona.getLabel('setup_start', 'INITIALIZE SESSION')),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 1.0, curve: Curves.easeOutQuad);
  }
}

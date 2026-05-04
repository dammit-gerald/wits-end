import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/study_notifier.dart';
import '../setup/setup_screen.dart';
import '../library/course_discovery_screen.dart';
import '../library/library_notifier.dart';
import '../onboarding/screens/auth_screen.dart';
import '../../core/supabase_service.dart';
import '../../core/persona_notifier.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final persona = ref.watch(personaProvider).current;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white24),
                  onPressed: () => _showSettings(context, ref),
                ),
              ),
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                  fit: BoxFit.contain,
                ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.9, 0.9)),
              ),
              const SizedBox(height: 40),
              _buildStatsCard(context, ref),
              const SizedBox(height: 40),
              _buildSectionHeader(persona.getLabel('dashboard_library', 'YOUR TACTICAL LIBRARY'), () async {
                final List<String>? selectedIds = await Navigator.push<List<String>>(
                  context,
                  MaterialPageRoute(builder: (context) => const CourseDiscoveryScreen()),
                );

                if (selectedIds != null && selectedIds.isNotEmpty && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SetupScreen(initialSubjectIds: selectedIds)),
                  );
                }
              }),
              const SizedBox(height: 16),
              _buildCourseLibrary(context, ref, libraryState),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SetupScreen()),
                  );
                },
                child: Text(persona.getLabel('dashboard_start', 'INITIALIZE DRILLS')),
              ).animate().scale(delay: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => _showResetConfirmation(context, ref),
                  child: const Text(
                    "RESET STATS",
                    style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.5),
        ),
        TextButton(
          onPressed: onAction,
          child: const Text("DISCOVER", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildCourseLibrary(BuildContext context, WidgetRef ref, LibraryState state) {
    final starred = state.starredSubjects;
    if (starred.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10, style: BorderStyle.none),
        ),
        child: Column(
          children: [
            const Icon(Icons.library_books_outlined, color: Colors.white10, size: 48),
            const SizedBox(height: 16),
            const Text(
              "NO COURSES ACTIVE",
              style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            const Text(
              "Visit the library to enlist in new subjects.",
              style: TextStyle(color: Colors.white10, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: starred.length,
        itemBuilder: (context, index) {
          final subject = starred[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  subject.iconCode == 'history' ? Icons.history_edu : Icons.public,
                  color: Colors.greenAccent,
                  size: 20,
                ),
                Text(
                  subject.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.2);
        },
      ),
    );
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            return DefaultTabController(
              length: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: "PERSONA"),
                        Tab(text: "RETIREMENT"),
                      ],
                      labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      indicatorColor: Colors.greenAccent,
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildPersonaTab(context, ref),
                          _buildRetirementTab(context, ref),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            foregroundColor: Colors.white54,
                          ),
                          child: const Text("CLOSE SETTINGS"),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        await ref.read(supabaseServiceProvider).signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const AuthScreen()),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text("SIGN OUT", style: TextStyle(color: Colors.redAccent, fontSize: 10, letterSpacing: 1.5)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPersonaTab(BuildContext context, WidgetRef ref) {
    final personaState = ref.watch(personaProvider);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: personaState.available.map((p) {
        final isSelected = personaState.current.id == p.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              ref.read(personaProvider.notifier).setPersona(p.id);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? Colors.greenAccent : Colors.white10),
              ),
              child: Row(
                children: [
                  Icon(_getPersonaIcon(p.id), color: isSelected ? Colors.greenAccent : Colors.white24),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.greenAccent : Colors.white)),
                        const SizedBox(height: 4),
                        Text((p.uiLabels['setup_start'] ?? "MENTOR").toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white38)),
                      ],
                    ),
                  ),
                  if (isSelected) const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRetirementTab(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studyProvider);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          "RETIREMENT THRESHOLD",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        const Text(
          "Hide questions after this many consecutive correct answers.",
          style: TextStyle(fontSize: 12, color: Colors.white38),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [3, 5, 10].map((val) {
            final isSelected = state.retirementThreshold == val;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed: () => ref.read(studyProvider.notifier).updateSettings(threshold: val),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Colors.greenAccent : Colors.white.withValues(alpha: 0.05),
                    foregroundColor: isSelected ? Colors.black : Colors.white,
                  ),
                  child: Text("$val HITS"),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 40),
        const Text(
          "COOLDOWN DURATION",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        const Text(
          "How long should a mastered question stay retired?",
          style: TextStyle(fontSize: 12, color: Colors.white38),
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<int>(
          initialValue: state.cooldownHours,
          dropdownColor: const Color(0xFF1A1A1A),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: const [
            DropdownMenuItem(value: 0, child: Text("PERMANENT", style: TextStyle(color: Colors.white))),
            DropdownMenuItem(value: 24, child: Text("24 HOURS", style: TextStyle(color: Colors.white))),
            DropdownMenuItem(value: 72, child: Text("72 HOURS", style: TextStyle(color: Colors.white))),
            DropdownMenuItem(value: 168, child: Text("1 WEEK", style: TextStyle(color: Colors.white))),
          ],
          onChanged: (val) => ref.read(studyProvider.notifier).updateSettings(cooldown: val),
        ),
      ],
    );
  }

  IconData _getPersonaIcon(String id) {
    switch (id) {
      case 'gerald': return Icons.coffee;
      case 'ashleigh': return Icons.auto_awesome;
      case 'marissa': return Icons.local_florist;
      case 'karen': return Icons.support_agent;
      case 'kevin': return Icons.casino;
      default: return Icons.school;
    }
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("MEMORY PURGE"),
        content: const Text("Are you sure you want to wipe your historical performance data? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ABORT", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              ref.read(studyProvider.notifier).resetStats();
              Navigator.pop(context);
            },
            child: const Text("CONFIRM PURGE", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studyProvider);
    final persona = ref.watch(personaProvider).current;
    final accuracy = state.totalAnswered == 0 ? 0 : (state.correctCount / state.totalAnswered) * 100;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(persona.getLabel('dashboard_stats_accuracy', 'TOTAL ACCURACY'), "${accuracy.toInt()}%"),
          Container(width: 1, height: 40, color: Colors.white10),
          _statItem(persona.getLabel('dashboard_stats_missions', 'MISSION COUNT'), state.totalAnswered.toString()),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_service.dart';
import '../../../core/persona_notifier.dart';
import '../../../core/study_notifier.dart';
import '../../library/library_notifier.dart';
import '../../dashboard/dashboard_screen.dart';

class SetupWizardScreen extends ConsumerStatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String> _selectedSubjectIds = [];
  int _retirementThreshold = 3;
  int _cooldownHours = 24;

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _finishSetup();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  Future<void> _finishSetup() async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final userId = supabase.currentUser?.id;
      if (userId == null) return;

      // 1. Save Persona preference (this also creates the user_profile row)
      final persona = ref.read(personaProvider).current;
      await supabase.updatePersona(userId, persona.id);

      // 2. Save Settings
      await ref.read(studyProvider.notifier).updateSettings(
        threshold: _retirementThreshold,
        cooldown: _cooldownHours,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Critical Failure: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildSubjectStep(),
                  _buildPersonaStep(),
                  _buildIntensityStep(),
                  _buildFinalStep(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ENLISTMENT PHASE: ${_currentPage + 1}/4",
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent, letterSpacing: 1.5),
              ),
              if (_currentPage > 0)
                TextButton(
                  onPressed: _previousPage,
                  child: const Text("BACK", style: TextStyle(color: Colors.white24, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentPage + 1) / 4,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation(Colors.greenAccent),
            minHeight: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    bool canProceed = true;
    if (_currentPage == 0 && _selectedSubjectIds.isEmpty) canProceed = false;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canProceed ? _nextPage : null,
          child: Text(_currentPage == 3 ? "BEGIN MISSION" : "NEXT PHASE"),
        ),
      ),
    );
  }

  Widget _buildSubjectStep() {
    final libraryState = ref.watch(libraryProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SELECT YOUR COURSES", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text("Choose the subjects you're enlisting for this term.", style: TextStyle(color: Colors.white38)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: libraryState.allSubjects.length,
              itemBuilder: (context, index) {
                final subject = libraryState.allSubjects[index];
                final isSelected = _selectedSubjectIds.contains(subject.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedSubjectIds.remove(subject.id);
                        } else {
                          _selectedSubjectIds.add(subject.id);
                        }
                      });
                      // Auto-star/enlist in library
                      ref.read(libraryProvider.notifier).toggleStar(subject.id);
                    },
                    tileColor: Colors.white.withValues(alpha: 0.03),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isSelected ? Colors.greenAccent : Colors.transparent),
                    ),
                    leading: Icon(
                      subject.iconCode == 'history' ? Icons.history_edu : Icons.public,
                      color: isSelected ? Colors.greenAccent : Colors.white24,
                    ),
                    title: Text(subject.title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.greenAccent : Colors.white)),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.greenAccent) : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaStep() {
    final personaState = ref.watch(personaProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CHOOSE YOUR MENTOR", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text("Select the persona that will guide your study sessions.", style: TextStyle(color: Colors.white38)),
          const SizedBox(height: 32),
          Expanded(
            child: personaState.isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
              : personaState.available.isEmpty
                ? const Center(child: Text("No mentors found in database.", style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    itemCount: personaState.available.length,
                    itemBuilder: (context, index) {
                      final p = personaState.available[index];
                      final isSelected = personaState.current.id == p.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () => ref.read(personaProvider.notifier).setPersona(p.id),
                          tileColor: Colors.white.withValues(alpha: 0.03),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: isSelected ? Colors.greenAccent : Colors.transparent),
                          ),
                          leading: Icon(_getPersonaIcon(p.id), color: isSelected ? Colors.greenAccent : Colors.white24),
                          title: Text(p.name, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.greenAccent : Colors.white)),
                          subtitle: Text((p.uiLabels['setup_start'] ?? "MENTOR").toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white38)),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.greenAccent) : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("STUDY INTENSITY", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text("How deep should we drill into the material?", style: TextStyle(color: Colors.white38)),
          const SizedBox(height: 32),
          _intensityOption("BALANCED", "A steady mix of all difficulty levels.", 3),
          const SizedBox(height: 16),
          _intensityOption("HIGH PRESSURE", "Aggressive drilling on high-criticality items.", 5),
          const SizedBox(height: 16),
          _intensityOption("COMPLETIONIST", "Ensures you see every single item in the pool.", 10),
          const SizedBox(height: 40),
          const Text("COOLDOWN DURATION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          const Text("How long should a mastered question stay retired?", style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: [
              _cooldownChip("24H", 24),
              _cooldownChip("72H", 72),
              _cooldownChip("1W", 168),
              _cooldownChip("PERM", 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cooldownChip(String label, int hours) {
    final isSelected = _cooldownHours == hours;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: () => setState(() => _cooldownHours = hours),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.greenAccent : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _intensityOption(String title, String desc, int threshold) {
    final isSelected = _retirementThreshold == threshold;
    return InkWell(
      onTap: () => setState(() => _retirementThreshold = threshold),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.greenAccent : Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.greenAccent : Colors.white)),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(fontSize: 12, color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user, size: 80, color: Colors.greenAccent),
          SizedBox(height: 32),
          Text("YOU ARE READY", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          SizedBox(height: 16),
          Text(
            "Your profile has been initialized. All settings can be adjusted in the tactical console later.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, height: 1.5),
          ),
        ],
      ),
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
}

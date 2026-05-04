import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/study_notifier.dart';
import '../../core/audio_service.dart';
import '../../core/persona_notifier.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/widgets/tactical_button.dart';
import '../../shared/widgets/intel_sheet.dart';

class StudyEngineScreen extends ConsumerStatefulWidget {
  const StudyEngineScreen({super.key});

  @override
  ConsumerState<StudyEngineScreen> createState() => _StudyEngineScreenState();
}

class _StudyEngineScreenState extends ConsumerState<StudyEngineScreen> {
  final TextEditingController _answerController = TextEditingController();
  bool _submitted = false;
  bool _playedResultSound = false;
  String? _selectedOption;
  
  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _submitFRQ() {
    if (_answerController.text.trim().isEmpty) return;
    setState(() => _submitted = true);
  }

  void _showIntelSheet(BuildContext context, DrillItem drill) {
    final persona = ref.read(personaProvider).current;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => IntelSheet(drill: drill, persona: persona),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studyProvider);
    final notifier = ref.read(studyProvider.notifier);
    final persona = ref.watch(personaProvider).current;

    if (state.sessionComplete) {
      if (!_playedResultSound) {
        _playedResultSound = true;
        final accuracy = state.sessionAnswered == 0 ? 0 : (state.sessionCorrect / state.sessionAnswered) * 100;
        if (accuracy >= 80) {
          AudioService.playSuccess();
        } else {
          AudioService.playFailure();
        }
      }
      return _buildResultsView(context, state, persona);
    }

    final drill = state.currentDrill;
    if (drill == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final currentQuestionNumber = min(state.sessionAnswered + 1, state.settings?.questionLimit ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: Text("${persona.getLabel('study_session', 'SESSION')}: $currentQuestionNumber/${state.settings?.questionLimit}"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (state.sessionAnswered) / (state.settings?.questionLimit ?? 1),
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(drill, persona),
                  const SizedBox(height: 24),
                  if (drill is MatchingItem) _buildMatching(drill, state, notifier),
                  if (drill is MCQItem) _buildMCQ(drill, state, notifier),
                  if (drill is FRQItem) _buildFRQ(drill, state, notifier),
                  const SizedBox(height: 32),
                  if (state.isAnswered) _buildFeedback(state, notifier, drill, persona),
                ],
              ),
            ),
          ),
          _buildActionArea(state, notifier, persona),
        ],
      ),
    );
  }

  Widget _buildHeader(DrillItem drill, Persona persona) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getCriticalityColor(drill.criticality).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                drill.criticality.name.toUpperCase(),
                style: TextStyle(color: _getCriticalityColor(drill.criticality), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showIntelSheet(context, drill),
              icon: const Icon(Icons.lightbulb_outline, size: 14, color: Colors.greenAccent),
              label: Text(persona.getLabel('study_intel', 'NEED INTEL?'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: Colors.greenAccent.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(drill.unit.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white54)),
        const SizedBox(height: 16),
        Text(
          drill.type == DrillType.mcq ? "MULTIPLE CHOICE" : (drill.type == DrillType.frq ? "FREE RESPONSE" : "MATCHING"),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.greenAccent),
        ),
      ],
    );
  }

  Color _getCriticalityColor(Criticality c) {
    switch (c) {
      case Criticality.high: return Colors.redAccent;
      case Criticality.medium: return Colors.orangeAccent;
      case Criticality.low: return Colors.blueAccent;
    }
  }

  Widget _buildFeedback(StudyState state, StudyNotifier notifier, DrillItem drill, Persona persona) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: state.isCorrect ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: state.isCorrect ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(state.isCorrect ? Icons.check_circle : Icons.error, color: state.isCorrect ? Colors.greenAccent : Colors.redAccent),
              const SizedBox(width: 12),
              Text(
                state.isCorrect 
                  ? persona.getLabel('study_success', 'MISSION SUCCESS') 
                  : persona.getLabel('study_failure', 'MISSION FAILURE'),
                style: TextStyle(fontWeight: FontWeight.bold, color: state.isCorrect ? Colors.greenAccent : Colors.redAccent),
              ),
              const Spacer(),
              if (!state.isCorrect && drill.type != DrillType.mcq)
                TextButton(
                  onPressed: () => notifier.overrideCorrect(),
                  child: const Text("I WAS RIGHT", style: TextStyle(fontSize: 12, color: Colors.white54)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(state.lastFeedback ?? "", style: const TextStyle(fontSize: 16, height: 1.4)),
          if (!state.isCorrect) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showIntelSheet(context, drill),
                icon: const Icon(Icons.menu_book, size: 16),
                label: Text(persona.getLabel('study_review', 'REVIEW CRASH COURSE')),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ],
      ).animate().slideY(begin: 0.2, curve: Curves.easeOutQuad).fadeIn(),
    );
  }

  Widget _buildActionArea(StudyState state, StudyNotifier notifier, Persona persona) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.black, border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: TacticalButton(
            persona: persona,
            labelKey: 'study_continue',
            fallback: 'CONTINUE MISSION',
            fullWidth: true,
            onPressed: state.isAnswered ? () {
              _answerController.clear();
              setState(() {
                _submitted = false;
                _selectedOption = null;
              });
              notifier.nextDrill();
            } : null,
          ),
        ),
      ),
    );
  }

  Widget _buildMatching(MatchingItem drill, StudyState state, StudyNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("TERM", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(drill.term, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        const Text("SELECT THE CORRECT DEFINITION", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...state.matchingOptions.map((def) => _buildDefinitionOption(def, def == drill.definition, state, notifier)),
      ],
    );
  }

  Widget _buildDefinitionOption(String text, bool isCorrect, StudyState state, StudyNotifier notifier) {
    bool isPicked = state.isAnswered && _selectedOption == text;
    bool isAnswer = state.isAnswered && isCorrect;
    
    Color bgColor = Colors.white.withValues(alpha: 0.05);
    Color borderColor = Colors.white10;
    
    if (state.isAnswered) {
      if (isAnswer) {
        bgColor = Colors.green.withValues(alpha: 0.2);
        borderColor = Colors.greenAccent;
      } else if (isPicked) {
        bgColor = Colors.red.withValues(alpha: 0.2);
        borderColor = Colors.redAccent;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: state.isAnswered ? null : () {
          setState(() => _selectedOption = text);
          notifier.submitAnswer(isCorrect);
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
          child: Row(
            children: [
              Expanded(child: Text(text)),
              if (state.isAnswered && isCorrect) const Icon(Icons.check, color: Colors.greenAccent),
              if (state.isAnswered && isPicked && !isCorrect) const Icon(Icons.close, color: Colors.redAccent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMCQ(MCQItem drill, StudyState state, StudyNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (drill.stimulus.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), border: Border(left: BorderSide(color: Colors.greenAccent, width: 3))),
            child: Text(drill.stimulus, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.white70, height: 1.5)),
          ),
          const SizedBox(height: 24),
        ],
        Text(drill.question, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4)),
        const SizedBox(height: 32),
        ...state.mcqOptions.map((opt) {
          final optionKey = opt.trim().split(')').first.trim();
          bool isCorrect = optionKey == drill.correctAnswer.trim();
          bool isPicked = state.isAnswered && _selectedOption == opt;
          
          Color bgColor = Colors.white.withValues(alpha: 0.05);
          Color borderColor = Colors.white10;
          
          if (state.isAnswered) {
            if (isCorrect) {
              bgColor = Colors.green.withValues(alpha: 0.2);
              borderColor = Colors.greenAccent;
            } else if (isPicked) {
              bgColor = Colors.red.withValues(alpha: 0.2);
              borderColor = Colors.redAccent;
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: state.isAnswered ? null : () {
                setState(() => _selectedOption = opt);
                notifier.submitAnswer(isCorrect);
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                child: Row(
                  children: [
                    Expanded(child: Text(opt)),
                    if (state.isAnswered && isCorrect) const Icon(Icons.check, color: Colors.greenAccent),
                    if (state.isAnswered && isPicked && !isCorrect) const Icon(Icons.close, color: Colors.redAccent),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFRQ(FRQItem drill, StudyState state, StudyNotifier notifier) {
    final persona = ref.read(personaProvider).current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(drill.prompt, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.4)),
        const SizedBox(height: 32),
        TextField(
          controller: _answerController,
          maxLines: 5,
          enabled: !_submitted,
          decoration: InputDecoration(
            hintText: "Bullet out your answer...",
            fillColor: Colors.white.withValues(alpha: 0.05),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        if (!_submitted)
          TacticalButton(
            persona: persona,
            labelKey: 'study_reveal',
            fallback: 'REVEAL RUBRIC',
            fullWidth: true,
            onPressed: _submitFRQ,
          ),
        if (_submitted) ...[
          const Text("SCORING RUBRIC", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 12),
          ...drill.rubricBulletPoints.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ", style: TextStyle(color: Colors.greenAccent)),
                Expanded(child: Text(point, style: const TextStyle(color: Colors.white70))),
              ],
            ),
          )),
          const SizedBox(height: 24),
          if (!state.isAnswered)
            Column(
              children: [
                const Text("HOW DID YOU DO?", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 10)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => notifier.submitAnswer(true), style: OutlinedButton.styleFrom(foregroundColor: Colors.greenAccent, side: const BorderSide(color: Colors.greenAccent)), child: Text(persona.getLabel('study_correct', 'CORRECT')))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () => notifier.submitAnswer(true), style: OutlinedButton.styleFrom(foregroundColor: Colors.orangeAccent, side: const BorderSide(color: Colors.orangeAccent)), child: Text(persona.getLabel('study_partial', 'PARTIAL')))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () => notifier.submitAnswer(false), style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)), child: Text(persona.getLabel('study_failed', 'FAILED')))),
                  ],
                ),
              ],
            ).animate().fadeIn().slideY(begin: 0.1),
        ],
      ],
    );
  }

  Widget _buildResultsView(BuildContext context, StudyState state, Persona persona) {
    final accuracy = state.sessionAnswered == 0 ? 0 : (state.sessionCorrect / state.sessionAnswered) * 100;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.analytics, size: 80, color: Colors.greenAccent),
              const SizedBox(height: 24),
              Text(persona.getLabel('study_results', 'DEBRIEF COMPLETE'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 40),
              _resultRow(persona.getLabel('study_accuracy', 'FINAL ACCURACY'), "${accuracy.toInt()}%"),
              _resultRow(persona.getLabel('study_answered', 'DRILLS COMPLETED'), state.sessionAnswered.toString()),
              const SizedBox(height: 60),
              TacticalButton(
                persona: persona,
                labelKey: 'study_exit',
                fallback: 'RETURN TO BASE',
                fullWidth: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

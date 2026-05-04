import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models.dart';
import '../../core/study_notifier.dart';
import '../../core/audio_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    const trapMarker = "The AP Trap:";
    const mdMarker = "**The AP Trap:**";
    
    String courseText = drill.crashCourse;
    String? trapText;
    
    if (drill.crashCourse.contains(mdMarker)) {
      final parts = drill.crashCourse.split(mdMarker);
      courseText = parts[0].trim();
      trapText = parts.length > 1 ? parts[1].trim() : null;
    } else if (drill.crashCourse.contains(trapMarker)) {
      final parts = drill.crashCourse.split(trapMarker);
      courseText = parts[0].trim();
      trapText = parts.length > 1 ? parts[1].trim() : null;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.greenAccent, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    "TACTICAL BRIEFING",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.greenAccent),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 32),
              const Text("CRASH COURSE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 2.0)),
              const SizedBox(height: 12),
              Text(courseText, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white)),
              if (trapText != null && trapText.isNotEmpty) ...[
                const SizedBox(height: 32),
                const Text("THE AP TRAP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orangeAccent, letterSpacing: 2.0)),
                const SizedBox(height: 12),
                Text(trapText, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white)),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ).animate().slideY(begin: 1.0, curve: Curves.easeOutQuad);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studyProvider);
    final notifier = ref.read(studyProvider.notifier);

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
      return _buildResultsView(context, state);
    }

    final drill = state.currentDrill;
    if (drill == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final currentQuestionNumber = min(state.sessionAnswered + 1, state.settings?.questionLimit ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: Text("SESSION: $currentQuestionNumber/${state.settings?.questionLimit}"),
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
                  _buildHeader(drill),
                  const SizedBox(height: 24),
                  if (drill is MatchingItem) _buildMatching(drill, state, notifier),
                  if (drill is MCQItem) _buildMCQ(drill, state, notifier),
                  if (drill is FRQItem) _buildFRQ(drill, state, notifier),
                  const SizedBox(height: 32),
                  if (state.isAnswered) _buildFeedback(state, notifier, drill),
                ],
              ),
            ),
          ),
          _buildActionArea(state, notifier),
        ],
      ),
    );
  }

  Widget _buildHeader(DrillItem drill) {
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
              label: const Text("NEED INTEL?", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
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

  Widget _buildFeedback(StudyState state, StudyNotifier notifier, DrillItem drill) {
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
                state.isCorrect ? "MISSION SUCCESS" : "MISSION FAILURE",
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
                label: const Text("REVIEW CRASH COURSE"),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ],
      ).animate().slideY(begin: 0.2, curve: Curves.easeOutQuad).fadeIn(),
    );
  }

  Widget _buildActionArea(StudyState state, StudyNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.black, border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.isAnswered ? () {
              _answerController.clear();
              setState(() {
                _submitted = false;
                _selectedOption = null;
              });
              notifier.nextDrill();
            } : null,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
            child: const Text("CONTINUE MISSION"),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _submitFRQ, child: const Text("REVEAL RUBRIC")),
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
                    Expanded(child: OutlinedButton(onPressed: () => notifier.submitAnswer(true), style: OutlinedButton.styleFrom(foregroundColor: Colors.greenAccent, side: const BorderSide(color: Colors.greenAccent)), child: const Text("CORRECT"))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () => notifier.submitAnswer(true), style: OutlinedButton.styleFrom(foregroundColor: Colors.orangeAccent, side: const BorderSide(color: Colors.orangeAccent)), child: const Text("PARTIAL"))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () => notifier.submitAnswer(false), style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)), child: const Text("FAILED"))),
                  ],
                ),
              ],
            ).animate().fadeIn().slideY(begin: 0.1),
        ],
      ],
    );
  }

  Widget _buildResultsView(BuildContext context, StudyState state) {
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
              const Text("DEBRIEF COMPLETE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 40),
              _resultRow("FINAL ACCURACY", "${accuracy.toInt()}%"),
              _resultRow("DRILLS COMPLETED", state.sessionAnswered.toString()),
              const SizedBox(height: 60),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("RETURN TO BASE"))),
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

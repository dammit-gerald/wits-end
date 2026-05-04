import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/study_notifier.dart';
import '../setup/setup_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 350,
                  fit: BoxFit.contain,
                ).animate().fadeIn(duration: 1000.ms).scale(begin: const Offset(0.9, 0.9)),
              ),
              const Spacer(flex: 2),
              _buildStatsCard(context, ref),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SetupScreen()),
                  );
                },
                child: const Text("START DRILLING"),
              ).animate().scale(delay: 800.ms, curve: Curves.elasticOut),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => _showResetConfirmation(context, ref),
                child: const Text(
                  "RESET STATS",
                  style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
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
          _statItem("ACCURACY", "${accuracy.toInt()}%"),
          Container(width: 1, height: 40, color: Colors.white10),
          _statItem("ANSWERS", state.totalAnswered.toString()),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

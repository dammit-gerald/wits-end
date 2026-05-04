import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models.dart';
import '../../core/study_notifier.dart';
import '../../core/audio_service.dart';
import '../drills/study_engine_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final List<String> _selectedUnits = [];
  final List<DrillType> _selectedTypes = [DrillType.matching, DrillType.mcq, DrillType.frq];
  int _questionLimit = 20;
  StudyIntensity _intensity = StudyIntensity.balanced;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final units = await ref.read(studyProvider.notifier).getAvailableUnits();
    setState(() {
      _selectedUnits.addAll(units);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("STRATEGIC BRIEFING"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text("SELECT UNITS", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FutureBuilder<List<String>>(
                  future: ref.read(studyProvider.notifier).getAvailableUnits(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final units = snapshot.data!;
                    return ListView.builder(
                      itemCount: units.length,
                      itemBuilder: (context, index) {
                        final unit = units[index];
                        final isSelected = _selectedUnits.contains(unit);
                        final stats = state.globalUnitStats[unit];
                        final accuracyText = stats == null ? "NO DATA" : "${stats.accuracy.toInt()}% (${stats.correct}/${stats.total})";
                        
                        return CheckboxListTile(
                          title: Text(unit, style: const TextStyle(fontSize: 14)),
                          subtitle: Text(
                            accuracyText,
                            style: TextStyle(
                              fontSize: 10,
                              color: stats == null ? Colors.white24 : (stats.accuracy > 70 ? Colors.greenAccent : Colors.redAccent),
                            ),
                          ),
                          value: isSelected,
                          activeColor: Colors.greenAccent,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedUnits.add(unit);
                              } else {
                                _selectedUnits.remove(unit);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              const Text("DRILL TYPES", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DrillType.values.map((type) {
                  final isSelected = _selectedTypes.contains(type);
                  String label;
                  switch (type) {
                    case DrillType.matching: label = "MATCHING"; break;
                    case DrillType.mcq: label = "MULTIPLE CHOICE"; break;
                    case DrillType.frq: label = "FREE RESPONSE"; break;
                  }
                  return FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: Colors.greenAccent.withValues(alpha: 0.2),
                    checkmarkColor: Colors.greenAccent,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedTypes.add(type);
                        } else if (_selectedTypes.length > 1) {
                          _selectedTypes.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              const Text("INTENSITY PRESET", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 12),
              Column(
                children: StudyIntensity.values.map((intensity) {
                  final isSelected = _intensity == intensity;
                  String title;
                  String subtitle;
                  IconData icon;
                  Color color;

                  switch (intensity) {
                    case StudyIntensity.high:
                      title = "HIGH INTENSITY";
                      subtitle = "Focus heavily on High Criticality items (80%).";
                      icon = Icons.bolt;
                      color = Colors.redAccent;
                      break;
                    case StudyIntensity.balanced:
                      title = "BALANCED";
                      subtitle = "Even mix across all criticality levels.";
                      icon = Icons.balance;
                      color = Colors.blueAccent;
                      break;
                    case StudyIntensity.completionist:
                      title = "COMPLETIONIST";
                      subtitle = "Prioritize Low Criticality and unattempted items.";
                      icon = Icons.checklist;
                      color = Colors.greenAccent;
                      break;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => setState(() => _intensity = intensity),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, color: isSelected ? color : Colors.white24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? color : Colors.white)),
                                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white54)),
                                ],
                              ),
                            ),
                            if (isSelected) Icon(Icons.check_circle, color: color, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              const Text("QUESTION LIMIT", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [10, 20, 50, 100].map((limit) {
                  return ChoiceChip(
                    label: Text(limit.toString()),
                    selected: _questionLimit == limit,
                    onSelected: (val) {
                      if (val) setState(() => _questionLimit = limit);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedUnits.isEmpty ? null : () async {
                    AudioService.playStart();
                    final notifier = ref.read(studyProvider.notifier);
                    await notifier.startSession(SessionSettings(
                      units: _selectedUnits,
                      types: _selectedTypes,
                      questionLimit: _questionLimit,
                      intensity: _intensity,
                    ));
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StudyEngineScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: const Text("LET'S GO"),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/models/models.dart';

class IntelSheet extends StatelessWidget {
  final DrillItem drill;
  final Persona persona;

  const IntelSheet({
    super.key,
    required this.drill,
    required this.persona,
  });

  @override
  Widget build(BuildContext context) {
    final trapLabel = persona.getLabel('study_trap', 'THE AP TRAP');
    
    // Scrub the content of hardcoded "AP Trap" language
    String processedContent = drill.crashCourse.replaceAll('The AP Trap:', '$trapLabel:');
    processedContent = processedContent.replaceAll('**The AP Trap:**', '**$trapLabel:**');

    // Split content into main body and "trap" sections
    final lines = processedContent.split('\n');
    final mainLines = lines.where((l) => !l.trim().startsWith('**') && !l.trim().contains(trapLabel)).toList();
    final trapLines = lines.where((l) => l.trim().startsWith('**') || l.trim().contains(trapLabel)).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.greenAccent),
              const SizedBox(width: 12),
              Text(
                persona.getLabel('study_intel', 'TACTICAL INTEL').toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: Colors.white12),
          if (mainLines.isNotEmpty) ...[
            Text(
              persona.getLabel('study_review', 'MISSION OVERVIEW'),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.greenAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              mainLines.join('\n').trim(),
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (trapLines.isNotEmpty) ...[
            Text(
              trapLabel.toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.orangeAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...trapLines.map((l) {
              final cleanText = l.replaceAll('**', '').replaceAll('$trapLabel:', '').trim();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  cleanText,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.orangeAccent,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(persona.getLabel('study_continue', 'UNDERSTOOD')),
            ),
          ),
        ],
      ),
    );
  }
}

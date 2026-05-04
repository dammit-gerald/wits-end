class Persona {
  final String id;
  final String name;
  final Map<String, String> uiLabels;
  final List<String> positiveFeedback;
  final List<String> negativeFeedback;

  Persona({
    required this.id,
    required this.name,
    required this.uiLabels,
    required this.positiveFeedback,
    required this.negativeFeedback,
  });

  String getLabel(String key, String fallback) => uiLabels[key] ?? fallback;

  factory Persona.fromMap(Map<String, dynamic> map) {
    return Persona(
      id: map['id'] ?? 'unknown',
      name: map['name'] ?? 'Unknown Persona',
      uiLabels: Map<String, String>.from(map['ui_labels'] ?? {}),
      positiveFeedback: List<String>.from(map['feedback_banks']?['positive'] ?? []),
      negativeFeedback: List<String>.from(map['feedback_banks']?['negative'] ?? []),
    );
  }

  /// Bare-bones default for initialization.
  /// All real content is loaded from Supabase.
  static Persona gerald() => Persona(
    id: 'gerald',
    name: 'Gerald',
    uiLabels: {
      'dashboard_start': 'INITIALIZE DRILLS',
      'dashboard_library': 'TACTICAL LIBRARY',
      'setup_title': 'STRATEGIC BRIEFING',
      'setup_start': "LET'S GO",
    },
    positiveFeedback: ['Excellent work.'],
    negativeFeedback: ['Error detected.'],
  );
}

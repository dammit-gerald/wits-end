enum DrillType { matching, mcq, frq }
enum Criticality { high, medium, low }
enum StudyIntensity { high, balanced, completionist }

extension CriticalityExtension on Criticality {
  int get weight {
    switch (this) {
      case Criticality.high: return 3;
      case Criticality.medium: return 2;
      case Criticality.low: return 1;
    }
  }

  static Criticality fromString(String value) {
    switch (value.toLowerCase()) {
      case 'high': return Criticality.high;
      case 'medium': return Criticality.medium;
      case 'low':
      default: return Criticality.low;
    }
  }
}

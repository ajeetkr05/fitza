/// PLACEHOLDER - the calorie tracker is being built as a separate feature.
/// This class defines the minimal shape RecommendationService needs from it.
/// When the real calorie tracker model exists, either:
///   (a) rename/replace this file to match the real model, or
///   (b) add a small mapper function that converts the real model into
///       this shape, so RecommendationService itself doesn't need edits.
class CalorieSummary {
  final double targetCalories;
  final double consumedCalories;

  const CalorieSummary({
    required this.targetCalories,
    required this.consumedCalories,
  });

  double get remaining => targetCalories - consumedCalories;

  /// True if the user is eating meaningfully below target (>15% under).
  /// Used to slightly reduce workout volume so recovery isn't compromised.
  bool get isSignificantDeficit =>
      targetCalories > 0 && (remaining / targetCalories) > 0.15;
}

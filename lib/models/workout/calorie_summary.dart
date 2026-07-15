/// Summarises today's calorie intake vs target, used by RecommendationService
/// to trim workout volume slightly when the user is running a significant
/// deficit.
///
/// TARGET VALUE NOTE: there's no per-user personalized calorie target
/// stored anywhere yet (checked UserProfile and all Nutrition models) - the
/// Nutrition history screen currently uses a hardcoded default of 2200.0
/// for everyone. Using that same constant here for consistency, so this
/// feature and the Nutrition tab agree with each other. If/when a real
/// personalized target (e.g. BMR/TDEE-based) is added, update
/// `kDefaultTargetCalories` here AND wherever the Nutrition screen defines
/// it - ideally these should be pulled from one shared source, not
/// duplicated constants, once that work happens.
const double kDefaultTargetCalories = 2200.0;

class CalorieSummary {
  final double targetCalories;
  final double consumedCalories;

  const CalorieSummary({
    required this.targetCalories,
    required this.consumedCalories,
  });

  /// Builds a summary from a list of today's MealEntry.totalCalories values.
  /// Pass the target explicitly if a personalized one becomes available
  /// later; defaults to the shared placeholder constant otherwise.
  factory CalorieSummary.fromDailyTotals(
    List<double> mealCalorieTotals, {
    double targetCalories = kDefaultTargetCalories,
  }) {
    final consumed = mealCalorieTotals.fold<double>(0, (sum, cal) => sum + cal);
    return CalorieSummary(targetCalories: targetCalories, consumedCalories: consumed);
  }

  double get remaining => targetCalories - consumedCalories;

  /// True if the user is eating meaningfully below target (>15% under).
  /// Used to slightly reduce workout volume so recovery isn't compromised.
  bool get isSignificantDeficit =>
      targetCalories > 0 && (remaining / targetCalories) > 0.15;
}

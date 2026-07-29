import 'dart:math' as math;
import '../models/models.dart';

/// NutritionCalculator — pure computation engine, no Flutter dependencies.
/// Maps portions to weights, computes macro ranges from per-100g data.
class NutritionCalculator {
  /// Calculate nutrition for a food item with a specific portion and quantity.
  NutritionRange calculateForPortion({
    required FoodItem food,
    required PortionSize portion,
    double quantity = 1.0,
  }) {
    final totalWeightG = portion.weightMidG * quantity;
    return _calculateForWeight(food, totalWeightG);
  }

  /// Calculate nutrition for a food item by explicit gram weight.
  NutritionRange calculateForWeight({
    required FoodItem food,
    required double weightG,
  }) {
    return _calculateForWeight(food, weightG);
  }

  NutritionRange _calculateForWeight(FoodItem food, double weightG) {
    final factor = weightG / 100.0;
    final p100 = food.per100g;
    return NutritionRange(
      caloriesMin: (p100.caloriesMin * factor).roundToDouble(),
      caloriesMax: (p100.caloriesMax * factor).roundToDouble(),
      protein: _round1(p100.protein * factor),
      carbs: _round1(p100.carbs * factor),
      fat: _round1(p100.fat * factor),
      fiber: _round1(p100.fiber * factor),
      confidence: food.confidenceLevel,
    );
  }

  /// Calculate total nutrition for a meal (sum of all items).
  NutritionRange calculateMealTotal(List<MealItem> items) {
    if (items.isEmpty) return NutritionRange.zero;
    return items.fold(NutritionRange.zero, (sum, item) => sum + item.nutrition);
  }

  /// Calculate whole-recipe nutrition (sum of all ingredients).
  NutritionRange calculateRecipeTotal(Recipe recipe) {
    if (recipe.ingredients.isEmpty) return NutritionRange.zero;

    NutritionRange total = NutritionRange.zero;
    for (final ingredient in recipe.ingredients) {
      if (ingredient.food != null) {
        final ingredientNutrition = _calculateForWeight(
          ingredient.food!,
          ingredient.quantityG,
        );
        total = total + ingredientNutrition;
      }
    }
    return total;
  }

  /// Calculate per-serving nutrition for a recipe.
  NutritionRange calculateRecipePerServing(Recipe recipe) {
    final total = calculateRecipeTotal(recipe);
    if (recipe.servings <= 0) return total;

    final s = recipe.servings.toDouble();
    return NutritionRange(
      caloriesMin: (total.caloriesMin / s).roundToDouble(),
      caloriesMax: (total.caloriesMax / s).roundToDouble(),
      protein: _round1(total.protein / s),
      carbs: _round1(total.carbs / s),
      fat: _round1(total.fat / s),
      fiber: _round1(total.fiber / s),
      confidence: total.confidence,
    );
  }

  /// Estimate how changing oil affects a recipe's calories.
  /// Returns calorie difference per serving.
  double estimateOilCalorieDiff({
    required double oldOilMl,
    required double newOilMl,
    required int servings,
  }) {
    // ~900 kcal per 100ml of oil = 9 kcal/ml
    const kcalPerMl = 9.0;
    final diff = (newOilMl - oldOilMl) * kcalPerMl;
    return diff / servings;
  }

  double _round1(double v) => (v * 10).round() / 10;
}

/// BMICalculator — calculates BMI and category.
class BMICalculator {
  double calculate({required double weightKg, required double heightCm}) {
    if (heightCm <= 0 || weightKg <= 0) return 0;
    final heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }

  BMICategory categorize(double bmi) {
    if (bmi < 18.5) return BMICategory.underweight;
    if (bmi < 25.0) return BMICategory.normal;
    if (bmi < 30.0) return BMICategory.overweight;
    if (bmi < 35.0) return BMICategory.obese1;
    return BMICategory.obese2;
  }
}

enum BMICategory { underweight, normal, overweight, obese1, obese2 }

extension BMICategoryExt on BMICategory {
  String get label {
    switch (this) {
      case BMICategory.underweight:
        return 'Underweight';
      case BMICategory.normal:
        return 'Healthy Weight';
      case BMICategory.overweight:
        return 'Overweight';
      case BMICategory.obese1:
        return 'Obese (Class I)';
      case BMICategory.obese2:
        return 'Obese (Class II+)';
    }
  }

  String get emoji {
    switch (this) {
      case BMICategory.underweight:
        return '⬇️';
      case BMICategory.normal:
        return '✅';
      case BMICategory.overweight:
        return '⚠️';
      case BMICategory.obese1:
      case BMICategory.obese2:
        return '🔴';
    }
  }
}

/// BMRCalculator — uses Mifflin-St Jeor equation.
class BMRCalculator {
  /// Calculate BMR using Mifflin-St Jeor equation (kcal/day).
  double calculate({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    switch (gender) {
      case Gender.male:
        return base + 5;
      case Gender.female:
        return base - 161;
      case Gender.other:
        return base - 78; // midpoint estimate
    }
  }

  /// Estimate TDEE (Total Daily Energy Expenditure) from BMR and activity.
  double estimateTDEE(double bmr, ActivityLevel activityLevel) {
    final multiplier = _activityMultiplier(activityLevel);
    return bmr * multiplier;
  }

  /// Calculate daily calorie target based on goal.
  /// Deficit of 300–500 kcal for weight loss, surplus of 300–500 for gain.
  int calculateDailyTarget(double tdee, WeightGoal goal) {
    switch (goal) {
      case WeightGoal.lose:
        return (tdee - 400).round().clamp(1200, 999999);
      case WeightGoal.maintain:
        return tdee.round();
      case WeightGoal.gain:
        return (tdee + 300).round();
    }
  }

  /// Estimate daily protein target (g) based on weight and goal.
  double calculateProteinTarget(double weightKg, WeightGoal goal) {
    switch (goal) {
      case WeightGoal.lose:
        return weightKg * 1.6; // Higher protein during deficit
      case WeightGoal.maintain:
        return weightKg * 1.2;
      case WeightGoal.gain:
        return weightKg * 1.8;
    }
  }

  double _activityMultiplier(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.lightlyActive:
        return 1.375;
      case ActivityLevel.moderatelyActive:
        return 1.55;
      case ActivityLevel.veryActive:
        return 1.725;
      case ActivityLevel.extraActive:
        return 1.9;
    }
  }
}

/// ActivityCalculator — estimates calories burned using MET values.
class ActivityCalculator {
  static const _metValues = {
    ActivityType.walking: {
      ActivityIntensity.light: 2.5,
      ActivityIntensity.moderate: 3.5,
      ActivityIntensity.vigorous: 4.5,
    },
    ActivityType.running: {
      ActivityIntensity.light: 7.0,
      ActivityIntensity.moderate: 9.0,
      ActivityIntensity.vigorous: 12.0,
    },
    ActivityType.cycling: {
      ActivityIntensity.light: 4.0,
      ActivityIntensity.moderate: 6.8,
      ActivityIntensity.vigorous: 10.0,
    },
    ActivityType.swimming: {
      ActivityIntensity.light: 5.0,
      ActivityIntensity.moderate: 7.0,
      ActivityIntensity.vigorous: 10.0,
    },
    ActivityType.strengthTraining: {
      ActivityIntensity.light: 3.0,
      ActivityIntensity.moderate: 5.0,
      ActivityIntensity.vigorous: 6.0,
    },
    ActivityType.yoga: {
      ActivityIntensity.light: 2.5,
      ActivityIntensity.moderate: 3.3,
      ActivityIntensity.vigorous: 4.0,
    },
    ActivityType.householdWork: {
      ActivityIntensity.light: 2.0,
      ActivityIntensity.moderate: 3.0,
      ActivityIntensity.vigorous: 4.0,
    },
    ActivityType.other: {
      ActivityIntensity.light: 3.0,
      ActivityIntensity.moderate: 5.0,
      ActivityIntensity.vigorous: 7.0,
    },
  };

  /// Estimate calories burned using MET formula:
  /// Calories = MET × weight_kg × time_hours
  double estimate({
    required ActivityType activity,
    required int durationMinutes,
    required double weightKg,
    ActivityIntensity intensity = ActivityIntensity.moderate,
  }) {
    final met = _metValues[activity]?[intensity] ?? 4.0;
    final hours = durationMinutes / 60.0;
    return met * weightKg * hours;
  }

  /// Get default activity estimates for the Fact Corner.
  List<ActivityEstimate> getDefaultEstimates(double weightKg) {
    return [
      ActivityEstimate(
        activity: ActivityType.walking,
        durationMinutes: 30,
        intensity: ActivityIntensity.moderate,
        label: '30 min walk',
        emoji: '🚶',
        calories: estimate(
          activity: ActivityType.walking,
          durationMinutes: 30,
          weightKg: weightKg,
        ).round().toDouble(),
      ),
      ActivityEstimate(
        activity: ActivityType.walking,
        durationMinutes: 60,
        intensity: ActivityIntensity.moderate,
        label: '60 min walk',
        emoji: '🚶',
        calories: estimate(
          activity: ActivityType.walking,
          durationMinutes: 60,
          weightKg: weightKg,
        ).round().toDouble(),
      ),
      ActivityEstimate(
        activity: ActivityType.running,
        durationMinutes: 20,
        intensity: ActivityIntensity.moderate,
        label: '20 min run',
        emoji: '🏃',
        calories: estimate(
          activity: ActivityType.running,
          durationMinutes: 20,
          weightKg: weightKg,
        ).round().toDouble(),
      ),
      ActivityEstimate(
        activity: ActivityType.running,
        durationMinutes: 30,
        intensity: ActivityIntensity.moderate,
        label: '30 min run',
        emoji: '🏃',
        calories: estimate(
          activity: ActivityType.running,
          durationMinutes: 30,
          weightKg: weightKg,
        ).round().toDouble(),
      ),
      ActivityEstimate(
        activity: ActivityType.cycling,
        durationMinutes: 30,
        intensity: ActivityIntensity.moderate,
        label: '30 min cycling',
        emoji: '🚴',
        calories: estimate(
          activity: ActivityType.cycling,
          durationMinutes: 30,
          weightKg: weightKg,
        ).round().toDouble(),
      ),
      ActivityEstimate(
        activity: ActivityType.yoga,
        durationMinutes: 45,
        intensity: ActivityIntensity.moderate,
        label: '45 min yoga',
        emoji: '🧘',
        calories: estimate(
          activity: ActivityType.yoga,
          durationMinutes: 45,
          weightKg: weightKg,
        ).round().toDouble(),
      ),
    ];
  }
}

class ActivityEstimate {
  final ActivityType activity;
  final int durationMinutes;
  final ActivityIntensity intensity;
  final String label;
  final String emoji;
  final double calories;

  const ActivityEstimate({
    required this.activity,
    required this.durationMinutes,
    required this.intensity,
    required this.label,
    required this.emoji,
    required this.calories,
  });
}

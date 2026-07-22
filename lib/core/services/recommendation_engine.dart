import '../models/models.dart';
import 'nutrition_calculator.dart';

/// RecommendationEngine — offline, rule-based meal suggestions.
/// Uses the user's household foods, remaining calorie/protein budget,
/// and meal type to suggest appropriate meal combinations.
class RecommendationEngine {
  final NutritionCalculator _calculator;

  RecommendationEngine(this._calculator);

  /// Generate meal recommendations based on remaining nutrition budget.
  List<MealRecommendation> recommend({
    required UserProfile user,
    required UserGoal goal,
    required double remainingCalories,
    required double remainingProtein,
    required List<FoodItem> householdFoods,
    required MealType mealType,
    int count = 3,
  }) {
    if (householdFoods.isEmpty) return [];

    // Filter foods appropriate for this meal type
    final mealFoods = householdFoods
        .where((f) =>
            f.mealTypes.isEmpty ||
            f.mealTypes.contains(mealType.name))
        .toList();

    if (mealFoods.isEmpty) return householdFoods.length > 3
        ? _generateCombinations(
            householdFoods.take(20).toList(),
            remainingCalories,
            remainingProtein,
            count,
            mealType,
          )
        : [];

    return _generateCombinations(
      mealFoods.take(20).toList(),
      remainingCalories,
      remainingProtein,
      count,
      mealType,
    );
  }

  List<MealRecommendation> _generateCombinations(
    List<FoodItem> foods,
    double targetCalories,
    double targetProtein,
    int count,
    MealType mealType,
  ) {
    // Separate into carbs, proteins, vegetables, extras
    final proteins = foods.where((f) => f.per100g.protein >= 10).toList();
    final carbs = foods
        .where((f) =>
            f.per100g.carbs >= 20 && !_isProtein(f) && !_isVegetable(f))
        .toList();
    final vegetables =
        foods.where((f) => _isVegetable(f) && f.per100g.caloriesMid < 100).toList();
    final legumes = foods.where((f) => f.category == 'legumes').toList();

    final recommendations = <MealRecommendation>[];

    // Strategy 1: Protein + Carb + Vegetable
    if (proteins.isNotEmpty && carbs.isNotEmpty) {
      final protein = proteins.first;
      final carb = carbs.first;
      final items = [protein, carb];
      if (vegetables.isNotEmpty) items.add(vegetables.first);

      final nutrition = _estimateMealNutrition(items);
      if (nutrition.caloriesMid <= targetCalories * 1.1) {
        recommendations.add(MealRecommendation(
          title: _buildTitle(items, rank: 1),
          foods: items,
          estimatedNutrition: nutrition,
          reasoning: '${_icon(protein.isVegetarian)} High protein combo',
          rank: 1,
        ));
      }
    }

    // Strategy 2: Dal + Roti/Rice (classic Indian)
    if (legumes.isNotEmpty) {
      final dal = legumes.first;
      final grain = carbs.isNotEmpty ? carbs.first : null;
      final items = grain != null ? [dal, grain] : [dal];
      final nutrition = _estimateMealNutrition(items);

      if (nutrition.caloriesMid <= targetCalories * 1.1) {
        recommendations.add(MealRecommendation(
          title: _buildTitle(items, rank: 2),
          foods: items,
          estimatedNutrition: nutrition,
          reasoning: '🌱 Balanced vegetarian option',
          rank: 2,
        ));
      }
    }

    // Strategy 3: Light/low-calorie if budget is small
    if (targetCalories < 400 && vegetables.isNotEmpty) {
      final items = vegetables.take(2).toList();
      if (legumes.isNotEmpty) items.add(legumes.first);

      final nutrition = _estimateMealNutrition(items);
      recommendations.add(MealRecommendation(
        title: _buildTitle(items, rank: 3),
        foods: items,
        estimatedNutrition: nutrition,
        reasoning: '🥗 Light option for your remaining budget',
        rank: 3,
      ));
    }

    // Fill remaining spots with other combinations
    if (recommendations.length < count && foods.length >= 2) {
      for (int i = 0; i < foods.length - 1 && recommendations.length < count; i++) {
        final items = [foods[i], foods[i + 1]];
        final nutrition = _estimateMealNutrition(items);
        final exists = recommendations
            .any((r) => r.foods.any((f) => items.any((ii) => ii.id == f.id)));
        if (!exists && nutrition.caloriesMid <= targetCalories * 1.15) {
          recommendations.add(MealRecommendation(
            title: _buildTitle(items, rank: recommendations.length + 1),
            foods: items,
            estimatedNutrition: nutrition,
            reasoning: '🏠 From your household kitchen',
            rank: recommendations.length + 1,
          ));
        }
      }
    }

    return recommendations.take(count).toList();
  }

  /// Suggest ways to make a meal lighter.
  List<LighterSuggestion> suggestLighter(List<MealItem> currentItems) {
    final suggestions = <LighterSuggestion>[];

    for (final item in currentItems) {
      if (item.food == null) continue;
      final food = item.food!;

      // Suggestion: reduce portion
      if (item.nutrition.caloriesMid > 300) {
        suggestions.add(LighterSuggestion(
          item: item,
          suggestion:
              'Reduce ${food.name} portion by half → save ~${(item.nutrition.caloriesMid * 0.4).round()} kcal',
          estimatedCalorieSaving: item.nutrition.caloriesMid * 0.4,
        ));
      }

      // Suggestion: high-fat foods
      if (food.per100g.fat > 15) {
        suggestions.add(LighterSuggestion(
          item: item,
          suggestion:
              '${food.name} is higher in fat. Try a smaller serving → save ~${(item.nutrition.caloriesMid * 0.25).round()} kcal',
          estimatedCalorieSaving: item.nutrition.caloriesMid * 0.25,
        ));
      }

      // Suggestion: high-carb items
      if (food.per100g.carbs > 40 && food.per100g.caloriesMid > 250) {
        suggestions.add(LighterSuggestion(
          item: item,
          suggestion:
              'Reduce ${food.name} (carb-dense) to save ~${(item.nutrition.caloriesMid * 0.35).round()} kcal',
          estimatedCalorieSaving: item.nutrition.caloriesMid * 0.35,
        ));
      }
    }

    // Sort by biggest saving
    suggestions.sort(
        (a, b) => b.estimatedCalorieSaving.compareTo(a.estimatedCalorieSaving));
    return suggestions.take(3).toList();
  }

  NutritionRange _estimateMealNutrition(List<FoodItem> foods) {
    NutritionRange total = NutritionRange.zero;
    for (final food in foods) {
      if (food.portions.isNotEmpty) {
        final portionNutrition = _calculator.calculateForPortion(
          food: food,
          portion: food.portions.first,
        );
        total = total + portionNutrition;
      }
    }
    return total;
  }

  bool _isProtein(FoodItem f) =>
      f.category == 'nonVeg' || f.subCategory == 'paneer' || f.subCategory == 'eggs';

  bool _isVegetable(FoodItem f) =>
      f.category == 'veg' &&
      (f.subCategory == 'vegetables' || f.subCategory == 'salad');

  String _icon(bool isVeg) => isVeg ? '🌱' : '🍗';

  String _buildTitle(List<FoodItem> items, {required int rank}) {
    final rankEmojis = ['🥇', '🥈', '🥉'];
    final emoji = rank <= 3 ? rankEmojis[rank - 1] : '🍽️';
    final names = items.map((f) => f.name).join(' + ');
    return '$emoji $names';
  }
}

/// AnalyticsEngine — generates insights from local nutrition data.
class AnalyticsEngine {
  /// Generate daily insights for the home screen.
  List<NutritionInsight> generateDailyInsights({
    required UserGoal goal,
    required DailyNutritionSummary summary,
  }) {
    final insights = <NutritionInsight>[];
    final consumed = summary.totalCalories;
    final target = goal.dailyCalorieTarget.toDouble();

    // Calorie insights
    final remaining = target - consumed;
    if (remaining > 0 && summary.mealCount > 0) {
      if (remaining < 200) {
        insights.add(const NutritionInsight(
          emoji: '⚠️',
          message: 'You\'re very close to your daily calorie limit.',
          type: InsightType.warning,
        ));
      } else {
        insights.add(NutritionInsight(
          emoji: '🔥',
          message:
              'You have ~${remaining.round()} kcal remaining for the day.',
          type: InsightType.neutral,
        ));
      }
    }

    // Protein insights
    final proteinRatio = summary.totalProtein / goal.dailyProteinTargetG;
    if (proteinRatio >= 0.9) {
      insights.add(const NutritionInsight(
        emoji: '💪',
        message: 'Great protein intake today! Keep it up.',
        type: InsightType.positive,
      ));
    } else if (proteinRatio < 0.5 && summary.mealCount >= 2) {
      insights.add(NutritionInsight(
        emoji: '🥩',
        message:
            'Your protein is a bit low. Consider adding dal, paneer, or eggs.',
        type: InsightType.suggestion,
      ));
    }

    // Fiber insights
    if (summary.totalFiber < 10 && summary.mealCount >= 2) {
      insights.add(const NutritionInsight(
        emoji: '🌾',
        message:
            'Fiber is lower today. A salad or dal can help boost it.',
        type: InsightType.suggestion,
      ));
    }

    // Encouraging message if doing well
    if (insights.isEmpty && summary.mealCount > 0) {
      insights.add(const NutritionInsight(
        emoji: '✨',
        message: 'You\'re on track today. Keep making healthy choices!',
        type: InsightType.positive,
      ));
    }

    return insights;
  }

  /// Analyze weight trend over a period.
  WeightTrend analyzeWeightTrend(List<WeightEntry> entries) {
    if (entries.length < 2) {
      return const WeightTrend(
        direction: TrendDirection.stable,
        changeKg: 0,
        periodDays: 0,
        message: 'Log more weight entries to see your trend.',
      );
    }

    final sorted = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final oldest = sorted.first;
    final newest = sorted.last;
    final change = newest.weightKg - oldest.weightKg;
    final days =
        newest.date.difference(oldest.date).inDays.abs().clamp(1, 999);

    final direction = change < -0.2
        ? TrendDirection.down
        : change > 0.2
            ? TrendDirection.up
            : TrendDirection.stable;

    String message;
    switch (direction) {
      case TrendDirection.down:
        message =
            'Your weight is trending down ↓ ${change.abs().toStringAsFixed(1)} kg over $days days. Great work!';
        break;
      case TrendDirection.up:
        message =
            'Your weight has increased by ${change.toStringAsFixed(1)} kg over $days days.';
        break;
      case TrendDirection.stable:
        message = 'Your weight has been stable over $days days.';
        break;
    }

    return WeightTrend(
      direction: direction,
      changeKg: change,
      periodDays: days,
      message: message,
    );
  }
}

class WeightTrend {
  final TrendDirection direction;
  final double changeKg;
  final int periodDays;
  final String message;

  const WeightTrend({
    required this.direction,
    required this.changeKg,
    required this.periodDays,
    required this.message,
  });
}

enum TrendDirection { up, down, stable }

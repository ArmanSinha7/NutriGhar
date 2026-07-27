import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/repositories.dart';
import '../services/nutrition_calculator.dart';
import '../services/food_search_engine.dart';
import '../services/recommendation_engine.dart';
import '../services/meal_prep_service.dart';
import '../services/habit_service.dart';
import '../models/models.dart';

// ─── Singleton service providers ───────────────────────────────────────────

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository();
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository();
});

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  return WeightRepository();
});

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository();
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository();
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository();
});

final nutritionCalculatorProvider = Provider<NutritionCalculator>((ref) {
  return NutritionCalculator();
});

final bmrCalculatorProvider = Provider<BMRCalculator>((ref) {
  return BMRCalculator();
});

final bmiCalculatorProvider = Provider<BMICalculator>((ref) {
  return BMICalculator();
});

final activityCalculatorProvider = Provider<ActivityCalculator>((ref) {
  return ActivityCalculator();
});

final recommendationEngineProvider = Provider<RecommendationEngine>((ref) {
  final calculator = ref.read(nutritionCalculatorProvider);
  return RecommendationEngine(calculator);
});

// ─── Initialization provider ────────────────────────────────────────────────

final appInitializedProvider = FutureProvider<bool>((ref) async {
  final foodRepo = ref.read(foodRepositoryProvider);
  final userRepo = ref.read(userProfileRepositoryProvider);
  final weightRepo = ref.read(weightRepositoryProvider);
  final mealRepo = ref.read(mealRepositoryProvider);
  final goalRepo = ref.read(goalRepositoryProvider);
  final activityRepo = ref.read(activityRepositoryProvider);

  await Future.wait([
    foodRepo.initialize(),
    userRepo.initialize(),
    weightRepo.initialize(),
    mealRepo.initialize(),
    goalRepo.initialize(),
    activityRepo.initialize(),
  ]);

  return true;
});

// ─── Active user provider ───────────────────────────────────────────────────

final activeUserProvider = FutureProvider<UserProfile?>((ref) async {
  final repo = ref.read(userProfileRepositoryProvider);
  return repo.getActiveProfile();
});

final allProfilesProvider = FutureProvider<List<UserProfile>>((ref) async {
  final repo = ref.read(userProfileRepositoryProvider);
  return repo.getAllProfiles();
});

// ─── Food providers ─────────────────────────────────────────────────────────

final allFoodsProvider = Provider<List<FoodItem>>((ref) {
  final repo = ref.read(foodRepositoryProvider);
  try {
    return repo.allFoods;
  } catch (_) {
    return [];
  }
});

final foodSearchEngineProvider = Provider<FoodSearchEngine?>((ref) {
  final repo = ref.read(foodRepositoryProvider);
  try {
    return repo.searchEngine;
  } catch (_) {
    return null;
  }
});

// ─── Today's nutrition ──────────────────────────────────────────────────────

final todayMealsProvider =
    FutureProvider.family<List<Meal>, String>((ref, userId) async {
  final repo = ref.read(mealRepositoryProvider);
  final allFoods = ref.watch(allFoodsProvider);
  final meals = await repo.getMealsForDay(userId, DateTime.now());
  
  return meals.map((meal) {
    return meal.copyWith(
      items: meal.items.map((item) {
        if (item.foodId != null) {
          final food = allFoods.cast<FoodItem?>().firstWhere(
            (f) => f?.id == item.foodId,
            orElse: () => null,
          );
          return item.copyWith(food: food);
        }
        return item;
      }).toList(),
    );
  }).toList();
});

final todayNutritionProvider =
    FutureProvider.family<DailyNutritionSummary, String>((ref, userId) async {
  final repo = ref.read(mealRepositoryProvider);
  final allFoods = ref.read(allFoodsProvider);
  return repo.getDailySummary(userId, DateTime.now(), allFoods);
});

// ─── Weight entries ─────────────────────────────────────────────────────────

final weightEntriesProvider =
    FutureProvider.family<List<WeightEntry>, String>((ref, userId) async {
  final repo = ref.read(weightRepositoryProvider);
  return repo.getEntries(userId);
});

// ─── Goals ─────────────────────────────────────────────────────────────────

final userGoalProvider =
    FutureProvider.family<UserGoal?, String>((ref, userId) async {
  final repo = ref.read(goalRepositoryProvider);
  return repo.getGoal(userId);
});

// ─── Activity ───────────────────────────────────────────────────────────────

final activityEntriesProvider =
    FutureProvider.family<List<ActivityEntry>, String>((ref, userId) async {
  final repo = ref.read(activityRepositoryProvider);
  return repo.getEntries(userId);
});

// ─── Preps ──────────────────────────────────────────────────────────────────

final mealPrepServiceProvider = Provider<MealPrepService>((ref) {
  return MealPrepService(ref);
});

final currentMealPrepProvider = FutureProvider<MealPrep?>((ref) async {
  final service = ref.read(mealPrepServiceProvider);
  return service.getCurrentPrep();
});

final mealPrepItemsProvider = FutureProvider.family<List<MealPrepItem>, String>((ref, prepId) async {
  final service = ref.read(mealPrepServiceProvider);
  return service.getPrepItems(prepId);
});

// ─── Habit Tracker ──────────────────────────────────────────────────────────

final habitServiceProvider = Provider<HabitService>((ref) {
  return HabitService();
});

final activeHabitsProvider = FutureProvider<List<Habit>>((ref) async {
  final service = ref.read(habitServiceProvider);
  return service.getActiveHabits();
});

final habitLogsForMonthProvider = FutureProvider.family<List<HabitLog>, String>((ref, monthStr) async {
  final service = ref.read(habitServiceProvider);
  return service.getLogsForMonth(monthStr);
});

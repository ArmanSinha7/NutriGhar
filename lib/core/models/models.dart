// Core data models for NutriGhar
// These are plain Dart models (not Drift tables) used throughout the domain layer

import 'dart:convert';

enum ConfidenceLevel { high, medium, low }

enum MealType { breakfast, lunch, snack, dinner }

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extraActive,
}

enum Gender { male, female, other }

enum WeightGoal { lose, maintain, gain }

enum ActivityType {
  walking,
  running,
  cycling,
  swimming,
  strengthTraining,
  yoga,
  householdWork,
  other,
}

enum ActivityIntensity { light, moderate, vigorous }

/// Represents a food's nutritional profile per 100g
class NutrientProfile {
  final double caloriesMin;
  final double caloriesMax;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double? sugar;
  final double? saturatedFat;
  final double? sodium;
  final double? potassium;
  final double? calcium;
  final double? iron;

  const NutrientProfile({
    required this.caloriesMin,
    required this.caloriesMax,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    this.sugar,
    this.saturatedFat,
    this.sodium,
    this.potassium,
    this.calcium,
    this.iron,
  });

  double get caloriesMid => (caloriesMin + caloriesMax) / 2;

  factory NutrientProfile.fromJson(Map<String, dynamic> j) => NutrientProfile(
        caloriesMin: (j['caloriesMin'] as num).toDouble(),
        caloriesMax: (j['caloriesMax'] as num).toDouble(),
        protein: (j['protein'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
        fat: (j['fat'] as num).toDouble(),
        fiber: (j['fiber'] as num).toDouble(),
        sugar: j['sugar'] != null ? (j['sugar'] as num).toDouble() : null,
        sodium: j['sodium'] != null ? (j['sodium'] as num).toDouble() : null,
      );

  Map<String, dynamic> toJson() => {
        'caloriesMin': caloriesMin,
        'caloriesMax': caloriesMax,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        if (sugar != null) 'sugar': sugar,
        if (sodium != null) 'sodium': sodium,
      };
}

/// Represents a household portion size for a food
class PortionSize {
  final String name;
  final String? nameHi;
  final double weightMinG;
  final double weightMaxG;

  const PortionSize({
    required this.name,
    this.nameHi,
    required this.weightMinG,
    required this.weightMaxG,
  });

  double get weightMidG => (weightMinG + weightMaxG) / 2;

  factory PortionSize.fromJson(Map<String, dynamic> j) => PortionSize(
        name: j['name'] as String,
        nameHi: j['nameHi'] as String?,
        weightMinG: (j['weightMinG'] as num).toDouble(),
        weightMaxG: (j['weightMaxG'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (nameHi != null) 'nameHi': nameHi,
        'weightMinG': weightMinG,
        'weightMaxG': weightMaxG,
      };
}

/// A food item from the database
class FoodItem {
  final String id;
  final String name;
  final String? nameHi;
  final String? nameHinglish;
  final List<String> aliases;
  final String category;
  final String? subCategory;
  final bool isVegetarian;
  final List<String> mealTypes;
  final ConfidenceLevel confidenceLevel;
  final String? confidenceNote;
  final NutrientProfile per100g;
  final List<PortionSize> portions;
  final bool isFavorite;
  final bool isCustom;
  final String? source;

  const FoodItem({
    required this.id,
    required this.name,
    this.nameHi,
    this.nameHinglish,
    required this.aliases,
    required this.category,
    this.subCategory,
    required this.isVegetarian,
    this.mealTypes = const [],
    required this.confidenceLevel,
    this.confidenceNote,
    required this.per100g,
    required this.portions,
    this.isFavorite = false,
    this.isCustom = false,
    this.source,
  });

  FoodItem copyWith({
    bool? isFavorite,
    bool? isCustom,
  }) =>
      FoodItem(
        id: id,
        name: name,
        nameHi: nameHi,
        nameHinglish: nameHinglish,
        aliases: aliases,
        category: category,
        subCategory: subCategory,
        isVegetarian: isVegetarian,
        mealTypes: mealTypes,
        confidenceLevel: confidenceLevel,
        confidenceNote: confidenceNote,
        per100g: per100g,
        portions: portions,
        isFavorite: isFavorite ?? this.isFavorite,
        isCustom: isCustom ?? this.isCustom,
        source: source,
      );

  factory FoodItem.fromJson(Map<String, dynamic> j) {
    ConfidenceLevel confidence;
    switch (j['confidenceLevel']) {
      case 'HIGH':
        confidence = ConfidenceLevel.high;
        break;
      case 'LOW':
        confidence = ConfidenceLevel.low;
        break;
      default:
        confidence = ConfidenceLevel.medium;
    }

    return FoodItem(
      id: j['id'] as String,
      name: j['name'] as String,
      nameHi: j['nameHi'] as String?,
      nameHinglish: j['nameHinglish'] as String?,
      aliases: (j['aliases'] as List<dynamic>?)?.cast<String>() ?? [],
      category: j['category'] as String,
      subCategory: j['subCategory'] as String?,
      isVegetarian: j['isVegetarian'] as bool? ?? true,
      mealTypes: (j['mealTypes'] as List<dynamic>?)?.cast<String>() ?? [],
      confidenceLevel: confidence,
      confidenceNote: j['confidenceNote'] as String?,
      per100g: NutrientProfile.fromJson(j['per100g'] as Map<String, dynamic>),
      portions: (j['portions'] as List<dynamic>?)
              ?.map((p) => PortionSize.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      isCustom: j['isCustom'] as bool? ?? false,
      source: j['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    String confLevelStr;
    switch (confidenceLevel) {
      case ConfidenceLevel.high:
        confLevelStr = 'HIGH';
        break;
      case ConfidenceLevel.low:
        confLevelStr = 'LOW';
        break;
      default:
        confLevelStr = 'MEDIUM';
    }

    return {
      'id': id,
      'name': name,
      if (nameHi != null) 'nameHi': nameHi,
      if (nameHinglish != null) 'nameHinglish': nameHinglish,
      'aliases': aliases,
      'category': category,
      if (subCategory != null) 'subCategory': subCategory,
      'isVegetarian': isVegetarian,
      'mealTypes': mealTypes,
      'confidenceLevel': confLevelStr,
      if (confidenceNote != null) 'confidenceNote': confidenceNote,
      'per100g': per100g.toJson(),
      'portions': portions.map((p) => p.toJson()).toList(),
      'isCustom': isCustom,
      'source': source,
    };
  }
}

/// Calculated nutrition for a specific portion of a food
class NutritionRange {
  final double caloriesMin;
  final double caloriesMax;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final ConfidenceLevel confidence;

  const NutritionRange({
    required this.caloriesMin,
    required this.caloriesMax,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    this.confidence = ConfidenceLevel.medium,
  });

  double get caloriesMid => (caloriesMin + caloriesMax) / 2;

  NutritionRange operator +(NutritionRange other) => NutritionRange(
        caloriesMin: caloriesMin + other.caloriesMin,
        caloriesMax: caloriesMax + other.caloriesMax,
        protein: protein + other.protein,
        carbs: carbs + other.carbs,
        fat: fat + other.fat,
        fiber: fiber + other.fiber,
        confidence: confidence.index > other.confidence.index
            ? confidence
            : other.confidence,
      );

  static NutritionRange zero = const NutritionRange(
    caloriesMin: 0,
    caloriesMax: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
    fiber: 0,
  );
}

/// A logged meal item
class MealItem {
  final String id;
  final String? foodId;
  final String? recipeId;
  final FoodItem? food;
  final String portionName;
  final double quantity;
  final NutritionRange nutrition;
  final String? note;

  const MealItem({
    required this.id,
    this.foodId,
    this.recipeId,
    this.food,
    required this.portionName,
    required this.quantity,
    required this.nutrition,
    this.note,
  });

  MealItem copyWith({
    String? id,
    String? foodId,
    String? recipeId,
    FoodItem? food,
    String? portionName,
    double? quantity,
    NutritionRange? nutrition,
    String? note,
  }) {
    return MealItem(
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      recipeId: recipeId ?? this.recipeId,
      food: food ?? this.food,
      portionName: portionName ?? this.portionName,
      quantity: quantity ?? this.quantity,
      nutrition: nutrition ?? this.nutrition,
      note: note ?? this.note,
    );
  }
}

/// A logged meal (breakfast/lunch/snack/dinner)
class Meal {
  final String id;
  final String userProfileId;
  final DateTime date;
  final MealType mealType;
  final List<MealItem> items;

  const Meal({
    required this.id,
    required this.userProfileId,
    required this.date,
    required this.mealType,
    required this.items,
  });

  NutritionRange get totalNutrition => items.fold(
        NutritionRange.zero,
        (sum, item) => sum + item.nutrition,
      );

  Meal copyWith({
    String? id,
    String? userProfileId,
    DateTime? date,
    MealType? mealType,
    List<MealItem>? items,
  }) {
    return Meal(
      id: id ?? this.id,
      userProfileId: userProfileId ?? this.userProfileId,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      items: items ?? this.items,
    );
  }
}

/// A user profile
class UserProfile {
  final String id;
  final String name;
  final int? age;
  final Gender? gender;
  final double? heightCm;
  final double? weightKg;
  final ActivityLevel activityLevel;
  final WeightGoal goal;
  final bool isVegetarian;
  final String? avatarEmoji;
  final bool isActive;

  const UserProfile({
    required this.id,
    required this.name,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.activityLevel = ActivityLevel.moderatelyActive,
    this.goal = WeightGoal.maintain,
    this.isVegetarian = false,
    this.avatarEmoji,
    this.isActive = false,
  });

  UserProfile copyWith({
    String? name,
    int? age,
    Gender? gender,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activityLevel,
    WeightGoal? goal,
    bool? isVegetarian,
    String? avatarEmoji,
    bool? isActive,
  }) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        activityLevel: activityLevel ?? this.activityLevel,
        goal: goal ?? this.goal,
        isVegetarian: isVegetarian ?? this.isVegetarian,
        avatarEmoji: avatarEmoji ?? this.avatarEmoji,
        isActive: isActive ?? this.isActive,
      );
}

/// A weight entry
class WeightEntry {
  final String id;
  final String userProfileId;
  final DateTime date;
  final double weightKg;
  final String? note;

  const WeightEntry({
    required this.id,
    required this.userProfileId,
    required this.date,
    required this.weightKg,
    this.note,
  });
}

/// A recipe
class Recipe {
  final String id;
  final String name;
  final String? description;
  final int servings;
  final String? category;
  final List<RecipeIngredient> ingredients;
  final bool isVegetarian;
  final bool isCustom;
  final DateTime? createdAt;

  const Recipe({
    required this.id,
    required this.name,
    this.description,
    required this.servings,
    this.category,
    required this.ingredients,
    required this.isVegetarian,
    this.isCustom = true,
    this.createdAt,
  });
}

/// An ingredient in a recipe
class RecipeIngredient {
  final String foodId;
  final FoodItem? food;
  final double quantityG;
  final String? note;

  const RecipeIngredient({
    required this.foodId,
    this.food,
    required this.quantityG,
    this.note,
  });
}

/// Goals for a user
class UserGoal {
  final String userProfileId;
  final WeightGoal goalType;
  final double? targetWeightKg;
  final int dailyCalorieTarget;
  final double dailyProteinTargetG;
  final double dailyCarbTargetG;
  final double dailyFatTargetG;
  final double dailyFiberTargetG;
  final DateTime startDate;

  const UserGoal({
    required this.userProfileId,
    required this.goalType,
    this.targetWeightKg,
    required this.dailyCalorieTarget,
    required this.dailyProteinTargetG,
    required this.dailyCarbTargetG,
    required this.dailyFatTargetG,
    required this.dailyFiberTargetG,
    required this.startDate,
  });

  UserGoal copyWith({
    String? userProfileId,
    WeightGoal? goalType,
    double? targetWeightKg,
    int? dailyCalorieTarget,
    double? dailyProteinTargetG,
    double? dailyCarbTargetG,
    double? dailyFatTargetG,
    double? dailyFiberTargetG,
    DateTime? startDate,
  }) {
    return UserGoal(
      userProfileId: userProfileId ?? this.userProfileId,
      goalType: goalType ?? this.goalType,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      dailyProteinTargetG: dailyProteinTargetG ?? this.dailyProteinTargetG,
      dailyCarbTargetG: dailyCarbTargetG ?? this.dailyCarbTargetG,
      dailyFatTargetG: dailyFatTargetG ?? this.dailyFatTargetG,
      dailyFiberTargetG: dailyFiberTargetG ?? this.dailyFiberTargetG,
      startDate: startDate ?? this.startDate,
    );
  }
}

/// Activity log entry
class ActivityEntry {
  final String id;
  final String userProfileId;
  final DateTime date;
  final ActivityType activityType;
  final int durationMinutes;
  final ActivityIntensity intensity;
  final double caloriesBurned;
  final String? note;

  const ActivityEntry({
    required this.id,
    required this.userProfileId,
    required this.date,
    required this.activityType,
    required this.durationMinutes,
    this.intensity = ActivityIntensity.moderate,
    required this.caloriesBurned,
    this.note,
  });
}

/// An educational fact card
class FactCard {
  final String id;
  final String title;
  final String body;
  final String emoji;
  final String category;

  const FactCard({
    required this.id,
    required this.title,
    required this.body,
    required this.emoji,
    required this.category,
  });

  factory FactCard.fromJson(Map<String, dynamic> j) => FactCard(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        emoji: j['emoji'] as String,
        category: j['category'] as String,
      );
}

/// Daily nutrition summary for a user
class DailyNutritionSummary {
  final DateTime date;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final int mealCount;

  const DailyNutritionSummary({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalFiber,
    required this.mealCount,
  });
}

/// An insight shown on the home screen
class NutritionInsight {
  final String emoji;
  final String message;
  final InsightType type;

  const NutritionInsight({
    required this.emoji,
    required this.message,
    required this.type,
  });
}

enum InsightType { positive, neutral, suggestion, warning }

/// Meal recommendation from the engine
class MealRecommendation {
  final String title;
  final List<FoodItem> foods;
  final NutritionRange estimatedNutrition;
  final String reasoning;
  final int rank;

  const MealRecommendation({
    required this.title,
    required this.foods,
    required this.estimatedNutrition,
    required this.reasoning,
    required this.rank,
  });
}

/// "Make it lighter" suggestion
class LighterSuggestion {
  final MealItem item;
  final String suggestion;
  final double estimatedCalorieSaving;
  final bool isAccepted;

  const LighterSuggestion({
    required this.item,
    required this.suggestion,
    required this.estimatedCalorieSaving,
    this.isAccepted = false,
  });
}

/// A user streak for gamification
class Streak {
  final String id;
  final String type;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastDate;

  const Streak({
    required this.id,
    required this.type,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastDate,
  });
}

/// A meal prep plan
class MealPrep {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int days;

  const MealPrep({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.days,
  });
}

/// A meal prep item within a plan
class MealPrepItem {
  final String id;
  final String prepId;
  final int day;
  final MealType mealType;
  final String foodId;
  final String portionName;
  final double quantity;

  const MealPrepItem({
    required this.id,
    required this.prepId,
    required this.day,
    required this.mealType,
    required this.foodId,
    required this.portionName,
    required this.quantity,
  });
}

// ─── Habit Tracker Models ───────────────────────────────────────────────────

class Habit {
  final String id;
  final String name;
  final String icon;
  final int colorValue;
  final String frequency; // e.g. "daily", "weekdays", or "1,3,5" for Mon,Wed,Fri
  final DateTime createdAt;
  final bool isArchived;

  const Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.frequency,
    required this.createdAt,
    this.isArchived = false,
  });

  Habit copyWith({
    String? name,
    String? icon,
    int? colorValue,
    String? frequency,
    bool? isArchived,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}

class HabitLog {
  final String id;
  final String habitId;
  final String date; // YYYY-MM-DD
  final int status; // 0 for incomplete, 1 for complete

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.status,
  });
}

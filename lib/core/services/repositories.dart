import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/food_search_engine.dart';
import '../services/nutrition_calculator.dart';
import '../services/recommendation_engine.dart';

/// FoodRepository — loads food data from seed JSON, manages favorites and custom foods.
class FoodRepository {
  static const _favoritesKey = 'favorites_';
  static const _customFoodsKey = 'custom_foods_';

  List<FoodItem> _allFoods = [];
  FoodSearchEngine? _searchEngine;
  SharedPreferences? _prefs;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _loadSeedFoods();
    await _loadCustomFoods();
    _searchEngine = FoodSearchEngine(_allFoods);
    _initialized = true;
  }

  Future<void> _loadSeedFoods() async {
    try {
      final List<FoodItem> allLoadedFoods = [];
      
      final paths = [
        'assets/data/foods_seed.json',
        'assets/data/foods/core_ingredients.json',
        'assets/data/foods/regional_dishes.json',
        'assets/data/foods/common_meals.json',
        'assets/data/foods/extended_indian_foods_part1.json',
        'assets/data/foods/massive_database_12k.json',
      ];

      for (var path in paths) {
        try {
          final jsonStr = await rootBundle.loadString(path);
          final data = json.decode(jsonStr) as Map<String, dynamic>;
          final foodsList = (data['foods'] as List<dynamic>)
              .map((f) => FoodItem.fromJson(f as Map<String, dynamic>))
              .toList();
          allLoadedFoods.addAll(foodsList);
        } catch (e) {
          print('Failed to load $path: $e');
        }
      }

      // Remove duplicates based on ID (newer files override older ones if same ID)
      final uniqueFoods = <String, FoodItem>{};
      for (var food in allLoadedFoods) {
        uniqueFoods[food.id] = food;
      }
      
      _allFoods = uniqueFoods.values.toList();
    } catch (e) {
      _allFoods = [];
    }
  }

  Future<void> _loadCustomFoods() async {
    final customJson = _prefs?.getString(_customFoodsKey) ?? '[]';
    try {
      final list = json.decode(customJson) as List<dynamic>;
      final customFoods = list
          .map((f) => FoodItem.fromJson(f as Map<String, dynamic>))
          .toList();
      _allFoods = [..._allFoods, ...customFoods];
    } catch (_) {}
  }

  Future<void> addCustomFood(FoodItem food) async {
    _ensureInitialized();
    final customJson = _prefs?.getString(_customFoodsKey) ?? '[]';
    final list = json.decode(customJson) as List<dynamic>;
    
    final existingIndex = list.indexWhere((item) => item['id'] == food.id);
    if (existingIndex != -1) {
      list[existingIndex] = food.toJson();
      final memIndex = _allFoods.indexWhere((f) => f.id == food.id);
      if (memIndex != -1) {
        _allFoods[memIndex] = food;
      }
    } else {
      list.add(food.toJson());
      _allFoods = [..._allFoods, food];
    }

    await _prefs?.setString(_customFoodsKey, json.encode(list));
    _searchEngine = FoodSearchEngine(_allFoods);
  }

  FoodSearchEngine get searchEngine {
    _ensureInitialized();
    return _searchEngine!;
  }

  List<FoodItem> get allFoods {
    _ensureInitialized();
    return List.unmodifiable(_allFoods);
  }

  FoodItem? findById(String id) {
    _ensureInitialized();
    try {
      return _allFoods.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> toggleFavorite(String userId, String foodId) async {
    _ensureInitialized();
    final key = _favoritesKey + userId;
    final existing = _prefs?.getStringList(key) ?? [];
    if (existing.contains(foodId)) {
      existing.remove(foodId);
    } else {
      existing.add(foodId);
    }
    await _prefs?.setStringList(key, existing);
  }

  List<String> getFavoriteIds(String userId) {
    return _prefs?.getStringList(_favoritesKey + userId) ?? [];
  }

  List<FoodItem> getFavorites(String userId) {
    final ids = getFavoriteIds(userId);
    return _allFoods.where((f) => ids.contains(f.id)).toList();
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('FoodRepository not initialized. Call initialize() first.');
    }
  }
}

/// UserProfileRepository — stores and retrieves user profiles locally.
class UserProfileRepository {
  static const _profilesKey = 'user_profiles';
  static const _activeProfileKey = 'active_profile_id';
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<UserProfile>> getAllProfiles() async {
    final json = _prefs?.getString(_profilesKey) ?? '[]';
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((p) => _profileFromJson(p as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<UserProfile?> getActiveProfile() async {
    final activeId = _prefs?.getString(_activeProfileKey);
    if (activeId == null) return null;
    final profiles = await getAllProfiles();
    try {
      return profiles.firstWhere((p) => p.id == activeId);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final profiles = await getAllProfiles();
    final idx = profiles.indexWhere((p) => p.id == profile.id);
    if (idx >= 0) {
      profiles[idx] = profile;
    } else {
      profiles.add(profile);
    }
    await _prefs?.setString(_profilesKey, jsonEncode(profiles.map(_profileToJson).toList()));
  }

  Future<void> setActiveProfile(String profileId) async {
    await _prefs?.setString(_activeProfileKey, profileId);
  }

  Future<void> deleteProfile(String profileId) async {
    final profiles = await getAllProfiles();
    profiles.removeWhere((p) => p.id == profileId);
    await _prefs?.setString(_profilesKey, jsonEncode(profiles.map(_profileToJson).toList()));
  }

  Map<String, dynamic> _profileToJson(UserProfile p) => {
        'id': p.id,
        'name': p.name,
        'age': p.age,
        'gender': p.gender?.name,
        'heightCm': p.heightCm,
        'weightKg': p.weightKg,
        'activityLevel': p.activityLevel.name,
        'goal': p.goal.name,
        'isVegetarian': p.isVegetarian,
        'avatarEmoji': p.avatarEmoji,
        'isActive': p.isActive,
      };

  UserProfile _profileFromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        age: j['age'] as int?,
        gender: j['gender'] != null
            ? Gender.values.firstWhere(
                (g) => g.name == j['gender'],
                orElse: () => Gender.other,
              )
            : null,
        heightCm: (j['heightCm'] as num?)?.toDouble(),
        weightKg: (j['weightKg'] as num?)?.toDouble(),
        activityLevel: ActivityLevel.values.firstWhere(
          (a) => a.name == j['activityLevel'],
          orElse: () => ActivityLevel.moderatelyActive,
        ),
        goal: WeightGoal.values.firstWhere(
          (g) => g.name == j['goal'],
          orElse: () => WeightGoal.maintain,
        ),
        isVegetarian: j['isVegetarian'] as bool? ?? false,
        avatarEmoji: j['avatarEmoji'] as String?,
        isActive: j['isActive'] as bool? ?? false,
      );
}

/// WeightRepository — stores weight entries locally.
class WeightRepository {
  static const _prefix = 'weight_entries_';
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<WeightEntry>> getEntries(String userId) async {
    final json = _prefs?.getString(_prefix + userId) ?? '[]';
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => _entryFromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {
      return [];
    }
  }

  Future<void> addEntry(WeightEntry entry) async {
    final entries = await getEntries(entry.userProfileId);
    entries.add(entry);
    await _save(entry.userProfileId, entries);
  }

  Future<void> deleteEntry(String userId, String entryId) async {
    final entries = await getEntries(userId);
    entries.removeWhere((e) => e.id == entryId);
    await _save(userId, entries);
  }

  Future<void> _save(String userId, List<WeightEntry> entries) async {
    await _prefs?.setString(
      _prefix + userId,
      jsonEncode(entries.map(_entryToJson).toList()),
    );
  }

  Map<String, dynamic> _entryToJson(WeightEntry e) => {
        'id': e.id,
        'userProfileId': e.userProfileId,
        'date': e.date.toIso8601String(),
        'weightKg': e.weightKg,
        'note': e.note,
      };

  WeightEntry _entryFromJson(Map<String, dynamic> j) => WeightEntry(
        id: j['id'] as String,
        userProfileId: j['userProfileId'] as String,
        date: DateTime.parse(j['date'] as String),
        weightKg: (j['weightKg'] as num).toDouble(),
        note: j['note'] as String?,
      );
}

/// MealRepository — stores meal logs locally per user per day.
class MealRepository {
  static const _prefix = 'meals_';
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String _dayKey(String userId, DateTime date) {
    return '$_prefix${userId}_${date.year}_${date.month}_${date.day}';
  }

  Future<List<Meal>> getMealsForDay(String userId, DateTime date) async {
    final key = _dayKey(userId, date);
    final json = _prefs?.getString(key) ?? '[]';
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((m) => _mealFromJson(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMeal(Meal meal) async {
    final key = _dayKey(meal.userProfileId, meal.date);
    final meals = await getMealsForDay(meal.userProfileId, meal.date);
    final idx = meals.indexWhere((m) => m.id == meal.id);
    if (idx >= 0) {
      meals[idx] = meal;
    } else {
      meals.add(meal);
    }
    await _prefs?.setString(key, jsonEncode(meals.map(_mealToJson).toList()));
  }

  Future<void> deleteMeal(String userId, DateTime date, String mealId) async {
    final meals = await getMealsForDay(userId, date);
    meals.removeWhere((m) => m.id == mealId);
    final key = _dayKey(userId, date);
    await _prefs?.setString(key, jsonEncode(meals.map(_mealToJson).toList()));
  }

  Future<DailyNutritionSummary> getDailySummary(
      String userId, DateTime date, List<FoodItem> allFoods) async {
    final meals = await getMealsForDay(userId, date);
    double totalCal = 0, totalProt = 0, totalCarbs = 0, totalFat = 0, totalFib = 0;
    int mealCount = 0;

    for (final meal in meals) {
      mealCount++;
      for (final item in meal.items) {
        totalCal += item.nutrition.caloriesMid;
        totalProt += item.nutrition.protein;
        totalCarbs += item.nutrition.carbs;
        totalFat += item.nutrition.fat;
        totalFib += item.nutrition.fiber;
      }
    }

    return DailyNutritionSummary(
      date: date,
      totalCalories: totalCal,
      totalProtein: totalProt,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      totalFiber: totalFib,
      mealCount: mealCount,
    );
  }

  // Serialization helpers
  Map<String, dynamic> _mealToJson(Meal m) => {
        'id': m.id,
        'userProfileId': m.userProfileId,
        'date': m.date.toIso8601String(),
        'mealType': m.mealType.name,
        'items': m.items.map(_itemToJson).toList(),
      };

  Map<String, dynamic> _itemToJson(MealItem i) => {
        'id': i.id,
        'foodId': i.foodId,
        'portionName': i.portionName,
        'quantity': i.quantity,
        'nutrition': {
          'caloriesMin': i.nutrition.caloriesMin,
          'caloriesMax': i.nutrition.caloriesMax,
          'protein': i.nutrition.protein,
          'carbs': i.nutrition.carbs,
          'fat': i.nutrition.fat,
          'fiber': i.nutrition.fiber,
        },
        'note': i.note,
      };

  Meal _mealFromJson(Map<String, dynamic> j) => Meal(
        id: j['id'] as String,
        userProfileId: j['userProfileId'] as String,
        date: DateTime.parse(j['date'] as String),
        mealType: MealType.values.firstWhere(
          (t) => t.name == j['mealType'],
          orElse: () => MealType.lunch,
        ),
        items: (j['items'] as List<dynamic>)
            .map((i) => _itemFromJson(i as Map<String, dynamic>))
            .toList(),
      );

  MealItem _itemFromJson(Map<String, dynamic> j) {
    final n = j['nutrition'] as Map<String, dynamic>;
    return MealItem(
      id: j['id'] as String,
      foodId: j['foodId'] as String?,
      portionName: j['portionName'] as String,
      quantity: (j['quantity'] as num).toDouble(),
      nutrition: NutritionRange(
        caloriesMin: (n['caloriesMin'] as num).toDouble(),
        caloriesMax: (n['caloriesMax'] as num).toDouble(),
        protein: (n['protein'] as num).toDouble(),
        carbs: (n['carbs'] as num).toDouble(),
        fat: (n['fat'] as num).toDouble(),
        fiber: (n['fiber'] as num).toDouble(),
      ),
      note: j['note'] as String?,
    );
  }
}

/// GoalRepository — stores user goals locally.
class GoalRepository {
  static const _prefix = 'goal_';
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<UserGoal?> getGoal(String userId) async {
    final json = _prefs?.getString(_prefix + userId);
    if (json == null) return null;
    try {
      return _fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveGoal(UserGoal goal) async {
    await _prefs?.setString(_prefix + goal.userProfileId, jsonEncode(_toJson(goal)));
  }

  Map<String, dynamic> _toJson(UserGoal g) => {
        'userProfileId': g.userProfileId,
        'goalType': g.goalType.name,
        'targetWeightKg': g.targetWeightKg,
        'dailyCalorieTarget': g.dailyCalorieTarget,
        'dailyProteinTargetG': g.dailyProteinTargetG,
        'dailyCarbTargetG': g.dailyCarbTargetG,
        'dailyFatTargetG': g.dailyFatTargetG,
        'dailyFiberTargetG': g.dailyFiberTargetG,
        'startDate': g.startDate.toIso8601String(),
      };

  UserGoal _fromJson(Map<String, dynamic> j) => UserGoal(
        userProfileId: j['userProfileId'] as String,
        goalType: WeightGoal.values.firstWhere(
          (g) => g.name == j['goalType'],
          orElse: () => WeightGoal.maintain,
        ),
        targetWeightKg: (j['targetWeightKg'] as num?)?.toDouble(),
        dailyCalorieTarget: (j['dailyCalorieTarget'] as num).toInt(),
        dailyProteinTargetG: (j['dailyProteinTargetG'] as num).toDouble(),
        dailyCarbTargetG: (j['dailyCarbTargetG'] as num).toDouble(),
        dailyFatTargetG: (j['dailyFatTargetG'] as num).toDouble(),
        dailyFiberTargetG: (j['dailyFiberTargetG'] as num).toDouble(),
        startDate: DateTime.parse(j['startDate'] as String),
      );
}

/// ActivityRepository — stores activity log entries locally.
class ActivityRepository {
  static const _prefix = 'activities_';
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<ActivityEntry>> getEntries(String userId) async {
    final json = _prefs?.getString(_prefix + userId) ?? '[]';
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => _fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {
      return [];
    }
  }

  Future<void> addEntry(ActivityEntry entry) async {
    final entries = await getEntries(entry.userProfileId);
    entries.add(entry);
    await _prefs?.setString(
        _prefix + entry.userProfileId,
        jsonEncode(entries.map(_toJson).toList()));
  }

  Map<String, dynamic> _toJson(ActivityEntry e) => {
        'id': e.id,
        'userProfileId': e.userProfileId,
        'date': e.date.toIso8601String(),
        'activityType': e.activityType.name,
        'durationMinutes': e.durationMinutes,
        'intensity': e.intensity.name,
        'caloriesBurned': e.caloriesBurned,
        'note': e.note,
      };

  ActivityEntry _fromJson(Map<String, dynamic> j) => ActivityEntry(
        id: j['id'] as String,
        userProfileId: j['userProfileId'] as String,
        date: DateTime.parse(j['date'] as String),
        activityType: ActivityType.values.firstWhere(
          (t) => t.name == j['activityType'],
          orElse: () => ActivityType.walking,
        ),
        durationMinutes: (j['durationMinutes'] as num).toInt(),
        intensity: ActivityIntensity.values.firstWhere(
          (i) => i.name == j['intensity'],
          orElse: () => ActivityIntensity.moderate,
        ),
        caloriesBurned: (j['caloriesBurned'] as num).toDouble(),
        note: j['note'] as String?,
      );
}

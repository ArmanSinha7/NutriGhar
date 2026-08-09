import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:nutrighar/core/database/database.dart';
import 'package:nutrighar/core/models/models.dart';
import 'package:nutrighar/core/di/providers.dart';

class MealPrepService {
  final Ref _ref;
  final _uuid = const Uuid();
  final _random = Random();

  MealPrepService(this._ref);

  Future<MealPrep?> getCurrentPrep() async {
    final db = await AppDatabase.instance.database;
    final results = await db.query('meal_preps', orderBy: 'startDate DESC', limit: 1);
    if (results.isEmpty) return null;

    final row = results.first;
    return MealPrep(
      id: row['id'] as String,
      name: row['name'] as String,
      startDate: DateTime.parse(row['startDate'] as String),
      endDate: DateTime.parse(row['endDate'] as String),
      days: row['days'] as int,
    );
  }

  Future<List<MealPrepItem>> getPrepItems(String prepId) async {
    final db = await AppDatabase.instance.database;
    final results = await db.query('meal_prep_items', where: 'prepId = ?', whereArgs: [prepId], orderBy: 'day ASC');
    
    return results.map((r) {
      final mtStr = r['mealType'] as String;
      final mt = MealType.values.firstWhere((e) => e.name == mtStr, orElse: () => MealType.lunch);
      
      return MealPrepItem(
        id: r['id'] as String,
        prepId: r['prepId'] as String,
        day: r['day'] as int,
        mealType: mt,
        foodId: r['foodId'] as String,
        portionName: r['portionName'] as String,
        quantity: (r['quantity'] as num).toDouble(),
      );
    }).toList();
  }

  Future<void> generatePlan(int days) async {
    final allFoods = _ref.read(allFoodsProvider);
    if (allFoods.isEmpty) return;

    final db = await AppDatabase.instance.database;
    final prepId = _uuid.v4();
    final today = DateTime.now();
    final endDate = today.add(Duration(days: days));

    // Delete existing just to keep it simple for this implementation
    await db.delete('meal_preps');
    await db.delete('meal_prep_items');

    await db.insert('meal_preps', {
      'id': prepId,
      'name': '$days-Day Plan',
      'startDate': today.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'days': days,
    });

    final breakfastFoods = allFoods.where((f) => f.mealTypes.contains(MealType.breakfast)).toList();
    final lunchFoods = allFoods.where((f) => f.mealTypes.contains(MealType.lunch)).toList();
    final snackFoods = allFoods.where((f) => f.mealTypes.contains(MealType.snack)).toList();
    final dinnerFoods = allFoods.where((f) => f.mealTypes.contains(MealType.dinner)).toList();

    // Fallbacks if lists are empty
    final fallbackList = allFoods;

    FoodItem pickRandom(List<FoodItem> list) {
      if (list.isEmpty) return fallbackList[_random.nextInt(fallbackList.length)];
      return list[_random.nextInt(list.length)];
    }

    final batch = db.batch();
    for (int day = 1; day <= days; day++) {
      final mealsToGenerate = [MealType.breakfast, MealType.lunch, MealType.snack, MealType.dinner];
      
      for (final mealType in mealsToGenerate) {
        FoodItem picked;
        switch (mealType) {
          case MealType.breakfast:
            picked = pickRandom(breakfastFoods);
            break;
          case MealType.lunch:
            picked = pickRandom(lunchFoods);
            break;
          case MealType.snack:
            picked = pickRandom(snackFoods);
            break;
          case MealType.dinner:
            picked = pickRandom(dinnerFoods);
            break;
        }

        final portion = picked.portions.isNotEmpty ? picked.portions.first.name : 'serving';
        
        batch.insert('meal_prep_items', {
          'id': _uuid.v4(),
          'prepId': prepId,
          'day': day,
          'mealType': mealType.name,
          'foodId': picked.id,
          'portionName': portion,
          'quantity': 1.0, // Base quantity
        });
      }
    }
    
    await batch.commit(noResult: true);
  }
}

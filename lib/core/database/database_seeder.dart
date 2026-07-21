import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'database.dart';

class DatabaseSeeder {
  static const List<String> _seedFiles = [
    'assets/data/foods/attached_datasets.json',
    'assets/data/foods/indian_expansion_1000.json',
    'assets/data/foods/massive_database_12k.json',
    'assets/data/foods/missing_foods.json',
    'assets/data/foods/regional_dishes.json',
    'assets/data/foods/core_ingredients.json',
    'assets/data/foods/common_meals.json',
    'assets/data/foods/extended_indian_foods_part1.json'
  ];

  static Future<void> seedDatabaseIfEmpty() async {
    final db = await AppDatabase.instance.database;
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM foods');
    final count = Sqflite.firstIntValue(countResult) ?? 0;

    if (count == 0) {
      print('Database is empty. Starting seeding process...');
      for (String file in _seedFiles) {
        try {
          final String response = await rootBundle.loadString(file);
          final data = await json.decode(response);
          final List<dynamic> foods = data['foods'];
          
          List<Map<String, dynamic>> dbRows = [];
          for (var item in foods) {
            final per100g = item['per100g'];
            dbRows.add({
              'id': item['id'],
              'name': item['name'],
              'category': item['category'],
              'subCategory': item['subCategory'],
              'isVegetarian': (item['isVegetarian'] ?? false) ? 1 : 0,
              'caloriesMin': per100g['caloriesMin'] ?? 0.0,
              'caloriesMax': per100g['caloriesMax'] ?? 0.0,
              'protein': per100g['protein'] ?? 0.0,
              'carbs': per100g['carbs'] ?? 0.0,
              'fat': per100g['fat'] ?? 0.0,
              'fiber': per100g['fiber'] ?? 0.0,
              'sugar': per100g['sugar'],
              'sodium': per100g['sodium'],
              'aliases': json.encode(item['aliases'] ?? []),
            });
          }
          
          await AppDatabase.instance.insertFoodBatch(dbRows);
          print('Successfully seeded \${dbRows.length} foods from $file');
        } catch (e) {
          print('Error loading seed file $file: $e');
        }
      }
      print('Database seeding complete.');
    } else {
      print('Database already contains $count records. Skipping seeding.');
    }
  }
}

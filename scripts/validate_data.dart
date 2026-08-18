import 'dart:convert';
import 'dart:io';

void main() async {
  final dataDir = Directory('assets/data/foods');
  if (!await dataDir.exists()) {
    print('Data directory not found: assets/data/foods');
    return;
  }

  int totalFoods = 0;
  int errors = 0;

  final files = await dataDir.list().where((e) => e.path.endsWith('.json')).toList();

  for (final file in files) {
    if (file is File) {
      print('Validating ${file.path}...');
      try {
        final content = await file.readAsString();
        final json = jsonDecode(content);
        
        if (json['foods'] is! List) {
          print('  Error: "foods" array missing or invalid in ${file.path}');
          errors++;
          continue;
        }

        final foods = json['foods'] as List;
        for (var food in foods) {
          totalFoods++;
          if (!validateFood(food, file.path)) {
            errors++;
          }
        }
      } catch (e) {
        print('  Failed to parse ${file.path}: $e');
        errors++;
      }
    }
  }

  print('\nValidation Complete.');
  print('Total Foods: $totalFoods');
  print('Errors Found: $errors');
  if (errors > 0) {
    exit(1);
  }
}

bool validateFood(Map<String, dynamic> food, String fileName) {
  final id = food['id'];
  if (id == null) {
    print('  Error: Food missing ID in $fileName');
    return false;
  }

  bool isValid = true;

  // Required fields
  final requiredFields = ['name', 'category', 'isVegetarian', 'confidenceLevel', 'per100g'];
  for (var field in requiredFields) {
    if (!food.containsKey(field) || food[field] == null) {
      print('  Error ($id): Missing required field "$field"');
      isValid = false;
    }
  }

  // Validate per100g
  final p100g = food['per100g'];
  if (p100g != null) {
    final calMin = p100g['caloriesMin'];
    final calMax = p100g['caloriesMax'];
    final p = p100g['protein'];
    final c = p100g['carbs'];
    final f = p100g['fat'];

    if (calMin == null || calMax == null || p == null || c == null || f == null) {
       print('  Error ($id): Missing macros in per100g');
       return false;
    }

    // Macro check: (P*4 + C*4 + F*9)
    final expectedCals = (p * 4.0) + (c * 4.0) + (f * 9.0);
    // Allow a 15% or 15kcal margin of error for rounding, fiber, etc.
    final margin = (expectedCals * 0.15).clamp(15.0, double.infinity);
    
    // We check against the average of min and max
    final avgCal = (calMin + calMax) / 2;

    if ((avgCal - expectedCals).abs() > margin) {
      print('  Warning ($id): Calorie mismatch. Expected ~$expectedCals, got range $calMin-$calMax');
      // Just a warning for now, don't fail validation
    }
  }

  return isValid;
}

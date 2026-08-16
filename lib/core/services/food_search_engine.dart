import '../models/models.dart';

/// FoodSearchEngine — offline fuzzy search for foods in English, Hindi, Hinglish.
/// Works entirely without internet connection.
class FoodSearchEngine {
  final List<FoodItem> _foods;

  FoodSearchEngine(this._foods);

  /// Search foods by query. Supports English, Hindi, and Hinglish.
  /// Returns results sorted by relevance score.
  List<SearchResult> search(String query, {int maxResults = 20}) {
    if (query.trim().isEmpty) return [];

    final q = query.trim().toLowerCase();
    final results = <SearchResult>[];

    for (final food in _foods) {
      final score = _scoreFood(food, q);
      if (score > 0) {
        results.add(SearchResult(food: food, score: score));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(maxResults).toList();
  }

  /// Get foods by category.
  List<FoodItem> getByCategory(String category) {
    return _foods.where((f) => f.category == category).toList();
  }

  /// Get foods filtered by criteria.
  List<FoodItem> filter(FoodFilter filter) {
    return _foods.where((food) {
      if (filter.isVegetarianOnly && !food.isVegetarian) return false;
      if (filter.categories.isNotEmpty &&
          !filter.categories.contains(food.category)) return false;
      if (filter.mealType != null &&
          !food.mealTypes.contains(filter.mealType!)) return false;

      final p = food.per100g;
      if (filter.maxCaloriesPer100g != null &&
          p.caloriesMid > filter.maxCaloriesPer100g!) return false;
      if (filter.minProteinPer100g != null &&
          p.protein < filter.minProteinPer100g!) return false;

      return true;
    }).toList();
  }

  /// Sort food list by criteria.
  List<FoodItem> sort(List<FoodItem> foods, FoodSortBy sortBy) {
    final sorted = List<FoodItem>.from(foods);
    switch (sortBy) {
      case FoodSortBy.caloriesAsc:
        sorted.sort((a, b) =>
            a.per100g.caloriesMid.compareTo(b.per100g.caloriesMid));
        break;
      case FoodSortBy.caloriesDesc:
        sorted.sort((a, b) =>
            b.per100g.caloriesMid.compareTo(a.per100g.caloriesMid));
        break;
      case FoodSortBy.proteinDesc:
        sorted.sort((a, b) => b.per100g.protein.compareTo(a.per100g.protein));
        break;
      case FoodSortBy.carbsAsc:
        sorted.sort((a, b) => a.per100g.carbs.compareTo(b.per100g.carbs));
        break;
      case FoodSortBy.fiberDesc:
        sorted.sort((a, b) => b.per100g.fiber.compareTo(a.per100g.fiber));
        break;
      case FoodSortBy.proteinCalorieRatio:
        sorted.sort((a, b) {
          final ratioA = a.per100g.caloriesMid > 0
              ? a.per100g.protein / a.per100g.caloriesMid
              : 0;
          final ratioB = b.per100g.caloriesMid > 0
              ? b.per100g.protein / b.per100g.caloriesMid
              : 0;
          return ratioB.compareTo(ratioA);
        });
        break;
      case FoodSortBy.nameAz:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return sorted;
  }

  int _scoreFood(FoodItem food, String query) {
    int score = 0;

    // Exact name match — highest priority
    if (food.name.toLowerCase() == query) return 1000;
    if (food.nameHi != null && food.nameHi!.toLowerCase() == query) return 950;
    if (food.nameHinglish != null &&
        food.nameHinglish!.toLowerCase() == query) return 900;

    // Prefix match in name
    if (food.name.toLowerCase().startsWith(query)) score += 80;
    if (food.nameHi != null && food.nameHi!.startsWith(query)) score += 75;
    if (food.nameHinglish != null &&
        food.nameHinglish!.toLowerCase().startsWith(query)) score += 70;

    // Contains match in name
    if (food.name.toLowerCase().contains(query)) score += 50;
    if (food.nameHi != null && food.nameHi!.contains(query)) score += 45;
    if (food.nameHinglish != null &&
        food.nameHinglish!.toLowerCase().contains(query)) score += 40;

    // Alias match
    for (final alias in food.aliases) {
      final a = alias.toLowerCase();
      if (a == query) return 850;
      if (a.startsWith(query)) score += 60;
      if (a.contains(query)) score += 30;
    }

    // Fuzzy match (simple: shared characters ratio)
    if (score == 0) {
      final fuzzy = _fuzzyScore(food.name.toLowerCase(), query);
      if (fuzzy > 0.6) score += (fuzzy * 20).round();

      // Check aliases for fuzzy
      for (final alias in food.aliases) {
        final f = _fuzzyScore(alias.toLowerCase(), query);
        if (f > 0.6) score += (f * 15).round();
      }
    }

    return score;
  }

  /// Simple fuzzy score: proportion of query characters found in target.
  double _fuzzyScore(String target, String query) {
    if (query.length > target.length + 3) return 0;
    int matches = 0;
    int tIdx = 0;
    for (int qIdx = 0; qIdx < query.length && tIdx < target.length; qIdx++) {
      while (tIdx < target.length && target[tIdx] != query[qIdx]) {
        tIdx++;
      }
      if (tIdx < target.length) {
        matches++;
        tIdx++;
      }
    }
    return matches / query.length;
  }
}

class SearchResult {
  final FoodItem food;
  final int score;

  const SearchResult({required this.food, required this.score});
}

class FoodFilter {
  final bool isVegetarianOnly;
  final List<String> categories;
  final String? mealType;
  final double? maxCaloriesPer100g;
  final double? minProteinPer100g;

  const FoodFilter({
    this.isVegetarianOnly = false,
    this.categories = const [],
    this.mealType,
    this.maxCaloriesPer100g,
    this.minProteinPer100g,
  });

  FoodFilter copyWith({
    bool? isVegetarianOnly,
    List<String>? categories,
    String? mealType,
    double? maxCaloriesPer100g,
    double? minProteinPer100g,
  }) =>
      FoodFilter(
        isVegetarianOnly: isVegetarianOnly ?? this.isVegetarianOnly,
        categories: categories ?? this.categories,
        mealType: mealType ?? this.mealType,
        maxCaloriesPer100g: maxCaloriesPer100g ?? this.maxCaloriesPer100g,
        minProteinPer100g: minProteinPer100g ?? this.minProteinPer100g,
      );

  bool get hasActiveFilter =>
      isVegetarianOnly ||
      categories.isNotEmpty ||
      mealType != null ||
      maxCaloriesPer100g != null ||
      minProteinPer100g != null;
}

enum FoodSortBy {
  caloriesAsc,
  caloriesDesc,
  proteinDesc,
  carbsAsc,
  fiberDesc,
  proteinCalorieRatio,
  nameAz,
}

/// FoodParser — parses natural language food input into food items + quantities.
/// Rule-based; designed to be replaceable by an AI model in future.
class FoodParser {
  final FoodSearchEngine searchEngine;

  FoodParser(this.searchEngine);

  /// Parse a natural language string into a list of parsed food entries.
  List<ParsedFoodEntry> parse(String input) {
    if (input.trim().isEmpty) return [];

    // Split by common separators: comma, "aur", "और", "+"
    final parts = _splitInput(input);
    final results = <ParsedFoodEntry>[];

    for (final part in parts) {
      final entry = _parsePart(part.trim());
      if (entry != null) results.add(entry);
    }

    return results;
  }

  List<String> _splitInput(String input) {
    // Split on: comma, " aur ", " और ", " + "
    return input
        .replaceAll(' aur ', ',')
        .replaceAll(' और ', ',')
        .replaceAll(' + ', ',')
        .replaceAll('+', ',')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  ParsedFoodEntry? _parsePart(String part) {
    // Extract quantity prefix: "2 roti", "3 pieces chicken", "aadha plate rice"
    String quantityStr = '';
    double quantity = 1.0;
    String portionHint = '';

    // Number at start: "2 roti", "3 chicken pieces"
    final numMatch = RegExp(r'^(\d+(?:\.\d+)?)\s+').firstMatch(part);
    if (numMatch != null) {
      quantity = double.tryParse(numMatch.group(1) ?? '1') ?? 1.0;
      quantityStr = numMatch.group(0) ?? '';
    }

    // Fraction: "aadha", "half", "½"
    if (part.toLowerCase().contains('aadha') ||
        part.contains('½') ||
        part.toLowerCase().contains('half')) {
      quantity = 0.5;
      portionHint = 'half';
    }

    // Portion keywords
    final portionKeywords = {
      'plate': 'plate',
      'katori': 'katori',
      'bowl': 'bowl',
      'glass': 'glass',
      'piece': 'piece',
      'pieces': 'piece',
      'roti': 'roti',
      'rotis': 'roti',
      'cup': 'cup',
      'spoon': 'spoon',
      'tbsp': 'tablespoon',
      'tsp': 'teaspoon',
    };

    for (final kw in portionKeywords.entries) {
      if (part.toLowerCase().contains(kw.key)) {
        portionHint = kw.value;
        break;
      }
    }

    // Remove quantity and portion hints to get food name
    String foodQuery = part
        .replaceFirst(quantityStr, '')
        .replaceAll(RegExp(r'\baadha\b', caseSensitive: false), '')
        .replaceAll('½', '')
        .replaceAll(RegExp(r'\bhalf\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bplate\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bkatori\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bbowl\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bpieces?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\brotis?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bglass\b', caseSensitive: false), '')
        .trim();

    if (foodQuery.isEmpty) return null;

    final searchResults = searchEngine.search(foodQuery, maxResults: 1);
    if (searchResults.isEmpty) {
      return ParsedFoodEntry(
        rawInput: part,
        foodQuery: foodQuery,
        quantity: quantity,
        portionHint: portionHint,
        food: null,
        confidence: ParseConfidence.low,
      );
    }

    final topResult = searchResults.first;
    final food = topResult.food;

    // Find best matching portion
    PortionSize? matchedPortion;
    if (portionHint.isNotEmpty) {
      for (final portion in food.portions) {
        if (portion.name.toLowerCase().contains(portionHint)) {
          matchedPortion = portion;
          break;
        }
      }
    }
    matchedPortion ??= food.portions.isNotEmpty ? food.portions.first : null;

    return ParsedFoodEntry(
      rawInput: part,
      foodQuery: foodQuery,
      quantity: quantity,
      portionHint: portionHint,
      food: food,
      matchedPortion: matchedPortion,
      confidence: topResult.score > 500
          ? ParseConfidence.high
          : topResult.score > 100
              ? ParseConfidence.medium
              : ParseConfidence.low,
    );
  }
}

class ParsedFoodEntry {
  final String rawInput;
  final String foodQuery;
  final double quantity;
  final String portionHint;
  final FoodItem? food;
  final PortionSize? matchedPortion;
  final ParseConfidence confidence;

  const ParsedFoodEntry({
    required this.rawInput,
    required this.foodQuery,
    required this.quantity,
    required this.portionHint,
    required this.food,
    this.matchedPortion,
    required this.confidence,
  });
}

enum ParseConfidence { high, medium, low }

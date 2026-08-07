import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/di/providers.dart';

class CustomFoodScreen extends StatefulWidget {
  final String? initialName;
  final FoodItem? foodToEdit;

  const CustomFoodScreen({super.key, this.initialName, this.foodToEdit});

  @override
  State<CustomFoodScreen> createState() => _CustomFoodScreenState();
}

class _CustomFoodScreenState extends State<CustomFoodScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _uuid = const Uuid();

  // Simple Custom Food Controllers
  final _foodNameCtrl = TextEditingController();
  final _foodCaloriesCtrl = TextEditingController();
  final _foodProteinCtrl = TextEditingController();
  final _foodCarbsCtrl = TextEditingController();
  final _foodFatCtrl = TextEditingController();
  final _foodFiberCtrl = TextEditingController();
  final _foodServingSizeCtrl = TextEditingController();
  final _foodServingUnitCtrl = TextEditingController();

  // Custom Recipe Controllers
  final _recipeNameCtrl = TextEditingController();
  final _recipeIngredientsCtrl = TextEditingController();
  final _recipeServingsCtrl = TextEditingController();
  final _recipeCaloriesCtrl = TextEditingController();
  final _recipeProteinCtrl = TextEditingController();
  final _recipeCarbsCtrl = TextEditingController();
  final _recipeFatCtrl = TextEditingController();
  final _recipeFiberCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialName != null) {
      _foodNameCtrl.text = widget.initialName!;
      _recipeNameCtrl.text = widget.initialName!;
    }
    
    if (widget.foodToEdit != null) {
      final f = widget.foodToEdit!;
      if (f.category == 'Recipe') {
        _tabController.index = 1;
        _recipeNameCtrl.text = f.name;
        // Approximation since we store per 100g. 
        // We assume 1 serving = 100g if it's a recipe.
        _recipeCaloriesCtrl.text = f.per100g.caloriesMid.toStringAsFixed(0);
        _recipeProteinCtrl.text = f.per100g.protein.toStringAsFixed(1);
        _recipeCarbsCtrl.text = f.per100g.carbs.toStringAsFixed(1);
        _recipeFatCtrl.text = f.per100g.fat.toStringAsFixed(1);
        _recipeFiberCtrl.text = f.per100g.fiber.toStringAsFixed(1);
        _recipeServingsCtrl.text = "1";
      } else {
        _tabController.index = 0;
        _foodNameCtrl.text = f.name;
        _foodCaloriesCtrl.text = f.per100g.caloriesMid.toStringAsFixed(0);
        _foodProteinCtrl.text = f.per100g.protein.toStringAsFixed(1);
        _foodCarbsCtrl.text = f.per100g.carbs.toStringAsFixed(1);
        _foodFatCtrl.text = f.per100g.fat.toStringAsFixed(1);
        _foodFiberCtrl.text = f.per100g.fiber.toStringAsFixed(1);
        if (f.portions.isNotEmpty) {
          _foodServingSizeCtrl.text = f.portions.first.weightMidG.toStringAsFixed(0);
          _foodServingUnitCtrl.text = f.portions.first.name;
        } else {
          _foodServingSizeCtrl.text = "100";
          _foodServingUnitCtrl.text = "g";
        }
      }
    } else {
      _foodServingSizeCtrl.text = "100";
      _foodServingUnitCtrl.text = "g";
      _recipeServingsCtrl.text = "1";
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _foodNameCtrl.dispose();
    _foodCaloriesCtrl.dispose();
    _foodProteinCtrl.dispose();
    _foodCarbsCtrl.dispose();
    _foodFatCtrl.dispose();
    _foodFiberCtrl.dispose();
    _foodServingSizeCtrl.dispose();
    _foodServingUnitCtrl.dispose();
    _recipeNameCtrl.dispose();
    _recipeIngredientsCtrl.dispose();
    _recipeServingsCtrl.dispose();
    _recipeCaloriesCtrl.dispose();
    _recipeProteinCtrl.dispose();
    _recipeCarbsCtrl.dispose();
    _recipeFatCtrl.dispose();
    _recipeFiberCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchExternalSearch(String query, bool isYouTube) async {
    final urlString = isYouTube
        ? 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query + " recipe how to make")}'
        : 'https://www.google.com/search?q=${Uri.encodeComponent(query + " calories protein carbs fat per serving")}';

    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open browser. Please check your connection or default browser settings.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        title: const Text('Add New Food / Recipe'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Simple Food'),
            Tab(text: 'Custom Recipe'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSimpleFoodTab(),
          _buildRecipeTab(),
        ],
      ),
    );
  }

  Widget _buildSimpleFoodTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Create a simple food by manually entering its macros.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _foodNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Food Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () {
              if (_foodNameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a food name first.')));
                return;
              }
              _launchExternalSearch(_foodNameCtrl.text.trim(), false);
            },
            icon: const Icon(Icons.search),
            label: const Text('🔎 Search Nutrition Online'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _foodServingSizeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Serving Size', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _foodServingUnitCtrl,
                  decoration: const InputDecoration(labelText: 'Unit (e.g. g, cup)', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildMacroField(_foodCaloriesCtrl, 'Calories (kcal)', AppColors.calorieColor),
          _buildMacroField(_foodProteinCtrl, 'Protein (g)', AppColors.proteinColor),
          _buildMacroField(_foodCarbsCtrl, 'Carbs (g)', AppColors.carbColor),
          _buildMacroField(_foodFatCtrl, 'Fat (g)', AppColors.fatColor),
          _buildMacroField(_foodFiberCtrl, 'Fiber (g)', Colors.brown),
          const SizedBox(height: AppSpacing.xl),
          Consumer(builder: (context, ref, _) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(AppSpacing.md),
              ),
              onPressed: () => _saveSimpleFood(ref),
              child: const Text('Save Food', style: TextStyle(fontSize: 16)),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecipeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Create a recipe. List ingredients and we will try to calculate macros, or enter them manually.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _recipeNameCtrl,
            decoration: const InputDecoration(labelText: 'Recipe Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () {
              if (_recipeNameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a recipe name first.')));
                return;
              }
              _launchExternalSearch(_recipeNameCtrl.text.trim(), true);
            },
            icon: const Icon(Icons.play_circle_fill, color: Colors.red),
            label: const Text('▶ Watch YouTube Recipe'),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _recipeServingsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Number of Servings', border: OutlineInputBorder()),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _recipeIngredientsCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Ingredients (optional note)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('Total Recipe Macros (for the entire recipe):', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          _buildMacroField(_recipeCaloriesCtrl, 'Total Calories (kcal)', AppColors.calorieColor),
          _buildMacroField(_recipeProteinCtrl, 'Total Protein (g)', AppColors.proteinColor),
          _buildMacroField(_recipeCarbsCtrl, 'Total Carbs (g)', AppColors.carbColor),
          _buildMacroField(_recipeFatCtrl, 'Total Fat (g)', AppColors.fatColor),
          _buildMacroField(_recipeFiberCtrl, 'Total Fiber (g)', Colors.brown),
          const SizedBox(height: AppSpacing.xl),
          Consumer(builder: (context, ref, _) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(AppSpacing.md),
              ),
              onPressed: () => _saveCustomRecipe(ref),
              child: const Text('Save Recipe', style: TextStyle(fontSize: 16)),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMacroField(TextEditingController ctrl, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: color),
          border: const OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: color, width: 2)),
        ),
      ),
    );
  }

  Future<void> _saveSimpleFood(WidgetRef ref) async {
    if (_foodNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name.')));
      return;
    }

    final servingSize = double.tryParse(_foodServingSizeCtrl.text) ?? 100;
    // Normalize to 100g for the DB storage
    final multiplier = 100 / servingSize;

    final cals = (double.tryParse(_foodCaloriesCtrl.text) ?? 0) * multiplier;
    final protein = (double.tryParse(_foodProteinCtrl.text) ?? 0) * multiplier;
    final carbs = (double.tryParse(_foodCarbsCtrl.text) ?? 0) * multiplier;
    final fat = (double.tryParse(_foodFatCtrl.text) ?? 0) * multiplier;
    final fiber = (double.tryParse(_foodFiberCtrl.text) ?? 0) * multiplier;

    final food = FoodItem(
      id: widget.foodToEdit?.id ?? _uuid.v4(),
      name: _foodNameCtrl.text.trim(),
      aliases: [],
      category: 'Custom',
      isVegetarian: true, // Defaulting, could add a toggle
      confidenceLevel: ConfidenceLevel.high,
      isCustom: true,
      source: 'custom_food',
      per100g: NutrientProfile(
        caloriesMin: cals,
        caloriesMax: cals,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
      ),
      portions: [
        PortionSize(name: _foodServingUnitCtrl.text.trim(), weightMinG: servingSize, weightMaxG: servingSize),
      ],
    );

    final foodRepo = ref.read(foodRepositoryProvider);
    await foodRepo.addCustomFood(food);
    
    // Invalidate search and foods
    ref.invalidate(allFoodsProvider);
    ref.invalidate(foodSearchEngineProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Custom food saved!')));
      Navigator.pop(context);
    }
  }

  Future<void> _saveCustomRecipe(WidgetRef ref) async {
    if (_recipeNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a recipe name.')));
      return;
    }

    final servings = double.tryParse(_recipeServingsCtrl.text) ?? 1;
    final totalCals = double.tryParse(_recipeCaloriesCtrl.text) ?? 0;
    final totalProtein = double.tryParse(_recipeProteinCtrl.text) ?? 0;
    final totalCarbs = double.tryParse(_recipeCarbsCtrl.text) ?? 0;
    final totalFat = double.tryParse(_recipeFatCtrl.text) ?? 0;
    final totalFiber = double.tryParse(_recipeFiberCtrl.text) ?? 0;

    // Convert total macros to per 100g equivalent just for consistency in storage,
    // assuming 1 serving = 100g equivalent for the math to work out when they select "1 serving".
    // A much simpler way is to just store per 100g as the per serving macros, and the portion size is "1 serving" = 100g.
    final calsPerServing = totalCals / servings;
    final proteinPerServing = totalProtein / servings;
    final carbsPerServing = totalCarbs / servings;
    final fatPerServing = totalFat / servings;
    final fiberPerServing = totalFiber / servings;

    final food = FoodItem(
      id: widget.foodToEdit?.id ?? _uuid.v4(),
      name: _recipeNameCtrl.text.trim(),
      aliases: [],
      category: 'Recipe',
      isVegetarian: true,
      confidenceLevel: ConfidenceLevel.high,
      isCustom: true,
      source: 'custom_recipe',
      per100g: NutrientProfile(
        caloriesMin: calsPerServing,
        caloriesMax: calsPerServing,
        protein: proteinPerServing,
        carbs: carbsPerServing,
        fat: fatPerServing,
        fiber: fiberPerServing,
      ),
      portions: [
        const PortionSize(name: 'serving', weightMinG: 100, weightMaxG: 100),
      ],
    );

    final foodRepo = ref.read(foodRepositoryProvider);
    await foodRepo.addCustomFood(food);
    
    ref.invalidate(allFoodsProvider);
    ref.invalidate(foodSearchEngineProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Custom recipe saved!')));
      Navigator.pop(context);
    }
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class FactCornerScreen extends StatelessWidget {
  const FactCornerScreen({super.key});

  static const _facts = [
    _FactData(
      emoji: '🫘',
      title: 'Dal — The Indian Superfood',
      body: 'A katori (~150g) of cooked dal provides 10–15g of protein and 6–8g of fiber. It\'s one of the most nutritious plant-based protein sources available in any Indian kitchen.',
      category: 'protein',
    ),
    _FactData(
      emoji: '🍳',
      title: 'Eggs & Complete Protein',
      body: 'One whole egg provides ~6g of protein with all essential amino acids. The yolk contains B12, Vitamin D, and choline. Boiling is healthier than frying (saves ~50 kcal per egg).',
      category: 'protein',
    ),
    _FactData(
      emoji: '🫓',
      title: 'How Many Calories in One Roti?',
      body: 'One medium plain wheat roti (~40g) has ~120–130 kcal. Made with ghee? Add ~50 kcal per teaspoon. Whole wheat roti has more fiber than maida (refined flour).',
      category: 'grains',
    ),
    _FactData(
      emoji: '🍚',
      title: 'Rice vs. Roti',
      body: 'Both are similar in calories (200–220 kcal per medium serving). Rice is easier to digest. Opt for brown rice or par-boiled rice for more fiber. Don\'t avoid either — balance is key.',
      category: 'grains',
    ),
    _FactData(
      emoji: '🛢️',
      title: 'Oil in Indian Cooking',
      body: 'All cooking oils have ~900 kcal per 100ml (~120 kcal per tablespoon). Choose oils high in unsaturated fats (mustard, olive, groundnut). Reducing 2 tablespoons of oil per day saves ~240 kcal.',
      category: 'fats',
    ),
    _FactData(
      emoji: '🧀',
      title: 'Paneer: High Protein & Fat',
      body: '100g paneer provides ~18g protein, ~20g fat, ~265 kcal. It\'s nutritious but calorically dense. A katori (~50g) is a good serving for a balanced meal.',
      category: 'dairy',
    ),
    _FactData(
      emoji: '🏃',
      title: 'Calories Burned Walking',
      body: 'A 70kg person burns approximately 3.5 kcal per minute walking at a moderate pace. That\'s ~210 kcal per hour, or ~105 kcal per 30 minutes. A 2km evening walk ≈ 100–120 kcal.',
      category: 'activity',
    ),
    _FactData(
      emoji: '🍌',
      title: 'Potassium & Heart Health',
      body: 'Bananas are rich in potassium (~360mg per banana) which supports heart health. One banana = ~90 kcal, great post-workout. Potatoes also have surprisingly high potassium.',
      category: 'fruits',
    ),
    _FactData(
      emoji: '🥛',
      title: 'Dahi (Curd) — Probiotic Power',
      body: 'A katori of plain dahi (~150g) has ~100 kcal, 5–7g protein, and beneficial probiotics that support gut health. Low-fat dahi has ~60 kcal. Much healthier than store-bought flavored yogurt.',
      category: 'dairy',
    ),
    _FactData(
      emoji: '🔥',
      title: 'What is BMR?',
      body: 'Basal Metabolic Rate (BMR) is the energy your body needs just to exist — breathing, heartbeat, brain function. A 70kg, 170cm, 30-year-old man burns ~1680 kcal/day at complete rest.',
      category: 'science',
    ),
    _FactData(
      emoji: '🌾',
      title: 'Why Fiber Matters',
      body: 'Fiber slows digestion, keeps you full longer, and supports healthy blood sugar levels. Indian foods rich in fiber: whole dals, vegetables, oats, jowar, bajra. Aim for 25–35g per day.',
      category: 'nutrition',
    ),
    _FactData(
      emoji: '🥚',
      title: 'Protein per kcal — Best choices',
      body: 'Egg whites: 11g protein per 50 kcal (22g/100 kcal). Chicken breast: 7.5g protein per 50 kcal. Moong dal: 4g per 50 kcal. Paneer: 3.4g per 50 kcal. Choosing protein-dense foods helps satiety.',
      category: 'protein',
    ),
    _FactData(
      emoji: '🧠',
      title: 'Mindful Eating',
      body: 'It takes 20 minutes for satiety signals to reach your brain. Eating slowly helps you eat less without feeling deprived. Avoid TV/phone during meals. Chew thoroughly.',
      category: 'lifestyle',
    ),
    _FactData(
      emoji: '🥗',
      title: 'Sabji (Vegetables) Are Nutrition Powerhouses',
      body: 'A cup of spinach (palak) has only 23 kcal but provides iron, Vitamin K, and folate. Gobi (cauliflower) is ~25 kcal per cup with Vitamin C. Eat a variety of colors for diverse micronutrients.',
      category: 'vegetables',
    ),
    _FactData(
      emoji: '💧',
      title: 'Water & Weight Management',
      body: 'Drinking 500ml water before meals can reduce calorie intake by 13%. Often hunger is actually thirst. Adults need 2–3L of water daily, more during summer or after exercise.',
      category: 'lifestyle',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        title: const Text('🔥 Nutrition Fact Corner'),
        backgroundColor: AppColors.backgroundWarm,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.secondary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📚 Learn about Indian Nutrition',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 4),
                Text('${_facts.length} bite-sized facts curated for Indian households',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Category filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _CategoryChip(label: '🥩 Protein'),
                SizedBox(width: 8),
                _CategoryChip(label: '🌾 Grains'),
                SizedBox(width: 8),
                _CategoryChip(label: '🏃 Activity'),
                SizedBox(width: 8),
                _CategoryChip(label: '🔬 Science'),
                SizedBox(width: 8),
                _CategoryChip(label: '🥗 Vegetables'),
                SizedBox(width: 8),
                _CategoryChip(label: '💡 Lifestyle'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Facts list
          ..._facts.asMap().entries.map((entry) {
            final fact = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(fact.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fact.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    fact.body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      fact.category,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),
          const _DisclaimerCard(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _FactData {
  final String emoji;
  final String title;
  final String body;
  final String category;

  const _FactData({
    required this.emoji,
    required this.title,
    required this.body,
    required this.category,
  });
}

class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ℹ️', style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'These facts are for educational purposes only. Nutritional values are approximate and based on ICMR-NIN data and general dietary guidelines. Consult a registered dietitian or doctor for personal medical advice.',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

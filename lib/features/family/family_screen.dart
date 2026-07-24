import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/di/providers.dart';
import '../../core/models/models.dart';
import '../../core/widgets/app_widgets.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  @override
  Widget build(BuildContext context) {
    final allProfiles = ref.watch(allProfilesProvider);
    final activeUser = ref.watch(activeUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        title: const Text('👨‍👩‍👧 Family Profiles'),
      ),
      body: allProfiles.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const Center(child: Text('Error loading profiles')),
        data: (profiles) {
          final activeId = activeUser.value?.id;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Family Mode', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primary)),
                    Text('Switch between family members to track everyone\'s nutrition goals.', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text('${profiles.length} profile${profiles.length != 1 ? 's' : ''}', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),

              ...profiles.map((profile) => _ProfileCard(
                profile: profile,
                isActive: profile.id == activeId,
                onSwitch: () async {
                  final userRepo = ref.read(userProfileRepositoryProvider);
                  await userRepo.setActiveProfile(profile.id);
                  ref.invalidate(activeUserProvider);
                  ref.invalidate(todayNutritionProvider);
                  ref.invalidate(todayMealsProvider);
                  if (mounted) Navigator.pop(context);
                },
                onEdit: () => _showEditProfileSheet(context, profile),
              )),

              const SizedBox(height: 16),

              // Add new profile
              ElevatedButton.icon(
                onPressed: () => _showAddProfileSheet(context),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Add Family Member'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),

              const SizedBox(height: 32),

              const _FamilyTipsCard(),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  void _showAddProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddProfileSheet(
        onAdd: (profile) async {
          final userRepo = ref.read(userProfileRepositoryProvider);
          await userRepo.saveProfile(profile);
          ref.invalidate(allProfilesProvider);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, UserProfile profile) {
    // Could show editing sheet — for now show a stub
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing ${profile.name}\'s profile coming soon!')),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserProfile profile;
  final bool isActive;
  final VoidCallback onSwitch;
  final VoidCallback onEdit;

  const _ProfileCard({
    required this.profile,
    required this.isActive,
    required this.onSwitch,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryContainer : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isActive ? AppColors.primary : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                profile.avatarEmoji ?? '👤',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(profile.name, style: Theme.of(context).textTheme.titleMedium),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: const Text('Active', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                Text(
                  _profileSummary(profile),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Actions
          Column(
            children: [
              if (!isActive)
                TextButton(
                  onPressed: onSwitch,
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
                  child: const Text('Switch'),
                ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.textTertiary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _profileSummary(UserProfile p) {
    final parts = <String>[];
    if (p.age != null) parts.add('${p.age} yrs');
    if (p.gender != null) parts.add(_genderLabel(p.gender!));
    if (p.weightKg != null) parts.add('${p.weightKg!.toStringAsFixed(0)} kg');
    if (p.isVegetarian) parts.add('🌱 Veg');
    return parts.join(' • ');
  }

  String _genderLabel(Gender g) {
    switch (g) {
      case Gender.male: return 'Male';
      case Gender.female: return 'Female';
      case Gender.other: return 'Other';
    }
  }
}

class _AddProfileSheet extends StatefulWidget {
  final Function(UserProfile) onAdd;

  const _AddProfileSheet({required this.onAdd});

  @override
  State<_AddProfileSheet> createState() => _AddProfileSheetState();
}

class _AddProfileSheetState extends State<_AddProfileSheet> {
  final _nameController = TextEditingController();
  Gender? _gender;
  int? _age;
  bool _isVegetarian = false;
  String _avatar = '👤';
  final _uuid = const Uuid();

  final _avatarOptions = ['👤', '👨', '👩', '🧑', '👦', '👧', '🧓', '👴', '👵', '🧒'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: AppColors.textTertiary.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Add Family Member', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),

          // Avatar picker
          Wrap(
            spacing: 10,
            children: _avatarOptions.map((emoji) => GestureDetector(
              onTap: () => setState(() => _avatar = emoji),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _avatar == emoji ? AppColors.primaryContainer : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _avatar == emoji ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
              ),
            )).toList(),
          ),

          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name', hintText: 'Amma, Baba, Rahul...'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age (optional)'),
                  onChanged: (v) => setState(() => _age = int.tryParse(v)),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  const Text('🌱 Veg'),
                  Switch.adaptive(
                    value: _isVegetarian,
                    onChanged: (v) => setState(() => _isVegetarian = v),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nameController.text.trim().isEmpty ? null : _addProfile,
              child: const Text('Add Member'),
            ),
          ),
        ],
      ),
    );
  }

  void _addProfile() {
    final profile = UserProfile(
      id: _uuid.v4(),
      name: _nameController.text.trim(),
      age: _age,
      gender: _gender,
      activityLevel: ActivityLevel.moderatelyActive,
      goal: WeightGoal.maintain,
      isVegetarian: _isVegetarian,
      avatarEmoji: _avatar,
      isActive: false,
    );
    widget.onAdd(profile);
  }
}

class _FamilyTipsCard extends StatelessWidget {
  const _FamilyTipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡 Family Mode Tips', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          SizedBox(height: 8),
          Text('• Each family member has their own nutrition targets and meal logs.', style: TextStyle(fontSize: 13, height: 1.5)),
          Text('• Switch profiles to track different members throughout the day.', style: TextStyle(fontSize: 13, height: 1.5)),
          Text('• All data is stored locally — no internet required.', style: TextStyle(fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

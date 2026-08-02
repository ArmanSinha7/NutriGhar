import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/di/providers.dart';

class ManageHabitScreen extends ConsumerStatefulWidget {
  final Habit? habit;
  const ManageHabitScreen({super.key, this.habit});

  @override
  ConsumerState<ManageHabitScreen> createState() => _ManageHabitScreenState();
}

class _ManageHabitScreenState extends ConsumerState<ManageHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _iconCtrl = TextEditingController(text: '✅');
  
  int _colorValue = AppColors.primary.value;
  String _frequency = 'daily';

  final List<Color> _colorOptions = [
    AppColors.primary,
    Colors.redAccent,
    Colors.orange,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      _nameCtrl.text = widget.habit!.name;
      _iconCtrl.text = widget.habit!.icon;
      _colorValue = widget.habit!.colorValue;
      _frequency = widget.habit!.frequency;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        title: Text(widget.habit == null ? 'New Habit' : 'Edit Habit'),
        actions: [
          if (widget.habit != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _deleteHabit(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji / Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(_colorValue).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: TextField(
                      controller: _iconCtrl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 40),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ),
              const Center(child: Text('Tap to change emoji', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
              const SizedBox(height: AppSpacing.xl),

              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Habit Name',
                  hintText: 'e.g. Read 10 pages',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Color picker
              const Text('Theme Color', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 12,
                children: _colorOptions.map((color) {
                  final isSelected = color.value == _colorValue;
                  return GestureDetector(
                    onTap: () => setState(() => _colorValue = color.value),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Frequency
              const Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Every day')),
                  DropdownMenuItem(value: 'weekdays', child: Text('Weekdays only')),
                  DropdownMenuItem(value: 'weekends', child: Text('Weekends only')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _frequency = val);
                },
              ),
              const SizedBox(height: AppSpacing.xl * 2),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(_colorValue),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _saveHabit(context),
                  child: const Text('Save Habit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveHabit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final service = ref.read(habitServiceProvider);
    
    if (widget.habit == null) {
      final habit = Habit(
        id: const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        icon: _iconCtrl.text.trim().isEmpty ? '✨' : _iconCtrl.text.trim(),
        colorValue: _colorValue,
        frequency: _frequency,
        createdAt: DateTime.now(),
      );
      await service.addHabit(habit);
    } else {
      final habit = widget.habit!.copyWith(
        name: _nameCtrl.text.trim(),
        icon: _iconCtrl.text.trim().isEmpty ? '✨' : _iconCtrl.text.trim(),
        colorValue: _colorValue,
        frequency: _frequency,
      );
      await service.updateHabit(habit);
    }

    ref.invalidate(activeHabitsProvider);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteHabit(BuildContext context) async {
    final service = ref.read(habitServiceProvider);
    await service.deleteHabit(widget.habit!.id);
    ref.invalidate(activeHabitsProvider);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

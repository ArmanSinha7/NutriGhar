import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrighar/core/database/database.dart';
import 'package:nutrighar/core/models/models.dart';
import 'package:nutrighar/core/services/repositories.dart';
import 'package:uuid/uuid.dart';

final streakServiceProvider = Provider<StreakService>((ref) {
  return StreakService(ref);
});

class StreakService {
  final Ref _ref;
  final _uuid = const Uuid();

  StreakService(this._ref);

  Future<List<Streak>> getStreaks() async {
    final db = await AppDatabase.instance.database;
    final results = await db.query('streaks');
    return results.map((r) => Streak(
      id: r['id'] as String,
      type: r['type'] as String,
      currentStreak: r['currentStreak'] as int,
      longestStreak: r['longestStreak'] as int,
      lastDate: DateTime.parse(r['lastDate'] as String),
    )).toList();
  }

  Future<void> updateLoggingStreak() async {
    final db = await AppDatabase.instance.database;
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final streaks = await getStreaks();
    final logStreak = streaks.where((s) => s.type == 'logging').firstOrNull;

    if (logStreak == null) {
      // First log
      await db.insert('streaks', {
        'id': _uuid.v4(),
        'type': 'logging',
        'currentStreak': 1,
        'longestStreak': 1,
        'lastDate': todayStr,
      });
      return;
    }

    final lastDate = logStreak.lastDate;
    final difference = DateTime(today.year, today.month, today.day).difference(DateTime(lastDate.year, lastDate.month, lastDate.day)).inDays;

    if (difference == 0) {
      // Already updated today
      return;
    } else if (difference == 1) {
      // Consecutive day
      final newCurrent = logStreak.currentStreak + 1;
      final newLongest = newCurrent > logStreak.longestStreak ? newCurrent : logStreak.longestStreak;
      await db.update('streaks', {
        'currentStreak': newCurrent,
        'longestStreak': newLongest,
        'lastDate': todayStr,
      }, where: 'id = ?', whereArgs: [logStreak.id]);
    } else {
      // Streak broken
      await db.update('streaks', {
        'currentStreak': 1,
        'lastDate': todayStr,
      }, where: 'id = ?', whereArgs: [logStreak.id]);
    }
  }
}

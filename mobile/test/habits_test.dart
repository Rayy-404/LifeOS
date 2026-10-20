import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lifeos_mobile/app/theme.dart';
import 'package:lifeos_mobile/features/habits/domain/habit.dart';
import 'package:lifeos_mobile/features/habits/presentation/widgets/habit_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final now = DateTime.utc(2026, 10, 16, 8, 0);

  test(
    'Habit and HabitLog models serialize/deserialize JSON and compute Best Streak & Consistency %',
    () {
      final json = {
        'id': 'habit-1',
        'name': 'Membaca Buku 20 Halaman',
        'description': 'Setiap pagi sebelum kuliah',
        'isActive': true,
        'activeDays': [1, 3, 5],
        'currentStreak': 2,
        'completedToday': false,
        'weeklyLogs': [
          {
            'date': '2026-10-12',
            'isoWeekday': 1,
            'scheduled': true,
            'completed': true,
          },
          {
            'date': '2026-10-13',
            'isoWeekday': 2,
            'scheduled': false,
            'completed': false,
          },
          {
            'date': '2026-10-14',
            'isoWeekday': 3,
            'scheduled': true,
            'completed': true,
          },
          {
            'date': '2026-10-15',
            'isoWeekday': 4,
            'scheduled': false,
            'completed': false,
          },
          {
            'date': '2026-10-16',
            'isoWeekday': 5,
            'scheduled': true,
            'completed': false,
          },
          {
            'date': '2026-10-17',
            'isoWeekday': 6,
            'scheduled': false,
            'completed': false,
          },
          {
            'date': '2026-10-18',
            'isoWeekday': 7,
            'scheduled': false,
            'completed': false,
          },
        ],
        'createdAt': '2026-10-01T00:00:00.000Z',
        'updatedAt': '2026-10-16T00:00:00.000Z',
      };

      final habit = Habit.fromJson(json);
      expect(habit.id, 'habit-1');
      expect(habit.name, 'Membaca Buku 20 Halaman');
      expect(habit.activeDays, [1, 3, 5]);
      expect(habit.currentStreak, 2);
      expect(habit.scheduledCountThisWeek, 3);
      expect(habit.completedCountThisWeek, 2);

      final roundTrip = Habit.fromJson(habit.toJson());
      expect(roundTrip.name, habit.name);
      expect(roundTrip.weeklyLogs.length, 7);

      final logs = [
        HabitLog.fromJson({
          'id': 'l-1',
          'habitId': 'habit-1',
          'logDate': '2026-10-05', // Mon
          'completedAt': '2026-10-05T07:00:00.000Z',
          'createdAt': '2026-10-05T07:00:00.000Z',
        }),
        HabitLog.fromJson({
          'id': 'l-2',
          'habitId': 'habit-1',
          'logDate': '2026-10-07', // Wed
          'completedAt': '2026-10-07T07:00:00.000Z',
          'createdAt': '2026-10-07T07:00:00.000Z',
        }),
        HabitLog.fromJson({
          'id': 'l-3',
          'habitId': 'habit-1',
          'logDate': '2026-10-09', // Fri
          'completedAt': '2026-10-09T07:00:00.000Z',
          'createdAt': '2026-10-09T07:00:00.000Z',
        }),
        HabitLog.fromJson({
          'id': 'l-4',
          'habitId': 'habit-1',
          'logDate': '2026-10-12', // Mon
          'completedAt': '2026-10-12T07:00:00.000Z',
          'createdAt': '2026-10-12T07:00:00.000Z',
        }),
      ];

      expect(habit.computeBestStreak(logs), 4);
      final consistency = habit.computeMonthlyConsistencyPercent(
        logs,
        2026,
        10,
        now: DateTime(2026, 10, 12),
      );
      expect(consistency, greaterThanOrEqualTo(80));
    },
  );

  testWidgets(
    'HabitCard displays streak pill, weekly count, and triggers check-in callback',
    (WidgetTester tester) async {
      var checkInTapped = false;
      final habit = Habit(
        id: 'habit-2',
        name: 'Minum 2L Air',
        activeDays: const [1, 2, 3, 4, 5, 6, 7],
        currentStreak: 5,
        completedToday: false,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: HabitCard(
              habit: habit,
              onToggleCheckIn: () => checkInTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Minum 2L Air'), findsOneWidget);
      expect(find.text('🔥 5 day streak'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('habit_checkin_habit-2')),
      );
      await tester.pump();

      expect(checkInTapped, isTrue);
    },
  );
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_mobile/core/state/data_revision_provider.dart';
import 'package:lifeos_mobile/core/utils/local_date_time_helper.dart';
import 'package:lifeos_mobile/features/calendar/domain/calendar_event.dart';
import 'package:lifeos_mobile/features/dashboard/domain/dashboard_summary.dart';
import 'package:lifeos_mobile/features/tasks/domain/task.dart';

void main() {
  test(
    'LocalDateTimeHelper converts UTC to local and evaluates event day overlap',
    () {
      final localStart = DateTime(2026, 10, 18, 23, 0);
      final localEnd = DateTime(2026, 10, 19, 1, 0); // crosses midnight

      expect(
        LocalDateTimeHelper.doesEventOverlapLocalDay(
          localStart,
          localEnd,
          DateTime(2026, 10, 18),
        ),
        isTrue,
      );
      expect(
        LocalDateTimeHelper.doesEventOverlapLocalDay(
          localStart,
          localEnd,
          DateTime(2026, 10, 19),
        ),
        isTrue,
      );
      expect(
        LocalDateTimeHelper.doesEventOverlapLocalDay(
          localStart,
          localEnd,
          DateTime(2026, 10, 20),
        ),
        isFalse,
      );
    },
  );

  test(
    'CalendarAgendaSnapshot combines EVENT and TASK entries in chronological order',
    () {
      final day = DateTime(2026, 10, 18);
      final event = CalendarEvent(
        id: 'ev-1',
        title: 'Kuliah Sistem Operasi',
        location: 'Gedung B R.204',
        startsAt: DateTime(2026, 10, 18, 8, 0),
        endsAt: DateTime(2026, 10, 18, 10, 0),
        createdAt: day,
        updatedAt: day,
      );
      final task = Task(
        id: 'tk-1',
        title: 'Laporan Praktikum Jarkom',
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        dueAt: DateTime(2026, 10, 18, 12, 0),
        createdAt: day,
        updatedAt: day,
      );

      final snapshot = CalendarAgendaSnapshot(
        from: '2026-10-18',
        to: '2026-10-18',
        events: [event],
        tasks: [task],
      );

      final combined = snapshot.combinedEntriesForDay(day);
      expect(combined, hasLength(2));
      expect(combined[0].isEvent, isTrue);
      expect(combined[0].event?.title, 'Kuliah Sistem Operasi');
      expect(combined[1].isTask, isTrue);
      expect(combined[1].task?.title, 'Laporan Praktikum Jarkom');
    },
  );

  test(
    'DashboardSnapshot parses JSON and computes completionPercent accurately',
    () {
      final json = {
        'date': '2026-10-18',
        'timezone': 'Asia/Jakarta',
        'tasks': {
          'total': 5,
          'completed': 3,
          'pending': 2,
          'overdue': 1,
        },
        'habits': {
          'scheduled': 3,
          'completed': 2,
        },
        'upcomingEvents': [
          {
            'id': 'ev-1',
            'title': 'Belajar Pemrograman',
            'location': 'Rumah',
            'startsAt': '2026-10-18T01:00:00.000Z',
            'endsAt': '2026-10-18T03:00:00.000Z',
            'createdAt': '2026-10-18T00:00:00.000Z',
            'updatedAt': '2026-10-18T00:00:00.000Z',
          },
        ],
        'todayTasks': [],
        'todayHabits': [],
      };

      final snapshot = DashboardSnapshot.fromJson(json);
      expect(snapshot.date, '2026-10-18');
      expect(snapshot.tasks.completionPercent, 60);
      expect(snapshot.habits.scheduled, 3);
      expect(snapshot.habits.completed, 2);
      expect(snapshot.upcomingEvents, hasLength(1));

      final roundTrip = DashboardSnapshot.fromJson(snapshot.toJson());
      expect(roundTrip.tasks.total, 5);
      expect(roundTrip.upcomingEvents.first.title, 'Belajar Pemrograman');
    },
  );

  test('dataRevisionProvider increments after a domain mutation signal', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(dataRevisionProvider), 0);
    container.read(dataRevisionProvider.notifier).markChanged();
    container.read(dataRevisionProvider.notifier).markChanged();
    expect(container.read(dataRevisionProvider), 2);
  });
}

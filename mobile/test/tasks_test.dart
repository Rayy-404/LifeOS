import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lifeos_mobile/app/theme.dart';
import 'package:lifeos_mobile/core/widgets/task_card.dart';
import 'package:lifeos_mobile/features/tasks/domain/task.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final now = DateTime.utc(2026, 10, 19, 8, 0);

  test('Task model serializes and deserializes JSON and evaluates isOverdue', () {
    final json = {
      'id': 'task-1',
      'title': 'Menyelesaikan proyek Flutter',
      'description': 'Implementasi task manager',
      'status': 'TODO',
      'priority': 'HIGH',
      'dueAt': '2026-10-18T12:00:00.000Z',
      'completedAt': null,
      'createdAt': '2026-10-18T01:00:00.000Z',
      'updatedAt': '2026-10-18T01:00:00.000Z',
      'reminders': [
        {'id': 'rem-1'},
      ],
    };

    final task = Task.fromJson(json);
    expect(task.id, 'task-1');
    expect(task.status, TaskStatus.todo);
    expect(task.priority, TaskPriority.high);
    expect(task.reminderIds, ['rem-1']);
    expect(task.isDone, isFalse);
    expect(task.isOverdue(now), isTrue);

    final doneTask = task.copyWith(
      status: TaskStatus.done,
      completedAt: now,
    );
    expect(doneTask.isDone, isTrue);
    expect(doneTask.isOverdue(now), isFalse);

    final roundTrip = Task.fromJson(doneTask.toJson());
    expect(roundTrip.status, TaskStatus.done);
    expect(roundTrip.priority, TaskPriority.high);
  });

  testWidgets('TaskCard renders title, priority badge, and triggers one-tap toggle', (
    WidgetTester tester,
  ) async {
    var toggled = false;
    final task = Task(
      id: 'task-2',
      title: 'Kumpul Laporan Praktikum Jarkom',
      description: 'Bab 1 sampai Bab 4',
      status: TaskStatus.todo,
      priority: TaskPriority.high,
      dueAt: DateTime.now().add(const Duration(hours: 5)),
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TaskCard(
            task: task,
            onToggleDone: () => toggled = true,
          ),
        ),
      ),
    );

    expect(find.text('Kumpul Laporan Praktikum Jarkom'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('task_checkbox_task-2')),
    );
    await tester.pump();

    expect(toggled, isTrue);
  });
}

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/tasks_repository.dart';
import '../domain/task.dart';

class TasksFilterState extends Equatable {
  const TasksFilterState({
    this.tab = TaskTabFilter.all,
    this.priority,
    this.search = '',
  });

  final TaskTabFilter tab;
  final TaskPriority? priority;
  final String search;

  TasksFilterState copyWith({
    TaskTabFilter? tab,
    TaskPriority? priority,
    bool clearPriority = false,
    String? search,
  }) {
    return TasksFilterState(
      tab: tab ?? this.tab,
      priority: clearPriority ? null : (priority ?? this.priority),
      search: search ?? this.search,
    );
  }

  @override
  List<Object?> get props => [tab, priority, search];
}

final tasksFilterProvider =
    NotifierProvider<TasksFilterNotifier, TasksFilterState>(
  TasksFilterNotifier.new,
);

class TasksFilterNotifier extends Notifier<TasksFilterState> {
  @override
  TasksFilterState build() => const TasksFilterState();

  void setTab(TaskTabFilter tab) {
    state = state.copyWith(tab: tab);
  }

  void setPriority(TaskPriority? priority) {
    state = state.copyWith(
      priority: priority,
      clearPriority: priority == null,
    );
  }

  void setSearch(String search) {
    state = state.copyWith(search: search);
  }

  void reset() {
    state = const TasksFilterState();
  }
}

final tasksControllerProvider =
    AsyncNotifierProvider<TasksController, PaginatedTasks>(
  TasksController.new,
);

class TasksController extends AsyncNotifier<PaginatedTasks> {
  TasksRepository get _repository => ref.read(tasksRepositoryProvider);

  @override
  Future<PaginatedTasks> build() async {
    final filter = ref.watch(tasksFilterProvider);
    return _fetchForFilter(filter);
  }

  Future<PaginatedTasks> _fetchForFilter(TasksFilterState filter) async {
    final now = DateTime.now();
    final dateFmt = DateFormat('yyyy-MM-dd');
    final todayStr = dateFmt.format(now);
    final tomorrowStr = dateFmt.format(now.add(const Duration(days: 1)));

    TaskStatus? statusParam;
    String? fromParam;
    String? toParam;

    switch (filter.tab) {
      case TaskTabFilter.all:
        break;
      case TaskTabFilter.today:
        fromParam = todayStr;
        toParam = todayStr;
      case TaskTabFilter.upcoming:
        fromParam = tomorrowStr;
      case TaskTabFilter.completed:
        statusParam = TaskStatus.done;
    }

    final result = await _repository.listTasks(
      status: statusParam,
      priority: filter.priority,
      from: fromParam,
      to: toParam,
      search: filter.search.trim().isEmpty ? null : filter.search.trim(),
    );

    if (filter.tab == TaskTabFilter.upcoming) {
      final filteredItems =
          result.items.where((task) => !task.isDone).toList();
      return PaginatedTasks(
        items: filteredItems,
        meta: result.meta,
        isFromCache: result.isFromCache,
      );
    }

    return result;
  }

  Future<void> refresh() async {
    final filter = ref.read(tasksFilterProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchForFilter(filter));
  }

  Future<Task> createTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueAt,
  }) async {
    final created = await _repository.createTask(
      title: title,
      description: description,
      priority: priority,
      dueAt: dueAt,
    );
    ref.invalidateSelf();
    return created;
  }

  Future<Task> updateTask(
    Task existing, {
    String? title,
    String? description,
    bool includeNullDescription = false,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueAt,
    bool includeNullDueAt = false,
  }) async {
    final updated = await _repository.updateTask(
      existing.id,
      title: title,
      description: description,
      includeNullDescription: includeNullDescription,
      status: status,
      priority: priority,
      dueAt: dueAt,
      includeNullDueAt: includeNullDueAt,
      reminderIdsToCancelOnDone: existing.reminderIds,
    );
    ref.invalidateSelf();
    return updated;
  }

  /// Optimistically toggles task status between `DONE` and `TODO` (`02-design-brief.md` Section 5).
  Future<void> toggleTaskDone(Task task) async {
    final nextStatus = task.isDone ? TaskStatus.todo : TaskStatus.done;
    final previousState = state.value;

    if (previousState != null) {
      final optimisticItems = previousState.items.map((item) {
        if (item.id != task.id) return item;
        return item.copyWith(
          status: nextStatus,
          completedAt: nextStatus == TaskStatus.done ? DateTime.now() : null,
          clearCompletedAt: nextStatus != TaskStatus.done,
        );
      }).toList();

      state = AsyncData(
        PaginatedTasks(
          items: optimisticItems,
          meta: previousState.meta,
          isFromCache: previousState.isFromCache,
        ),
      );
    }

    try {
      await _repository.updateTask(
        task.id,
        status: nextStatus,
        reminderIdsToCancelOnDone: task.reminderIds,
      );
      ref.invalidateSelf();
    } catch (_) {
      if (previousState != null) {
        state = AsyncData(previousState);
      }
      rethrow;
    }
  }

  Future<void> deleteTask(Task task) async {
    await _repository.deleteTask(
      task.id,
      reminderIds: task.reminderIds,
    );
    ref.invalidateSelf();
  }
}

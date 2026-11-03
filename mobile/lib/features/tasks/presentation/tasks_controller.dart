import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/state/data_revision_provider.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
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
    if (state.value == null) {
      state = const AsyncLoading();
    }
    state = await AsyncValue.guard(() => _fetchForFilter(filter));
  }

  /// Optimistically inserts a temporary task into UI state immediately (< 50ms)
  /// and reconciles with the real server task in the background.
  Future<Task> createTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueAt,
  }) async {
    final now = DateTime.now().toUtc();
    final tempId = 'temp_${now.microsecondsSinceEpoch}';
    final tempTask = Task(
      id: tempId,
      title: title,
      description: description,
      status: TaskStatus.todo,
      priority: priority,
      dueAt: dueAt?.toUtc(),
      createdAt: now,
      updatedAt: now,
    );

    final previousState = state.value;
    if (previousState != null) {
      state = AsyncData(
        PaginatedTasks(
          items: [tempTask, ...previousState.items],
          meta: PaginationMeta(
            page: previousState.meta.page,
            limit: previousState.meta.limit,
            totalItems: previousState.meta.totalItems + 1,
            totalPages: previousState.meta.totalPages == 0
                ? 1
                : previousState.meta.totalPages,
          ),
          isFromCache: previousState.isFromCache,
        ),
      );
    }
    ref
        .read(dashboardControllerProvider.notifier)
        .optimisticInsertTask(tempTask);

    try {
      final created = await _repository.createTask(
        title: title,
        description: description,
        priority: priority,
        dueAt: dueAt,
      );

      final current = state.value;
      if (current != null) {
        final reconciled = current.items
            .map((t) => t.id == tempId ? created : t)
            .toList(growable: false);
        state = AsyncData(
          PaginatedTasks(
            items: reconciled,
            meta: current.meta,
            isFromCache: current.isFromCache,
          ),
        );
      }
      ref
          .read(dashboardControllerProvider.notifier)
          .optimisticReplaceTask(tempId, created);
      _notifyDataChanged();
      return created;
    } catch (_) {
      if (previousState != null) {
        state = AsyncData(previousState);
      }
      ref
          .read(dashboardControllerProvider.notifier)
          .optimisticRemoveTask(tempId);
      rethrow;
    }
  }

  /// Optimistically updates the task in local state before syncing with the server.
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
    final previousState = state.value;
    final optimisticTask = existing.copyWith(
      title: title ?? existing.title,
      description: description,
      clearDescription: includeNullDescription,
      status: status ?? existing.status,
      priority: priority ?? existing.priority,
      dueAt: dueAt?.toUtc(),
      clearDueAt: includeNullDueAt,
      updatedAt: DateTime.now().toUtc(),
    );

    if (previousState != null) {
      state = AsyncData(
        PaginatedTasks(
          items: previousState.items
              .map((t) => t.id == existing.id ? optimisticTask : t)
              .toList(growable: false),
          meta: previousState.meta,
          isFromCache: previousState.isFromCache,
        ),
      );
    }
    ref
        .read(dashboardControllerProvider.notifier)
        .optimisticReplaceTask(existing.id, optimisticTask);

    try {
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

      final current = state.value;
      if (current != null) {
        state = AsyncData(
          PaginatedTasks(
            items: current.items
                .map((t) => t.id == existing.id ? updated : t)
                .toList(growable: false),
            meta: current.meta,
            isFromCache: current.isFromCache,
          ),
        );
      }
      ref
          .read(dashboardControllerProvider.notifier)
          .optimisticReplaceTask(existing.id, updated);
      _notifyDataChanged();
      return updated;
    } catch (_) {
      if (previousState != null) {
        state = AsyncData(previousState);
      }
      ref
          .read(dashboardControllerProvider.notifier)
          .optimisticReplaceTask(existing.id, existing);
      rethrow;
    }
  }

  /// Optimistically toggles task status between `DONE` and `TODO` (`02-design-brief.md` Section 5).
  Future<void> toggleTaskDone(Task task) async {
    final nextStatus = task.isDone ? TaskStatus.todo : TaskStatus.done;
    final previousState = state.value;
    final optimisticTask = task.copyWith(
      status: nextStatus,
      completedAt: nextStatus == TaskStatus.done ? DateTime.now() : null,
      clearCompletedAt: nextStatus != TaskStatus.done,
    );

    if (previousState != null) {
      final optimisticItems = previousState.items.map((item) {
        if (item.id != task.id) return item;
        return optimisticTask;
      }).toList(growable: false);

      state = AsyncData(
        PaginatedTasks(
          items: optimisticItems,
          meta: previousState.meta,
          isFromCache: previousState.isFromCache,
        ),
      );
    }
    ref
        .read(dashboardControllerProvider.notifier)
        .optimisticReplaceTask(task.id, optimisticTask);

    try {
      final updated = await _repository.updateTask(
        task.id,
        status: nextStatus,
        reminderIdsToCancelOnDone: task.reminderIds,
      );

      final current = state.value;
      if (current != null) {
        state = AsyncData(
          PaginatedTasks(
            items: current.items
                .map((item) => item.id == task.id ? updated : item)
                .toList(growable: false),
            meta: current.meta,
            isFromCache: current.isFromCache,
          ),
        );
      }
      ref
          .read(dashboardControllerProvider.notifier)
          .optimisticReplaceTask(task.id, updated);
      _notifyDataChanged();
    } catch (_) {
      if (previousState != null) {
        state = AsyncData(previousState);
      }
      ref
          .read(dashboardControllerProvider.notifier)
          .optimisticReplaceTask(task.id, task);
      rethrow;
    }
  }

  /// Optimistically removes the task immediately before deleting on the backend.
  Future<void> deleteTask(Task task) async {
    final previousState = state.value;
    if (previousState != null) {
      state = AsyncData(
        PaginatedTasks(
          items: previousState.items
              .where((t) => t.id != task.id)
              .toList(growable: false),
          meta: PaginationMeta(
            page: previousState.meta.page,
            limit: previousState.meta.limit,
            totalItems:
                (previousState.meta.totalItems - 1).clamp(0, 999999),
            totalPages: previousState.meta.totalPages,
          ),
          isFromCache: previousState.isFromCache,
        ),
      );
    }
    ref
        .read(dashboardControllerProvider.notifier)
        .optimisticRemoveTask(task.id);

    try {
      await _repository.deleteTask(
        task.id,
        reminderIds: task.reminderIds,
      );
      _notifyDataChanged();
    } catch (_) {
      if (previousState != null) {
        state = AsyncData(previousState);
      }
      ref
          .read(dashboardControllerProvider.notifier)
          .optimisticInsertTask(task);
      rethrow;
    }
  }

  void _notifyDataChanged() {
    ref.read(dataRevisionProvider.notifier).markChanged();
  }
}

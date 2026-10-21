import 'package:equatable/equatable.dart';

enum TaskStatus {
  todo('TODO', 'To Do'),
  inProgress('IN_PROGRESS', 'In Progress'),
  done('DONE', 'Completed');

  const TaskStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static TaskStatus fromApi(String? value) {
    switch (value) {
      case 'IN_PROGRESS':
        return TaskStatus.inProgress;
      case 'DONE':
        return TaskStatus.done;
      case 'TODO':
      default:
        return TaskStatus.todo;
    }
  }
}

enum TaskPriority {
  low('LOW', 'Low'),
  medium('MEDIUM', 'Medium'),
  high('HIGH', 'High');

  const TaskPriority(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static TaskPriority fromApi(String? value) {
    switch (value) {
      case 'LOW':
        return TaskPriority.low;
      case 'HIGH':
        return TaskPriority.high;
      case 'MEDIUM':
      default:
        return TaskPriority.medium;
    }
  }
}

/// Primary filter chips on S-05 My Tasks (`DESIGN.md` S-05).
enum TaskTabFilter {
  all('All'),
  today('Today'),
  upcoming('Upcoming'),
  completed('Completed');

  const TaskTabFilter(this.label);
  final String label;
}

class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    this.description,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.dueAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.reminderIds = const [],
  });

  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> reminderIds;

  bool get isDone => status == TaskStatus.done;

  bool isOverdue([DateTime? now]) {
    if (isDone || dueAt == null) return false;
    final reference = now ?? DateTime.now();
    return dueAt!.isBefore(reference);
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final rawReminders = json['reminders'];
    final reminderIds = <String>[];
    if (rawReminders is List) {
      for (final item in rawReminders) {
        if (item is Map<String, dynamic> && item['id'] is String) {
          reminderIds.add(item['id'] as String);
        }
      }
    }

    final now = DateTime.now().toUtc();
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: TaskStatus.fromApi(json['status'] as String?),
      priority: TaskPriority.fromApi(json['priority'] as String?),
      dueAt: json['dueAt'] != null
          ? DateTime.parse(json['dueAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : now,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : now,
      reminderIds: reminderIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.apiValue,
      'priority': priority.apiValue,
      'dueAt': dueAt?.toUtc().toIso8601String(),
      'completedAt': completedAt?.toUtc().toIso8601String(),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'reminders': reminderIds
          .map((id) => <String, dynamic>{'id': id})
          .toList(growable: false),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool clearDescription = false,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueAt,
    bool clearDueAt = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? reminderIds,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderIds: reminderIds ?? this.reminderIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        priority,
        dueAt,
        completedAt,
        createdAt,
        updatedAt,
        reminderIds,
      ];
}

class PaginationMeta extends Equatable {
  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  factory PaginationMeta.fromJson(Map<String, dynamic>? json, int fallbackCount) {
    if (json == null) {
      return PaginationMeta(
        page: 1,
        limit: 20,
        totalItems: fallbackCount,
        totalPages: fallbackCount == 0 ? 0 : 1,
      );
    }
    return PaginationMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? fallbackCount,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'page': page,
        'limit': limit,
        'totalItems': totalItems,
        'totalPages': totalPages,
      };

  @override
  List<Object?> get props => [page, limit, totalItems, totalPages];
}

class PaginatedTasks extends Equatable {
  const PaginatedTasks({
    required this.items,
    required this.meta,
    this.isFromCache = false,
  });

  final List<Task> items;
  final PaginationMeta meta;
  final bool isFromCache;

  @override
  List<Object?> get props => [items, meta, isFromCache];
}

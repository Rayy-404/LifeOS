import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/error_state_card.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../../../core/widgets/task_card.dart';
import '../../domain/task.dart';
import '../tasks_controller.dart';
import '../widgets/task_form_sheet.dart';

/// S-05 My Tasks Screen (`DESIGN.md` S-05 & `02-design-brief.md` Section 6).
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      ref.read(tasksFilterProvider.notifier).setSearch(value);
    });
  }

  Future<void> _openTaskForm({Task? task}) async {
    final saved = await TaskFormSheet.show(context, initialTask: task);
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            task == null ? 'Task created' : 'Task updated',
          ),
        ),
      );
    }
  }

  Future<void> _handleToggleDone(Task task) async {
    try {
      await ref.read(tasksControllerProvider.notifier).toggleTaskDone(task);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(tasksFilterProvider);
    final tasksAsync = ref.watch(tasksControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          PopupMenuButton<TaskPriority?>(
            tooltip: 'Filter by priority',
            icon: Icon(
              LucideIcons.slidersHorizontal,
              color: filter.priority != null
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
            onSelected: (priority) =>
                ref.read(tasksFilterProvider.notifier).setPriority(priority),
            itemBuilder: (_) => [
              const PopupMenuItem<TaskPriority?>(
                value: null,
                child: Text('All Priorities'),
              ),
              ...TaskPriority.values.map(
                (priority) => PopupMenuItem<TaskPriority?>(
                  value: priority,
                  child: Text('Priority: ${priority.label}'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: filter.search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(tasksFilterProvider.notifier)
                                .setSearch('');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: TaskTabFilter.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final tab = TaskTabFilter.values[index];
                    final selected = filter.tab == tab;
                    return InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      onTap: () =>
                          ref.read(tasksFilterProvider.notifier).setTab(tab),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Center(
                          child: Text(
                            tab.label,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: tasksAsync.when(
                  loading: () => const TaskListShimmer(),
                  error: (error, _) {
                    final message = error is ApiException
                        ? error.message
                        : 'Tidak dapat memuat daftar tugas.';
                    return ErrorStateCard(
                      message: message,
                      onRetry: () =>
                          ref.read(tasksControllerProvider.notifier).refresh(),
                    );
                  },
                  data: (paginated) {
                    if (paginated.items.isEmpty) {
                      return AppEmptyState(
                        icon: LucideIcons.circleCheck,
                        title: filter.search.isNotEmpty
                            ? 'No matching tasks'
                            : 'No tasks today 🎉',
                        subtitle: filter.search.isNotEmpty
                            ? 'Try a different keyword or clear your filters.'
                            : 'Add your lecture assignments or daily targets to stay organized.',
                        actionLabel:
                            filter.search.isEmpty ? 'Add your first task' : null,
                        onAction: filter.search.isEmpty
                            ? () => _openTaskForm()
                            : null,
                      );
                    }

                    return Column(
                      children: [
                        if (paginated.isFromCache) ...[
                          const OfflineBanner(),
                          const SizedBox(height: 12),
                        ],
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () => ref
                                .read(tasksControllerProvider.notifier)
                                .refresh(),
                            child: ListView.separated(
                              padding: const EdgeInsets.only(bottom: 100),
                              itemCount: paginated.items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final task = paginated.items[index];
                                return TaskCard(
                                  key: ValueKey('task_${task.id}'),
                                  task: task,
                                  onToggleDone: () => _handleToggleDone(task),
                                  onTap: () => _openTaskForm(task: task),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

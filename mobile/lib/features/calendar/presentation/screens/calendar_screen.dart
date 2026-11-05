import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../app/theme.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/utils/local_date_time_helper.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/error_state_card.dart';
import '../../../../core/widgets/lifeos_top_header.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../../tasks/presentation/widgets/task_form_sheet.dart';
import '../../domain/calendar_event.dart';
import '../calendar_controller.dart';
import '../widgets/event_form_sheet.dart';

/// S-07 Calendar Screen — matches Google Stitch `Calendar` (`a2a743ddaa98449ab1b9b428c68a4f9c`)
/// and connects to `/api/v1/calendar/events` (`02-design-brief.md` Section 6 S-07 & `DESIGN.md` S-07).
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  List<Color> _dotsForDay(CalendarAgendaSnapshot? snapshot, DateTime day) {
    if (snapshot == null) return const [];
    final events = snapshot.eventsForDay(day);
    final tasks = snapshot.tasksForDay(day);
    final colors = <Color>[];
    if (events.isNotEmpty) {
      colors.add(AppColors.violet);
    }
    if (tasks.isNotEmpty) {
      final hasOverdue = tasks.any((t) => t.isOverdue());
      colors.add(hasOverdue ? AppColors.error : AppColors.warning);
    }
    return colors;
  }

  String _periodLabel(DateTime dt) {
    final h = dt.hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final viewState = ref.watch(calendarViewProvider);
    final agendaAsync = ref.watch(calendarControllerProvider);
    final snapshot = agendaAsync.value;
    final isFromCache = snapshot?.isFromCache ?? false;

    final selectedDay = viewState.selectedDay;
    final focusedDay = viewState.focusedDay;
    final entries =
        snapshot?.combinedEntriesForDay(selectedDay) ?? const <CalendarAgendaEntry>[];

    final mondayOfSelectedWeek =
        selectedDay.subtract(Duration(days: selectedDay.weekday - 1));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const LifeOsTopHeader(title: 'Calendar'),
            if (isFromCache) const OfflineBanner(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(calendarControllerProvider.notifier).refresh(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                  children: [
                    // Title & Week | Month Segmented Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Calendar',
                              style: textTheme.headlineMedium?.copyWith(
                                fontSize: 22,
                                height: 28 / 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Academic schedule & deadlines',
                              style: textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ViewSegmentChip(
                                label: 'Week',
                                selected: viewState.isWeekMode,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  ref
                                      .read(calendarViewProvider.notifier)
                                      .setWeekMode(true);
                                },
                              ),
                              _ViewSegmentChip(
                                label: 'Month',
                                selected: !viewState.isWeekMode,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  ref
                                      .read(calendarViewProvider.notifier)
                                      .setWeekMode(false);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Month Navigation Bar + "Today" Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                        border: Border.all(color: AppColors.border, width: 1),
                        boxShadow: AppShadows.card,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                DateFormat('MMMM yyyy').format(focusedDay),
                                style: textTheme.titleSmall?.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => ref
                                    .read(calendarViewProvider.notifier)
                                    .jumpToToday(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    'Today',
                                    style: textTheme.labelSmall?.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              InkWell(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                onTap: () {
                                  final step = viewState.isWeekMode
                                      ? selectedDay
                                          .subtract(const Duration(days: 7))
                                      : DateTime(
                                          focusedDay.year,
                                          focusedDay.month - 1,
                                          1,
                                        );
                                  ref
                                      .read(calendarViewProvider.notifier)
                                      .selectDay(step, step);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    LucideIcons.chevronLeft,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                onTap: () {
                                  final step = viewState.isWeekMode
                                      ? selectedDay.add(const Duration(days: 7))
                                      : DateTime(
                                          focusedDay.year,
                                          focusedDay.month + 1,
                                          1,
                                        );
                                  ref
                                      .read(calendarViewProvider.notifier)
                                      .selectDay(step, step);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    LucideIcons.chevronRight,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Calendar Header Widget (Week Strip or Month TableCalendar)
                    if (viewState.isWeekMode)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                          border: Border.all(color: AppColors.border, width: 1),
                          boxShadow: AppShadows.card,
                        ),
                        child: Row(
                          children: List.generate(7, (index) {
                            final day = mondayOfSelectedWeek.add(
                              Duration(days: index),
                            );
                            final selected = isSameDay(day, selectedDay);
                            final dots = _dotsForDay(snapshot, day);

                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  ref
                                      .read(calendarViewProvider.notifier)
                                      .selectDay(day, day);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  curve: Curves.easeOutCubic,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: selected ? AppShadows.activeChip : null,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        DateFormat('EEE').format(day),
                                        style: textTheme.labelSmall?.copyWith(
                                          fontSize: 11,
                                          color: selected
                                              ? Colors.white
                                                  .withValues(alpha: 0.85)
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${day.day}',
                                        style: textTheme.titleSmall?.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: selected
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: dots.isEmpty
                                            ? [
                                                const SizedBox(
                                                  width: 6,
                                                  height: 6,
                                                ),
                                              ]
                                            : dots
                                                .map(
                                                  (c) => Container(
                                                    width: 6,
                                                    height: 6,
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 1.5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: selected
                                                          ? Colors.white
                                                          : c,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TableCalendar<Color>(
                          firstDay: DateTime.utc(2024, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: focusedDay,
                          headerVisible: false,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          selectedDayPredicate: (d) => isSameDay(d, selectedDay),
                          eventLoader: (d) => _dotsForDay(snapshot, d),
                          onDaySelected: (sel, foc) => ref
                              .read(calendarViewProvider.notifier)
                              .selectDay(sel, foc),
                          onPageChanged: (foc) => ref
                              .read(calendarViewProvider.notifier)
                              .setFocusedDay(foc),
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            todayTextStyle: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, date, markers) {
                              if (markers.isEmpty) return null;
                              return Positioned(
                                bottom: 4,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: markers
                                      .map(
                                        (color) => Container(
                                          width: 5,
                                          height: 5,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Selected Day Schedule Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isSameDay(selectedDay, DateTime.now())
                              ? "Today's Schedule"
                              : DateFormat('EEEE, d MMM').format(selectedDay),
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${entries.length} ${entries.length == 1 ? 'Item' : 'Items'}',
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (agendaAsync.isLoading && snapshot == null)
                      const TaskListShimmer(itemCount: 3)
                    else if (agendaAsync.hasError && snapshot == null)
                      ErrorStateCard(
                        message: agendaAsync.error is ApiException
                            ? (agendaAsync.error as ApiException).message
                            : 'Could not load calendar agenda.',
                        onRetry: () => ref
                            .read(calendarControllerProvider.notifier)
                            .refresh(),
                      )
                    else if (entries.isEmpty)
                      AppEmptyState(
                        icon: LucideIcons.calendar,
                        title: 'No schedule on this day',
                        subtitle:
                            'Add a lecture, study group, or deadline to stay organized.',
                        actionLabel: '+ Add Event',
                        onAction: () async {
                          await EventFormSheet.show(
                            context,
                            initialDate: selectedDay,
                          );
                        },
                      )
                    else
                      ...entries.map((entry) {
                        if (entry.isEvent) {
                          final ev = entry.event!;
                          final mins = ev.duration.inMinutes;
                          final durationLabel = mins >= 60
                              ? '${(mins / 60).toStringAsFixed(mins % 60 == 0 ? 0 : 1)} hrs'
                              : '$mins mins';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TimelineEventRow(
                              timeLabel:
                                  LocalDateTimeHelper.formatTime12(ev.startsAt),
                              periodLabel: _periodLabel(ev.startsAt),
                              title: ev.title,
                              metaLeft:
                                  '${ev.formattedTimeRange} ($durationLabel)',
                              metaRight: ev.location,
                              metaRightIcon: LucideIcons.mapPin,
                              badgeIcon: LucideIcons.calendar,
                              cardBg: AppColors.violetPastel,
                              accentColor: AppColors.violet,
                              onTap: () async {
                                await EventFormSheet.show(
                                  context,
                                  existingEvent: ev,
                                );
                              },
                            ),
                          );
                        } else {
                          final task = entry.task!;
                          final isOverdue = task.isOverdue();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TimelineEventRow(
                              timeLabel: LocalDateTimeHelper.formatTime12(
                                entry.timestamp,
                              ),
                              periodLabel: _periodLabel(entry.timestamp),
                              title: task.title,
                              metaLeft: task.isDone
                                  ? 'Completed'
                                  : (isOverdue
                                      ? 'Overdue · ${task.priority.label}'
                                      : 'Task Deadline · ${task.priority.label}'),
                              isUrgentMeta: isOverdue,
                              badgeIcon: task.isDone
                                  ? LucideIcons.circleCheck
                                  : LucideIcons.fileText,
                              cardBg: isOverdue
                                  ? AppColors.errorPastel
                                  : AppColors.orangePastel,
                              accentColor: isOverdue
                                  ? AppColors.error
                                  : AppColors.orange,
                              onTap: () async {
                                await TaskFormSheet.show(
                                  context,
                                  initialTask: task,
                                );
                              },
                            ),
                          );
                        }
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewSegmentChip extends StatelessWidget {
  const _ViewSegmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
        ),
      ),
    );
  }
}

class _TimelineEventRow extends StatelessWidget {
  const _TimelineEventRow({
    required this.timeLabel,
    required this.periodLabel,
    required this.title,
    required this.metaLeft,
    this.metaRight,
    this.metaRightIcon,
    required this.badgeIcon,
    required this.cardBg,
    required this.accentColor,
    this.isUrgentMeta = false,
    this.onTap,
  });

  final String timeLabel;
  final String periodLabel;
  final String title;
  final String metaLeft;
  final String? metaRight;
  final IconData? metaRightIcon;
  final IconData badgeIcon;
  final Color cardBg;
  final Color accentColor;
  final bool isUrgentMeta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RepaintBoundary(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeLabel,
                    style: textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    periodLabel,
                    style: textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        color: accentColor,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.titleSmall?.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          isUrgentMeta
                                              ? LucideIcons.circleAlert
                                              : LucideIcons.clock,
                                          size: 13,
                                          color: accentColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            metaLeft,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                textTheme.labelSmall?.copyWith(
                                              fontSize: 11,
                                              color: isUrgentMeta
                                                  ? accentColor
                                                  : AppColors.textSecondary,
                                              fontWeight: isUrgentMeta
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (metaRight != null &&
                                            metaRight!.trim().isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            '•',
                                            style: TextStyle(
                                              color: AppColors.textSecondary
                                                  .withValues(alpha: 0.4),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            metaRightIcon ?? LucideIcons.mapPin,
                                            size: 13,
                                            color: accentColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              metaRight!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  badgeIcon,
                                  size: 15,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

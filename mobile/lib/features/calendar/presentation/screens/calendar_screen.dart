import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/lifeos_top_header.dart';
import '../../../tasks/presentation/widgets/task_form_sheet.dart';

/// S-07 Calendar Screen — matches Google Stitch `Calendar` (`a2a743ddaa98449ab1b9b428c68a4f9c`).
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _isWeekView = true;
  int _selectedDayIndex = 2; // Wed 23 active by default

  static const _weekDays = [
    ('Mon', '21', AppColors.pink),
    ('Tue', '22', AppColors.sky),
    ('Wed', '23', AppColors.primary),
    ('Thu', '24', AppColors.orange),
    ('Fri', '25', AppColors.success),
    ('Sat', '26', null),
    ('Sun', '27', null),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Column(
          children: [
            const LifeOsTopHeader(title: 'Calendar'),
            Expanded(
              child: ListView(
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
                              selected: _isWeekView,
                              onTap: () => setState(() => _isWeekView = true),
                            ),
                            _ViewSegmentChip(
                              label: 'Month',
                              selected: !_isWeekView,
                              onTap: () => setState(() => _isWeekView = false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Month Navigation Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A5B5BF6),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'October 2026',
                              style: textTheme.titleSmall?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x99E1DFFF),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                'Today',
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF413EDC),
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
                              onTap: () {},
                              child: const Padding(
                                padding: EdgeInsets.all(4),
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
                              onTap: () {},
                              child: const Padding(
                                padding: EdgeInsets.all(4),
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
                  // Week Strip: 7 Day Columns
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D5B5BF6),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: List.generate(_weekDays.length, (index) {
                        final (dayName, dayNumber, dotColor) = _weekDays[index];
                        final selected = _selectedDayIndex == index;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedDayIndex = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: selected
                                    ? const [
                                        BoxShadow(
                                          color: Color(0x525B5BF6),
                                          blurRadius: 16,
                                          offset: Offset(0, 6),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    dayName,
                                    style: textTheme.labelSmall?.copyWith(
                                      fontSize: 11,
                                      color: selected
                                          ? Colors.white.withValues(alpha: 0.85)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dayNumber,
                                    style: textTheme.titleSmall?.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? Colors.white
                                          : (dotColor ?? Colors.transparent),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Today's Schedule Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Schedule",
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '4 Events',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF413EDC),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _TimelineEventRow(
                    timeLabel: '09:00 AM',
                    periodLabel: 'Morning',
                    title: 'Kuliah Kecerdasan Buatan',
                    metaLeft: '1.5 hrs',
                    metaRight: 'Lab Komputer 3',
                    metaRightIcon: LucideIcons.mapPin,
                    badgeIcon: LucideIcons.graduationCap,
                    cardBg: AppColors.violetPastel,
                    accentColor: AppColors.violet,
                  ),
                  const SizedBox(height: 12),
                  const _TimelineEventRow(
                    timeLabel: '11:00 AM',
                    periodLabel: 'Midday',
                    title: 'Rapat BEM Fakultas Teknik',
                    metaLeft: '1 hr',
                    metaRight: 'Ruang Sidang',
                    metaRightIcon: LucideIcons.doorOpen,
                    badgeIcon: LucideIcons.users,
                    cardBg: AppColors.pinkPastel,
                    accentColor: AppColors.pink,
                  ),
                  const SizedBox(height: 12),
                  const _TimelineEventRow(
                    timeLabel: '01:30 PM',
                    periodLabel: 'Afternoon',
                    title: 'Deadline Review Paper IEEE',
                    metaLeft: 'Due today at 11:59 PM',
                    isUrgentMeta: true,
                    badgeIcon: LucideIcons.fileText,
                    cardBg: AppColors.orangePastel,
                    accentColor: AppColors.orange,
                  ),
                  const SizedBox(height: 12),
                  const _TimelineEventRow(
                    timeLabel: '03:00 PM',
                    periodLabel: 'Afternoon',
                    title: 'Study Group Algoritma Pemrograman',
                    metaLeft: '2 hrs',
                    metaRight: 'Perpustakaan Lt. 2',
                    metaRightIcon: LucideIcons.bookOpen,
                    badgeIcon: LucideIcons.code,
                    cardBg: AppColors.skyPastel,
                    accentColor: AppColors.sky,
                  ),
                  const SizedBox(height: 20),
                  // Bottom "+ Add Event" CTA Pill Button
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x595B5BF6),
                          blurRadius: 20,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      onPressed: () => TaskFormSheet.show(context),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.plus, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Add Event',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
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
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
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
                                        style: textTheme.labelSmall?.copyWith(
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
                                    if (metaRight != null) ...[
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
                                          style: textTheme.labelSmall?.copyWith(
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
      ],
    );
  }
}

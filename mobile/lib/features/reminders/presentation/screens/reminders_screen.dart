import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/notifications/local_notification_service.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/error_state_card.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../domain/reminder.dart';
import '../reminders_controller.dart';
import '../widgets/reminder_form_sheet.dart';

/// Scheduled reminder management screen reached from the header bell and the
/// S-10 "Reminders & Alerts" row (`03-technical-spec.md` §4.5, §3.2).
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  ReminderStatus? _filter = ReminderStatus.scheduled;

  Future<void> _editTime(Reminder reminder) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: reminder.remindAt.isAfter(now) ? reminder.remindAt : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: reminder.remindAt.isAfter(now)
          ? TimeOfDay.fromDateTime(reminder.remindAt)
          : TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;

    final remindAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!remindAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih waktu di masa depan.')),
      );
      return;
    }

    try {
      final result = await ref
          .read(remindersControllerProvider.notifier)
          .updateTime(
            reminder,
            remindAt: remindAt,
            title: reminder.targetTitle,
            body: reminder.isTaskReminder
                ? 'Task deadline is approaching'
                : 'Your event is coming up',
          );
      if (!mounted) return;
      if (!result.permissionGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izin notifikasi nonaktif. Aktifkan di Pengaturan Android.',
            ),
          ),
        );
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _cancel(Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan pengingat?'),
        content: Text('Pengingat untuk "${reminder.targetTitle}" akan dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Kembali'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(remindersControllerProvider.notifier)
          .cancelReminder(reminder);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _delete(Reminder reminder) async {
    try {
      await ref
          .read(remindersControllerProvider.notifier)
          .deleteReminder(reminder);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Color _statusColor(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.scheduled:
        return AppColors.primary;
      case ReminderStatus.sent:
        return AppColors.success;
      case ReminderStatus.failed:
        return AppColors.error;
      case ReminderStatus.cancelled:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final asyncValue = ref.watch(remindersControllerProvider);
    final snapshot = asyncValue.value;
    final permission = ref.watch(notificationPermissionProvider);
    final allItems = snapshot?.items ?? const <Reminder>[];
    final items = _filter == null
        ? allItems
        : allItems.where((item) => item.status == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        LucideIcons.chevronLeft,
                        size: 22,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reminders',
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${snapshot?.scheduledCount ?? 0} scheduled',
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => ReminderFormSheet.show(context),
                      tooltip: 'Tambah Pengingat',
                      icon: const Icon(
                        LucideIcons.plus,
                        size: 21,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(remindersControllerProvider.notifier)
                          .refresh(),
                      tooltip: 'Refresh',
                      icon: const Icon(
                        LucideIcons.refreshCw,
                        size: 19,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (snapshot?.isFromCache ?? false) const OfflineBanner(),
            if (permission.value == false)
              _PermissionBanner(
                onEnable: () async {
                  final granted = await ref
                      .read(localNotificationServiceProvider)
                      .requestPermissions();
                  ref.invalidate(notificationPermissionProvider);
                  if (!granted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Izin ditolak. Buka Pengaturan Android → Apps → '
                          'LifeOS → Notifications untuk mengaktifkan.',
                        ),
                      ),
                    );
                  }
                },
              ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: 'Scheduled',
                    selected: _filter == ReminderStatus.scheduled,
                    onTap: () =>
                        setState(() => _filter = ReminderStatus.scheduled),
                  ),
                  _FilterChip(
                    label: 'Sent',
                    selected: _filter == ReminderStatus.sent,
                    onTap: () => setState(() => _filter = ReminderStatus.sent),
                  ),
                  _FilterChip(
                    label: 'Failed',
                    selected: _filter == ReminderStatus.failed,
                    onTap: () => setState(() => _filter = ReminderStatus.failed),
                  ),
                  _FilterChip(
                    label: 'Cancelled',
                    selected: _filter == ReminderStatus.cancelled,
                    onTap: () =>
                        setState(() => _filter = ReminderStatus.cancelled),
                  ),
                  _FilterChip(
                    label: 'All',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(remindersControllerProvider.notifier).refresh(),
                child: Builder(
                  builder: (context) {
                    if (asyncValue.isLoading && snapshot == null) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: TaskListShimmer(itemCount: 5),
                      );
                    }
                    if (asyncValue.hasError && snapshot == null) {
                      final error = asyncValue.error;
                      return ErrorStateCard(
                        message: error is ApiException
                            ? error.message
                            : 'Gagal memuat pengingat.',
                        onRetry: () => ref
                            .read(remindersControllerProvider.notifier)
                            .refresh(),
                      );
                    }
                    if (items.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          const AppEmptyState(
                            icon: LucideIcons.bellOff,
                            title: 'Belum ada pengingat',
                            subtitle:
                                'Buat pengingat untuk tugas atau kegiatan '
                                'agar notifikasi lokal muncul tepat waktu.',
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () => ReminderFormSheet.show(context),
                              icon: const Icon(LucideIcons.plus, size: 18),
                              label: const Text('Tambah Pengingat Baru'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(200, 48),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final reminder = items[index];
                        return _ReminderCard(
                          reminder: reminder,
                          statusColor: _statusColor(reminder.status),
                          onEditTime: reminder.isScheduled
                              ? () => _editTime(reminder)
                              : null,
                          onCancel: reminder.isScheduled
                              ? () => _cancel(reminder)
                              : null,
                          onDelete: reminder.isScheduled
                              ? null
                              : () => _delete(reminder),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add_reminder_fab'),
        onPressed: () => ReminderFormSheet.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: const Text(
          'Tambah Pengingat',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.onEnable});

  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningPastel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.bellOff, size: 18, color: AppColors.warning),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Izin notifikasi nonaktif. Pengingat tidak akan muncul.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: onEnable,
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.statusColor,
    this.onEditTime,
    this.onCancel,
    this.onDelete,
  });

  final Reminder reminder;
  final Color statusColor;
  final VoidCallback? onEditTime;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: reminder.isTaskReminder
                  ? AppColors.primarySoft
                  : AppColors.violetPastel,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              reminder.isTaskReminder
                  ? LucideIcons.squareCheckBig
                  : LucideIcons.calendar,
              size: 19,
              color: reminder.isTaskReminder
                  ? AppColors.primary
                  : AppColors.violet,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.targetTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('EEE, d MMM yyyy · HH:mm')
                      .format(reminder.remindAt),
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        reminder.status.label,
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (onEditTime != null)
                      IconButton(
                        onPressed: onEditTime,
                        tooltip: 'Ubah waktu',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          LucideIcons.pencil,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (onCancel != null)
                      IconButton(
                        onPressed: onCancel,
                        tooltip: 'Batalkan',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          LucideIcons.bellOff,
                          size: 16,
                          color: AppColors.warning,
                        ),
                      ),
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        tooltip: 'Hapus',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          LucideIcons.trash2,
                          size: 16,
                          color: AppColors.error,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

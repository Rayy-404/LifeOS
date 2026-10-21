import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/auth_controller.dart';
import 'reminders_controller.dart';

/// Wraps the app and reconciles Android local notifications after a cold start
/// and every time the app returns to the foreground
/// (`03-technical-spec.md` §3.2 item 5 & `04-architecture-security-testing.md` §12.3).
class ReminderSyncGate extends ConsumerStatefulWidget {
  const ReminderSyncGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ReminderSyncGate> createState() => _ReminderSyncGateState();
}

class _ReminderSyncGateState extends ConsumerState<ReminderSyncGate>
    with WidgetsBindingObserver {
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIfAuthenticated());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncIfAuthenticated();
    }
  }

  Future<void> _syncIfAuthenticated() async {
    if (!mounted || _syncing) return;
    if (ref.read(authControllerProvider).status != AuthStatus.authenticated) {
      return;
    }

    _syncing = true;
    try {
      await ref
          .read(remindersControllerProvider.notifier)
          .syncPendingReminders();
    } catch (error) {
      // Reconciliation must never block the UI; the next resume retries.
      if (kDebugMode) {
        debugPrint('Reminder reconciliation failed: $error');
      }
    } finally {
      _syncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated &&
          previous?.status != AuthStatus.authenticated) {
        _syncIfAuthenticated();
      }
    });
    return widget.child;
  }
}

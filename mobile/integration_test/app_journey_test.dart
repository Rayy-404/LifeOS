import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lifeos_mobile/main.dart' as app;

/// Critical user journey Android (`04-architecture-security-testing.md` §14.1
/// item 4 & §14.2, `planning/06` Playbook 3).
///
/// Prasyarat eksekusi:
/// - Backend berjalan di port 3000. Untuk emulator gunakan
///   `adb reverse tcp:3000 tcp:3000`, lalu jalankan dengan
///   `--dart-define=API_BASE_URL=http://localhost:3000/api/v1`.
/// - Izin notifikasi sudah di-grant (`adb shell pm grant
///   com.lifeos.lifeos_mobile android.permission.POST_NOTIFICATIONS`) agar
///   dialog izin Android tidak memblokir alur.
/// - Instalasi baru (onboarding tampil satu kali).
///
/// Skenario yang TIDAK bisa diverifikasi andal di CI tanpa perangkat fisik
/// dijelaskan di README bagian "Keterbatasan Verifikasi Manual".
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'journey: register -> buat tugas -> tandai selesai -> reminders -> logout',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // 1. Onboarding (hanya pada instalasi baru).
      final onboardingButton =
          find.byKey(const ValueKey('onboarding_get_started'));
      if (onboardingButton.evaluate().isNotEmpty) {
        await tester.tap(onboardingButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // 2. Registrasi akun baru.
      await tester.tap(find.textContaining('Create an account'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final email =
          'journey-${DateTime.now().millisecondsSinceEpoch}@example.com';
      await tester.enterText(
        find.byKey(const ValueKey('register_name')),
        'Journey Tester',
      );
      await tester.enterText(
        find.byKey(const ValueKey('register_email')),
        email,
      );
      await tester.enterText(
        find.byKey(const ValueKey('register_password')),
        'sup3r-secret-password',
      );
      await tester.tap(find.byKey(const ValueKey('register_submit')));
      await tester.pumpAndSettle(const Duration(seconds: 8));

      expect(find.text('LIFEOS ACADEMICS'), findsOneWidget);

      // 3. Buat tugas lewat FAB tengah.
      await tester.tap(find.byKey(const ValueKey('nav_add_task_fab')));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await tester.enterText(
        find.byKey(const ValueKey('task_form_title')),
        'Tugas dari integration test',
      );
      await tester.tap(find.byKey(const ValueKey('task_form_save')));
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // 4. Tandai tugas selesai dari dashboard.
      final taskCheckbox = find.byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> &&
            key.value.startsWith('task_checkbox_');
      });
      await tester.tap(taskCheckbox.first);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 5. Buka daftar pengingat lewat lonceng di header.
      await tester.tap(find.byKey(const ValueKey('header_bell')));
      await tester.pumpAndSettle(const Duration(seconds: 4));
      expect(find.text('Reminders'), findsOneWidget);

      // 6. Kembali dan logout melalui S-10.
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.byKey(const ValueKey('header_avatar')));
      await tester.pumpAndSettle(const Duration(seconds: 4));
      await tester.tap(find.byKey(const ValueKey('profile_logout')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byKey(const ValueKey('login_submit')), findsOneWidget);
    },
  );
}

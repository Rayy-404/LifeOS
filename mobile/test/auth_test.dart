import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_mobile/core/storage/local_cache_service.dart';
import 'package:lifeos_mobile/features/auth/domain/user.dart';
import 'package:lifeos_mobile/features/auth/presentation/onboarding_seen_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingSeenController', () {
    test('default false, lalu persist true setelah markSeen', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(onboardingSeenProvider), isFalse);

      await container.read(onboardingSeenProvider.notifier).markSeen();

      expect(container.read(onboardingSeenProvider), isTrue);
      expect(prefs.getBool(kOnboardingSeenPrefsKey), isTrue);
    });

    test('membaca flag true yang sudah tersimpan', () async {
      SharedPreferences.setMockInitialValues({
        kOnboardingSeenPrefsKey: true,
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(onboardingSeenProvider), isTrue);
    });
  });

  group('User model', () {
    test('fromJson/toJson round-trip dengan default timezone', () {
      final user = User.fromJson(const {
        'id': 'user-1',
        'name': 'Rayhan',
        'email': 'rayhan@example.com',
      });

      expect(user.timezone, 'Asia/Jakarta');
      expect(user.toJson(), {
        'id': 'user-1',
        'name': 'Rayhan',
        'email': 'rayhan@example.com',
        'timezone': 'Asia/Jakarta',
      });
    });
  });
}

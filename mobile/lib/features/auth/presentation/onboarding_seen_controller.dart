import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_cache_service.dart';

const String kOnboardingSeenPrefsKey = 'lifeos_onboarding_seen';

final onboardingSeenProvider =
    NotifierProvider<OnboardingSeenController, bool>(
  OnboardingSeenController.new,
);

/// Tracks whether the first-run onboarding screen (S-01) has been shown.
class OnboardingSeenController extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(kOnboardingSeenPrefsKey) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(kOnboardingSeenPrefsKey, true);
    state = true;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_mobile/features/auth/presentation/screens/login_screen.dart';

Future<void> _pumpLoginScreen(WidgetTester tester) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: const LoginScreen()),
    ),
  );
}

void main() {
  group('LoginScreen — validasi form (S-02)', () {
    testWidgets('menampilkan error saat submit dengan field kosong', (
      tester,
    ) async {
      await _pumpLoginScreen(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.pump();

      expect(find.text('Email wajib diisi'), findsOneWidget);
      expect(find.text('Password wajib diisi'), findsOneWidget);
    });

    testWidgets('menampilkan error format email yang tidak valid', (
      tester,
    ) async {
      await _pumpLoginScreen(tester);

      await tester.enterText(find.byType(TextField).at(0), 'bukan-email');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.pump();

      expect(find.text('Format email tidak valid'), findsOneWidget);
      expect(find.text('Password wajib diisi'), findsNothing);
    });

    testWidgets('menampilkan error saat password kurang dari 8 karakter', (
      tester,
    ) async {
      await _pumpLoginScreen(tester);

      await tester.enterText(find.byType(TextField).at(0), 'rayhan@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'short');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.pump();

      expect(find.text('Password minimal 8 karakter'), findsOneWidget);
    });
  });
}

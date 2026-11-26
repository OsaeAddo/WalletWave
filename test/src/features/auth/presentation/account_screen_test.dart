import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_wave/src/features/auth/presentation/account_screen.dart';

void main() {
  testWidgets('explains how to enable sync instead of showing an error', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: AccountScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cloud sync is off in this build.'), findsOneWidget);
    expect(find.textContaining('bash tool/flutter-env.sh'), findsOneWidget);
    expect(
      find.textContaining('--dart-define-from-file=.env.flutter'),
      findsOneWidget,
    );

    // The form stays visibly disabled, and signing in cannot be attempted.
    final emailField = tester.widget<TextField>(find.byType(TextField).first);
    expect(emailField.enabled, isFalse);
    final signInButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(signInButton.onPressed, isNull);
  });
}

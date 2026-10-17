import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_design/main.dart';

void main() {
  testWidgets('MGA app startup smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FlashAnzanApp());

    expect(find.byType(FlashAnzanApp), findsOneWidget);

    // Allow the Splash Screen's 5-second timer to finish.
    await tester.pump(const Duration(seconds: 6));

    // Dispose the app tree so no app timer remains active.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
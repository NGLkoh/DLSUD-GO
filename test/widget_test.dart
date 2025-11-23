// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dlsud_go/main.dart';

void main() {
  testWidgets('App starts with splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DLSUGoApp());

    // Verify that the splash screen appears
    expect(find.text('DLSU-D Go!'), findsOneWidget);
    expect(find.text('Your Smart Campus Navigator'), findsOneWidget);
  });

  testWidgets('App shows loading indicator on splash', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DLSUGoApp());

    // Verify that loading indicator is present
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
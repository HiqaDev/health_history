// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_history/main.dart';
import 'package:health_history/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Supabase so any services used by widgets can access the client
    try {
      // Install mock SharedPreferences handler for tests (avoids MissingPluginException)
      SharedPreferences.setMockInitialValues({});
      await SupabaseService.initialize();
    } catch (_) {
      // Allow tests to proceed even if remote init fails; UI should still build
    }
  });

  testWidgets('App boots and shows a MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    // Sanity check: the root MaterialApp renders
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

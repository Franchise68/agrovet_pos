// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrovet_pos/main.dart';

void main() {
  testWidgets('Dashboard loads and shows cards', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardPage()));
    // Check for dashboard cards
    expect(find.text('Total Products'), findsOneWidget);
    expect(find.text("Today's Sales"), findsOneWidget);
    expect(find.text('Low Stock'), findsOneWidget);
  });
}


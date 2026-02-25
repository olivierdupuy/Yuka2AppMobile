import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuka2_app/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const Yuka2App());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

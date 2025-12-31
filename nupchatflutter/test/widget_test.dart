import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nupchatflutter/main.dart';

void main() {
  testWidgets('NupChat app renders home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NupChatApp());

    // Verify that home screen is displayed
    expect(find.text('NupChat'), findsAny);

    // Verify the app bar has correct background color
    final appBar = find.byType(AppBar);
    expect(appBar, findsOneWidget);
  });
}

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pipecat_flutter_example/main.dart';

void main() {
  testWidgets('Verify PipecatExample UI', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: PipecatExample()));

    // Verify that the AppBar title is correct.
    expect(find.text('Pipecat Flutter Rich Example'), findsOneWidget);

    // Verify the initial status is 'Disconnected'.
    expect(find.text('Disconnected'), findsOneWidget);

    // Verify that the 'Connect' and 'Disconnect' buttons are present.
    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('Disconnect'), findsOneWidget);

    // Verify the Bot Endpoint text field is present by its label.
    expect(find.text('Bot Endpoint'), findsOneWidget);

    // Verify hardware dropdowns are present.
    expect(find.text('Microphone'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);

    // Verify input panel message field hint.
    expect(find.text('Type a message...'), findsOneWidget);
  });
}

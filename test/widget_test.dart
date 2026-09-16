import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Ascend App basic widget smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Ascend Focus')),
        ),
      ),
    );

    expect(find.text('Ascend Focus'), findsOneWidget);
  });
}

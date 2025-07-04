import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reusemart_mobile/main.dart'; // ini mengarah ke ReuseMartApp()

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ReuseMartApp());

    // Tes lainnya boleh dihapus jika tidak dibutuhkan
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

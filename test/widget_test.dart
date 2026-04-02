import 'package:flutter_test/flutter_test.dart';

import 'package:untitled2/main.dart'; // تأكد من أن اسم الحزمة يطابق اسم مشروعك

void main() {
  testWidgets('Splash Screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TrendyApp());

    // Verify that our application title 'Trendy' is displayed.
    expect(find.text('Trendy'), findsOneWidget);

    // Verify that the slogan text is displayed.
    expect(find.text('الموضة في متناول يدك'), findsOneWidget);
  });
}

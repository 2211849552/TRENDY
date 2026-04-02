import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/main.dart'; 

void main() {
  testWidgets('Splash Screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MatajariApp());

    // Verify that our application title 'متجري' is displayed.
    expect(find.text('متجري'), findsOneWidget);
  });
}

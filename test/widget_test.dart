import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/main.dart'; 

void main() {
  testWidgets('Splash Screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AppRoot());
    expect(find.text('Trendy'), findsOneWidget);
  });
}

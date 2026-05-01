import 'package:flutter_test/flutter_test.dart';
import 'package:waste_logistics/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Waste Logistics'), findsOneWidget);
  });
}

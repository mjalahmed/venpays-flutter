import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('example app loads checkout demo', (tester) async {
    await tester.pumpWidget(const VenPaysExampleApp());
    expect(find.text('VenPays Card Checkout'), findsOneWidget);
    expect(find.text('Pay with card'), findsOneWidget);
  });
}

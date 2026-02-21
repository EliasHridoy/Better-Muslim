import 'package:flutter_test/flutter_test.dart';
import 'package:better_muslim/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const BetterMuslimApp());
    // Verify the app title or greeting renders
    expect(find.text('Assalamu Alaikum ☪'), findsOneWidget);
  });
}

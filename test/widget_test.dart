import 'package:flutter_test/flutter_test.dart';
import 'package:tickflow/main.dart';

void main() {
  testWidgets('TickFlowApp builds cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(const TickFlowApp());
    expect(find.byType(TickFlowApp), findsOneWidget);
  });
}

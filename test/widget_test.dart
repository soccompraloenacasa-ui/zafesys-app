import 'package:flutter_test/flutter_test.dart';
import 'package:zafesys_tecnico/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ZafesysApp());
    await tester.pumpAndSettle();

    // Verify the app title is displayed
    expect(find.text('ZAFESYS'), findsOneWidget);
    expect(find.text('App para Tecnicos'), findsOneWidget);
  });
}

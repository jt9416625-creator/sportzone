
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_app_movil/main.dart';

void main() {
  testWidgets('SportZone inicia correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const SportZoneApp());

    expect(find.text('SportZone'), findsOneWidget);
  });
}

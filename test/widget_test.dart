import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nail_pos/main.dart';

void main() {
  testWidgets('App boots and shows login branding', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: NailPOSApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('TPOS'), findsOneWidget);
    expect(find.text('Nail Salon Management'), findsOneWidget);
  });
}

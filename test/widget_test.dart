import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clipper/main.dart';

void main() {
  testWidgets('ClipperApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ClipperApp(),
      ),
    );

    // Verify app title displays in the header
    expect(find.text('Clipper'), findsOneWidget);
    expect(find.text('All History'), findsOneWidget);
  });
}

// WardSense Widget Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wardsense/main.dart';

void main() {
  testWidgets('WardSense app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: WardSenseApp(),
      ),
    );

    // Verify that the app loads with the WardSense title.
    expect(find.text('WardSense'), findsOneWidget);
  });
}

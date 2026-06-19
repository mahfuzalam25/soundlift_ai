import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundlift_ai/main.dart';

void main() {
  testWidgets('Verify app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: SoundLiftApp()));

    // Verify that the app widget is mounted
    expect(find.byType(SoundLiftApp), findsOneWidget);
  });
}

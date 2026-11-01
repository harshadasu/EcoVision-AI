import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecovision_ai/main.dart';
import 'package:ecovision_ai/providers/app_state.dart';

void main() {
  testWidgets('EcoVision AI smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
        ],
        child: const EcoVisionApp(),
      ),
    );

    // Initial splash frame
    expect(find.text('EcoVision AI'), findsOneWidget);

    // Let splash screen timer elapse and navigate to onboarding
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify Onboarding Screen
    expect(find.textContaining('Green\nLiving Guide'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}

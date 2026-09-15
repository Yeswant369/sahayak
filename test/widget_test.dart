import 'package:flutter_test/flutter_test.dart';
import 'package:sahayak/app_state.dart';
import 'package:sahayak/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App boots to home screen with demo engine',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await appState.load();
    await tester.pumpWidget(const SahayakApp());

    expect(find.text('Sahayak'), findsOneWidget);
    expect(find.text('Medicine Lens'), findsOneWidget);
    expect(find.text('Voice Triage'), findsOneWidget);
  });
}

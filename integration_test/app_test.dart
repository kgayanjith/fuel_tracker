import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fuel_tracker/firebase_options.dart';
import 'package:fuel_tracker/screens/home.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  testWidgets(
    'Home screen loads and switching between Runtime and Fuel tabs works',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Runtime'), findsOneWidget);
      expect(find.text('Fuel'), findsOneWidget);
      expect(find.text('Select Date'), findsOneWidget);
      expect(find.text('Select Generator'), findsOneWidget);
      expect(find.text('Select Running Time'), findsOneWidget);

      await tester.tap(find.text('Fuel'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Liters Added'), findsOneWidget);
      expect(find.text('Rate Rs.'), findsOneWidget);

      await tester.tap(find.text('Runtime'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Select Running Time'), findsOneWidget);
    },
  );
}

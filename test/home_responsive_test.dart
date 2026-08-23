import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safecircle/providers/auth_provider.dart';
import 'package:safecircle/providers/home_provider.dart';
import 'package:safecircle/screens/home/home_screen.dart';

void main() {
  Widget buildTestableWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
      ],
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  testWidgets('HomeScreen renders on standard screen size (390x844) without crash', (WidgetTester tester) async {
    // Set typical iPhone 12/13/14 size
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Verify key UI text elements are present
    expect(find.text("Today's Summary"), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
  });

  testWidgets('HomeScreen renders on very narrow screen size (320x568) without crash', (WidgetTester tester) async {
    // Set typical iPhone SE or small Android screen size
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Verify key UI text elements are present
    expect(find.text("Today's Summary"), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safecircle/core/constants/app_colors.dart';

Widget buildDialogTestWidget({double textScale = 1.0, VoidCallback? onNeedHelp, VoidCallback? onSafe}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1F000000),
                                  blurRadius: 24,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: AppColors.warningOrange,
                                          size: 32,
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            "You're running late.",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    const Text(
                                      'Everything okay?',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'SafeCircle has detected your delay. Let your circle know you are safe or trigger emergency help.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.45,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(double.infinity, 48),
                                        side: const BorderSide(color: AppColors.sosRed, width: 1.5),
                                        foregroundColor: AppColors.sosRed,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: onNeedHelp ?? () => Navigator.pop(context),
                                      child: const Text(
                                        'Need Help',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.sosRed,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(double.infinity, 48),
                                        backgroundColor: AppColors.safeGreen,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: onSafe ?? () => Navigator.pop(context),
                                      child: const Text(
                                        "I'm Safe",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Smart Check-in dialog renders without overflow on OnePlus 12R dimensions (412x915)', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildDialogTestWidget());
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Verify all content rendered
    expect(find.text("You're running late."), findsOneWidget);
    expect(find.text('Everything okay?'), findsOneWidget);
    expect(find.text('Need Help'), findsOneWidget);
    expect(find.text("I'm Safe"), findsOneWidget);

    // Verify buttons are tappable
    await tester.tap(find.text("I'm Safe"));
    await tester.pumpAndSettle();
    expect(find.text("You're running late."), findsNothing);
  });

  testWidgets('Smart Check-in dialog renders without overflow on narrow device (320x568)', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildDialogTestWidget());
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Title should wrap nicely without any overflow
    expect(find.text("You're running late."), findsOneWidget);
    expect(find.text('Need Help'), findsOneWidget);
    expect(find.text("I'm Safe"), findsOneWidget);

    await tester.tap(find.text('Need Help'));
    await tester.pumpAndSettle();
    expect(find.text("You're running late."), findsNothing);
  });

  testWidgets('Smart Check-in dialog handles 1.5x large text scale cleanly', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildDialogTestWidget(textScale: 1.5));
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text("You're running late."), findsOneWidget);
    expect(find.text('Everything okay?'), findsOneWidget);
    expect(find.text('Need Help'), findsOneWidget);
    expect(find.text("I'm Safe"), findsOneWidget);
  });
}

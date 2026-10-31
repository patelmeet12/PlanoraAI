import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planora_ai/features/events/presentation/providers/event_providers.dart';
import 'package:planora_ai/features/onboarding/presentation/screens/onboarding_wizard_screen.dart';

void main() {
  testWidgets('OnboardingWizardScreen validates and navigates through wizard steps', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: OnboardingWizardScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial Step 1: Basics & Category
    expect(find.text('Plan Your Next Event'), findsOneWidget);
    expect(find.text('Step 1 of 5 — Basics & Category'), findsOneWidget);
    expect(find.text('Event Name *'), findsOneWidget);

    // Look for continue
    final continueFinder = find.text('Continue');
    expect(continueFinder, findsOneWidget);
    await tester.ensureVisible(continueFinder);
    await tester.tap(continueFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Step 2: Scale & Budget
    expect(find.text('Step 2 of 5 — Scale & Budget'), findsOneWidget);
    expect(find.text('Expected Guest Count *'), findsOneWidget);
    expect(find.text('Total Target Budget *'), findsOneWidget);

    // Verify live calculation estimate is shown
    expect(find.text('Projected Cost per Guest'), findsOneWidget);

    // Navigate to Step 3: Style & Atmosphere
    await tester.ensureVisible(continueFinder);
    await tester.tap(continueFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Step 3 of 5 — Style & Atmosphere'), findsOneWidget);
    expect(find.text('Preferred Theme Concept'), findsOneWidget);

    // Test Back button
    final backFinder = find.text('Back');
    expect(backFinder, findsOneWidget);
    await tester.ensureVisible(backFinder);
    await tester.tap(backFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify returned to Step 2 with state preserved
    expect(find.text('Step 2 of 5 — Scale & Budget'), findsOneWidget);

    // Navigate forward to Step 3
    await tester.ensureVisible(continueFinder);
    await tester.tap(continueFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Step 3 of 5 — Style & Atmosphere'), findsOneWidget);

    // Navigate to Step 4: Dietary & Accessibility
    await tester.ensureVisible(continueFinder);
    await tester.tap(continueFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Step 4 of 5 — Dietary & Accessibility'), findsOneWidget);
    expect(find.text('Inclusivity & Special Requirements'), findsOneWidget);

    // Navigate to Step 5: Review & Generate
    await tester.ensureVisible(continueFinder);
    await tester.tap(continueFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Step 5 of 5 — Review & Generate'), findsOneWidget);
    expect(find.text('Ready to Generate Your Event Plan'), findsOneWidget);

    // Look for Generate Intelligent Plan CTA
    final generateBtn = find.text('Generate Intelligent Plan');
    expect(generateBtn, findsOneWidget);
  });

  testWidgets('OnboardingWizardScreen enforces validation errors on empty or invalid input', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: OnboardingWizardScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Clear event name to trigger validation
    final nameField = find.widgetWithText(TextFormField, 'Summer Gala & Reception');
    await tester.enterText(nameField, '');
    await tester.pump();

    final continueFinder = find.text('Continue');
    await tester.ensureVisible(continueFinder);
    await tester.tap(continueFinder);
    await tester.pump();

    // Should display validation error snackbar and remain on Step 1
    expect(find.text('Please complete event name and city'), findsOneWidget);
    expect(find.text('Step 1 of 5 — Basics & Category'), findsOneWidget);
  });
}

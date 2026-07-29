import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundlift_ai/features/onboarding/onboarding_screen.dart';
import 'package:soundlift_ai/features/splash/splash_screen.dart';

/// Test harness helper to wrap tested screens inside a mock [GoRouter] and [ProviderScope].
Widget createRouterTestApp({
  required Widget child,
  List<GoRoute>? additionalRoutes,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(
        path: '/intro',
        builder: (context, state) =>
            const Scaffold(body: Text('Intro Destination Screen')),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) =>
            const Scaffold(body: Text('Auth Destination Screen')),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) =>
            const Scaffold(body: Text('Dashboard Destination Screen')),
      ),
      ...?additionalRoutes,
    ],
  );

  return ProviderScope(child: MaterialApp.router(routerConfig: router));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashScreen Widget Tests', () {
    testWidgets('Renders SplashScreen elements correctly', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(createRouterTestApp(child: const SplashScreen()));

      // 1. Verify that SplashScreen and its fallback branding text are mounted immediately
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      // 2. FIX: Fast-forward the virtual clock to flush out the pending
      // Animation and Future.delayed timers so the test can exit cleanly without throwing the Timer error.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('Navigates to /intro when no access token is stored', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(createRouterTestApp(child: const SplashScreen()));

      // Pump through fade animation (2s) and splash delay timer (3s)
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verify redirection to /intro screen
      expect(find.text('Intro Destination Screen'), findsOneWidget);
    });
  });

  group('OnboardingScreen Widget Tests', () {
    testWidgets('Renders initial onboarding slide (Slide 1) correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createRouterTestApp(child: const OnboardingScreen()),
      );

      // Verify 1st slide content and action buttons
      expect(find.text("AI Noise Removal"), findsOneWidget);
      expect(
        find.text("Remove unwanted noise from audio and videos."),
        findsOneWidget,
      );
      expect(find.text("Next"), findsOneWidget);
      expect(find.text("Skip"), findsOneWidget);
    });

    testWidgets('Navigates through all 4 onboarding slides to "Get Started"', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createRouterTestApp(child: const OnboardingScreen()),
      );

      // --- Slide 1 -> Slide 2 ---
      await tester.tap(find.text("Next"));
      await tester.pumpAndSettle();
      expect(find.text("Professional Audio Enhancement"), findsOneWidget);
      expect(
        find.text("Transform poor recordings into studio-quality sound."),
        findsOneWidget,
      );

      // --- Slide 2 -> Slide 3 ---
      await tester.tap(find.text("Next"));
      await tester.pumpAndSettle();
      expect(find.text("Video Audio Replacement"), findsOneWidget);
      expect(
        find.text("Mute original audio and add new voice tracks."),
        findsOneWidget,
      );

      // --- Slide 3 -> Slide 4 ---
      await tester.tap(find.text("Next"));
      await tester.pumpAndSettle();
      expect(find.text("Export Anywhere"), findsOneWidget);
      expect(
        find.text("Download and share your enhanced media instantly."),
        findsOneWidget,
      );

      // Verify button label changes on final slide
      expect(find.text("Get Started"), findsOneWidget);

      // Tap "Get Started" and verify navigation to /auth
      await tester.tap(find.text("Get Started"));
      await tester.pumpAndSettle();
      expect(find.text('Auth Destination Screen'), findsOneWidget);
    });

    testWidgets('Tapping "Skip" navigates directly to /auth', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createRouterTestApp(child: const OnboardingScreen()),
      );

      expect(find.text("Skip"), findsOneWidget);
      await tester.tap(find.text("Skip"));
      await tester.pumpAndSettle();

      expect(find.text('Auth Destination Screen'), findsOneWidget);
    });
  });
}

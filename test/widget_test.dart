import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // NEW: Imported dotenv
import 'package:soundlift_ai/features/onboarding/onboarding_screen.dart';
import 'package:soundlift_ai/features/splash/splash_screen.dart';
import 'package:soundlift_ai/features/auth/login_screen.dart';
import 'package:soundlift_ai/features/auth/register_screen.dart';

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
        path: '/auth/verify',
        builder: (context, state) =>
            const Scaffold(body: Text('Verify Destination Screen')),
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

  // NEW: Inject mock environment variables into the test harness memory
  // to prevent the NotInitializedError when providers load.
  dotenv.testLoad(
    fileInput: '''
API_BASE_URL=http://localhost:8001
ADMOB_BANNER_ANDROID=test_id
ADMOB_BANNER_IOS=test_id
ADMOB_INTERSTITIAL_ANDROID=test_id
ADMOB_INTERSTITIAL_IOS=test_id
''',
  );

  group('SplashScreen Widget Tests', () {
    testWidgets('Renders SplashScreen elements correctly', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(createRouterTestApp(child: const SplashScreen()));

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('Navigates to /intro when no access token is stored', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(createRouterTestApp(child: const SplashScreen()));

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

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

      await tester.tap(find.text("Next"));
      await tester.pumpAndSettle();
      expect(find.text("Professional Audio Enhancement"), findsOneWidget);
      expect(
        find.text("Transform poor recordings into studio-quality sound."),
        findsOneWidget,
      );

      await tester.tap(find.text("Next"));
      await tester.pumpAndSettle();
      expect(find.text("Video Audio Replacement"), findsOneWidget);
      expect(
        find.text("Mute original audio and add new voice tracks."),
        findsOneWidget,
      );

      await tester.tap(find.text("Next"));
      await tester.pumpAndSettle();
      expect(find.text("Export Anywhere"), findsOneWidget);
      expect(
        find.text("Download and share your enhanced media instantly."),
        findsOneWidget,
      );

      expect(find.text("Get Started"), findsOneWidget);

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

  group('LoginScreen Widget Tests', () {
    testWidgets('Renders LoginScreen UI elements correctly', (
      WidgetTester tester,
    ) async {
      // NEW: Mock SharedPreferences before rendering the LoginScreen
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(createRouterTestApp(child: const LoginScreen()));

      expect(find.text("Let's sign in"), findsOneWidget);
      expect(find.text("Welcome Back, You have been missed."), findsOneWidget);
      expect(find.text("Login"), findsOneWidget);
      expect(find.text("Forgot Password"), findsOneWidget);
      expect(find.text("Continue with Google"), findsOneWidget);
    });

    testWidgets('Shows validation Snackbar when fields are empty', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(createRouterTestApp(child: const LoginScreen()));

      await tester.tap(find.text("Login"));
      await tester.pump();

      expect(find.text("Please fill all fields"), findsOneWidget);
    });
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('Renders RegisterScreen UI elements correctly', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const RegisterScreen()),
      );

      expect(find.text("Let's register account"), findsOneWidget);
      expect(find.text("Register"), findsOneWidget);
      expect(find.text("Sign up with Google"), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);
    });

    testWidgets('Shows validation Snackbar when passwords do not match', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const RegisterScreen()),
      );

      final textInputs = find.byType(EditableText);
      expect(textInputs, findsNWidgets(5));

      await tester.enterText(textInputs.at(3), "SecurePass123");
      await tester.enterText(textInputs.at(4), "DifferentPass456");

      await tester.tap(find.text("Register"));
      await tester.pump();

      expect(find.text("Passwords do not match"), findsOneWidget);
    });
  });
}

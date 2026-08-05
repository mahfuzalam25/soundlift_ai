import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:soundlift_ai/core/network/api_client.dart';
import 'package:soundlift_ai/features/onboarding/onboarding_screen.dart';
import 'package:soundlift_ai/features/splash/splash_screen.dart';
import 'package:soundlift_ai/features/auth/login_screen.dart';
import 'package:soundlift_ai/features/auth/register_screen.dart';
import 'package:soundlift_ai/features/auth/otp_verify_screen.dart';
import 'package:soundlift_ai/features/auth/forgot_password_screen.dart';
import 'package:soundlift_ai/features/auth/new_password_screen.dart';
import 'package:soundlift_ai/features/dashboard/dashboard_screen.dart';
import 'package:soundlift_ai/features/dashboard/main_layout.dart';
import 'package:soundlift_ai/features/create/create_screen.dart';
import 'package:soundlift_ai/features/projects/projects_screen.dart';
import 'package:soundlift_ai/features/subscription/subscription_screen.dart';
import 'package:soundlift_ai/features/profile/profile_screen.dart';
import 'package:soundlift_ai/features/profile/sessions_screen.dart';
import 'package:soundlift_ai/features/profile/change_password_screen.dart';
import 'package:soundlift_ai/features/profile/edit_profile_screen.dart';
import 'package:soundlift_ai/features/profile/security_screen.dart';
import 'package:soundlift_ai/features/projects/media_viewer_screen.dart';
import 'package:soundlift_ai/features/billing/billing_screen.dart'; // NEW: Imported BillingScreen

// --- MOCK API SETUP ---
// This safely intercepts all HTTP calls during testing, returning
// valid JSON to prevent Riverpod parsing crashes and hanging timers.
final mockDio = Dio();

void setupMockDio() {
  mockDio.interceptors.clear();
  mockDio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final path = options.path;

        if (path.contains('/profile')) {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'name': 'Test User', 'profile_picture': null},
            ),
          );
        } else if (path.endsWith('/projects/')) {
          // INTERCEPT: Fetch all projects list
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: [
                {
                  'id': 'proj-1',
                  'project_name': 'Sample Audio Project',
                  'status': 'completed',
                  'created_at': '2026-05-01T12:00:00Z',
                  'media_file': {'format': 'mp3'},
                },
                {
                  'id': 'proj-2',
                  'project_name': 'Sample Video Project',
                  'status': 'processing',
                  'created_at': '2026-05-02T12:00:00Z',
                  'media_file': {'format': 'mp4'},
                },
              ],
            ),
          );
        } else if (path.contains('/projects/') &&
            !path.endsWith('/download/')) {
          // NEW INTERCEPT: Single Project Details
          // Returns null URLs to safely bypass video/audio plugin crashes during widget tests
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id': 'proj-1',
                'project_name': 'Sample Audio Project',
                'status': 'completed',
                'created_at': '2026-05-01T12:00:00Z',
                'media_file': {
                  'format': 'mp3',
                  'original_file': null,
                  'processed_file': null,
                },
              },
            ),
          );
        } else if (path.contains('/my-subscription')) {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id': '1',
                'plan_name': 'Free',
                'status': 'active',
                'is_active': true,
                'current_period_end': '2026-12-31T00:00:00Z',
                'cancel_at_period_end': false,
                'days_until_expiry': 30,
                'remaining_minutes': 10.0,
                'total_allocated_minutes': 10.0,
              },
            ),
          );
        } else if (path.contains('/plans')) {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: [
                {
                  'id': 'plan_1',
                  'name': 'Pro Plan',
                  'price': '9.99',
                  'duration': '/month',
                  'is_popular': true,
                  'allocated_minutes': 100,
                  'max_storage_mb': 500,
                  'max_upload_mb': 50,
                  'export_resolution': 1080,
                  'has_watermark': false,
                  'features': ['Priority Support'],
                },
              ],
            ),
          );
        } else if (path.contains('/sessions')) {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: [
                {
                  'id': 1,
                  'ip_address': '192.168.1.1',
                  'user_agent': 'Dart/3.0 (Android)',
                  'login_datetime': '2026-07-31T12:00:00Z',
                  'is_active': true,
                },
              ],
            ),
          );
        } else if (path.contains('/notifications')) {
          return handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: []),
          );
        } else if (path.contains('/billing/overview')) {
          // NEW INTERCEPT: Billing Overview
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'current_plan': {
                  'name': 'Pro',
                  'price': '9.99',
                  'duration': '/month',
                  'status': 'Active',
                  'is_active': true,
                  'current_period_end': '2026-12-31T00:00:00Z',
                },
                'recent_invoices': [
                  {
                    'id': 'inv-1',
                    'invoice_number': 'INV-2026-001',
                    'plan_name': 'Pro Plan',
                    'amount': '9.99',
                    'currency': 'USD',
                    'status': 'paid',
                    'created_at': '2026-05-01T12:00:00Z',
                  },
                ],
              },
            ),
          );
        }

        // Generic fallback to prevent null crashes
        return handler.resolve(
          Response(requestOptions: options, statusCode: 200, data: {}),
        );
      },
    ),
  );
}

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
        path: '/auth/login',
        builder: (context, state) =>
            const Scaffold(body: Text('Login Destination Screen')),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) =>
            const Scaffold(body: Text('Register Destination Screen')),
      ),
      GoRoute(
        path: '/auth/verify',
        builder: (context, state) =>
            const Scaffold(body: Text('Verify Destination Screen')),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) =>
            const Scaffold(body: Text('Forgot Password Destination Screen')),
      ),
      GoRoute(
        path: '/auth/new-password',
        builder: (context, state) =>
            const Scaffold(body: Text('New Password Destination Screen')),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) =>
            const Scaffold(body: Text('Dashboard Destination Screen')),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) =>
            const Scaffold(body: Text('Notifications Destination Screen')),
      ),
      GoRoute(
        path: '/upload',
        builder: (context, state) =>
            const Scaffold(body: Text('Upload Destination Screen')),
      ),
      GoRoute(
        path: '/upload/replace-audio',
        builder: (context, state) =>
            const Scaffold(body: Text('Replace Audio Destination Screen')),
      ),
      GoRoute(
        path: '/project/:id',
        builder: (context, state) =>
            const Scaffold(body: Text('Project Overview Screen')),
      ),
      GoRoute(
        path: '/subscription/billing',
        builder: (context, state) =>
            const Scaffold(body: Text('Billing Destination Screen')),
      ),
      GoRoute(
        path: '/referrals',
        builder: (context, state) =>
            const Scaffold(body: Text('Referrals Destination Screen')),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) =>
            const Scaffold(body: Text('Edit Profile Destination Screen')),
      ),
      GoRoute(
        path: '/profile/security',
        builder: (context, state) =>
            const Scaffold(body: Text('Security Destination Screen')),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) =>
            const Scaffold(body: Text('Settings Destination Screen')),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) =>
            const Scaffold(body: Text('Help Destination Screen')),
      ),
      GoRoute(
        path: '/profile/sessions',
        builder: (context, state) =>
            const Scaffold(body: Text('Sessions Destination Screen')),
      ),
      GoRoute(
        path: '/profile/change-password',
        builder: (context, state) =>
            const Scaffold(body: Text('Change Password Destination Screen')),
      ),
      ...?additionalRoutes,
    ],
  );

  // Override the API client provider to use our Mock Dio instance
  return ProviderScope(
    overrides: [dioProvider.overrideWithValue(mockDio)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setupMockDio();

  // Inject mock environment variables into the test harness memory
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

  group('ForgotPasswordScreen Widget Tests', () {
    testWidgets('Renders ForgotPasswordScreen UI elements correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createRouterTestApp(child: const ForgotPasswordScreen()),
      );

      expect(find.text("Reset Password"), findsOneWidget);
      expect(find.text("Enter your email to receive an OTP."), findsOneWidget);
      expect(find.text("Send OTP"), findsOneWidget);
    });

    testWidgets('Tapping "Send OTP" navigates to OTP verification screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createRouterTestApp(child: const ForgotPasswordScreen()),
      );

      await tester.tap(find.text("Send OTP"));
      await tester.pumpAndSettle();

      expect(find.text('Verify Destination Screen'), findsOneWidget);
    });
  });

  group('OtpVerifyScreen Widget Tests', () {
    testWidgets(
      'Renders OtpVerifyScreen elements correctly for register flow',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(
          createRouterTestApp(child: const OtpVerifyScreen(flow: 'register')),
        );

        expect(find.text("Verify OTP"), findsOneWidget);
        expect(find.text("Verify"), findsOneWidget);
        expect(find.byType(EditableText), findsOneWidget);
      },
    );

    testWidgets('Renders OtpVerifyScreen elements correctly for reset flow', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const OtpVerifyScreen(flow: 'reset')),
      );

      expect(find.text("Verify OTP"), findsOneWidget);
      expect(find.text("Verify"), findsOneWidget);
    });
  });

  group('NewPasswordScreen Widget Tests', () {
    testWidgets('Renders NewPasswordScreen UI elements correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createRouterTestApp(child: const NewPasswordScreen()),
      );

      expect(find.text("Create New Password"), findsOneWidget);
      expect(find.byType(EditableText), findsNWidgets(2));
      expect(find.text("Save & Login"), findsOneWidget);
    });

    testWidgets('Tapping "Save & Login" navigates to login route', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createRouterTestApp(child: const NewPasswordScreen()),
      );

      await tester.tap(find.text("Save & Login"));
      await tester.pumpAndSettle();

      expect(find.text('Login Destination Screen'), findsOneWidget);
    });
  });

  group('DashboardScreen Widget Tests', () {
    testWidgets('Renders DashboardScreen headers and Quick Actions', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const DashboardScreen()),
      );
      // Wait for Mock Dio futures to resolve and loading indicators to clear
      await tester.pumpAndSettle();

      expect(find.text("Quick Actions"), findsOneWidget);
      expect(find.text("Recent Projects"), findsOneWidget);
      expect(find.text("Enhance\nAudio"), findsOneWidget);
      expect(find.text("Enhance\nVideo"), findsOneWidget);
      expect(find.text("Replace\nAudio"), findsOneWidget);
    });

    testWidgets('Tapping notification bell navigates to notifications route', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const DashboardScreen()),
      );
      await tester.pumpAndSettle();

      final notificationBell = find.byIcon(Icons.notifications_none);
      expect(notificationBell, findsOneWidget);

      await tester.tap(notificationBell);
      await tester.pumpAndSettle();

      expect(find.text('Notifications Destination Screen'), findsOneWidget);
    });
  });

  group('MainLayout Widget Tests', () {
    testWidgets('Renders MainLayout bottom navigation bar items', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(createRouterTestApp(child: const MainLayout()));
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text("Home"), findsOneWidget);
      expect(find.text("Projects"), findsOneWidget);
      expect(find.text("Create"), findsOneWidget);
      expect(find.text("Plans"), findsOneWidget);
      expect(find.text("Profile"), findsOneWidget);
    });

    testWidgets('Tapping bottom navigation bar tab updates active index', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(createRouterTestApp(child: const MainLayout()));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Projects"));
      await tester.pumpAndSettle();

      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNavBar.currentIndex, 1);
    });
  });

  group('CreateScreen Widget Tests', () {
    testWidgets('Renders CreateScreen UI elements correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: CreateScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text("Create New Project"), findsOneWidget);
      expect(
        find.text("Choose the type of enhancement you need."),
        findsOneWidget,
      );
      expect(find.text("Audio\nEnhancement"), findsOneWidget);
      expect(find.text("Video\nEnhancement"), findsOneWidget);
      expect(find.text("Replace\nAudio"), findsOneWidget);
      expect(find.text("AI Subtitles\n(Coming Soon)"), findsOneWidget);
    });

    testWidgets('Tapping Audio Enhancement navigates to upload route', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: CreateScreen())),
      );
      await tester.pumpAndSettle();

      final audioOption = find.text("Audio\nEnhancement");
      await tester.ensureVisible(audioOption);
      await tester.tap(audioOption);
      await tester.pumpAndSettle();

      expect(find.text('Upload Destination Screen'), findsOneWidget);
    });

    testWidgets('Tapping AI Subtitles shows coming soon Snackbar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: CreateScreen())),
      );
      await tester.pumpAndSettle();

      final subtitlesOption = find.text("AI Subtitles\n(Coming Soon)");
      await tester.ensureVisible(subtitlesOption);
      await tester.tap(subtitlesOption);
      await tester.pump(); // Trigger SnackBar animation

      expect(
        find.text('AI Subtitles are coming in a future update!'),
        findsOneWidget,
      );
    });
  });

  group('ProjectsScreen Widget Tests', () {
    testWidgets('Renders ProjectsScreen UI headers, search field, and tabs', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: ProjectsScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text("Your Projects"), findsOneWidget);
      expect(find.text("Search Project..."), findsOneWidget);
      expect(find.text("Audio"), findsOneWidget);
      expect(find.text("Video"), findsOneWidget);

      expect(find.text("Processing"), findsNWidgets(2));
      expect(find.text("Completed"), findsNWidgets(2));

      expect(find.text("Failed"), findsOneWidget);
      expect(find.text("Sample Audio Project"), findsOneWidget);
    });

    testWidgets('Filters project list when selecting the Audio filter chip', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: ProjectsScreen())),
      );
      await tester.pumpAndSettle();

      final audioFilterChip = find.widgetWithText(GestureDetector, "Audio");
      await tester.tap(audioFilterChip);
      await tester.pumpAndSettle();

      expect(find.text("Sample Audio Project"), findsOneWidget);
      expect(find.text("Sample Video Project"), findsNothing);
    });

    testWidgets(
      'Switches tabs to Processing tab and displays matching project',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(
          createRouterTestApp(child: const Scaffold(body: ProjectsScreen())),
        );
        await tester.pumpAndSettle();

        final processingTab = find.widgetWithText(Tab, "Processing");
        await tester.tap(processingTab);
        await tester.pumpAndSettle();

        expect(find.text("Sample Video Project"), findsOneWidget);
        expect(find.text("Sample Audio Project"), findsNothing);
      },
    );
  });

  group('SubscriptionScreen Widget Tests', () {
    testWidgets('Renders SubscriptionScreen UI and loaded mock data', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: SubscriptionScreen())),
      );
      await tester.pumpAndSettle();

      // Core headings
      expect(find.text("Subscription"), findsOneWidget);
      expect(find.text("Billing"), findsOneWidget);

      // Data driven from mySubscriptionProvider Mock
      expect(find.text("Current Plan"), findsOneWidget);
      expect(find.text("Free Tier"), findsOneWidget);

      // Data driven from subscriptionPlansProvider Mock
      expect(find.text("Upgrade Plans"), findsOneWidget);
      expect(find.text("Pro Plan"), findsOneWidget);
      expect(find.text("\$9.99"), findsOneWidget);
      expect(find.text("Refer & Earn Credits"), findsOneWidget);
    });

    testWidgets('Tapping Billing navigates to billing route', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: SubscriptionScreen())),
      );
      await tester.pumpAndSettle();

      final billingBtn = find.text("Billing");
      await tester.ensureVisible(billingBtn);
      await tester.tap(billingBtn);
      await tester.pumpAndSettle();

      expect(find.text('Billing Destination Screen'), findsOneWidget);
    });

    testWidgets('Tapping Refer & Earn navigates to referrals route', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: SubscriptionScreen())),
      );
      await tester.pumpAndSettle();

      final referBtn = find.text("Refer & Earn Credits");
      await tester.ensureVisible(referBtn);
      await tester.tap(referBtn);
      await tester.pumpAndSettle();

      expect(find.text('Referrals Destination Screen'), findsOneWidget);
    });
  });

  group('ProfileScreen Widget Tests', () {
    testWidgets('Renders ProfileScreen UI and user details from mock', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: ProfileScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text("Test User"), findsOneWidget);
      expect(find.text("No bio added yet"), findsOneWidget);
      expect(find.text("0"), findsNWidgets(2));
      expect(find.text("0 MB"), findsOneWidget);

      expect(find.text("Edit Profile"), findsOneWidget);
      expect(find.text("Account Security"), findsOneWidget);
      expect(find.text("Support"), findsOneWidget);
      expect(find.text("Logout"), findsOneWidget);
    });

    testWidgets('Tapping Edit Profile navigates to edit profile route', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: ProfileScreen())),
      );
      await tester.pumpAndSettle();

      final editProfileTile = find.text("Edit Profile");
      await tester.ensureVisible(editProfileTile);
      await tester.tap(editProfileTile);
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile Destination Screen'), findsOneWidget);
    });

    testWidgets(
      'Tapping Logout triggers logout process and navigates to login',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(
          createRouterTestApp(child: const Scaffold(body: ProfileScreen())),
        );
        await tester.pumpAndSettle();

        final logoutTile = find.text("Logout");
        await tester.ensureVisible(logoutTile);
        await tester.tap(logoutTile);
        await tester.pumpAndSettle();

        expect(find.text('Login Destination Screen'), findsOneWidget);
      },
    );
  });

  group('SessionsScreen Widget Tests', () {
    testWidgets('Renders SessionsScreen and loaded mock data', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: SessionsScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text("Login History & Sessions"), findsOneWidget);
      expect(find.text("192.168.1.1"), findsOneWidget);
      expect(find.text("Active"), findsOneWidget);
    });
  });

  group('ChangePasswordScreen Widget Tests', () {
    testWidgets('Renders ChangePasswordScreen UI elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createRouterTestApp(
          child: const Scaffold(body: ChangePasswordScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Change Password"), findsOneWidget);
      expect(find.text("Update your password"), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.text("Update Password"), findsOneWidget);
    });

    testWidgets('Shows validation Snackbar when fields are empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createRouterTestApp(
          child: const Scaffold(body: ChangePasswordScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final updateBtn = find.text("Update Password");
      await tester.ensureVisible(updateBtn);
      await tester.tap(updateBtn);
      await tester.pump();

      expect(find.text("Please fill in all fields"), findsOneWidget);
    });

    testWidgets('Shows validation Snackbar when passwords mismatch', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createRouterTestApp(
          child: const Scaffold(body: ChangePasswordScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final textInputs = find.byType(EditableText);
      expect(textInputs, findsNWidgets(3));

      await tester.enterText(textInputs.at(0), "OldPass123");
      await tester.enterText(textInputs.at(1), "NewPass123");
      await tester.enterText(textInputs.at(2), "MismatchPass456");

      final updateBtn = find.text("Update Password");
      await tester.ensureVisible(updateBtn);
      await tester.tap(updateBtn);
      await tester.pump();

      expect(find.text("New passwords do not match"), findsOneWidget);
    });
  });

  group('EditProfileScreen Widget Tests', () {
    testWidgets(
      'Renders EditProfileScreen UI elements and reads mock profile',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(
          createRouterTestApp(child: const Scaffold(body: EditProfileScreen())),
        );
        await tester.pumpAndSettle();

        expect(find.text("Edit Profile"), findsOneWidget);
        expect(find.text("Personal Information"), findsOneWidget);
        expect(find.text("Location Details"), findsOneWidget);
        expect(find.text("Save Changes"), findsOneWidget);
        expect(find.text("Bangladesh"), findsOneWidget);
      },
    );
  });

  group('SecurityScreen Widget Tests', () {
    testWidgets('Renders SecurityScreen UI components', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: SecurityScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text("Account Security"), findsOneWidget);
      expect(find.text("Account Settings"), findsOneWidget);
      expect(find.text("Email Verification"), findsOneWidget);
      expect(find.text("Change Password"), findsOneWidget);
      expect(find.text("Two-Factor Authentication"), findsOneWidget);
      expect(find.text("Active Sessions"), findsOneWidget);
    });

    testWidgets('Tapping Change Password navigates correctly', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: SecurityScreen())),
      );
      await tester.pumpAndSettle();

      final passBtn = find.text("Change Password");
      await tester.ensureVisible(passBtn);
      await tester.tap(passBtn);
      await tester.pumpAndSettle();

      expect(find.text("Change Password Destination Screen"), findsOneWidget);
    });

    testWidgets('Tapping Active Sessions navigates correctly', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: SecurityScreen())),
      );
      await tester.pumpAndSettle();

      final sessionBtn = find.text("Active Sessions");
      await tester.ensureVisible(sessionBtn);
      await tester.tap(sessionBtn);
      await tester.pumpAndSettle();

      expect(find.text("Sessions Destination Screen"), findsOneWidget);
    });
  });

  group('MediaViewerScreen Widget Tests', () {
    testWidgets(
      'Renders MediaViewerScreen details safely bypassing media plugins',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(
          createRouterTestApp(
            child: const Scaffold(body: MediaViewerScreen(projectId: 'proj-1')),
          ),
        );
        await tester.pumpAndSettle();

        // UI Texts from screen
        expect(find.text("Project Overview"), findsOneWidget);

        // Values drawn from the Mock Project Detail API response
        expect(find.text("Sample Audio Project"), findsOneWidget);
        expect(find.text("Format: MP3"), findsOneWidget);

        // Control buttons
        expect(find.text("Original"), findsOneWidget);
        expect(find.text("Enhanced"), findsOneWidget);

        // Safety check: The UI should gracefully default to "Media not available"
        // instead of trying to initialize the native video/audio player plugin.
        expect(find.text("Media not available"), findsOneWidget);
      },
    );

    testWidgets('Toggles between Original and Enhanced buttons safely', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(
          child: const Scaffold(body: MediaViewerScreen(projectId: 'proj-1')),
        ),
      );
      await tester.pumpAndSettle();

      final originalBtn = find.text("Original");
      final enhancedBtn = find.text("Enhanced");

      // Tap Original State
      await tester.ensureVisible(originalBtn);
      await tester.tap(originalBtn);
      await tester.pumpAndSettle();

      // Tap Enhanced State
      await tester.ensureVisible(enhancedBtn);
      await tester.tap(enhancedBtn);
      await tester.pumpAndSettle();

      // Ensure that toggling state does not trigger a crash and the safe container persists
      expect(find.text("Media not available"), findsOneWidget);
    });
  });

  // NEW: BillingScreen Widget Tests
  group('BillingScreen Widget Tests', () {
    testWidgets('Renders BillingScreen UI elements and loaded mock data', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: BillingScreen())),
      );
      await tester.pumpAndSettle();

      // Top level headings
      expect(find.text("Billing & Payments"), findsOneWidget);
      expect(find.text("Overview"), findsOneWidget);
      expect(find.text("Billing History"), findsOneWidget);

      // Current Plan Widget
      expect(find.text("Active"), findsOneWidget);
      expect(find.text("\$9.99 / month"), findsOneWidget);
      expect(find.text("Visa ending in 4242"), findsOneWidget);

      // Because date parsing handles timezones based on local execution context,
      // we check for a partial match on the label to prevent CI timezone mismatch failures.
      expect(find.textContaining("Next renewal on"), findsOneWidget);

      // Billing History List
      expect(find.text("Invoice INV-2026-001"), findsOneWidget);
      expect(find.text("\$9.99"), findsOneWidget);
      expect(find.text("Paid"), findsOneWidget);
    });

    testWidgets('Tapping Edit payment method shows coming soon Snackbar', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: BillingScreen())),
      );
      await tester.pumpAndSettle();

      final editBtn = find.text("Edit");
      await tester.ensureVisible(editBtn);
      await tester.tap(editBtn);
      await tester.pump();

      expect(find.text("Update Payment Method coming soon"), findsOneWidget);
    });

    testWidgets('Tapping download on invoice shows downloading Snackbar', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: BillingScreen())),
      );
      await tester.pumpAndSettle();

      final downloadBtn = find.byIcon(Icons.download_rounded);
      await tester.ensureVisible(downloadBtn);
      await tester.tap(downloadBtn);
      await tester.pump();

      expect(find.text("Downloading INV-2026-001 as PDF..."), findsOneWidget);
    });
  });
}

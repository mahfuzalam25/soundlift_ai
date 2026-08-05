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
import 'package:soundlift_ai/features/billing/billing_screen.dart';
import 'package:soundlift_ai/features/editor/video_editor_screen.dart';
import 'package:soundlift_ai/features/notifications/notifications_screen.dart';
import 'package:soundlift_ai/features/processing/processing_screen.dart';
import 'package:soundlift_ai/features/referral/referral_screen.dart';
import 'package:soundlift_ai/features/settings/settings_screen.dart';
import 'package:soundlift_ai/features/support/help_screen.dart';
import 'package:soundlift_ai/features/support/support_screen.dart';
import 'package:soundlift_ai/features/support/faq_screen.dart';
import 'package:soundlift_ai/features/support/docs_screen.dart';
import 'package:soundlift_ai/features/support/tutorials_screen.dart';
import 'package:soundlift_ai/features/support/contact_support_screen.dart';
import 'package:soundlift_ai/features/upload/upload_screen.dart';
import 'package:soundlift_ai/features/upload/replace_audio_upload_screen.dart';

// --- MOCK API SETUP ---
// This safely intercepts all HTTP calls during testing, returning
// valid JSON to prevent Riverpod parsing crashes and hanging timers.
final mockDio = Dio();

// FIX: Added a state variable to make the mock profile API stateful across requests
bool mockPushNotifications = false;

void setupMockDio() {
  mockDio.interceptors.clear();
  mockDio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final path = options.path;

        if (path.contains('/profile')) {
          // FIX: Intercept PATCH requests to update the state variable
          if (options.method == 'PATCH' && options.data is Map) {
            final dataMap = options.data as Map;
            if (dataMap.containsKey('push_notifications')) {
              mockPushNotifications = dataMap['push_notifications'];
            }
          }

          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'name': 'Test User',
                'profile_picture': null,
                'push_notifications':
                    mockPushNotifications, // Use the state variable
              },
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
            !path.endsWith('/download/') &&
            !path.contains('/status/')) {
          // INTERCEPT: Single Project Details
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
        } else if (path.contains('/status/')) {
          // INTERCEPT: Project Processing Status
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'job_status': 'completed',
                'progress': 100,
                'processed_file_url': 'http://mock.url/file.mp4',
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
          if (options.method == 'PATCH') {
            return handler.resolve(
              Response(requestOptions: options, statusCode: 200, data: {}),
            );
          }
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: [
                {
                  'id': 'notif-1',
                  'title': 'Project Success',
                  'message': 'Your audio replacement is completed.',
                  'is_read': false,
                  'created_at': '2026-08-05T10:00:00Z',
                },
                {
                  'id': 'notif-2',
                  'title': 'Upload Error',
                  'message': 'Failed to upload video.',
                  'is_read': true,
                  'created_at': '2026-08-04T10:00:00Z',
                },
              ],
            ),
          );
        } else if (path.contains('/billing/overview')) {
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
        } else if (path.contains('/pdf')) {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: "Mock PDF content",
            ),
          );
        } else if (path.contains('/v3.0/tracks')) {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'headers': {'status': 'success'},
                'results': [
                  {
                    'name': 'Epic Cinematic',
                    'audio': 'http://localhost:8001/audio.mp3',
                    'artist_name': 'Hans Zimmer',
                  },
                ],
              },
            ),
          );
        } else if (path.contains('/referrals/my-code/')) {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'code': 'MOCKCODE',
                'total_referrals': 5,
                'total_earned_minutes': 250.0,
                'has_claimed_welcome_reward': false,
              },
            ),
          );
        } else if (path.contains('/referrals/claim/')) {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'message': 'Referral claimed successfully'},
            ),
          );
        } else if (path.contains('/support/faqs')) {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: [
                {
                  'id': '1',
                  'question': 'How do I enhance audio?',
                  'answer':
                      'Go to the Create tab and select Audio Enhancement.',
                },
              ],
            ),
          );
        } else if (path.contains('/support/tutorials')) {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: [
                {
                  'id': '1',
                  'title': 'Getting Started',
                  'description': 'Learn the basics of SoundLift AI',
                  'video_url': 'https://youtube.com/watch?v=mock_video_id',
                },
              ],
            ),
          );
        } else if (path.contains('/support/docs')) {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: [
                {
                  'id': '1',
                  'title': 'Terms of Service',
                  'content': 'These are the terms and conditions.',
                },
              ],
            ),
          );
        } else if (path.contains('/support/contact')) {
          if (options.method == 'POST') {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'message': 'Success'},
              ),
            );
          }
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: [
                {
                  'id': '1',
                  'subject': 'App Crashed',
                  'message': 'The app crashes when I upload.',
                  'is_replied': true,
                  'admin_reply': 'We have fixed this in v1.2',
                  'created_at': '2026-08-01T12:00:00Z',
                },
              ],
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
      GoRoute(
        path: '/help/faq',
        builder: (context, state) =>
            const Scaffold(body: Text('FAQ Destination Screen')),
      ),
      GoRoute(
        path: '/help/tutorials',
        builder: (context, state) =>
            const Scaffold(body: Text('Tutorials Destination Screen')),
      ),
      GoRoute(
        path: '/help/docs',
        builder: (context, state) =>
            const Scaffold(body: Text('Docs Destination Screen')),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) =>
            const Scaffold(body: Text('Support Destination Screen')),
      ),
      GoRoute(
        path: '/support/contact',
        builder: (context, state) =>
            const Scaffold(body: Text('Contact Support Destination Screen')),
      ),
      GoRoute(
        path: '/help/tutorials/player/:id',
        builder: (context, state) =>
            const Scaffold(body: Text('Tutorial Player Destination Screen')),
      ),
      GoRoute(
        path: '/editor/video',
        builder: (context, state) =>
            const Scaffold(body: Text('Video Editor Destination Screen')),
      ),
      ...?additionalRoutes,
    ],
  );

  return ProviderScope(
    overrides: [dioProvider.overrideWithValue(mockDio)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setupMockDio();

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

      await tester.tap(find.text("Next"));
      await tester.pumpAndSettle();
      expect(find.text("Video Audio Replacement"), findsOneWidget);

      await tester.tap(find.text("Next"));
      await tester.pumpAndSettle();
      expect(find.text("Export Anywhere"), findsOneWidget);

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
      await tester.pump();
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
      expect(find.text("Subscription"), findsOneWidget);
      expect(find.text("Billing"), findsOneWidget);
      expect(find.text("Current Plan"), findsOneWidget);
      expect(find.text("Free Tier"), findsOneWidget);
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
        expect(find.text("Project Overview"), findsOneWidget);
        expect(find.text("Sample Audio Project"), findsOneWidget);
        expect(find.text("Format: MP3"), findsOneWidget);
        expect(find.text("Original"), findsOneWidget);
        expect(find.text("Enhanced"), findsOneWidget);
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

      await tester.ensureVisible(originalBtn);
      await tester.tap(originalBtn);
      await tester.pumpAndSettle();

      await tester.ensureVisible(enhancedBtn);
      await tester.tap(enhancedBtn);
      await tester.pumpAndSettle();

      expect(find.text("Media not available"), findsOneWidget);
    });
  });

  group('BillingScreen Widget Tests', () {
    testWidgets('Renders BillingScreen UI elements and loaded mock data', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: BillingScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text("Billing & Payments"), findsOneWidget);
      expect(find.text("Overview"), findsOneWidget);
      expect(find.text("Billing History"), findsOneWidget);

      expect(find.text("Active"), findsOneWidget);
      expect(find.text("\$9.99 / month"), findsOneWidget);
      expect(find.text("Visa ending in 4242"), findsOneWidget);
      expect(find.textContaining("Next renewal on"), findsOneWidget);

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

    testWidgets(
      'Tapping download on invoice shows failure Snackbar in test environment',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(
          createRouterTestApp(child: const Scaffold(body: BillingScreen())),
        );
        await tester.pumpAndSettle();

        final downloadBtn = find.byIcon(Icons.download_rounded);
        await tester.ensureVisible(downloadBtn);
        await tester.tap(downloadBtn);

        await tester.pump();
        expect(find.text("Failed to download invoice."), findsOneWidget);
      },
    );
  });

  group('VideoEditorScreen Widget Tests', () {
    final mockVideos = [
      {
        'name': 'Test Video.mp4',
        'networkUrl': 'http://localhost:8001/media/test_video.mp4',
        'extension': 'mp4',
      },
    ];
    final mockAudios = [
      {
        'name': 'Test Audio.mp3',
        'networkUrl': 'http://localhost:8001/media/test_audio.mp3',
        'extension': 'mp3',
      },
    ];

    testWidgets('Renders VideoEditorScreen UI components', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(
          child: VideoEditorScreen(
            projectName: "My Awesome Project",
            videos: mockVideos,
            audios: mockAudios,
          ),
        ),
      );
      // Wait for any initial player instantiation attempts to fail gracefully
      await tester.pumpAndSettle();

      expect(find.text("Video NLE Editor"), findsOneWidget);
      expect(find.text("Export"), findsOneWidget);
      expect(find.text("Editing: Test Video.mp4"), findsOneWidget);

      expect(find.text("Video Sequence", skipOffstage: false), findsOneWidget);
      expect(find.text("Audio Sequence", skipOffstage: false), findsOneWidget);
      expect(
        find.text("Background Music", skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text("Add Background Music", skipOffstage: false),
        findsOneWidget,
      );

      expect(
        find.text("Select clip to load duration...", skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('Tapping Speed button cycles speed options', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(
          child: VideoEditorScreen(
            projectName: "My Awesome Project",
            videos: mockVideos,
            audios: mockAudios,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final speedBtn = find.textContaining("Speed:");
      expect(speedBtn, findsOneWidget);
      expect(find.text("Speed: 1.0x"), findsOneWidget);

      await tester.tap(speedBtn);
      await tester.pumpAndSettle();

      expect(find.text("Speed: 1.5x"), findsOneWidget);
    });

    testWidgets('Tapping Add Background Music opens Jamendo sheet', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(
          child: VideoEditorScreen(
            projectName: "My Awesome Project",
            videos: mockVideos,
            audios: mockAudios,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final addBgmBtn = find.text("Add Background Music", skipOffstage: false);
      await tester.ensureVisible(addBgmBtn);
      await tester.pumpAndSettle();

      await tester.tap(addBgmBtn);
      await tester.pumpAndSettle(); // Wait for bottom sheet

      expect(find.text("Music Library (Jamendo)"), findsOneWidget);
      expect(find.text("Epic Cinematic"), findsOneWidget);
    });
  });

  group('NotificationsScreen Widget Tests', () {
    testWidgets('Renders NotificationsScreen UI and mock notifications', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: NotificationsScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text("Notifications"), findsOneWidget);
      expect(find.text("Mark all read"), findsOneWidget);
      expect(find.text("Recent"), findsOneWidget);
      expect(find.text("Project Success"), findsOneWidget);
      expect(find.text("Earlier"), findsOneWidget);
      expect(find.text("Upload Error"), findsOneWidget);
    });

    testWidgets('Tapping Mark all read clears unread notifications', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: NotificationsScreen())),
      );
      await tester.pumpAndSettle();

      final markAllBtn = find.text("Mark all read");
      await tester.ensureVisible(markAllBtn);
      await tester.tap(markAllBtn);
      await tester.pumpAndSettle();

      // The "Recent" section should be gone
      expect(find.text("Recent"), findsNothing);
      // Both notifications should now be under "Earlier"
      expect(find.text("Project Success"), findsOneWidget);
      expect(find.text("Upload Error"), findsOneWidget);
      // The Mark all read button should disappear
      expect(find.text("Mark all read"), findsNothing);
    });

    testWidgets('Tapping an unread notification marks it as read', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: NotificationsScreen())),
      );
      await tester.pumpAndSettle();

      final unreadTile = find.text("Project Success");
      await tester.ensureVisible(unreadTile);
      await tester.tap(unreadTile);
      await tester.pumpAndSettle();

      // The "Recent" section should be gone (since there was only 1 unread)
      expect(find.text("Recent"), findsNothing);
      expect(find.text("Mark all read"), findsNothing);
    });
  });

  group('ProcessingScreen Widget Tests', () {
    testWidgets(
      'Renders ProcessingScreen and transitions from Processing to Success',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(
          createRouterTestApp(
            child: const Scaffold(body: ProcessingScreen(jobId: 'job-123')),
          ),
        );

        // Initial State (Before 2.5s timer triggers)
        expect(find.text("Processing"), findsOneWidget);
        expect(
          find.text("Please wait while we process your file."),
          findsOneWidget,
        );
        expect(find.text("Run in Background"), findsOneWidget);

        // Fast forward the virtual clock by 2600ms to trigger the Periodic Timer.
        // This will hit the mocked /status/ endpoint returning "completed"
        // which natively kills the timer and triggers the state change.
        await tester.pump(const Duration(milliseconds: 2600));

        // Pump once to capture the Snackbar being drawn to the screen
        await tester.pump();
        expect(find.text("Processing Complete!"), findsOneWidget);

        // Let the remaining animations finish safely
        await tester.pumpAndSettle();

        expect(find.text("Success!"), findsOneWidget);
        expect(find.text("Your media is ready to view!"), findsOneWidget);
        expect(find.text("View Result"), findsOneWidget);
      },
    );

    testWidgets('Tapping Run in Background stops polling and navigates', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(
          child: const Scaffold(body: ProcessingScreen(jobId: 'job-123')),
        ),
      );

      final runBtn = find.text("Run in Background");
      await tester.ensureVisible(runBtn);
      await tester.tap(runBtn);
      await tester.pumpAndSettle();

      // Verifies the user was kicked out to the dashboard immediately
      expect(find.text('Dashboard Destination Screen'), findsOneWidget);
    });

    testWidgets('Tapping View Result navigates to project overview', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        createRouterTestApp(
          child: const Scaffold(body: ProcessingScreen(jobId: 'job-123')),
        ),
      );

      // Fast forward to completed state via mock API
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pumpAndSettle();

      final viewBtn = find.text("View Result");
      await tester.ensureVisible(viewBtn);
      await tester.tap(viewBtn);
      await tester.pumpAndSettle();

      expect(find.text('Project Overview Screen'), findsOneWidget);
    });
  });

  group('ReferralScreen Widget Tests', () {
    testWidgets('Renders ReferralScreen UI elements and reads mock data', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: ReferralScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text("Refer & Earn"), findsOneWidget);
      expect(find.text("Invite Friends,\nEarn Free Minutes"), findsOneWidget);
      expect(find.text("Your Unique Referral Code"), findsOneWidget);

      // Values drawn from Mock API
      expect(find.text("MOCKCODE"), findsOneWidget);
      expect(find.text("5"), findsOneWidget); // Total Referrals
      expect(find.text("250"), findsOneWidget); // Total Earned Minutes
    });

    testWidgets(
      'Shows validation Snackbar when submitting an empty claim code',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(
          createRouterTestApp(child: const Scaffold(body: ReferralScreen())),
        );
        await tester.pumpAndSettle();

        final claimBtn = find.text("Claim Reward");
        await tester.ensureVisible(claimBtn);
        await tester.tap(claimBtn);
        await tester.pump(); // Get first frame of Snackbar

        expect(find.text("Please enter a code"), findsOneWidget);
      },
    );

    testWidgets('Shows success Snackbar when claiming a valid code', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: ReferralScreen())),
      );
      await tester.pumpAndSettle();

      final codeField = find.byType(EditableText);
      await tester.enterText(codeField.first, "VALIDCODE");

      final claimBtn = find.text("Claim Reward");
      await tester.ensureVisible(claimBtn);
      await tester.tap(claimBtn);

      // Trigger the tap and async Loading state
      await tester.pump();

      // Let the mock API Future resolve
      await tester.pump(const Duration(milliseconds: 50));

      // Paint the resulting Snackbar frame
      await tester.pump();

      expect(
        find.text("Referral code claimed! You earned 50 free minutes."),
        findsOneWidget,
      );

      // Flush the pending API requests triggered by provider invalidation
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping Copy Link shows copied to clipboard Snackbar', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: ReferralScreen())),
      );
      await tester.pumpAndSettle();

      final copyBtn = find.text("Copy Link");
      await tester.ensureVisible(copyBtn);
      await tester.tap(copyBtn);
      await tester.pump(); // Get first frame of Snackbar

      expect(find.text("Referral link copied to clipboard!"), findsOneWidget);
    });
  });

  group('SettingsScreen Widget Tests', () {
    testWidgets('Renders SettingsScreen UI elements and reads profile data', (
      WidgetTester tester,
    ) async {
      mockPushNotifications = false; // Reset state
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: SettingsScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text("Settings"), findsOneWidget);
      expect(find.text("Preferences"), findsOneWidget);
      expect(find.text("Notifications"), findsOneWidget);
      expect(find.text("Processing & Export"), findsOneWidget);

      expect(find.text("Appearance"), findsOneWidget);
      expect(find.text("Language"), findsOneWidget);
      expect(find.text("Push Notifications"), findsOneWidget);
      expect(find.text("Email Updates"), findsOneWidget);
      expect(find.text("Auto Save to Device"), findsOneWidget);
      expect(find.text("Default Quality"), findsOneWidget);
    });

    testWidgets('Toggling notification settings updates the switch state', (
      WidgetTester tester,
    ) async {
      mockPushNotifications = false; // Reset state
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: SettingsScreen())),
      );
      await tester.pumpAndSettle();

      final pushSwitchFinder = find.descendant(
        of: find.widgetWithText(ListTile, "Push Notifications"),
        matching: find.byType(Switch),
      );

      // Verify default state is false (from mocked Profile)
      expect(tester.widget<Switch>(pushSwitchFinder).value, false);

      // Tap and wait for async mock API update
      await tester.ensureVisible(pushSwitchFinder);
      await tester.tap(pushSwitchFinder);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // State should now be true
      expect(tester.widget<Switch>(pushSwitchFinder).value, true);
    });

    testWidgets('Changing dropdown selection updates the UI state', (
      WidgetTester tester,
    ) async {
      mockPushNotifications = false; // Reset state
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: SettingsScreen())),
      );
      await tester.pumpAndSettle();

      // Ensure "System" is initially visible for Appearance
      expect(find.text("System"), findsOneWidget);

      // Open the Appearance dropdown
      await tester.tap(find.text("System"));
      await tester.pumpAndSettle();

      // Select "Dark" from the dropdown menu
      final darkOption = find.text("Dark").last;
      await tester.tap(darkOption);
      await tester.pumpAndSettle();

      // Verify the value changed
      expect(find.text("System"), findsNothing);
      expect(find.text("Dark"), findsOneWidget);
    });
  });

  // NEW: Support Folder Widget Tests
  group('HelpScreen Widget Tests', () {
    testWidgets('Renders HelpScreen UI elements correctly', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: HelpScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text("Help Center"), findsOneWidget);
      expect(find.text("How can we help you?"), findsOneWidget);
      expect(find.text("FAQ"), findsOneWidget);
      expect(find.text("Tutorials"), findsOneWidget);
      expect(find.text("Documentation"), findsOneWidget);
      expect(find.text("Still need help?"), findsOneWidget);
      expect(find.text("Contact Support"), findsOneWidget);
    });

    testWidgets('Tapping FAQ navigates to FAQ route', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: HelpScreen())),
      );
      await tester.pumpAndSettle();

      // FIX: Ensure card is in viewport before tapping
      final faqCard = find.text("FAQ");
      await tester.ensureVisible(faqCard);
      await tester.tap(faqCard);
      await tester.pumpAndSettle();
      expect(find.text("FAQ Destination Screen"), findsOneWidget);
    });

    testWidgets('Tapping Tutorials navigates to Tutorials route', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: HelpScreen())),
      );
      await tester.pumpAndSettle();

      // FIX: Ensure card is in viewport before tapping
      final tutorialsCard = find.text("Tutorials");
      await tester.ensureVisible(tutorialsCard);
      await tester.tap(tutorialsCard);
      await tester.pumpAndSettle();
      expect(find.text("Tutorials Destination Screen"), findsOneWidget);
    });

    testWidgets('Tapping Documentation navigates to Docs route', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: HelpScreen())),
      );
      await tester.pumpAndSettle();

      // FIX: Ensure card is in viewport before tapping to prevent offstage Offset error
      final docsCard = find.text("Documentation");
      await tester.ensureVisible(docsCard);
      await tester.tap(docsCard);
      await tester.pumpAndSettle();
      expect(find.text("Docs Destination Screen"), findsOneWidget);
    });

    testWidgets('Tapping Contact Support navigates to Support route', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: HelpScreen())),
      );
      await tester.pumpAndSettle();

      final contactSupportBtn = find.text("Contact Support");
      await tester.ensureVisible(contactSupportBtn);
      await tester.tap(contactSupportBtn);
      await tester.pumpAndSettle();
      expect(find.text("Support Destination Screen"), findsOneWidget);
    });
  });

  group('SupportScreen Widget Tests', () {
    testWidgets('Renders SupportScreen options', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: SupportScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text("Contact Support"), findsOneWidget);
      expect(find.text("We're here to help"), findsOneWidget);
      expect(find.text("Live Chat"), findsOneWidget);
      expect(find.text("Email Support"), findsOneWidget);
      expect(find.text("Create Ticket"), findsOneWidget);
    });

    testWidgets('Tapping Email Support navigates to contact route', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: SupportScreen())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text("Email Support"));
      await tester.pumpAndSettle();
      expect(find.text("Contact Support Destination Screen"), findsOneWidget);
    });
  });

  group('FaqScreen Widget Tests', () {
    testWidgets('Renders FaqScreen and reads mock FAQ data', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: FaqScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text("FAQ"), findsOneWidget);
      expect(find.text("How do I enhance audio?"), findsOneWidget);
    });

    testWidgets('Tapping an FAQ reveals the answer', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: FaqScreen())),
      );
      await tester.pumpAndSettle();

      final faqQuestion = find.text("How do I enhance audio?");
      await tester.tap(faqQuestion);
      await tester.pumpAndSettle();

      expect(
        find.text("Go to the Create tab and select Audio Enhancement."),
        findsOneWidget,
      );
    });
  });

  group('DocsScreen Widget Tests', () {
    testWidgets('Renders DocsScreen and reads mock documentation data', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: DocsScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text("Documentation"), findsOneWidget);
      expect(find.text("Terms of Service"), findsOneWidget);
      expect(find.text("These are the terms and conditions."), findsOneWidget);
    });
  });

  group('TutorialsScreen Widget Tests', () {
    testWidgets('Renders TutorialsScreen and reads mock tutorial data', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(child: const Scaffold(body: TutorialsScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text("Tutorials"), findsOneWidget);
      expect(find.text("Getting Started"), findsOneWidget);
      expect(find.text("Learn the basics of SoundLift AI"), findsOneWidget);
    });

    testWidgets(
      'Tapping a tutorial navigates to the video player route safely',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(
          createRouterTestApp(child: const Scaffold(body: TutorialsScreen())),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text("Getting Started"));
        await tester.pumpAndSettle();

        expect(find.text("Tutorial Player Destination Screen"), findsOneWidget);
      },
    );
  });

  group('ContactSupportScreen Widget Tests', () {
    testWidgets(
      'Renders ContactSupportScreen and reads mock previous tickets',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(
          createRouterTestApp(
            child: const Scaffold(body: ContactSupportScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text("Email Support"), findsOneWidget);
        expect(find.text("Send us a message"), findsOneWidget);
        expect(find.text("Your Messages"), findsOneWidget);
        expect(find.text("App Crashed"), findsOneWidget);
        expect(find.text("Replied"), findsOneWidget);
        expect(find.text("We have fixed this in v1.2"), findsOneWidget);
      },
    );

    testWidgets('Shows validation error Snackbar when submitting empty form', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(
          child: const Scaffold(body: ContactSupportScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final sendBtn = find.text("Send Message");
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pump(); // Get first frame of Snackbar

      expect(find.text("Please fill out all fields"), findsOneWidget);
    });

    testWidgets(
      'Shows success Snackbar when submitting valid support message',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(
          createRouterTestApp(
            child: const Scaffold(body: ContactSupportScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final textInputs = find.byType(EditableText);
        await tester.enterText(textInputs.first, "Need help with billing");
        await tester.enterText(textInputs.last, "Please update my card.");

        final sendBtn = find.text("Send Message");
        await tester.ensureVisible(sendBtn);
        await tester.tap(sendBtn);

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump();

        expect(find.text("Message sent successfully!"), findsOneWidget);

        await tester
            .pumpAndSettle(); // Flush network invalidation timers safely
      },
    );
  });

  // NEW: UploadScreen Widget Tests
  group('UploadScreen Widget Tests', () {
    testWidgets('Renders UploadScreen UI elements correctly', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(
          child: const Scaffold(body: UploadScreen(type: 'audio_enhancement')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Upload Media"), findsOneWidget);
      expect(find.text("Project Details"), findsOneWidget);
      expect(find.text("Project Name"), findsOneWidget);
      expect(find.text("Tap to Browse Files"), findsOneWidget);
      expect(find.text("Submit for Processing"), findsOneWidget);
    });

    testWidgets('Shows validation Snackbars for empty submissions', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(
          child: const Scaffold(body: UploadScreen(type: 'audio_enhancement')),
        ),
      );
      await tester.pumpAndSettle();

      final submitBtn = find.text("Submit for Processing");
      await tester.ensureVisible(submitBtn);

      await tester.tap(submitBtn);
      await tester.pump(); // frame for snackbar
      await tester.pump(const Duration(milliseconds: 50)); // allow animation
      await tester.pump(); // FIX: render the snackbar frame onto the screen

      expect(find.text("Please enter a project name."), findsOneWidget);

      // Hide snackbar fully
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle(); // Clear the queue before next interaction

      // Enter text and try again
      await tester.enterText(find.byType(TextField), "My Audio Project");
      // FIX: Close keyboard before interacting with the off-screen UI!
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.ensureVisible(submitBtn); // Ensure button is brought back onto screen
      await tester.tap(submitBtn);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester
          .pump(); // FIX: render the second snackbar frame onto the screen

      expect(find.text("Please select a file first"), findsOneWidget);
    });
  });

  // NEW: ReplaceAudioUploadScreen Widget Tests
  group('ReplaceAudioUploadScreen Widget Tests', () {
    testWidgets('Renders ReplaceAudioUploadScreen UI elements', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(
          child: const Scaffold(body: ReplaceAudioUploadScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Media Library"), findsOneWidget);
      expect(find.text("Project Name"), findsOneWidget);
      expect(find.text("1. Videos"), findsOneWidget);
      expect(find.text("2. Audio Tracks"), findsOneWidget);
      expect(find.text("Continue to Editor"), findsOneWidget);
    });

    testWidgets('Shows validation Snackbars for empty submissions', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(
          child: const Scaffold(body: ReplaceAudioUploadScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final continueBtn = find.text("Continue to Editor");
      await tester.ensureVisible(continueBtn);

      await tester.tap(continueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(); // FIX: render the snackbar frame onto the screen

      expect(find.text("Please enter a project name"), findsOneWidget);

      // Hide snackbar fully
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle(); // Clear the queue before next interaction

      await tester.enterText(find.byType(TextField), "My Video Project");
      // FIX: Close keyboard before interacting with the off-screen UI!
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.ensureVisible(continueBtn); // Ensure button is brought back onto screen
      await tester.tap(continueBtn);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester
          .pump(); // FIX: render the second snackbar frame onto the screen

      expect(find.text("Add at least one video"), findsOneWidget);
    });

    testWidgets('Tapping cloud download fetches and shows completed projects', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(
          child: const Scaffold(body: ReplaceAudioUploadScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // The second cloud download icon is for Audio Tracks
      final cloudIcons = find.byIcon(Icons.cloud_download);
      expect(cloudIcons, findsNWidgets(2));

      await tester.tap(cloudIcons.last);
      await tester
          .pumpAndSettle(); // Allow bottom sheet to open and API mock to resolve

      // The mock API returns 'Sample Audio Project' as a completed audio project
      expect(find.text("Sample Audio Project"), findsWidgets);

      // Tap the project in the bottom sheet to add it
      final listTile = find.widgetWithText(ListTile, "Sample Audio Project");
      await tester.ensureVisible(listTile);
      await tester.tap(listTile);
      await tester.pumpAndSettle();

      // Bottom sheet should close, and the file card should be visible.
      // ReplaceAudioUploadScreen doesn't show "Format" in its UI, it only shows "Size"
      expect(find.textContaining("Size: 0 B"), findsOneWidget);
    });

    testWidgets('Tapping video cloud download shows empty state Snackbar', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createRouterTestApp(
          child: const Scaffold(body: ReplaceAudioUploadScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // The first cloud download icon is for Video Tracks
      final cloudIcons = find.byIcon(Icons.cloud_download);

      await tester.tap(cloudIcons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      // Mock returns no *completed* video projects (proj-2 is processing)
      expect(find.text("No completed projects found."), findsOneWidget);
    });
  });
}
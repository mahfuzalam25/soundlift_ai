import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/otp_verify_screen.dart';
import '../../features/auth/new_password_screen.dart';
import '../../features/dashboard/main_layout.dart';
import '../../features/upload/upload_screen.dart';
import '../../features/processing/processing_screen.dart';
import '../../features/editor/video_editor_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/billing/billing_screen.dart';
import '../../features/referral/referral_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/security_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/support/help_screen.dart';
import '../../features/support/support_screen.dart';
import '../../features/profile/change_password_screen.dart';
import '../../features/profile/sessions_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/intro',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Auth Flow
      GoRoute(
        path: '/auth',
        redirect: (context, state) => '/auth/login', // Redirect base auth route
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/verify',
        builder: (context, state) {
          // Read the flow type from query parameters (e.g., ?flow=reset)
          final flowType = state.uri.queryParameters['flow'] ?? 'register';
          return OtpVerifyScreen(flow: flowType);
        },
      ),
      GoRoute(
        path: '/auth/new-password',
        builder: (context, state) => const NewPasswordScreen(),
      ),

      // Dashboard Placeholder (for testing post-login navigation)
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainLayout(),
      ),
      GoRoute(
        path: '/upload',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? 'audio-enhance';
          return UploadScreen(type: type);
        },
      ),
      GoRoute(
        path: '/processing/:jobId',
        builder: (context, state) {
          final jobId = state.pathParameters['jobId']!;
          return ProcessingScreen(jobId: jobId);
        },
      ),
      GoRoute(
        path: '/editor/video/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VideoEditorScreen(projectId: id);
        },
      ),
      // Future Project Details Route
      GoRoute(
        path: '/project/:id',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text("Project Details placeholder")),
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/subscription/billing',
        builder: (context, state) => const BillingScreen(),
      ),
      GoRoute(
        path: '/referrals',
        builder: (context, state) => const ReferralScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/security',
        builder: (context, state) => const SecurityScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(path: '/help', builder: (context, state) => const HelpScreen()),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/profile/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/profile/sessions',
        builder: (context, state) => const SessionsScreen(),
      ),
    ],
  );
});

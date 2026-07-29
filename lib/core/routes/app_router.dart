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
import '../../features/support/faq_screen.dart';
import '../../features/support/tutorials_screen.dart';
import '../../features/support/docs_screen.dart';
import '../../features/support/contact_support_screen.dart';
import '../../features/support/tutorial_player_screen.dart';
import '../../features/projects/media_viewer_screen.dart';
import '../../features/upload/replace_audio_upload_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/intro',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/auth', redirect: (context, state) => '/auth/login'),
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
          final flowType = state.uri.queryParameters['flow'] ?? 'register';
          return OtpVerifyScreen(flow: flowType);
        },
      ),
      GoRoute(
        path: '/auth/new-password',
        builder: (context, state) => const NewPasswordScreen(),
      ),

      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainLayout(),
      ),
      GoRoute(
        path: '/upload/replace-audio',
        builder: (context, state) => const ReplaceAudioUploadScreen(),
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
        path: '/editor/video',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return VideoEditorScreen(
            projectName: data['projectName'],
            videos: List<Map<String, dynamic>>.from(data['videos']),
            audios: List<Map<String, dynamic>>.from(data['audios']),
          );
        },
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

      GoRoute(
        path: '/help/faq',
        builder: (context, state) => const FaqScreen(),
      ),
      GoRoute(
        path: '/help/tutorials',
        builder: (context, state) => const TutorialsScreen(),
      ),
      GoRoute(
        path: '/help/docs',
        builder: (context, state) => const DocsScreen(),
      ),
      GoRoute(
        path: '/support/contact',
        builder: (context, state) => const ContactSupportScreen(),
      ),
      GoRoute(
        path: '/help/tutorials/player/:videoId',
        builder: (context, state) {
          final videoId = state.pathParameters['videoId']!;
          return TutorialPlayerScreen(videoId: videoId);
        },
      ),
      GoRoute(
        path: '/project/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MediaViewerScreen(projectId: id);
        },
      ),
    ],
  );
});

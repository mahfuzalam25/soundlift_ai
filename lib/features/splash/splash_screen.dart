import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/ad_service.dart';
import '../subscription/providers/subscription_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 3));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (mounted) {
      if (token != null && token.isNotEmpty) {
        try {
          // NEW: Validate Plan & Fire Ad if Free User
          final sub = await ref.read(mySubscriptionProvider.future);
          if (sub.planName.toLowerCase() == 'free') {
            AdService.showInterstitialWithLoader(context, onComplete: () {
              if (mounted) context.go('/dashboard');
            });
          } else {
            context.go('/dashboard');
          }
        } catch (e) {
          context.go('/dashboard'); // Failsafe
        }
      } else {
        context.go('/intro');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Image.asset(
            'assets/images/splash_logo.png',
            width: 250,
            errorBuilder: (context, error, stackTrace) {
              return const Text(
                "SoundLift AI",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
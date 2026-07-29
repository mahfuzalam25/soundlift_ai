import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../theme/app_colors.dart';

class AdService {
  static String get bannerAdUnitId {
    if (Platform.isAndroid)
      return dotenv.env['ADMOB_BANNER_ANDROID'] ??
          'ca-app-pub-3940256099942544/6300978111';
    if (Platform.isIOS)
      return dotenv.env['ADMOB_BANNER_IOS'] ??
          'ca-app-pub-3940256099942544/2934735716';
    return '';
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid)
      return dotenv.env['ADMOB_INTERSTITIAL_ANDROID'] ??
          'ca-app-pub-3940256099942544/1033173712';
    if (Platform.isIOS)
      return dotenv.env['ADMOB_INTERSTITIAL_IOS'] ??
          'ca-app-pub-3940256099942544/4411468910';
    return '';
  }

  static void showInterstitialWithLoader(
    BuildContext context, {
    required VoidCallback onComplete,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    bool isResolved = false;
    void resolve() {
      if (!isResolved) {
        isResolved = true;
        Navigator.pop(context); // Close loading dialog
        onComplete();
      }
    }

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              resolve();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              resolve();
            },
          );
          if (!isResolved) {
            isResolved = true;
            Navigator.pop(context);
          }
          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) => resolve(),
      ),
    );

    // Fail-safe to prevent infinite loader if network fails
    Future.delayed(const Duration(seconds: 4), resolve);
  }
}

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isLoaded = true),
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

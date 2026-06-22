import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const _androidProductionBannerAdUnitId =
    'ca-app-pub-6427159244427547/7342625356';
const _androidTestBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
const _iosProductionBannerAdUnitId = 'ca-app-pub-6427159244427547/3403380344';
const _iosTestBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';

String? get _bannerAdUnitId {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return kReleaseMode
        ? _androidProductionBannerAdUnitId
        : _androidTestBannerAdUnitId;
  }

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return kReleaseMode ? _iosProductionBannerAdUnitId : _iosTestBannerAdUnitId;
  }

  return null;
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

    final adUnitId = _bannerAdUnitId;
    if (adUnitId == null) {
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox();
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

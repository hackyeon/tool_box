import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app.dart';
import 'core/ads/ad_support.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (isMobileAdSupported) {
    await MobileAds.instance.initialize();
  }

  runApp(const App());
}

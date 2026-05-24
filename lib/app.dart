import 'package:flutter/material.dart';

import 'features/home/super_app_home_page.dart';
import 'features/image_to_pdf/image_to_pdf_page.dart';
import 'features/privacy/ez_pdf_privacy_page.dart';
import 'features/privacy/privacy_index_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  static const routeHome = '/';
  static const routeEzPdf = '/tools/ez-pdf';
  static const routePrivacy = '/privacy';
  static const routeEzPdfPrivacy = '/privacy/ez-pdf';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '편안한 도구들',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: routeHome,
      routes: {
        routeHome: (_) => const SuperAppHomePage(),
        routeEzPdf: (_) => const ImageToPdfPage(),
        routePrivacy: (_) => const PrivacyIndexPage(),
        routeEzPdfPrivacy: (_) => const EzPdfPrivacyPage(),
      },
    );
  }
}

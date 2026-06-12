import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'features/home/super_app_home_page.dart';
import 'features/image_tools/image_tools_page.dart';
import 'features/image_to_pdf/image_to_pdf_page.dart';
import 'features/qr_generator/qr_generator_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  static const routeHome = '/';
  static const routeEzPdf = '/tools/ez-pdf';
  static const routeImageTools = '/tools/image-tools';
  static const routeQrGenerator = '/tools/qr-generator';

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemUiOverlayStyle,
      child: MaterialApp(
        title: '편한도구함',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: routeHome,
        routes: {
          routeHome: (_) => const SuperAppHomePage(),
          routeEzPdf: (_) => const ImageToPdfPage(),
          routeImageTools: (_) => const ImageToolsPage(),
          routeQrGenerator: (_) => const QrGeneratorPage(),
        },
      ),
    );
  }
}

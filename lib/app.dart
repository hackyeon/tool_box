import 'package:flutter/material.dart';

import 'features/home/super_app_home_page.dart';
import 'features/image_to_pdf/image_to_pdf_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  static const routeHome = '/';
  static const routeEzPdf = '/tools/ez-pdf';

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
      },
    );
  }
}

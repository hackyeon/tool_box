import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const appBackgroundColor = Color(0xFFF7F9FC);
  static const systemBarDividerColor = Color(0xFFE2E8F0);

  static const systemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: appBackgroundColor,
    systemNavigationBarDividerColor: systemBarDividerColor,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );

  static ThemeData get light {
    return ThemeData(
      colorSchemeSeed: Colors.blue,
      scaffoldBackgroundColor: appBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: appBackgroundColor,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: systemUiOverlayStyle,
      ),
      useMaterial3: true,
    );
  }
}

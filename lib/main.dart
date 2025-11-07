import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'services/ad_service.dart';
import 'bridge_generated.dart/frb_generated.dart'; // import your generated ffi.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RustLib.init();
  
  // Initialize Google Mobile Ads
  await MobileAds.instance.initialize();
  
  runApp(const SmartPDFApp());
}

class SmartPDFApp extends StatelessWidget {
  const SmartPDFApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdService()),
      ],
      child: MaterialApp(
        title: 'SmartPDF',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
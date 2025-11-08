import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:ffi';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'services/ad_service.dart';
import 'bridge_generated.dart/frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Rust library 
    await RustLib.init();
    print('Rust library initialized successfully');
  } catch (e) {
    print('Failed to initialize Rust library: $e');
    // Continue with app launch even if Rust fails to load
  }
  
  // Initialize Google Mobile Ads
  try {
    await MobileAds.instance.initialize();
    print('AdMob initialized successfully');
  } catch (e) {
    print('Failed to initialize AdMob: $e');
    // Continue with app launch even if AdMob fails
  }
  
  runApp(const SmartPDFApp());
}

Future<void> _initializeRustLib() async {
  if (Platform.isIOS) {
    // For iOS, use the dylib file
    await RustLib.init(
      externalLibrary: ExternalLibrary.open('libspdfcore.dylib'),
    );
  } else {
    // For other platforms, use default initialization
    await RustLib.init();
  }
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
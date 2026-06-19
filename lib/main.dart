import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picder/providers/theme_provider.dart';
import 'package:picder/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/photo_sorter_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ← requis avant l'init des Ads
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await MobileAds.instance.initialize(); // ← initialise le SDK AdMob

  runApp(
    // MultiProvider injecte nos providers dans tout l'arbre de widgets
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PhotoSorterProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'PICDER',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.flutterThemeMode, // ← contrôle dynamique
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
      ),
      home: const HomeScreen(),
    );
  }
}

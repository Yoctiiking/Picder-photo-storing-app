import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/photo_sorter_provider.dart';
import 'screens/swipe_screen.dart';

void main() {
  runApp(
    // MultiProvider injecte nos providers dans tout l'arbre de widgets
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PhotoSorterProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PICDER',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark, // thème sombre = photos mises en valeur
        ),
        useMaterial3: true,
      ),
      home: const SwipeScreen(),
    );
  }
}
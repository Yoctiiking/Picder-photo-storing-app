import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Statistiques', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Text('Bientôt disponible', style: TextStyle(color: Colors.white54)),
      ),
    );
  }
}
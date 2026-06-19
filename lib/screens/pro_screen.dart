import 'package:flutter/material.dart';

import '../utils/responsive.dart';

class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Picder Pro', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.maxContentWidth(context),
          ),
          child: const Center(
            child: Text(
              'Bientôt disponible',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class Responsive {
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600;

  static bool isLargeTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900;

  // Nombre de colonnes pour les grilles (HomeScreen)
  static int gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  // Largeur max pour le contenu centré (formulaires, listes, résumés)
  static double maxContentWidth(BuildContext context) {
    return isTablet(context) ? 480 : double.infinity;
  }

  // Largeur max pour la zone de swipe (plus large que le contenu standard)
  static double maxSwipeWidth(BuildContext context) {
    return isTablet(context) ? 500 : double.infinity;
  }
}
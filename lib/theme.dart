import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta tomada del logo: atardecer naranja, arena, tierra y la silueta negra
/// del atarrayero.
class Paleta {
  static const atardecer = Color(0xFFBD6B2F);
  static const arena = Color(0xFFC3995F);
  static const tierra = Color(0xFF7A4A24);
  static const cienaga = Color(0xFF1F6F78);
  static const noche = Color(0xFF1B1712);
  static const crema = Color(0xFFFBF7F0);
}

Color colorHex(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

IconData iconoDe(String nombre) {
  switch (nombre) {
    case 'history_edu':
      return Icons.history_edu;
    case 'music_note':
      return Icons.music_note;
    case 'restaurant':
      return Icons.restaurant;
    case 'place':
      return Icons.place;
    case 'eco':
      return Icons.eco;
    case 'person':
      return Icons.person;
    default:
      return Icons.info_outline;
  }
}

ThemeData temaClaro() {
  final base = ColorScheme.fromSeed(
    seedColor: Paleta.atardecer,
    primary: Paleta.atardecer,
    secondary: Paleta.cienaga,
    surface: Paleta.crema,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    scaffoldBackgroundColor: Paleta.crema,
    textTheme: GoogleFonts.nunitoSansTextTheme().copyWith(
      headlineMedium: GoogleFonts.dmSerifDisplay(
          fontSize: 30, color: Paleta.noche, height: 1.1),
      headlineSmall: GoogleFonts.dmSerifDisplay(
          fontSize: 24, color: Paleta.noche, height: 1.15),
      titleLarge: GoogleFonts.nunitoSans(
          fontSize: 20, fontWeight: FontWeight.w800, color: Paleta.noche),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Paleta.crema,
      foregroundColor: Paleta.noche,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Paleta.arena.withOpacity(.35)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Paleta.atardecer.withOpacity(.16),
    ),
  );
}

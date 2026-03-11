import 'package:flutter/material.dart';

class AppTheme {
  // Paleta Zinc
  static const Color zinc950 = Color(0xFF09090B);
  static const Color zinc900 = Color(0xFF18181B);
  static const Color zinc800 = Color(0xFF27272A);
  static const Color zinc400 = Color(0xFFA1A1AA);
  static const Color zinc50  = Color(0xFFFAFAFA);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: zinc950,
      fontFamily: 'Roboto', // Fonte limpa sem serifas
      
      colorScheme: const ColorScheme.dark(
        primary: zinc50,
        surface: zinc900,
        error: Color(0xFFF87171), // Destrutivo
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: zinc950,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: zinc50),
        titleTextStyle: TextStyle(
          color: zinc50, 
          fontSize: 22, 
          fontWeight: FontWeight.w600,
        ),
      ),
      
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: zinc900,
        hintStyle: TextStyle(color: zinc400),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: zinc800),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }
}
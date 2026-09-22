import 'package:flutter/material.dart';

abstract class AppColors {
  // Brand Primary & Accents (Deep Wine / Crimson Security Palette)
  static const Color primary = Color(0xFF5E0C1B); // Deep Burgundy / Wine
  static const Color primaryDark = Color(0xFF420812); // Night Wine
  static const Color primaryLight = Color(0xFF8A1528); // Rich Crimson
  static const Color accentWine = Color(0xFFA61C33); // Vivid Crimson Accent
  static const Color accentRose = Color(0xFFFBECEE); // Soft Rose Highlight
  static const Color accentGold = Color(0xFFE5A118); // Operational Gold Accent

  // Gradients
  static const LinearGradient wineGradient = LinearGradient(
    colors: [Color(0xFF4C0A15), Color(0xFF7A1224)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardWineGradient = LinearGradient(
    colors: [Color(0xFF550C19), Color(0xFF821427)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softRoseGradient = LinearGradient(
    colors: [Color(0xFFFFF8F9), Color(0xFFF9EFF1)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Background & Surface Neutrals
  static const Color backgroundLight = Color(0xFFFBF6F7); // Soft Tinted Pearl
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure White Surface
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF6ECEE); // Pill / Capsule Tint
  static const Color backgroundDark = Color(0xFF14080B);
  static const Color surfaceDark = Color(0xFF220E14);

  // Status & System Colors
  static const Color success = Color(0xFF0D8253);
  static const Color successBadgeBg = Color(0xFFE7F7F0);
  static const Color warning = Color(0xFFC27803);
  static const Color warningBadgeBg = Color(0xFFFEF6E7);
  static const Color error = Color(0xFFBA1A33);
  static const Color errorBadgeBg = Color(0xFFFDECEF);
  static const Color info = Color(0xFF3568B2);
  static const Color infoBadgeBg = Color(0xFFEDF3FC);

  // Text Neutral Colors
  static const Color textPrimaryLight = Color(0xFF1D0B10); // Deep Espresso
  static const Color textSecondaryLight = Color(0xFF6B585E); // Muted Rose Slate
  static const Color textTertiaryLight = Color(0xFF9E8B91);
  static const Color textPrimaryDark = Color(0xFFFDF7F8);
  static const Color textSecondaryDark = Color(0xFFB8A4AA);

  // Borders & Dividers
  static const Color borderLight = Color(0xFFF0E1E4); // Subtle Rose Gray
  static const Color borderDark = Color(0xFF381C23);
  static const Color shadowColor = Color(0x0C4A0A14);
}

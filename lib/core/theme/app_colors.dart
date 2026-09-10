import 'package:flutter/material.dart';

/// Barbara's Bedtime Stories — Color System
/// Dreamy, calming palette inspired by twilight skies and moonlit nights.
class AppColors {
  AppColors._();

  // ── Primary Palette ──
  static const Color deepNavy = Color(0xFF0B1329);
  static const Color midnightBlack = Color(0xFF070B18);
  static const Color deepViolet = Color(0xFF161238);
  static const Color twilightPurple = Color(0xFF1E1B4B);
  static const Color royalPurple = Color(0xFF312E81);
  static const Color softPurple = Color(0xFF4C1D95);

  // ── Accent Colors ──
  static const Color warmGold = Color(0xFFFCD34D);
  static const Color softGold = Color(0xFFFDE68A);
  static const Color lavender = Color(0xFFC4B5FD);
  static const Color softLavender = Color(0xFFDDD6FE);
  static const Color moonlightWhite = Color(0xFFF0EDFF);

  // ── Functional Colors ──
  static const Color surface = Color(0xFF1A1640);
  static const Color surfaceLight = Color(0xFF252152);
  static const Color cardBackground = Color(0xFF1E1A4A);
  static const Color cardBackgroundLight = Color(0xFF2A2660);

  // ── Text Colors ──
  static const Color textPrimary = Color(0xFFF0EDFF);
  static const Color textSecondary = Color(0xFFA5A0D0);
  static const Color textMuted = Color(0xFF7B75A8);

  // ── Status Colors ──
  static const Color success = Color(0xFF34D399);
  static const Color error = Color(0xFFF87171);
  static const Color warning = Color(0xFFFBBF24);

  // ── Gradients ──
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepNavy, twilightPurple],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceLight, surface],
  );

  static const LinearGradient playerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0B1329),
      Color(0xFF1E1B4B),
      Color(0xFF312E81),
    ],
  );

  static const LinearGradient goldShimmer = LinearGradient(
    colors: [warmGold, softGold, warmGold],
  );
}

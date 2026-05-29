import 'package:flutter/material.dart';

class AppColors {
  // Primary & Secondary
  static const Color primary = Color(0xFF7C4DFF); // Neon mor
  static const Color secondary = Color(0xFF00E5FF); // Neon blue/cyan

  // Backgrounds
  static const Color background = Color(0xFF0F1117); // Koyu arka plan
  static const Color cardBackground = Color(0xFF1A1D24); // Kart arka planı (biraz daha açık)
  static const Color surfaceLight = Color(0xFF242830); // Slightly lighter surface

  // Feedback
  static const Color success = Color(0xFF00FF95); // Success / XP
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFFCC00);

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9E9E9E);

  // Stat Colors
  static const Color statFocus = Color(0xFF00E5FF); // Cyan
  static const Color statEnergy = Color(0xFF7C4DFF); // Purple
  static const Color statKnowledge = Color(0xFFFFAB40); // Orange
  static const Color statStrength = Color(0xFFFF4081); // Pink

  // Achievement
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFB8860B);

  // Gradient Presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFF9C6FFF)],
  );
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C4DFF), Color(0xFF00E5FF)],
  );
  static const LinearGradient xpGradient = LinearGradient(
    colors: [Color(0xFF00FF95), Color(0xFF00E5FF)],
  );
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
  );
}

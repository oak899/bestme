import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand — vibrant modern blue-purple
  static const primary = Color(0xFF4F46E5);
  static const primaryDark = Color(0xFF3730A3);
  static const primaryLight = Color(0xFF818CF8);
  static const accent = Color(0xFF06B6D4);
  static const accentWarm = Color(0xFFF97316);

  // Surfaces
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);
  static const borderLight = Color(0xFFF1F5F9);

  // Text
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const inProgress = Color(0xFF8B5CF6);
  static const done = Color(0xFF10B981);
  static const todo = Color(0xFF3B82F6);
  static const backlog = Color(0xFF64748B);
  static const blocked = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  // Dark
  static const backgroundDark = Color(0xFF0B1120);
  static const surfaceDark = Color(0xFF1E293B);
  static const borderDark = Color(0xFF334155);

  // Gradients
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF06B6D4)],
  );

  static const warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF97316), Color(0xFFFB923C), Color(0xFFFCD34D)],
  );

  static const successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF34D399), Color(0xFF6EE7B7)],
  );

  static const glassOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white24, Colors.white10],
  );

  static const chartPalette = [
    Color(0xFF4F46E5),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
  ];

  // Decorative blob colors
  static const blob1 = Color(0xFF4F46E5);
  static const blob2 = Color(0xFF06B6D4);
  static const blob3 = Color(0xFFF97316);
  static const blob4 = Color(0xFFEC4899);
}

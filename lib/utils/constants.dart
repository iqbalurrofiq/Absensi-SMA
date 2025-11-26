import 'package:flutter/material.dart';

// Color Scheme
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF8B5CF6); // Purple
  static const Color primaryDark = Color(0xFF4F46E5); // Dark Indigo

  // Secondary Colors
  static const Color secondary = Color(0xFF10B981); // Emerald
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryDark = Color(0xFF059669);

  // Accent Colors
  static const Color accent = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red
  static const Color success = Color(0xFF10B981); // Green
  static const Color warning = Color(0xFFF59E0B); // Yellow

  // Neutral Colors
  static const Color background = Color(0xFFF8FAFC); // Light Gray
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B); // Dark Slate
  static const Color textSecondary = Color(0xFF64748B); // Slate
  static const Color textHint = Color(0xFF94A3B8); // Light Slate

  // Card Colors
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Status Colors
  static const Color present = Color(0xFF10B981); // Green
  static const Color absent = Color(0xFFEF4444); // Red
  static const Color late = Color(0xFFF59E0B); // Yellow
  static const Color pending = Color(0xFF6B7280); // Gray
}

// Text Styles
class AppTextStyles {
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}

// Spacing
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// Border Radius
class AppBorderRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlRadius = BorderRadius.all(Radius.circular(xl));
}

// Shadows
class AppShadows {
  static const BoxShadow sm = BoxShadow(
    color: Color(0x0D000000),
    offset: Offset(0, 1),
    blurRadius: 2,
  );

  static const BoxShadow md = BoxShadow(
    color: Color(0x14000000),
    offset: Offset(0, 2),
    blurRadius: 4,
  );

  static const BoxShadow lg = BoxShadow(
    color: Color(0x1A000000),
    offset: Offset(0, 4),
    blurRadius: 8,
  );

  static const BoxShadow xl = BoxShadow(
    color: Color(0x1F000000),
    offset: Offset(0, 8),
    blurRadius: 16,
  );
}

// Gradients
class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondary = LinearGradient(
    colors: [AppColors.secondary, AppColors.secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient background = LinearGradient(
    colors: [AppColors.background, Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

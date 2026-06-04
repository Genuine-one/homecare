import 'package:flutter/material.dart';

/// KLE HOMECARE — Brand Color Palette with Gradients
class AppColors {
  AppColors._();

  // ── Primary (Deep Medical Blue) ───────────────────────────────────────────
  static const Color primary        = Color(0xFF1565C0);
  static const Color primaryLight   = Color(0xFF5E92F3);
  static const Color primaryDark    = Color(0xFF003C8F);

  // ── Secondary (Teal) ──────────────────────────────────────────────────────
  static const Color secondary      = Color(0xFF00897B);
  static const Color secondaryLight = Color(0xFF4EBAAA);
  static const Color secondaryDark  = Color(0xFF005B4F);

  // ── Accent ────────────────────────────────────────────────────────────────
  static const Color accent         = Color(0xFFFF6F00);

  // ── Status ────────────────────────────────────────────────────────────────
  static const Color success        = Color(0xFF2E7D32);
  static const Color warning        = Color(0xFFF57F17);
  static const Color error          = Color(0xFFC62828);
  static const Color info           = Color(0xFF0277BD);

  // ── Urgency ───────────────────────────────────────────────────────────────
  static const Color routine        = Color(0xFF2E7D32);
  static const Color urgent         = Color(0xFFF57F17);
  static const Color emergency      = Color(0xFFC62828);

  // ── Neutral ───────────────────────────────────────────────────────────────
  static const Color background     = Color(0xFFF0F4F8);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color divider        = Color(0xFFE2E8F0);
  static const Color textPrimary    = Color(0xFF1A202C);
  static const Color textSecondary  = Color(0xFF718096);
  static const Color textHint       = Color(0xFFCBD5E0);

  // ── Role Colors ───────────────────────────────────────────────────────────
  static const Color patientColor   = Color(0xFF1565C0);
  static const Color adminColor     = Color(0xFF6A1B9A);
  static const Color nurseColor     = Color(0xFF00897B);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
  );

  static const LinearGradient adminGradient = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [Color(0xFF8E24AA), Color(0xFF4A148C)],
  );

  static const LinearGradient nurseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [Color(0xFF00ACC1), Color(0xFF00695C)],
  );

  static const LinearGradient cardGradient1 = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
  );

  static const LinearGradient cardGradient2 = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [Color(0xFF00ACC1), Color(0xFF00838F)],
  );

  static const LinearGradient cardGradient3 = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [Color(0xFFFF8F00), Color(0xFFE65100)],
  );

  static const LinearGradient cardGradient4 = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [Color(0xFF388E3C), Color(0xFF1B5E20)],
  );

  static const LinearGradient adminCardGradient1 = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
  );

  static const LinearGradient adminCardGradient2 = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [Color(0xFF00ACC1), Color(0xFF006064)],
  );

  static const LinearGradient adminCardGradient3 = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [Color(0xFFF57F17), Color(0xFFE65100)],
  );

  static const LinearGradient adminCardGradient4 = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
  );

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color:       Colors.black.withValues(alpha: 0.08),
      blurRadius:  16,
      offset:      const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color:       Colors.black.withValues(alpha: 0.05),
      blurRadius:  10,
      offset:      const Offset(0, 2),
    ),
  ];

  // ── Material Theme ────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: surface,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design System RIENTRO
/// 
/// Filosofia: Dark-first, minimal, system-like
/// Ispirato a: Apple HIG, Material You, app di sicurezza premium
class AppTheme {
  AppTheme._();
  
  // ═══════════════════════════════════════════════════════════════
  // COLORI - Palette scura con accent verde sicurezza
  // ═══════════════════════════════════════════════════════════════
  
  // Backgrounds
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceElevated = Color(0xFF1C1C1E);
  static const Color surfaceHighlight = Color(0xFF2C2C2E);
  
  // Accent - Verde "sicurezza" professionale
  static const Color accent = Color(0xFF34C759);
  static const Color accentMuted = Color(0xFF30D158);
  static const Color accentSoft = Color(0x1A34C759);
  
  // Semantic Colors
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFFD60A);
  static const Color error = Color(0xFFFF453A);
  static const Color info = Color(0xFF0A84FF);
  
  // Status Colors (per rientro)
  static const Color statusActive = Color(0xFF34C759);
  static const Color statusLate = Color(0xFFFFD60A);
  static const Color statusEmergency = Color(0xFFFF453A);
  static const Color statusInactive = Color(0xFF48484A);
  
  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF48484A);
  static const Color textOnAccent = Color(0xFF000000);
  
  // Borders & Dividers
  static const Color border = Color(0xFF38383A);
  static const Color borderSubtle = Color(0xFF2C2C2E);
  static const Color divider = Color(0xFF38383A);
  
  // ═══════════════════════════════════════════════════════════════
  // TIPOGRAFIA - SF Pro inspired, clean, readable
  // ═══════════════════════════════════════════════════════════════
  
  static const String fontFamilyDisplay = 'SF Pro Display';
  static const String fontFamilyText = 'SF Pro Text';
  
  static const TextTheme textTheme = TextTheme(
    // Display - Per titoli hero
    displayLarge: TextStyle(
      fontSize: 56,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.5,
      height: 1.1,
      color: textPrimary,
    ),
    displayMedium: TextStyle(
      fontSize: 44,
      fontWeight: FontWeight.w600,
      letterSpacing: -1,
      height: 1.15,
      color: textPrimary,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      height: 1.2,
      color: textPrimary,
    ),
    
    // Headlines - Per sezioni
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      height: 1.25,
      color: textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.25,
      height: 1.3,
      color: textPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.35,
      color: textPrimary,
    ),
    
    // Title - Per card, list items
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.4,
      color: textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      height: 1.4,
      color: textPrimary,
    ),
    titleSmall: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.4,
      color: textPrimary,
    ),
    
    // Body - Per contenuto
    bodyLarge: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.5,
      color: textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.5,
      color: textSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.5,
      color: textSecondary,
    ),
    
    // Label - Per bottoni, badge
    labelLarge: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      height: 1.2,
      color: textPrimary,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.2,
      color: textSecondary,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.2,
      color: textTertiary,
    ),
  );
  
  // ═══════════════════════════════════════════════════════════════
  // SPAZIATURA - Sistema 8pt
  // ═══════════════════════════════════════════════════════════════
  
  static const double spacing2 = 2;
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing40 = 40;
  static const double spacing48 = 48;
  static const double spacing56 = 56;
  static const double spacing64 = 64;
  
  // Padding standard
  static const EdgeInsets paddingPage = EdgeInsets.all(24);
  static const EdgeInsets paddingCard = EdgeInsets.all(16);
  static const EdgeInsets paddingButton = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 16,
  );
  
  // ═══════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ═══════════════════════════════════════════════════════════════
  
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 24;
  static const double radiusRound = 100;
  
  static final BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius borderRadiusMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius borderRadiusLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius borderRadiusXLarge = BorderRadius.circular(radiusXLarge);
  
  // ═══════════════════════════════════════════════════════════════
  // SHADOWS
  // ═══════════════════════════════════════════════════════════════
  
  static List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> glowAccent = [
    BoxShadow(
      color: accent.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
  
  static List<BoxShadow> glowError = [
    BoxShadow(
      color: error.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
  
  // ═══════════════════════════════════════════════════════════════
  // ANIMAZIONI
  // ═══════════════════════════════════════════════════════════════
  
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  
  static const Curve curveDefault = Curves.easeOutCubic;
  static const Curve curveEmphasized = Curves.easeInOutCubic;
  static const Curve curveBounce = Curves.elasticOut;
  
  // ═══════════════════════════════════════════════════════════════
  // THEME DATA
  // ═══════════════════════════════════════════════════════════════
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Colors
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentMuted,
        surface: surface,
        error: error,
        onPrimary: textOnAccent,
        onSecondary: textOnAccent,
        onSurface: textPrimary,
        onError: textPrimary,
      ),
      
      scaffoldBackgroundColor: background,
      
      // Typography
      textTheme: textTheme,
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      
      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMedium,
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: textOnAccent,
          elevation: 0,
          padding: paddingButton,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusMedium,
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          padding: paddingButton,
          side: const BorderSide(color: border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusMedium,
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: const BorderSide(color: error, width: 1),
        ),
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(color: textSecondary),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 0.5,
        space: 0,
      ),
      
      // ListTile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tileColor: Colors.transparent,
        iconColor: textSecondary,
        textColor: textPrimary,
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textPrimary;
          }
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent;
          }
          return surfaceHighlight;
        }),
      ),
      
      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXLarge),
          ),
        ),
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusLarge,
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMedium,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}


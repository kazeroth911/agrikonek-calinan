import 'package:flutter/material.dart';

/// AgriKonek's look: the colours of a Calinan farm. Leaf green for actions,
/// harvest gold (durian, banana, mango) for highlights, Davao soil for
/// accents, on a warm rice-paper background.
///
/// Large touch targets, a 16-point body size and high-contrast text are
/// deliberate: the paper's HCI commitments target older, low-digital-
/// literacy users on small, low-end Android screens, often outdoors.
class AppTheme {
  AppTheme._();

  // Brand colours, also used by the logo and the hills artwork.
  static const leaf = Color(0xFF1F6B3A);
  static const leafDark = Color(0xFF124A27);
  static const leafLight = Color(0xFF3E8E57);
  static const sprout = Color(0xFFCDEBD3);
  static const harvest = Color(0xFFE8A92A);
  static const harvestLight = Color(0xFFFFE6A8);
  static const soil = Color(0xFFA0522D);
  static const soilLight = Color(0xFFFFDCC8);
  static const ricePaper = Color(0xFFFBF8F1);
  static const ink = Color(0xFF1E211C);

  static const fontFamily = 'Poppins';

  static const _radius = 16.0;

  static ColorScheme get _scheme =>
      ColorScheme.fromSeed(seedColor: leaf).copyWith(
        primary: leaf,
        onPrimary: Colors.white,
        primaryContainer: sprout,
        onPrimaryContainer: const Color(0xFF0B3D1E),
        secondary: const Color(0xFF8A5F00),
        onSecondary: Colors.white,
        secondaryContainer: harvestLight,
        onSecondaryContainer: const Color(0xFF3D2A00),
        tertiary: soil,
        onTertiary: Colors.white,
        tertiaryContainer: soilLight,
        onTertiaryContainer: const Color(0xFF3A1606),
        error: const Color(0xFFB3261E),
        errorContainer: const Color(0xFFF9DEDC),
        onErrorContainer: const Color(0xFF410E0B),
        surface: ricePaper,
        onSurface: ink,
        onSurfaceVariant: const Color(0xFF4A4F45),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF6F2E8),
        surfaceContainer: const Color(0xFFF1ECE0),
        surfaceContainerHigh: const Color(0xFFEBE5D7),
        surfaceContainerHighest: const Color(0xFFE5DECD),
        outline: const Color(0xFF7A8072),
        outlineVariant: const Color(0xFFDAD4C4),
        surfaceTint: Colors.transparent,
      );

  static ThemeData get light {
    final scheme = _scheme;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
    );
    final text = base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: base.textTheme.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
      headlineSmall: base.textTheme.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2),
      titleLarge: base.textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w600, fontSize: 21),
      titleMedium: base.textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w600, fontSize: 17),
      titleSmall: base.textTheme.titleSmall
          ?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
      bodyMedium:
          base.textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.45),
      bodySmall: base.textTheme.bodySmall?.copyWith(
          fontSize: 13, height: 1.4, color: scheme.onSurfaceVariant),
      labelLarge: base.textTheme.labelLarge
          ?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
      labelMedium:
          base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    );

    final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius));

    // Passed to the constructor rather than copyWith: the constructor
    // accepts both the older and newer theme-data classes across Flutter
    // versions.
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.comfortable,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius + 4),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56), // big tap target
          shape: shape,
          textStyle: text.titleMedium?.copyWith(fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: shape,
          side: BorderSide(color: scheme.outline),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: text.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        extendedTextStyle: text.labelLarge?.copyWith(fontSize: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius + 2)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius - 2),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius - 2),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius - 2),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius - 2),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius - 2),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.onPrimaryContainer,
        iconTheme: IconThemeData(color: scheme.primary, size: 18),
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
        labelStyle: text.labelLarge?.copyWith(color: scheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 3,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
            text.labelMedium?.copyWith(
              fontSize: 13,
              color: states.contains(WidgetState.selected)
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
            )),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
        dividerColor: scheme.outlineVariant,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
        contentTextStyle: text.bodyLarge?.copyWith(color: scheme.onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: leafDark,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: harvest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        titleTextStyle: text.titleSmall?.copyWith(color: scheme.onSurface),
        subtitleTextStyle: text.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      badgeTheme: const BadgeThemeData(
        backgroundColor: soil,
        textColor: Colors.white,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}

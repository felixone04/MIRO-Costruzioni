import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'site_theme.dart';

/// Colori fissi del gestionale: neutri freddi e chiari, come il cemento.
class Palette {
  static const ink = Color(0xFF16191C);
  static const paper = Color(0xFFF3F2EF);
  static const ivory = Color(0xFFFCFBF9);
  static const linen = Color(0xFFE9E7E2);
  static const stone = Color(0xFF5E6368); // testo secondario
  static const ash = Color(0xFF8D9196); // etichette
  static const line = Color(0x2416191C);
  static const lineStrong = Color(0x5916191C);
  static const error = Color(0xFFB3261E);
}

extension AccentX on BuildContext {
  /// Colore del marchio (l'ocra del sito).
  Color get brand => Theme.of(this).colorScheme.tertiary;
}

/// Titoli del gestionale.
TextStyle display(
  double size, {
  Color color = Palette.ink,
  FontWeight weight = FontWeight.w600,
  double height = 1.05,
}) => GoogleFonts.fraunces(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
);

/// Etichette maiuscole spaziate.
TextStyle label(
  double size, {
  Color color = Palette.ink,
  FontWeight weight = FontWeight.w600,
  double spacing = 0.2,
}) => GoogleFonts.dmSans(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: 1.3,
  letterSpacing: size * spacing,
);

/// Testo corrente.
TextStyle body(
  double size, {
  Color color = Palette.ink,
  FontWeight weight = FontWeight.w400,
  double height = 1.6,
}) => GoogleFonts.dmSans(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
);

class AppTheme {
  /// Tema chiaro e "gestionale" per l'area riservata.
  static ThemeData admin() {
    const strong = Palette.ink;
    final accent = Site.accent;
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: strong,
        onPrimary: Palette.paper,
        secondary: accent,
        tertiary: accent,
        onTertiary: Site.onAccent,
        secondaryContainer: strong,
        onSecondaryContainer: Palette.paper,
        surface: Colors.white,
        onSurface: Palette.ink,
      ),
      scaffoldBackgroundColor: Palette.paper,
    );
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: c, width: w),
    );
    return base.copyWith(
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: b(const Color(0xFFD3D1CC)),
        enabledBorder: b(const Color(0xFFD3D1CC)),
        focusedBorder: b(strong, 1.4),
        errorBorder: b(Palette.error),
        focusedErrorBorder: b(Palette.error, 1.4),
        labelStyle: GoogleFonts.dmSans(color: const Color(0xFF63676C)),
        floatingLabelStyle: GoogleFonts.dmSans(color: strong),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFD3D1CC)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE2E0DB)),
        ),
      ),
      dividerColor: const Color(0xFFE2E0DB),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Larghezza "di progetto" oltre la quale l'intero sito viene ingrandito
/// in proporzione (TV e monitor molto grandi): vedi [ScreenScale].
const designMaxWidth = 1600.0;

/// Breakpoint e misure fluide.
extension Responsive on BuildContext {
  double get w => MediaQuery.sizeOf(this).width;
  double get h => MediaQuery.sizeOf(this).height;
  bool get isPhone => w < 600;
  bool get isMobile => w < 720;
  bool get isTablet => w < 1024;

  /// Valore che cresce linearmente con la larghezza tra telefono (360) e
  /// desktop ampio (1600).
  double fluid(double min, double max) {
    final t = ((w - 360) / (designMaxWidth - 360)).clamp(0.0, 1.0);
    return min + (max - min) * t;
  }

  /// Margine laterale delle sezioni.
  double get gutter => fluid(20, 80);

  /// Altezza della barra di navigazione.
  double get navH => fluid(68, 92);

  /// Altezza utile per sezioni "a schermo intero" (mai troppo bassa né
  /// troppo alta, anche su telefoni in orizzontale).
  double get screenH => math.max(h, w < 600 ? 560 : 620);
}

/// Sui display più larghi di [designMaxWidth] (TV, monitor 4K) ingrandisce
/// tutto il sito in modo uniforme, così le proporzioni restano quelle
/// progettate invece di lasciare enormi spazi vuoti.
class ScreenScale extends StatelessWidget {
  const ScreenScale({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    if (width <= designMaxWidth + 120) return child;
    final s = (width / designMaxWidth).clamp(1.0, 3.0);
    final logical = Size(width / s, mq.size.height / s);
    return MediaQuery(
      data: mq.copyWith(
        size: logical,
        padding: mq.padding / s,
        viewPadding: mq.viewPadding / s,
        viewInsets: mq.viewInsets / s,
      ),
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: logical.width,
          height: logical.height,
          child: child,
        ),
      ),
    );
  }
}

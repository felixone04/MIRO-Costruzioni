import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Una tavolozza del sito: le stesse pagine con atmosfere diverse, chiare o
/// scure.
@immutable
class SiteTheme {
  const SiteTheme({
    required this.id,
    required this.name,
    required this.dark,
    required this.paper,
    required this.concrete,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.accentDeep,
    required this.onAccent,
    required this.night,
    required this.mutedDark,
  });

  final String id;
  final String name;

  /// Pagine su fondo scuro e testo chiaro.
  final bool dark;

  /// Fondo della pagina, fondo alternato delle sezioni, schede e campi.
  final Color paper;
  final Color concrete;
  final Color surface;

  /// Testo e testo secondario.
  final Color ink;
  final Color muted;

  /// Colore delle scritte in evidenza, la sua versione per i testi piccoli e
  /// il colore che ci va sopra.
  final Color accent;
  final Color accentDeep;
  final Color onAccent;

  /// Fondo delle parti sempre scure (prima schermata, piè di pagina) e testo
  /// secondario che ci va sopra.
  final Color night;
  final Color mutedDark;

  static SiteTheme lerp(SiteTheme a, SiteTheme b, double t) {
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return SiteTheme(
      id: t < 0.5 ? a.id : b.id,
      name: t < 0.5 ? a.name : b.name,
      dark: t < 0.5 ? a.dark : b.dark,
      paper: c(a.paper, b.paper),
      concrete: c(a.concrete, b.concrete),
      surface: c(a.surface, b.surface),
      ink: c(a.ink, b.ink),
      muted: c(a.muted, b.muted),
      accent: c(a.accent, b.accent),
      accentDeep: c(a.accentDeep, b.accentDeep),
      onAccent: c(a.onAccent, b.onAccent),
      night: c(a.night, b.night),
      mutedDark: c(a.mutedDark, b.mutedDark),
    );
  }
}

/// Le tavolozze proposte dal pulsante "Colori": tre chiare e tre scure.
const builtInThemes = <SiteTheme>[
  SiteTheme(
    id: 'sabbia',
    name: 'Sabbia',
    dark: false,
    paper: Color(0xFFF4EEE4),
    concrete: Color(0xFFEBE2D4),
    surface: Color(0xFFFBF8F3),
    ink: Color(0xFF3B2B27),
    muted: Color(0xFF7D6C64),
    accent: Color(0xFFCD5C5C),
    accentDeep: Color(0xFFB44848),
    onAccent: Color(0xFFFFFFFF),
    night: Color(0xFF2E2120),
    mutedDark: Color(0xFFC9B9B0),
  ),
  SiteTheme(
    id: 'calce',
    name: 'Calce',
    dark: false,
    paper: Color(0xFFF6F5F2),
    concrete: Color(0xFFECEAE5),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF23262A),
    muted: Color(0xFF6B6F74),
    accent: Color(0xFF7A2E3A),
    accentDeep: Color(0xFF7A2E3A),
    onAccent: Color(0xFFFFFFFF),
    night: Color(0xFF1E2023),
    mutedDark: Color(0xFFB4B7BB),
  ),
  SiteTheme(
    id: 'salvia',
    name: 'Salvia',
    dark: false,
    paper: Color(0xFFEEF0E8),
    concrete: Color(0xFFE2E6DA),
    surface: Color(0xFFF8F9F4),
    ink: Color(0xFF2D3830),
    muted: Color(0xFF66716A),
    accent: Color(0xFF8A6A3D),
    accentDeep: Color(0xFF7A5C31),
    onAccent: Color(0xFFFFFFFF),
    night: Color(0xFF233026),
    mutedDark: Color(0xFFB3BDB5),
  ),
  SiteTheme(
    id: 'bordeaux',
    name: 'Bordeaux',
    dark: true,
    paper: Color(0xFF3A1A20),
    concrete: Color(0xFF452128),
    surface: Color(0xFF4A2530),
    ink: Color(0xFFF3E7DA),
    muted: Color(0xFFCDB5AE),
    accent: Color(0xFFE9C39B),
    accentDeep: Color(0xFFE9C39B),
    onAccent: Color(0xFF3A1A20),
    night: Color(0xFF26100F),
    mutedDark: Color(0xFFCDB5AE),
  ),
  SiteTheme(
    id: 'terra',
    name: 'Terra',
    dark: true,
    paper: Color(0xFF2A2320),
    concrete: Color(0xFF332A26),
    surface: Color(0xFF3A302B),
    ink: Color(0xFFF1E6D8),
    muted: Color(0xFFBDAEA2),
    accent: Color(0xFFE07A6F),
    accentDeep: Color(0xFFE88B80),
    onAccent: Color(0xFF2A1A17),
    night: Color(0xFF1A1513),
    mutedDark: Color(0xFFBDAEA2),
  ),
  SiteTheme(
    id: 'notte',
    name: 'Notte',
    dark: true,
    paper: Color(0xFF17191C),
    concrete: Color(0xFF1F2226),
    surface: Color(0xFF25292E),
    ink: Color(0xFFECE9E3),
    muted: Color(0xFFA7A9AD),
    accent: Color(0xFFD9A65B),
    accentDeep: Color(0xFFDDB06C),
    onAccent: Color(0xFF17191C),
    night: Color(0xFF0F1012),
    mutedDark: Color(0xFFA7A9AD),
  ),
];

/// Colori del sito pubblico, presi dalla tavolozza attiva.
///
/// La tavolozza cambia dal pulsante "Colori" (vedi `ThemeFader`, che durante
/// il passaggio la sfuma e ridisegna tutto il sito).
class Site {
  static SiteTheme current = builtInThemes.first;

  static bool get dark => current.dark;
  static Color get paper => current.paper;
  static Color get concrete => current.concrete;
  static Color get surface => current.surface;
  static Color get ink => current.ink;
  static Color get muted => current.muted;
  static Color get accent => current.accent;
  static Color get accentDeep => current.accentDeep; // testi piccoli
  static Color get onAccent => current.onAccent;
  static Color get night => current.night;
  static Color get mutedDark => current.mutedDark; // secondario sul buio
  static Color get line => current.ink.withValues(alpha: 0.13);
  static const lineDark = Color(0x26FFFFFF);
}

/// Raggi degli angoli arrotondati.
class Radii {
  static const photo = 22.0;
  static const card = 18.0;
  static const field = 14.0;
}

/// Titoli: un serif morbido, in minuscolo come si scrive.
TextStyle siteHead(
  double size, {
  Color? color,
  FontWeight weight = FontWeight.w400,
  double height = 1.04,
  bool italic = false,
}) => GoogleFonts.fraunces(
  fontSize: size,
  fontWeight: weight,
  color: color ?? Site.ink,
  height: height,
  letterSpacing: -size * 0.015,
  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
);

/// Etichette piccole (categorie, dati, menu).
TextStyle siteLabel(
  double size, {
  Color? color,
  FontWeight weight = FontWeight.w600,
  double height = 1.4,
}) => GoogleFonts.dmSans(
  fontSize: size,
  fontWeight: weight,
  color: color ?? Site.ink,
  height: height,
  letterSpacing: size * 0.02,
);

/// Testo corrente.
TextStyle siteBody(
  double size, {
  Color? color,
  FontWeight weight = FontWeight.w400,
  double height = 1.65,
}) => GoogleFonts.dmSans(
  fontSize: size,
  fontWeight: weight,
  color: color ?? Site.ink,
  height: height,
);

ThemeData siteThemeData() {
  final scheme = Site.dark
      ? ColorScheme.dark(
          primary: Site.accent,
          onPrimary: Site.onAccent,
          secondary: Site.accent,
          tertiary: Site.accent,
          surface: Site.paper,
          onSurface: Site.ink,
        )
      : ColorScheme.light(
          primary: Site.ink,
          onPrimary: Site.paper,
          secondary: Site.accent,
          tertiary: Site.accent,
          surface: Site.paper,
          onSurface: Site.ink,
        );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Site.paper,
  );
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(Radii.field),
    borderSide: BorderSide(color: c, width: w),
  );
  return base.copyWith(
    textTheme: GoogleFonts.dmSansTextTheme(base.textTheme),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Site.ink,
      selectionColor: Site.accent.withValues(alpha: 0.33),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Site.surface,
      border: b(Site.line),
      enabledBorder: b(Site.line),
      focusedBorder: b(Site.accent, 1.5),
      errorBorder: b(const Color(0xFFC0392B)),
      focusedErrorBorder: b(const Color(0xFFC0392B), 1.5),
      labelStyle: GoogleFonts.dmSans(color: Site.muted),
      floatingLabelStyle: GoogleFonts.dmSans(color: Site.ink),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Site.accent : null,
      ),
      checkColor: WidgetStatePropertyAll(Site.onAccent),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Site.surface),
      ),
    ),
  );
}

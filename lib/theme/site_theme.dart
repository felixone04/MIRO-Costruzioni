import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Una tavolozza del sito: le stesse pagine con tonalità diverse.
@immutable
class SiteTheme {
  const SiteTheme({
    required this.id,
    required this.name,
    required this.night,
    required this.graphite,
    required this.steel,
    required this.concrete,
    required this.paper,
    required this.ink,
    required this.muted,
    required this.mutedDark,
    required this.accent,
    required this.accentDeep,
    required this.onAccent,
  });

  final String id;
  final String name;

  /// Fondo delle sezioni scure (barra, servizi, piè di pagina).
  final Color night;
  final Color graphite;
  final Color steel;

  /// Fondi chiari.
  final Color concrete;
  final Color paper;

  /// Testo sul chiaro e secondario sul chiaro / sullo scuro.
  final Color ink;
  final Color muted;
  final Color mutedDark;

  /// Colore del marchio, la sua versione leggibile sul chiaro e il testo
  /// che ci va sopra.
  final Color accent;
  final Color accentDeep;
  final Color onAccent;

  static SiteTheme lerp(SiteTheme a, SiteTheme b, double t) {
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return SiteTheme(
      id: t < 0.5 ? a.id : b.id,
      name: t < 0.5 ? a.name : b.name,
      night: c(a.night, b.night),
      graphite: c(a.graphite, b.graphite),
      steel: c(a.steel, b.steel),
      concrete: c(a.concrete, b.concrete),
      paper: c(a.paper, b.paper),
      ink: c(a.ink, b.ink),
      muted: c(a.muted, b.muted),
      mutedDark: c(a.mutedDark, b.mutedDark),
      accent: c(a.accent, b.accent),
      accentDeep: c(a.accentDeep, b.accentDeep),
      onAccent: c(a.onAccent, b.onAccent),
    );
  }
}

/// Le tavolozze proposte dal pulsante "Colori".
const builtInThemes = <SiteTheme>[
  SiteTheme(
    id: 'cantiere',
    name: 'Ocra cantiere',
    night: Color(0xFF111315),
    graphite: Color(0xFF1A1D20),
    steel: Color(0xFF2A2E33),
    concrete: Color(0xFFE7E4DE),
    paper: Color(0xFFF3F1ED),
    ink: Color(0xFF141618),
    muted: Color(0xFF666A70),
    mutedDark: Color(0xFFA2A6AB),
    accent: Color(0xFFE29B2E),
    accentDeep: Color(0xFFB9761A),
    onAccent: Color(0xFF141618),
  ),
  SiteTheme(
    id: 'cotto',
    name: 'Cotto e argilla',
    night: Color(0xFF1C1512),
    graphite: Color(0xFF261C18),
    steel: Color(0xFF3A2C26),
    concrete: Color(0xFFEDE3D9),
    paper: Color(0xFFF7F1EA),
    ink: Color(0xFF1F1612),
    muted: Color(0xFF76665C),
    mutedDark: Color(0xFFB5A79D),
    accent: Color(0xFFD0623A),
    accentDeep: Color(0xFFAE4520),
    onAccent: Color(0xFFFFFFFF),
  ),
  SiteTheme(
    id: 'progetto',
    name: 'Blu progetto',
    night: Color(0xFF0D1522),
    graphite: Color(0xFF142034),
    steel: Color(0xFF22324B),
    concrete: Color(0xFFE3E8EF),
    paper: Color(0xFFF2F5F9),
    ink: Color(0xFF0E1A2B),
    muted: Color(0xFF5A6779),
    mutedDark: Color(0xFF9CA9BB),
    accent: Color(0xFF4C8DF6),
    accentDeep: Color(0xFF235FCB),
    onAccent: Color(0xFFFFFFFF),
  ),
  SiteTheme(
    id: 'oliva',
    name: 'Verde oliva',
    night: Color(0xFF141A15),
    graphite: Color(0xFF1C241E),
    steel: Color(0xFF2C382F),
    concrete: Color(0xFFE4E7DE),
    paper: Color(0xFFF2F3EC),
    ink: Color(0xFF151C16),
    muted: Color(0xFF5E6A60),
    mutedDark: Color(0xFFA0ABA1),
    accent: Color(0xFF9DB55A),
    accentDeep: Color(0xFF627A24),
    onAccent: Color(0xFF141C10),
  ),
  SiteTheme(
    id: 'mattone',
    name: 'Rosso mattone',
    night: Color(0xFF161414),
    graphite: Color(0xFF201C1C),
    steel: Color(0xFF332D2D),
    concrete: Color(0xFFE9E5E2),
    paper: Color(0xFFF5F3F1),
    ink: Color(0xFF181414),
    muted: Color(0xFF6C6563),
    mutedDark: Color(0xFFAAA3A1),
    accent: Color(0xFFD9412F),
    accentDeep: Color(0xFFB52E1E),
    onAccent: Color(0xFFFFFFFF),
  ),
  SiteTheme(
    id: 'sicurezza',
    name: 'Giallo sicurezza',
    night: Color(0xFF0F0F10),
    graphite: Color(0xFF19191B),
    steel: Color(0xFF29292C),
    concrete: Color(0xFFE6E5E0),
    paper: Color(0xFFF4F3EF),
    ink: Color(0xFF111112),
    muted: Color(0xFF66666A),
    mutedDark: Color(0xFFA5A5A9),
    accent: Color(0xFFF5C518),
    accentDeep: Color(0xFF9E7C00),
    onAccent: Color(0xFF111112),
  ),
  SiteTheme(
    id: 'oro',
    name: 'Nero e oro',
    night: Color(0xFF0A0A0A),
    graphite: Color(0xFF141413),
    steel: Color(0xFF242321),
    concrete: Color(0xFFE2DDD2),
    paper: Color(0xFFF1EEE7),
    ink: Color(0xFF0D0C0B),
    muted: Color(0xFF6B665D),
    mutedDark: Color(0xFFA9A397),
    accent: Color(0xFFC9A961),
    accentDeep: Color(0xFF8E7234),
    onAccent: Color(0xFF0D0C0B),
  ),
];

/// Colori del sito pubblico, presi dalla tavolozza attiva.
///
/// La tavolozza cambia dal pulsante "Colori" (vedi `ThemeFader`, che durante
/// il passaggio la sfuma e ridisegna tutto il sito).
class Site {
  static SiteTheme current = builtInThemes.first;

  static Color get night => current.night;
  static Color get graphite => current.graphite;
  static Color get steel => current.steel;
  static Color get concrete => current.concrete;
  static Color get paper => current.paper;
  static Color get ink => current.ink;
  static Color get muted => current.muted;
  static Color get mutedDark => current.mutedDark; // testo secondario sul buio
  static Color get accent => current.accent;
  static Color get accentDeep => current.accentDeep; // leggibile sul chiaro
  static Color get onAccent => current.onAccent; // testo sopra l'accento
  static Color get line => current.ink.withValues(alpha: 0.12);
  static const lineDark = Color(0x24FFFFFF);
}

/// Titoli: condensato, deciso, sempre maiuscolo.
TextStyle siteHead(
  double size, {
  Color? color,
  FontWeight weight = FontWeight.w600,
  double height = 0.95,
  double spacing = 0,
}) => GoogleFonts.barlowCondensed(
  fontSize: size,
  fontWeight: weight,
  color: color ?? Site.ink,
  height: height,
  letterSpacing: spacing,
);

/// Titolo "a contorno" (solo il bordo delle lettere).
TextStyle siteOutline(
  double size, {
  Color? color,
  double stroke = 1.2,
  FontWeight weight = FontWeight.w700,
  double height = 0.95,
}) => GoogleFonts.barlowCondensed(
  fontSize: size,
  fontWeight: weight,
  height: height,
  foreground: Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..color = color ?? Site.ink,
);

/// Etichette "da tavola tecnica": numeri, coordinate, dati del cantiere.
TextStyle siteMono(
  double size, {
  Color? color,
  FontWeight weight = FontWeight.w500,
  double spacing = 0.12,
  double height = 1.4,
}) => GoogleFonts.ibmPlexMono(
  fontSize: size,
  fontWeight: weight,
  color: color ?? Site.ink,
  height: height,
  letterSpacing: size * spacing,
);

/// Testo corrente.
TextStyle siteBody(
  double size, {
  Color? color,
  FontWeight weight = FontWeight.w400,
  double height = 1.65,
}) => GoogleFonts.manrope(
  fontSize: size,
  fontWeight: weight,
  color: color ?? Site.ink,
  height: height,
);

ThemeData siteThemeData() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: Site.ink,
      onPrimary: Colors.white,
      secondary: Site.accent,
      tertiary: Site.accent,
      surface: Site.paper,
      onSurface: Site.ink,
    ),
    scaffoldBackgroundColor: Site.paper,
  );
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: c, width: w),
  );
  return base.copyWith(
    textTheme: GoogleFonts.manropeTextTheme(base.textTheme),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Site.ink,
      selectionColor: Site.accent.withValues(alpha: 0.33),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: b(const Color(0xFFD5D2CC)),
      enabledBorder: b(const Color(0xFFD5D2CC)),
      focusedBorder: b(Site.ink, 1.5),
      errorBorder: b(const Color(0xFFB3261E)),
      focusedErrorBorder: b(const Color(0xFFB3261E), 1.5),
      labelStyle: GoogleFonts.manrope(color: Site.muted),
      floatingLabelStyle: GoogleFonts.manrope(color: Site.ink),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Site.ink : null,
      ),
    ),
  );
}

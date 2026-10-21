import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../theme/app_theme.dart';
import '../theme/site_theme.dart';

/// Apre un indirizzo (sito, telefono, email, WhatsApp) in una nuova scheda.
Future<void> openUrl(String url) async {
  if (url.trim().isEmpty) return;
  await launchUrl(Uri.parse(url.trim()), webOnlyWindowName: '_blank');
}

/// Solo cifre e "+", per i link tel: e WhatsApp.
String phoneDigits(String phone) => phone.replaceAll(RegExp(r'[^0-9+]'), '');

// ------------------------------------------------------------------ immagini

final _dataCache = <String, Uint8List>{};

/// Decodifica una foto caricata; null se il dato è danneggiato.
Uint8List? _decode(String url) {
  final hit = _dataCache[url];
  if (hit != null) return hit;
  try {
    return _dataCache[url] = base64Decode(url.substring(url.indexOf(',') + 1));
  } on FormatException {
    return null;
  }
}

/// Le foto di Unsplash si possono chiedere alla larghezza esatta che serve.
String _withWidth(String url, int w) {
  if (!url.contains('images.unsplash.com')) return url;
  return url.contains(RegExp(r'[?&]w=\d+'))
      ? url.replaceFirstMapped(RegExp(r'([?&])w=\d+'), (m) => '${m[1]}w=$w')
      : '$url${url.contains('?') ? '&' : '?'}w=$w';
}

/// Mostra un'immagine da URL web oppure da un caricamento locale (data URL).
class PhotoImage extends StatelessWidget {
  const PhotoImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.dark = false,
  });

  final String url;
  final BoxFit fit;
  final Alignment alignment;

  /// Fondo scuro durante il caricamento (foto su sezioni scure).
  final bool dark;

  Color get _bg => dark ? Site.steel : Palette.linen;

  Widget _placeholder() => ColoredBox(
    color: _bg,
    child: Center(
      child: Icon(
        Icons.apartment_rounded,
        color: dark ? Site.mutedDark : Palette.ash,
        size: 28,
      ),
    ),
  );

  /// Larghezze a "gradini": evitano di riscaricare la foto a ogni piccolo
  /// ridimensionamento della finestra.
  static const _steps = [480, 800, 1200, 1600, 2000, 2600];

  Widget _network(String src) => Image.network(
    src,
    fit: fit,
    alignment: alignment,
    gaplessPlayback: true,
    filterQuality: FilterQuality.medium,
    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
    frameBuilder: (context, child, frame, sync) {
      if (sync) return child;
      // Durante il caricamento: solo il colore di fondo, poi dissolvenza.
      return ColoredBox(
        color: fit == BoxFit.contain ? Colors.transparent : _bg,
        child: AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOut,
          child: child,
        ),
      );
    },
    errorBuilder: (context, _, _) => _placeholder(),
  );

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return _placeholder();
    if (url.startsWith('data:')) {
      final bytes = _decode(url);
      if (bytes == null) return _placeholder();
      return Image.memory(
        bytes,
        fit: fit,
        alignment: alignment,
        gaplessPlayback: true,
        errorBuilder: (context, _, _) => _placeholder(),
      );
    }
    if (!url.contains('images.unsplash.com')) return _network(url);
    return LayoutBuilder(
      builder: (context, box) {
        if (!box.maxWidth.isFinite) return _network(url);
        final px = box.maxWidth * MediaQuery.devicePixelRatioOf(context);
        final w = _steps.firstWhere((s) => s >= px, orElse: () => _steps.last);
        return _network(_withWidth(url, w));
      },
    );
  }
}

/// Foto che scorre più lentamente della pagina (effetto profondità).
class ParallaxImage extends StatefulWidget {
  const ParallaxImage(
    this.url, {
    super.key,
    this.extent = 0.22,
    this.dark = false,
  });
  final String url;

  /// Quanto la foto è più alta del riquadro (0.22 = +22%).
  final double extent;
  final bool dark;

  @override
  State<ParallaxImage> createState() => _ParallaxImageState();
}

class _ParallaxImageState extends State<ParallaxImage> {
  @override
  Widget build(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context);
    final image = PhotoImage(widget.url, dark: widget.dark);
    if (scrollable == null) return image;
    return Flow(
      delegate: _ParallaxDelegate(
        scrollable: scrollable,
        itemContext: context,
        extent: widget.extent,
      ),
      children: [image],
    );
  }
}

class _ParallaxDelegate extends FlowDelegate {
  _ParallaxDelegate({
    required this.scrollable,
    required this.itemContext,
    required this.extent,
  }) : super(repaint: scrollable.position);

  final ScrollableState scrollable;
  final BuildContext itemContext;
  final double extent;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints c) =>
      BoxConstraints.tightFor(
        width: c.maxWidth,
        height: c.maxHeight * (1 + extent),
      );

  @override
  void paintChildren(FlowPaintingContext context) {
    final box = itemContext.findRenderObject();
    final view = scrollable.context.findRenderObject();
    if (box is! RenderBox || view is! RenderBox || !box.hasSize) {
      context.paintChild(0);
      return;
    }
    final center = box.localToGlobal(
      box.size.center(Offset.zero),
      ancestor: view,
    );
    final viewport = scrollable.position.viewportDimension;
    final t = (center.dy / math.max(viewport, 1)).clamp(0.0, 1.0);
    final child = context.getChildSize(0) ?? context.size;
    final dy = -(child.height - context.size.height) * (1 - t);
    context.paintChild(0, transform: Matrix4.translationValues(0, dy, 0));
  }

  @override
  bool shouldRepaint(_ParallaxDelegate old) =>
      scrollable != old.scrollable ||
      itemContext != old.itemContext ||
      extent != old.extent;
}

// -------------------------------------------------------------------- reveal

/// Esegue [onShow] la prima volta che il contenuto entra nella finestra.
class _OnceVisible extends StatefulWidget {
  const _OnceVisible({required this.child, required this.onShow});
  final Widget child;
  final VoidCallback onShow;

  @override
  State<_OnceVisible> createState() => _OnceVisibleState();
}

class _OnceVisibleState extends State<_OnceVisible> {
  final _key = UniqueKey();
  bool _done = false;

  @override
  Widget build(BuildContext context) => VisibilityDetector(
    key: _key,
    onVisibilityChanged: (info) {
      if (_done || info.visibleFraction < 0.05) return;
      _done = true;
      widget.onShow();
    },
    child: widget.child,
  );
}

/// Fa comparire il contenuto (dissolvenza + scorrimento) quando entra nella
/// finestra visibile.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 40,
    this.horizontal = false,
  });
  final Widget child;
  final Duration delay;
  final double offset;
  final bool horizontal;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> {
  bool _shown = false;

  void _show() {
    final wait = widget.delay + untilSplashEnds;
    Future.delayed(wait, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _OnceVisible(
      onShow: _show,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: _shown ? 1 : 0),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutQuart,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: widget.horizontal
                ? Offset((1 - t) * widget.offset, 0)
                : Offset(0, (1 - t) * widget.offset),
            child: child,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Titolo che sale riga per riga da dietro una "maschera".
class RevealTitle extends StatefulWidget {
  const RevealTitle(
    this.text, {
    super.key,
    required this.style,
    this.delay = Duration.zero,
    this.textAlign = TextAlign.start,
    this.accentLast = false,
  });
  final String text;
  final TextStyle style;
  final Duration delay;
  final TextAlign textAlign;

  /// L'ultima riga in ocra.
  final bool accentLast;

  @override
  State<RevealTitle> createState() => _RevealTitleState();
}

class _RevealTitleState extends State<RevealTitle> {
  bool _shown = false;

  void _show() {
    Future.delayed(widget.delay + untilSplashEnds, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.text.toUpperCase().split('\n');
    final align = switch (widget.textAlign) {
      TextAlign.center => CrossAxisAlignment.center,
      TextAlign.end || TextAlign.right => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.start,
    };
    return _OnceVisible(
      onShow: _show,
      child: Semantics(
        header: true,
        label: widget.text.replaceAll('\n', ' '),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: align,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < lines.length; i++)
                ClipRect(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _shown ? 1 : 0),
                    duration: Duration(milliseconds: 1000 + i * 160),
                    curve: Interval(
                      math.min(i * 0.12, 0.5),
                      1,
                      curve: Curves.easeOutQuart,
                    ),
                    builder: (context, t, child) => FractionalTranslation(
                      translation: Offset(0, 1.05 * (1 - t)),
                      child: child,
                    ),
                    child: Text(
                      lines[i],
                      textAlign: widget.textAlign,
                      style:
                          widget.accentLast &&
                              i == lines.length - 1 &&
                              lines.length > 1
                          ? widget.style.copyWith(color: Site.accent)
                          : widget.style,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Numero che "conta" fino al valore quando diventa visibile
/// (es. "420+" → 0…420 con il "+" fisso).
class CountUp extends StatefulWidget {
  const CountUp(this.value, {super.key, required this.style});
  final String value;
  final TextStyle style;

  @override
  State<CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<CountUp> {
  bool _shown = false;
  static final _re = RegExp(r'^(\D*)(\d[\d.]*)(.*)$');

  @override
  Widget build(BuildContext context) {
    final m = _re.firstMatch(widget.value.trim());
    if (m == null) return Text(widget.value, style: widget.style);
    final prefix = m[1]!;
    final digits = m[2]!;
    final suffix = m[3]!;
    final target = int.tryParse(digits.replaceAll('.', '')) ?? 0;
    final dots = digits.contains('.');
    String fmt(int n) {
      final s = '$n';
      if (!dots) return s;
      final b = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
        b.write(s[i]);
      }
      return b.toString();
    }

    return _OnceVisible(
      onShow: () => Future.delayed(untilSplashEnds, () {
        if (mounted) setState(() => _shown = true);
      }),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: _shown ? 1 : 0),
        duration: const Duration(milliseconds: 2200),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => Text(
          '$prefix${fmt((target * t).round())}$suffix',
          style: widget.style,
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- layout

/// Sezione a tutta larghezza con margini laterali fluidi e contenuto
/// centrato fino a [maxWidth].
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.child,
    this.color,
    this.top,
    this.bottom,
    this.maxWidth = 1440,
  });
  final Widget child;
  final Color? color;
  final double? top;
  final double? bottom;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final v = context.fluid(72, 140);
    return Container(
      color: color,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        top ?? v,
        context.gutter,
        bottom ?? v,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// Etichetta tecnica: "[02] —— PROGETTI".
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.number, this.dark = false});
  final String text;
  final String? number;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final c = dark ? Colors.white : Site.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (number != null) ...[
          Text(
            '[$number]',
            style: siteMono(12, color: dark ? Site.accent : Site.accentDeep),
          ),
          const SizedBox(width: 12),
        ],
        Container(width: 32, height: 1, color: c.withValues(alpha: 0.45)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(text.toUpperCase(), style: siteMono(12, color: c)),
        ),
      ],
    );
  }
}

/// Intestazione di una sezione: etichetta, titolo e testo (affiancati su
/// schermi larghi).
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.kicker,
    required this.title,
    this.number,
    this.text = '',
    this.dark = false,
    this.trailing,
  });
  final String kicker;
  final String title;
  final String? number;
  final String text;
  final bool dark;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final wide = context.w >= 980;
    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Reveal(
          child: Tag(kicker, number: number, dark: dark),
        ),
        SizedBox(height: context.fluid(18, 28)),
        RevealTitle(
          title,
          style: siteHead(
            context.fluid(44, 92),
            color: dark ? Colors.white : Site.ink,
          ),
          accentLast: true,
        ),
      ],
    );
    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (text.isNotEmpty)
          Reveal(
            delay: const Duration(milliseconds: 200),
            child: Text(
              text,
              style: siteBody(
                context.fluid(15.5, 17.5),
                color: dark ? Site.mutedDark : Site.muted,
              ),
            ),
          ),
        if (trailing != null) ...[
          if (text.isNotEmpty) const SizedBox(height: 26),
          Reveal(delay: const Duration(milliseconds: 300), child: trailing!),
        ],
      ],
    );
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          head,
          if (text.isNotEmpty || trailing != null) ...[
            const SizedBox(height: 22),
            side,
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(flex: 7, child: head),
        const SizedBox(width: 60),
        Expanded(flex: 4, child: side),
      ],
    );
  }
}

// ----------------------------------------------------------------- bottoni

enum ButtonKind { accent, dark, light }

/// Bottone squadrato del sito: al passaggio del mouse il colore "riempie"
/// il bottone da sinistra e la freccia avanza.
class SiteButton extends StatefulWidget {
  const SiteButton(
    this.text, {
    super.key,
    required this.onTap,
    this.kind = ButtonKind.accent,
    this.icon = Icons.arrow_forward_rounded,
    this.loading = false,
    this.big = false,
  });
  final String text;
  final VoidCallback? onTap;
  final ButtonKind kind;
  final IconData icon;
  final bool loading;
  final bool big;

  @override
  State<SiteButton> createState() => _SiteButtonState();
}

class _SiteButtonState extends State<SiteButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, fill, fillFg, border) = switch (widget.kind) {
      ButtonKind.accent => (
        Site.accent,
        Site.onAccent,
        Site.ink,
        Colors.white,
        Site.accent,
      ),
      ButtonKind.dark => (
        Colors.transparent,
        Site.ink,
        Site.ink,
        Colors.white,
        Site.ink,
      ),
      ButtonKind.light => (
        Colors.transparent,
        Colors.white,
        Colors.white,
        Site.ink,
        Colors.white,
      ),
    };
    final enabled = widget.onTap != null && !widget.loading;
    final color = _hover ? fillFg : fg;
    final h = widget.big ? 62.0 : 54.0;
    return Semantics(
      button: true,
      label: widget.text,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: enabled ? widget.onTap : null,
          // Il riempimento è un gradiente a taglio netto che avanza.
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: _hover ? 1 : 0),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => SizedBox(
              height: h,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [fill, fill, bg, bg],
                    stops: [0, t, t, 1],
                  ),
                  border: Border.all(color: border, width: 1.4),
                ),
                child: child,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: h * 0.45),
              child: Align(
                widthFactor: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: siteMono(
                          widget.big ? 13.5 : 12.5,
                          color: color,
                          weight: FontWeight.w600,
                        ),
                        child: Text(
                          widget.text.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    if (widget.loading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    else
                      AnimatedSlide(
                        offset: Offset(_hover ? 0.35 : 0, 0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        child: Icon(widget.icon, size: 18, color: color),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Link testuale con sottolineatura animata.
class HoverLink extends StatefulWidget {
  const HoverLink(
    this.text, {
    super.key,
    required this.onTap,
    required this.style,
    this.active = false,
    this.arrow = false,
    this.lineColor,
  });
  final String text;
  final VoidCallback onTap;
  final TextStyle style;
  final bool active;
  final bool arrow;
  final Color? lineColor;

  @override
  State<HoverLink> createState() => _HoverLinkState();
}

class _HoverLinkState extends State<HoverLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final on = _hover || widget.active;
    return Semantics(
      link: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(widget.text, style: widget.style)),
                    if (widget.arrow) ...[
                      const SizedBox(width: 8),
                      AnimatedSlide(
                        offset: Offset(_hover ? 0.3 : 0, 0),
                        duration: const Duration(milliseconds: 260),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: (widget.style.fontSize ?? 14) * 1.15,
                          color: widget.style.color,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  height: 1.5,
                  width: on ? 26 : 0,
                  color: widget.lineColor ?? Site.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Istante di avvio dell'app (impostato in `main`).
DateTime appStartedAt = DateTime.now();

/// Durata del logo d'apertura definito in `web/index.html` (dissolvenza
/// compresa): le animazioni d'ingresso partono dopo.
const splashMs = 1900;

/// Tempo che manca alla fine del logo d'apertura.
Duration get untilSplashEnds {
  final ms = splashMs - DateTime.now().difference(appStartedAt).inMilliseconds;
  return Duration(milliseconds: ms.clamp(0, splashMs));
}

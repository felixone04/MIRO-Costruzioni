import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/site_theme.dart';
import 'common.dart';

/// Il simbolo di prova: due tetti a capanna che disegnano una "M" dentro un
/// quadrato ocra, come un timbro di cantiere.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _MarkPainter(Site.accent, Site.onAccent)),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.bg, this.fg);
  final Color bg;
  final Color fg;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    canvas.drawRect(Offset.zero & s, Paint()..color = bg);
    final p = Paint()
      ..color = fg
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.085
      ..strokeJoin = StrokeJoin.miter
      ..strokeCap = StrokeCap.square;
    // Due capanne affiancate: la "M".
    final m = Path()
      ..moveTo(w * 0.18, w * 0.80)
      ..lineTo(w * 0.18, w * 0.46)
      ..lineTo(w * 0.34, w * 0.26)
      ..lineTo(w * 0.50, w * 0.46)
      ..lineTo(w * 0.66, w * 0.26)
      ..lineTo(w * 0.82, w * 0.46)
      ..lineTo(w * 0.82, w * 0.80);
    canvas.drawPath(m, p);
    // La linea di terra.
    canvas.drawLine(
      Offset(w * 0.12, w * 0.80),
      Offset(w * 0.88, w * 0.80),
      p..strokeWidth = w * 0.05,
    );
    // La "porta" centrale.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.455, w * 0.60, w * 0.09, w * 0.20),
      Paint()..color = fg,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.bg != bg || old.fg != fg;
}

/// Logo completo: simbolo + "M.I.R.O." + "COSTRUZIONI". Se nel gestionale è
/// stato caricato un logo, si usa quello.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 44, this.light = false});

  /// Altezza del simbolo.
  final double height;

  /// Scritte chiare (su fondo scuro o su foto).
  final bool light;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().content;
    if (c.logo.trim().isNotEmpty) {
      return SizedBox(
        height: height,
        width: height * 3.6,
        child: PhotoImage(
          c.logo,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
        ),
      );
    }
    final color = light ? Colors.white : Site.ink;
    // "M.I.R.O. Costruzioni" → sotto il nome breve va "COSTRUZIONI".
    final rest = c.companyName.replaceFirst(c.shortName, '').trim();
    return Semantics(
      label: c.companyName,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LogoMark(size: height),
            SizedBox(width: height * 0.3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.shortName.toUpperCase(),
                  style: siteHead(
                    height * 0.62,
                    color: color,
                    weight: FontWeight.w700,
                    height: 1,
                    spacing: height * 0.04,
                  ),
                ),
                if (rest.isNotEmpty) ...[
                  SizedBox(height: height * 0.05),
                  Text(
                    rest.toUpperCase(),
                    style: siteMono(
                      height * 0.2,
                      color: color.withValues(alpha: 0.75),
                      weight: FontWeight.w600,
                      spacing: 0.32,
                      height: 1,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

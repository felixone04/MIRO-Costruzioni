import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/site_theme.dart';
import 'common.dart';

/// Il simbolo di prova: due tetti a capanna che disegnano una "M" dentro un
/// quadrato dagli angoli morbidi.
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
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(w * 0.26)),
      Paint()..color = bg,
    );
    final p = Paint()
      ..color = fg
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    // Due capanne affiancate: la "M".
    final m = Path()
      ..moveTo(w * 0.22, w * 0.74)
      ..lineTo(w * 0.22, w * 0.47)
      ..lineTo(w * 0.36, w * 0.30)
      ..lineTo(w * 0.50, w * 0.47)
      ..lineTo(w * 0.64, w * 0.30)
      ..lineTo(w * 0.78, w * 0.47)
      ..lineTo(w * 0.78, w * 0.74);
    canvas.drawPath(m, p);
    // La porta centrale.
    canvas.drawLine(Offset(w * 0.5, w * 0.62), Offset(w * 0.5, w * 0.74), p);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.bg != bg || old.fg != fg;
}

/// Logo completo: simbolo + nome breve + resto della ragione sociale. Se nel
/// gestionale è stato caricato un logo, si usa quello.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 42, this.light = false});

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
    // "M.I.R.O. Costruzioni" → sotto il nome breve va "Costruzioni".
    final rest = c.companyName.replaceFirst(c.shortName, '').trim();
    return Semantics(
      label: c.companyName,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LogoMark(size: height),
            SizedBox(width: height * 0.28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.shortName,
                  style: siteHead(
                    height * 0.5,
                    color: color,
                    weight: FontWeight.w600,
                    height: 1,
                  ),
                ),
                if (rest.isNotEmpty) ...[
                  SizedBox(height: height * 0.06),
                  Text(
                    rest,
                    style: siteLabel(
                      height * 0.27,
                      color: color.withValues(alpha: 0.7),
                      weight: FontWeight.w500,
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

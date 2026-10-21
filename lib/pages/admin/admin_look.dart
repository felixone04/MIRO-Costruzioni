import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/site_theme.dart';
import 'admin_widgets.dart';

/// Indirizzo del sito con i parametri del link (routing con "#").
String _siteLink(Map<String, String> q) {
  final base = Uri.base;
  final origin = base.isScheme('http') || base.isScheme('https')
      ? '${base.origin}${base.path}'
      : base.toString();
  return '$origin#/?${Uri(queryParameters: q).query}';
}

class AdminLook extends StatelessWidget {
  const AdminLook({super.key});

  Future<void> _copy(BuildContext context, String link, String what) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) toast(context, '$what copiato: $link');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final look = s.look;

    void save(void Function(LookSettings l) change) {
      final l = LookSettings.fromJson(look.toJson());
      change(l);
      s.setLook(l);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminHeader(
          title: 'Stile e colori',
          subtitle:
              'Le stesse pagine con tonalità diverse. Scegli la tavolozza predefinita, quali proporre ai '
              'visitatori e chi vede il pulsante "Colori".',
        ),
        Panel(
          title: 'Pulsante "Colori" sul sito',
          subtitle: 'Il pulsante in basso a sinistra apre l\'elenco delle tavolozze e le applica al volo.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in SwitcherMode.values)
                    ChoiceChip(
                      label: Text(m.label),
                      selected: look.switcher == m,
                      onSelected: (_) => save((l) => l.switcher = m),
                    ),
                ],
              ),
              if (look.switcher == SwitcherMode.link) ...[
                const SizedBox(height: 16),
                Text(
                  'Il pulsante compare solo a chi apre il sito con questo link:',
                  style: body(14, color: Palette.stone),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _copy(
                    context,
                    _siteLink({'prova': '1'}),
                    'Link di prova',
                  ),
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: const Text('Copia il link di prova'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Panel(
          title: 'Tavolozze',
          subtitle:
              'La stella indica quella con cui si apre il sito. "Prova" la applica subito a questo browser; '
              'il link apre il sito già con quei colori (utile da mandare a un cliente).',
          child: LayoutBuilder(
            builder: (context, box) {
              final cols = box.maxWidth >= 900
                  ? 3
                  : (box.maxWidth >= 560 ? 2 : 1);
              const gap = 14.0;
              final w = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final t in builtInThemes)
                    SizedBox(
                      width: w,
                      child: _ThemeCard(
                        theme: t,
                        isDefault: t.id == s.defaultTheme.id,
                        isCurrent: t.id == s.currentTheme.id,
                        offered:
                            !look.hidden.contains(t.id) ||
                            t.id == s.defaultTheme.id,
                        onDefault: () => save((l) {
                          l.defaultTheme = t.id;
                          l.hidden.remove(t.id);
                        }),
                        onOffered: (v) => save((l) {
                          if (v) {
                            l.hidden.remove(t.id);
                          } else if (!l.hidden.contains(t.id)) {
                            l.hidden.add(t.id);
                          }
                        }),
                        onTry: () => s.selectTheme(t.id),
                        onLink: () => _copy(
                          context,
                          _siteLink({'tema': t.id}),
                          'Link per il cliente',
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.isDefault,
    required this.isCurrent,
    required this.offered,
    required this.onDefault,
    required this.onOffered,
    required this.onTry,
    required this.onLink,
  });
  final SiteTheme theme;
  final bool isDefault;
  final bool isCurrent;
  final bool offered;
  final VoidCallback onDefault;
  final ValueChanged<bool> onOffered;
  final VoidCallback onTry;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    // Material (non un riquadro colorato): l'interruttore ne usa la superficie.
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isCurrent ? t.accent : const Color(0xFFE2E0DB),
          width: isCurrent ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Preview(theme: t),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 4),
            child: Row(
              children: [
                Expanded(child: Text(t.name, style: display(24))),
                IconButton(
                  tooltip: isDefault ? 'Predefinita' : 'Rendi predefinita',
                  onPressed: isDefault ? null : onDefault,
                  icon: Icon(
                    isDefault ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isDefault ? const Color(0xFFD08A16) : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          SwitchListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            title: const Text('Proponi ai visitatori'),
            value: offered,
            onChanged: isDefault ? null : onOffered,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: onTry,
                  icon: Icon(
                    isCurrent ? Icons.check_rounded : Icons.visibility_outlined,
                    size: 18,
                  ),
                  label: Text(isCurrent ? 'In uso' : 'Prova'),
                ),
                TextButton.icon(
                  onPressed: onLink,
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: const Text('Copia link'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Miniatura del sito con i colori della tavolozza: barra scura, titolo con
/// l'ultima riga d'accento, fascia chiara e bottone.
class _Preview extends StatelessWidget {
  const _Preview({required this.theme});
  final SiteTheme theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    Widget bar(double w, Color c, [double h = 6]) =>
        Container(width: w, height: h, color: c);
    return AspectRatio(
      aspectRatio: 16 / 8,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: t.night,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 12, height: 12, color: t.accent),
                      const SizedBox(width: 6),
                      bar(34, Colors.white70, 5),
                    ],
                  ),
                  const Spacer(),
                  bar(90, Colors.white, 9),
                  const SizedBox(height: 5),
                  bar(70, t.accent, 9),
                  const SizedBox(height: 10),
                  bar(28, t.accent, 10),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              color: t.paper,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(30, t.accentDeep, 4),
                  const SizedBox(height: 8),
                  bar(56, t.ink, 7),
                  const SizedBox(height: 4),
                  bar(40, t.ink, 7),
                  const Spacer(),
                  Expanded(child: Container(color: t.concrete)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

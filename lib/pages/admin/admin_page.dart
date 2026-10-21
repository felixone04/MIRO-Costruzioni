import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/site_theme.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/common.dart';
import '../../widgets/site_scaffold.dart' show BlueprintGrid;
import 'admin_calendar.dart';
import 'admin_catalog.dart';
import 'admin_content.dart';
import 'admin_dashboard.dart';
import 'admin_look.dart';
import 'admin_projects.dart';
import 'admin_requests.dart';
import 'admin_settings.dart';
import 'admin_widgets.dart';

class _Section {
  const _Section(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

/// Voci del menu, raggruppate.
const _groups = <(String, List<_Section>)>[
  (
    'Attività',
    [
      _Section('panoramica', 'Panoramica', Icons.space_dashboard_outlined),
      _Section('richieste', 'Richieste', Icons.mark_email_unread_outlined),
      _Section('calendario', 'Calendario', Icons.calendar_month_outlined),
    ],
  ),
  (
    'Portfolio',
    [
      _Section('progetti', 'Progetti', Icons.apartment_outlined),
      _Section('servizi', 'Servizi', Icons.construction_outlined),
      _Section('testimonianze', 'Testimonianze', Icons.format_quote_outlined),
    ],
  ),
  (
    'Sito',
    [
      _Section('stile', 'Stile e colori', Icons.palette_outlined),
      _Section('home', 'Pagina Home', Icons.web_outlined),
      _Section('azienda', 'Azienda', Icons.history_edu_outlined),
      _Section('contatti', 'Identità e contatti', Icons.badge_outlined),
    ],
  ),
  ('Sistema', [_Section('impostazioni', 'Impostazioni', Icons.tune_rounded)]),
];

final _sections = [for (final g in _groups) ...g.$2];

class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.section});
  final String? section;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Theme(
      data: AppTheme.admin(),
      child: s.adminAuthenticated ? _Shell(section: section) : const _Login(),
    );
  }
}

// ======================================================================= LOGIN

class _Login extends StatefulWidget {
  const _Login();

  @override
  State<_Login> createState() => _LoginState();
}

class _LoginState extends State<_Login> {
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _show = false;
  bool _remember = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = context.read<AppState>();
    setState(() => _error = null);
    if (!s.hasAdminPassword) {
      if (_pw.text.length < 8) {
        setState(() => _error = 'La password deve avere almeno 8 caratteri.');
        return;
      }
      if (_pw.text != _pw2.text) {
        setState(() => _error = 'Le due password non coincidono.');
        return;
      }
      setState(() => _busy = true);
      await s.setAdminPassword(_pw.text, remember: _remember);
    } else {
      setState(() => _busy = true);
      final ok = await s.login(_pw.text, remember: _remember);
      if (!ok && mounted) {
        setState(() {
          _busy = false;
          _error = 'Password non corretta.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final create = !s.hasAdminPassword;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final photo = s.heroProjects.isNotEmpty
        ? s.heroProjects.first.coverUrl
        : s.content.ctaImage;

    final form = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              create ? 'PRIMO ACCESSO' : 'AREA RISERVATA',
              style: label(11, color: Palette.stone),
            ),
            const SizedBox(height: 18),
            Text(
              create ? 'SCEGLI LA\nPASSWORD.' : 'BENTORNATO.',
              style: display(wide ? 62 : 50, height: 0.95),
            ),
            const SizedBox(height: 12),
            Text(
              create
                  ? 'Servirà per entrare nella gestione del sito.'
                  : 'Inserisci la password per gestire il sito.',
              style: body(14.5, color: Palette.stone),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _pw,
              obscureText: !_show,
              autofocus: true,
              autofillHints: [
                create ? AutofillHints.newPassword : AutofillHints.password,
              ],
              onSubmitted: (_) => create ? null : _submit(),
              decoration: InputDecoration(
                labelText: create
                    ? 'Nuova password (min. 8 caratteri)'
                    : 'Password',
                suffixIcon: IconButton(
                  tooltip: _show ? 'Nascondi' : 'Mostra',
                  onPressed: () => setState(() => _show = !_show),
                  icon: Icon(
                    _show
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                ),
              ),
            ),
            if (create) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _pw2,
                obscureText: !_show,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Ripeti la password',
                ),
              ),
            ],
            const SizedBox(height: 6),
            CheckboxListTile(
              value: _remember,
              onChanged: (v) => setState(() => _remember = v ?? true),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('Ricordami su questo dispositivo', style: body(14)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(_error!, style: body(14, color: Palette.error)),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: const RoundedRectangleBorder(),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Palette.paper,
                      ),
                    )
                  : Text(
                      create ? 'CREA E ENTRA' : 'ENTRA',
                      style: label(12, color: Palette.paper),
                    ),
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Torna al sito'),
              ),
            ),
          ],
        ),
      ),
    );

    final poster = Stack(
      fit: StackFit.expand,
      children: [
        PhotoImage(photo, dark: true),
        ColoredBox(color: Site.night.withValues(alpha: 0.55)),
        const BlueprintGrid(opacity: 0.08),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandLogo(height: wide ? 64 : 44, light: true),
              SizedBox(height: wide ? 22 : 12),
              Text('AREA RISERVATA', style: label(10.5, color: Colors.white70)),
            ],
          ),
        ),
      ],
    );

    if (wide) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 6, child: poster),
            Expanded(
              flex: 5,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: form,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 220, child: poster),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 32, 22, 40),
              child: Center(child: form),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================== SHELL

class _Shell extends StatefulWidget {
  const _Shell({required this.section});
  final String? section;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String get _current => _sections.any((e) => e.id == widget.section)
      ? widget.section!
      : 'panoramica';

  Widget _page() {
    final page = switch (_current) {
      'richieste' => const AdminPageScroll(child: AdminRequests()),
      'calendario' => const AdminPageScroll(child: AdminCalendar()),
      'progetti' => const AdminPageScroll(child: AdminProjects()),
      'servizi' => const AdminPageScroll(child: AdminServices()),
      'testimonianze' => const AdminPageScroll(child: AdminTestimonials()),
      'stile' => const AdminPageScroll(child: AdminLook()),
      'home' => const AdminHomeEditor(),
      'azienda' => const AdminAboutEditor(),
      'contatti' => const AdminIdentityEditor(),
      'impostazioni' => const AdminPageScroll(child: AdminSettingsPage()),
      _ => const AdminPageScroll(child: AdminDashboard()),
    };
    return KeyedSubtree(key: ValueKey(_current), child: page);
  }

  void _select(String id) {
    _scaffoldKey.currentState?.closeDrawer();
    if (id != _current) context.go('/admin/$id');
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final nav = _NavPanel(current: _current, onSelect: _select);

    if (wide) {
      return Scaffold(
        key: _scaffoldKey,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 264, child: nav),
            Expanded(child: _page()),
          ],
        ),
      );
    }
    final current = _sections.firstWhere((e) => e.id == _current);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Site.night,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Text(
          current.label.toUpperCase(),
          style: display(26, color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Vedi il sito',
            onPressed: openSiteInNewTab,
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      drawer: Drawer(
        width: 290,
        backgroundColor: Site.night,
        shape: const RoundedRectangleBorder(),
        child: nav,
      ),
      body: _page(),
    );
  }
}

/// Menu laterale scuro, come la barra del sito.
class _NavPanel extends StatelessWidget {
  const _NavPanel({required this.current, required this.onSelect});
  final String current;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Material(
      color: Site.night,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 26),
              child: Align(
                alignment: Alignment.centerLeft,
                child: BrandLogo(height: 38, light: true),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (var g = 0; g < _groups.length; g++) ...[
                    Padding(
                      padding: EdgeInsets.fromLTRB(12, g == 0 ? 0 : 18, 12, 8),
                      child: Text(
                        _groups[g].$1.toUpperCase(),
                        style: siteMono(10, color: Site.mutedDark),
                      ),
                    ),
                    for (final sec in _groups[g].$2)
                      _NavItem(
                        section: sec,
                        selected: sec.id == current,
                        badge: sec.id == 'richieste' && s.newRequests > 0
                            ? s.newRequests
                            : null,
                        onTap: () => onSelect(sec.id),
                      ),
                  ],
                ],
              ),
            ),
            Container(height: 1, color: Site.lineDark),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              child: Column(
                children: [
                  _NavAction(
                    icon: Icons.open_in_new_rounded,
                    text: 'Vedi il sito',
                    onTap: openSiteInNewTab,
                  ),
                  _NavAction(
                    icon: Icons.logout_rounded,
                    text: 'Esci',
                    onTap: () async {
                      await context.read<AppState>().logout();
                      if (context.mounted) context.go('/admin');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.section,
    required this.selected,
    required this.onTap,
    this.badge,
  });
  final _Section section;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    final fg = sel || _hover ? Colors.white : Site.mutedDark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: sel
                  ? Colors.white.withValues(alpha: 0.08)
                  : (_hover ? Colors.white.withValues(alpha: 0.04) : null),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 3,
                  height: sel ? 18 : 0,
                  margin: const EdgeInsets.only(right: 10),
                  color: Site.accent,
                ),
                Icon(
                  widget.section.icon,
                  size: 19,
                  color: sel ? Site.accent : fg,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.section.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: body(
                      14,
                      color: fg,
                      weight: sel ? FontWeight.w600 : FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                ),
                if (widget.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    color: Site.accent,
                    child: Text(
                      '${widget.badge}',
                      style: body(
                        12,
                        color: Site.onAccent,
                        weight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavAction extends StatelessWidget {
  const _NavAction({
    required this.icon,
    required this.text,
    required this.onTap,
  });
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Site.mutedDark),
            const SizedBox(width: 12),
            Text(text, style: body(14, color: Site.mutedDark, height: 1.2)),
          ],
        ),
      ),
    );
  }
}

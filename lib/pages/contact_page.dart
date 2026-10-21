import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/site_theme.dart';
import '../widgets/common.dart';
import '../widgets/site_scaffold.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key, this.type, this.project, this.category});

  /// Precompilati dai link "Richiedi sopralluogo" di servizi e progetti.
  final String? type;
  final String? project;
  final String? category;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().content;
    final wide = context.w >= 1000;
    return SiteScaffold(
      current: '/contatti',
      children: [
        PageHero(
          kicker: 'Contatti',
          title: c.contactTitle,
          text: c.contactText,
          image: c.contactImage,
          height: context.screenH * 0.66 < 460 ? 460 : context.screenH * 0.66,
        ),
        Section(
          top: context.fluid(50, 100),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(flex: 4, child: _Info()),
                    const SizedBox(width: 80),
                    Expanded(
                      flex: 7,
                      child: _RequestForm(
                        type: type,
                        project: project,
                        category: category,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RequestForm(
                      type: type,
                      project: project,
                      category: category,
                    ),
                    const SizedBox(height: 60),
                    const _Info(),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().content.contacts;
    final items = [
      if (c.phone.isNotEmpty)
        (
          Icons.call_outlined,
          'Telefono',
          c.phone,
          'tel:${phoneDigits(c.phone)}',
        ),
      if (c.whatsapp.isNotEmpty)
        (
          Icons.chat_outlined,
          'WhatsApp',
          c.whatsapp,
          'https://wa.me/${phoneDigits(c.whatsapp).replaceAll('+', '')}',
        ),
      if (c.email.isNotEmpty)
        (Icons.mail_outline_rounded, 'Email', c.email, 'mailto:${c.email}'),
      if (c.pec.isNotEmpty)
        (Icons.verified_outlined, 'PEC', c.pec, 'mailto:${c.pec}'),
      if (c.address.isNotEmpty)
        (Icons.place_outlined, 'Sede', c.address, mapsUrl(c.address)),
      if (c.hours.isNotEmpty)
        (Icons.schedule_rounded, 'Orari ufficio', c.hours, ''),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Reveal(child: Tag('Dove trovarci', number: '01')),
        const SizedBox(height: 22),
        for (var i = 0; i < items.length; i++)
          Reveal(
            delay: Duration(milliseconds: 70 * i),
            child: _InfoRow(
              icon: items[i].$1,
              label: items[i].$2,
              value: items[i].$3,
              url: items[i].$4,
            ),
          ),
        if (c.address.isNotEmpty) ...[
          const SizedBox(height: 30),
          Reveal(
            child: SiteButton(
              'Apri in Google Maps',
              kind: ButtonKind.dark,
              icon: Icons.map_outlined,
              onTap: () => openUrl(mapsUrl(c.address)),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatefulWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.url,
  });
  final IconData icon;
  final String label;
  final String value;
  final String url;

  @override
  State<_InfoRow> createState() => _InfoRowState();
}

class _InfoRowState extends State<_InfoRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final link = widget.url.isNotEmpty;
    return MouseRegion(
      cursor: link ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: link ? () => openUrl(widget.url) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Site.line)),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 46,
                height: 46,
                color: _hover && link ? Site.accent : Site.concrete,
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: _hover && link ? Site.onAccent : Site.ink,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label.toUpperCase(),
                      style: siteMono(10.5, color: Site.muted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.value,
                      style: siteBody(16, weight: FontWeight.w600, height: 1.4),
                    ),
                  ],
                ),
              ),
              if (link)
                AnimatedSlide(
                  offset: Offset(_hover ? 0.2 : 0, 0),
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    size: 18,
                    color: Site.muted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================== MODULO

class _RequestForm extends StatefulWidget {
  const _RequestForm({this.type, this.project, this.category});
  final String? type;
  final String? project;
  final String? category;

  @override
  State<_RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<_RequestForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  final _area = TextEditingController();
  late final _message = TextEditingController(
    text: widget.project == null
        ? ''
        : 'Ho visto il progetto "${widget.project}" e vorrei realizzare qualcosa di simile.',
  );
  String _type = '';
  String _timing = '';
  bool _privacy = false;
  bool _privacyError = false;
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    final types = context.read<AppState>().content.requestTypes;
    // Il servizio o la categoria del progetto scelgono il tipo d'intervento.
    final hint = (widget.type ?? widget.category ?? '').toLowerCase();
    if (hint.isNotEmpty) {
      // Basta una parola in comune, al singolare o al plurale
      // ("Ristrutturazioni" → "Ristrutturazione").
      bool similar(String t) => t
          .toLowerCase()
          .split(RegExp(r'[^a-zàèéìòù]+'))
          .where((w) => w.length >= 5)
          .any((w) => hint.contains(w.substring(0, w.length - 1)));
      _type = types.firstWhere(similar, orElse: () => '');
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _city, _area, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = _form.currentState!.validate();
    setState(() => _privacyError = !_privacy);
    if (!ok || !_privacy) return;
    setState(() => _sending = true);
    await context.read<AppState>().addRequest(
      ContactRequest(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        city: _city.text.trim(),
        type: _type,
        timing: _timing,
        area: _area.text.trim(),
        message: _message.text.trim(),
        projectRef: widget.project ?? '',
      ),
    );
    // Una breve attesa rende percepibile l'invio.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _sending = false;
        _sent = true;
      });
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().content;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(a),
          child: child,
        ),
      ),
      child: _sent ? _thanks() : _formView(c),
    );
  }

  Widget _thanks() => Container(
    key: const ValueKey('sent'),
    width: double.infinity,
    padding: EdgeInsets.all(context.fluid(28, 56)),
    color: Site.night,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          builder: (context, t, child) =>
              Transform.scale(scale: t, child: child),
          child: Container(
            width: 64,
            height: 64,
            color: Site.accent,
            child: Icon(Icons.check_rounded, size: 34, color: Site.onAccent),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'RICHIESTA INVIATA.',
          style: siteHead(context.fluid(40, 64), color: Colors.white),
        ),
        const SizedBox(height: 14),
        Text(
          'Grazie ${_name.text.trim().split(' ').first}: ti ricontatteremo entro due '
          'giorni lavorativi per fissare il sopralluogo.',
          style: siteBody(17, color: Site.mutedDark),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SiteButton(
              'Guarda i progetti',
              onTap: () => context.go('/progetti'),
            ),
            SiteButton(
              'Nuova richiesta',
              kind: ButtonKind.light,
              icon: Icons.refresh_rounded,
              onTap: () => setState(() {
                _sent = false;
                _privacy = false;
                for (final ctl in [
                  _name,
                  _phone,
                  _email,
                  _city,
                  _area,
                  _message,
                ]) {
                  ctl.clear();
                }
                _type = '';
                _timing = '';
              }),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _formView(SiteContent c) {
    const gap = SizedBox(height: 16);
    final two = context.w >= 640;
    Widget pair(Widget a, Widget b) => two
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: 16),
              Expanded(child: b),
            ],
          )
        : Column(children: [a, gap, b]);

    return Form(
      key: _form,
      child: AutofillGroup(
        child: Column(
          key: const ValueKey('form'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Reveal(child: Tag('Richiedi un sopralluogo', number: '02')),
            const SizedBox(height: 22),
            if (widget.project != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                color: Site.concrete,
                child: Row(
                  children: [
                    const Icon(Icons.apartment_rounded, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Richiesta a partire dal progetto “${widget.project}”',
                        style: siteBody(14.5, weight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            Reveal(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DI COSA HAI BISOGNO?',
                    style: siteMono(11.5, color: Site.muted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in c.requestTypes)
                        _Choice(
                          label: t,
                          selected: _type == t,
                          onTap: () =>
                              setState(() => _type = _type == t ? '' : t),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Reveal(
              child: Column(
                children: [
                  pair(
                    TextFormField(
                      controller: _name,
                      autofillHints: const [AutofillHints.name],
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome e cognome *',
                      ),
                      validator: _required,
                    ),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: const InputDecoration(
                        labelText: 'Telefono *',
                      ),
                      validator: (v) {
                        if (_required(v) != null) return 'Campo obbligatorio';
                        return phoneDigits(v!).replaceAll('+', '').length < 6
                            ? 'Numero non valido'
                            : null;
                      },
                    ),
                  ),
                  gap,
                  pair(
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email *'),
                      validator: (v) {
                        if (_required(v) != null) return 'Campo obbligatorio';
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(v!.trim())
                            ? null
                            : 'Email non valida';
                      },
                    ),
                    TextFormField(
                      controller: _city,
                      decoration: const InputDecoration(
                        labelText: 'Località dell\'intervento',
                      ),
                    ),
                  ),
                  gap,
                  pair(
                    TextFormField(
                      controller: _area,
                      decoration: const InputDecoration(
                        labelText: 'Superficie indicativa (m²)',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _timing.isEmpty ? null : _timing,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Quando vorresti iniziare?',
                      ),
                      items: [
                        for (final t in c.timings)
                          DropdownMenuItem(value: t, child: Text(t)),
                      ],
                      onChanged: (v) => setState(() => _timing = v ?? ''),
                    ),
                  ),
                  gap,
                  TextFormField(
                    controller: _message,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Raccontaci il progetto',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Reveal(
              child: CheckboxListTile(
                value: _privacy,
                onChanged: (v) => setState(() {
                  _privacy = v ?? false;
                  if (_privacy) _privacyError = false;
                }),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Acconsento al trattamento dei dati per essere ricontattato (GDPR). *',
                  style: siteBody(14, height: 1.4),
                ),
                subtitle: _privacyError
                    ? Text(
                        'Serve il consenso per inviare la richiesta.',
                        style: siteBody(13, color: const Color(0xFFB3261E)),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 18),
            Reveal(
              child: SiteButton(
                'Invia richiesta',
                big: true,
                loading: _sending,
                onTap: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? Site.accent : Colors.white,
            border: Border.all(
              color: selected ? Site.accent : const Color(0xFFD5D2CC),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Site.onAccent,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Text(
                label,
                style: siteBody(
                  14,
                  weight: FontWeight.w600,
                  height: 1.2,
                  color: selected ? Site.onAccent : Site.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

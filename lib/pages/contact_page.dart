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
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().content;
    final wide = context.w >= 1000;
    return SiteScaffold(
      current: '/contatti',
      children: [
        PageHeader(
          kicker: 'Contatti',
          title: c.contactTitle,
          text: c.contactText,
        ),
        Section(
          top: 0,
          child: wide
              ? const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: _Info()),
                    SizedBox(width: 70),
                    Expanded(flex: 7, child: _RequestForm()),
                  ],
                )
              : const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [_RequestForm(), SizedBox(height: 50), _Info()],
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
    return Container(
      padding: EdgeInsets.all(context.fluid(22, 32)),
      decoration: BoxDecoration(
        color: Site.concrete,
        borderRadius: BorderRadius.circular(Radii.photo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        ],
      ),
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
    final on = _hover && link;
    return MouseRegion(
      cursor: link ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: link ? () => openUrl(widget.url) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: on ? Site.accent : Site.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 19,
                  color: on ? Site.onAccent : Site.ink,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: siteBody(12.5, color: Site.muted, height: 1.3),
                    ),
                    Text(
                      widget.value,
                      style: siteBody(
                        15.5,
                        weight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
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
  const _RequestForm();

  @override
  State<_RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<_RequestForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  final _message = TextEditingController();
  String _type = '';
  bool _privacy = false;
  bool _privacyError = false;
  bool _sending = false;
  bool _sent = false;

  List<TextEditingController> get _all => [
    _name,
    _phone,
    _email,
    _city,
    _message,
  ];

  @override
  void dispose() {
    for (final c in _all) {
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
        message: _message.text.trim(),
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
    padding: EdgeInsets.all(context.fluid(28, 52)),
    decoration: BoxDecoration(
      color: Site.concrete,
      borderRadius: BorderRadius.circular(Radii.photo),
    ),
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Site.accent,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 30, color: Site.onAccent),
          ),
        ),
        const SizedBox(height: 24),
        Text('Richiesta inviata', style: siteHead(context.fluid(34, 52))),
        const SizedBox(height: 12),
        Text(
          'Grazie ${_name.text.trim().split(' ').first}, ti richiamiamo '
          'entro due giorni lavorativi.',
          style: siteBody(17, color: Site.muted),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SiteButton(
              'Guarda i progetti',
              onTap: () => context.go('/progetti'),
            ),
            SiteButton(
              'Nuovo messaggio',
              kind: ButtonKind.outline,
              icon: Icons.refresh_rounded,
              onTap: () => setState(() {
                _sent = false;
                _privacy = false;
                for (final ctl in _all) {
                  ctl.clear();
                }
                _type = '';
              }),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _formView(SiteContent c) {
    const gap = SizedBox(height: 14);
    final two = context.w >= 640;
    Widget pair(Widget a, Widget b) => two
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: 14),
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
            Reveal(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Di cosa si tratta?',
                    style: siteBody(15, color: Site.muted),
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
            const SizedBox(height: 24),
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
                      decoration: const InputDecoration(labelText: 'Comune'),
                    ),
                  ),
                  gap,
                  TextFormField(
                    controller: _message,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Raccontaci cosa hai in mente',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
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
                  'Acconsento al trattamento dei dati per essere ricontattato. *',
                  style: siteBody(14, height: 1.4),
                ),
                subtitle: _privacyError
                    ? Text(
                        'Serve il consenso per inviare il messaggio.',
                        style: siteBody(13, color: const Color(0xFFC0392B)),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Reveal(
              child: SiteButton(
                'Invia',
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Site.accent : Colors.transparent,
            border: Border.all(
              color: selected ? Site.accent : Site.line,
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            style: siteBody(
              14.5,
              weight: FontWeight.w500,
              height: 1.2,
              color: selected ? Site.onAccent : Site.ink,
            ),
          ),
        ),
      ),
    ),
  );
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/download.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/site_theme.dart';
import '../widgets/common.dart';
import '../widgets/lightbox.dart';
import '../widgets/site_scaffold.dart';

/// Area personale del cliente: accesso, elenco dei suoi lavori e scheda di
/// ogni cantiere. Gli account si creano solo dal gestionale.
class ClientAreaPage extends StatelessWidget {
  const ClientAreaPage({super.key, this.worksiteId});
  final String? worksiteId;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final client = s.currentClient;
    final List<Widget> body;
    if (client == null) {
      body = const [_Login()];
    } else {
      final w = s.worksiteById(worksiteId);
      body = w != null && w.clientId == client.id
          ? [_WorksiteView(worksite: w)]
          : [_Dashboard(client: client)];
    }
    return SiteScaffold(current: '/area-clienti', children: body);
  }
}

String _date(DateTime d) => DateFormat('d MMMM y', 'it_IT').format(d);

String _size(int bytes) {
  if (bytes <= 0) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

// ===================================================================== LOGIN

class _Login extends StatefulWidget {
  const _Login();

  @override
  State<_Login> createState() => _LoginState();
}

class _LoginState extends State<_Login> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _show = false;
  bool _remember = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _pw.text.isEmpty) {
      setState(() => _error = 'Inserisci email e password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await context.read<AppState>().clientLogin(
      _email.text,
      _pw.text,
      remember: _remember,
    );
    if (mounted && err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Material (non un riquadro colorato): la casella "Ricordami" ne usa la
    // superficie.
    final form = Material(
      color: Site.concrete,
      borderRadius: BorderRadius.circular(Radii.photo),
      child: Padding(
        padding: EdgeInsets.all(context.fluid(24, 40)),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pw,
                obscureText: !_show,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    tooltip: _show ? 'Nascondi' : 'Mostra',
                    onPressed: () => setState(() => _show = !_show),
                    icon: Icon(
                      _show
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: Site.muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              CheckboxListTile(
                value: _remember,
                onChanged: (v) => setState(() => _remember = v ?? true),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  'Ricordami su questo dispositivo',
                  style: siteBody(14, height: 1.3),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: siteBody(14, color: const Color(0xFFC0392B)),
                  ),
                ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: SiteButton(
                  'Entra',
                  big: true,
                  loading: _busy,
                  icon: Icons.lock_open_rounded,
                  onTap: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final note = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Non hai le credenziali?', style: siteHead(26)),
        const SizedBox(height: 10),
        Text(
          'L\'accesso è riservato a chi ha un lavoro in corso con noi: '
          'quando apriamo il cantiere ti mandiamo email e password. '
          'Se le hai perse, chiamaci o scrivici.',
          style: siteBody(16, color: Site.muted),
        ),
        const SizedBox(height: 16),
        HoverLink(
          'Contattaci',
          arrow: true,
          onTap: () => context.go('/contatti'),
          style: siteLabel(15, color: Site.accentDeep),
        ),
      ],
    );
    final wide = context.w >= 900;
    return Column(
      children: [
        const PageHeader(
          kicker: 'Area clienti',
          title: 'Il tuo\ncantiere.',
          text:
              'Segui i lavori da vicino: avanzamento, foto, documenti da '
              'scaricare e un filo diretto con noi.',
        ),
        Section(
          top: 0,
          child: Reveal(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: form),
                      const SizedBox(width: 70),
                      Expanded(flex: 4, child: note),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [form, const SizedBox(height: 40), note],
                  ),
          ),
        ),
      ],
    );
  }
}

// ================================================================= DASHBOARD

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.client});
  final ClientAccount client;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.worksitesOf(client.id);
    // Il nome intero: "Famiglia Lorusso" o "Rossi Srl" non si accorciano bene.
    final first = client.name.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          kicker: 'Area clienti',
          title: 'Ciao,\n$first.',
          text: list.isEmpty ? 'Qui troverai i tuoi lavori appena li apriamo.' : 'Ecco i tuoi lavori: tocca un cantiere per vedere come procede.',
          bottom: _AccountActions(),
        ),
        Section(
          top: 0,
          child: list.isEmpty
              ? const SizedBox.shrink()
              : LayoutBuilder(
                  builder: (context, box) {
                    final cols = box.maxWidth >= 900 ? 2 : 1;
                    final gap = context.fluid(16, 28);
                    final w = (box.maxWidth - gap * (cols - 1)) / cols;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (var i = 0; i < list.length; i++)
                          SizedBox(
                            width: w,
                            child: Reveal(
                              delay: Duration(milliseconds: 100 * (i % cols)),
                              child: _WorksiteCard(worksite: list[i]),
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

class _AccountActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final style = siteLabel(14.5, color: Site.muted);
    return Wrap(
      spacing: 24,
      children: [
        HoverLink(
          'Cambia password',
          onTap: () => showDialog(
            context: context,
            builder: (_) => const _PasswordDialog(),
          ),
          style: style,
        ),
        HoverLink(
          'Esci',
          onTap: () async {
            await s.clientLogout();
            if (context.mounted) context.go('/area-clienti');
          },
          style: style,
        ),
      ],
    );
  }
}

class _WorksiteCard extends StatefulWidget {
  const _WorksiteCard({required this.worksite});
  final Worksite worksite;

  @override
  State<_WorksiteCard> createState() => _WorksiteCardState();
}

class _WorksiteCardState extends State<_WorksiteCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final w = widget.worksite;
    final unread = w.unreadForClient;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.go('/area-clienti/${w.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: Site.surface,
            borderRadius: BorderRadius.circular(Radii.photo),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedScale(
                      scale: _hover ? 1.05 : 1,
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      child: PhotoImage(w.cover),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 14,
                        top: 14,
                        child: _Pill(
                          unread == 1
                              ? '1 messaggio nuovo'
                              : '$unread messaggi nuovi',
                          color: Site.accent,
                          onColor: Site.onAccent,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.title, style: siteHead(26, height: 1.15)),
                    const SizedBox(height: 4),
                    Text(
                      [
                        w.address,
                        w.status.label,
                      ].where((e) => e.isNotEmpty).join(' · '),
                      style: siteBody(14, color: Site.muted, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    _ProgressBar(value: w.progress),
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

/// Barra d'avanzamento che si riempie quando compare.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, this.big = false});
  final int value;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final h = big ? 14.0 : 8.0;
    return Reveal(
      offset: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value / 100),
        duration: const Duration(milliseconds: 1600),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => Row(
          children: [
            Expanded(
              child: Container(
                height: h,
                decoration: BoxDecoration(
                  color: Site.line,
                  borderRadius: BorderRadius.circular(h),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: t.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Site.accent,
                      borderRadius: BorderRadius.circular(h),
                    ),
                  ),
                ),
              ),
            ),
            if (!big) ...[
              const SizedBox(width: 12),
              Text(
                '${(t * 100).round()}%',
                style: siteLabel(14, color: Site.accentDeep),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {required this.color, required this.onColor});
  final String text;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(text, style: siteLabel(12.5, color: onColor, height: 1.2)),
  );
}

// ================================================================== CANTIERE

class _WorksiteView extends StatefulWidget {
  const _WorksiteView({required this.worksite});
  final Worksite worksite;

  @override
  State<_WorksiteView> createState() => _WorksiteViewState();
}

class _WorksiteViewState extends State<_WorksiteView> {
  @override
  void initState() {
    super.initState();
    // Aprendo il cantiere i messaggi dell'impresa risultano letti.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().markRead(widget.worksite, byClient: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.worksite;
    final wide = context.w >= 980;
    final updates = [...w.updates]..sort((a, b) => b.date.compareTo(a.date));
    final files = [...w.files]
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

    final progress = Container(
      padding: EdgeInsets.all(context.fluid(24, 40)),
      decoration: BoxDecoration(
        color: Site.concrete,
        borderRadius: BorderRadius.circular(Radii.photo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 16,
            runSpacing: 6,
            children: [
              CountUp(
                '${w.progress}%',
                style: siteHead(
                  context.fluid(64, 96),
                  color: Site.accent,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  w.phase.isEmpty ? w.status.label : 'Fase attuale: ${w.phase}',
                  style: siteBody(16, color: Site.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ProgressBar(value: w.progress, big: true),
          const SizedBox(height: 18),
          Wrap(
            spacing: 28,
            runSpacing: 8,
            children: [
              for (final (k, v) in [
                ('Stato', w.status.label),
                ('Inizio', w.start),
                ('Fine prevista', w.end),
              ])
                if (v.isNotEmpty)
                  RichText(
                    text: TextSpan(
                      style: siteBody(14.5, color: Site.muted),
                      children: [
                        TextSpan(text: '$k  '),
                        TextSpan(
                          text: v,
                          style: siteBody(14.5, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ],
      ),
    );

    final steps = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < w.steps.length; i++)
          Reveal(
            delay: Duration(milliseconds: 60 * i),
            child: _StepRow(step: w.steps[i], last: i == w.steps.length - 1),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          kicker: w.address.isEmpty ? 'Il tuo cantiere' : w.address,
          title: w.title,
          text: w.description,
          bottom: HoverLink(
            'I tuoi lavori',
            onTap: () => context.go('/area-clienti'),
            style: siteLabel(14.5, color: Site.muted),
          ),
        ),
        Section(
          top: 0,
          bottom: context.fluid(40, 70),
          child: Reveal(child: progress),
        ),
        if (w.steps.isNotEmpty || w.cover.isNotEmpty)
          Section(
            top: 0,
            bottom: context.fluid(40, 70),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _Block(title: 'Le fasi', child: steps),
                      ),
                      const SizedBox(width: 60),
                      if (w.cover.isNotEmpty)
                        Expanded(
                          flex: 6,
                          child: Reveal(
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: Rounded(child: PhotoImage(w.cover)),
                            ),
                          ),
                        ),
                    ],
                  )
                : _Block(title: 'Le fasi', child: steps),
          ),
        Section(
          top: 0,
          bottom: context.fluid(40, 70),
          child: _Block(
            title: 'Aggiornamenti',
            child: updates.isEmpty
                ? Text(
                    'Ancora nessun aggiornamento: arriveranno qui con foto e note.',
                    style: siteBody(15.5, color: Site.muted),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final u in updates)
                        Reveal(child: _UpdateCard(update: u)),
                    ],
                  ),
          ),
        ),
        Section(
          top: 0,
          bottom: context.fluid(40, 70),
          child: _Block(
            title: 'Documenti',
            child: files.isEmpty
                ? Text(
                    'Nessun documento per ora.',
                    style: siteBody(15.5, color: Site.muted),
                  )
                : Column(
                    children: [
                      for (final f in files) Reveal(child: _FileRow(file: f)),
                    ],
                  ),
          ),
        ),
        Section(
          top: 0,
          child: _Block(
            title: 'Messaggi',
            child: _Messages(worksite: w),
          ),
        ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Reveal(child: Kicker(title)),
      const SizedBox(height: 18),
      child,
    ],
  );
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.last});
  final WorksiteStep step;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: step.done ? Site.accent : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: step.done ? Site.accent : Site.line,
                      width: 2,
                    ),
                  ),
                  child: step.done
                      ? Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Site.onAccent,
                        )
                      : null,
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: step.done ? Site.accent : Site.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: siteHead(
                      21,
                      height: 1.2,
                      color: step.done ? Site.ink : Site.muted,
                    ),
                  ),
                  if (step.date.isNotEmpty)
                    Text(
                      step.date,
                      style: siteBody(13.5, color: Site.muted, height: 1.4),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.update});
  final WorksiteUpdate update;

  @override
  Widget build(BuildContext context) {
    final u = update;
    final photos = [
      for (final p in u.photos) ProjectPhoto(url: p, caption: u.title),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(context.fluid(18, 26)),
      decoration: BoxDecoration(
        color: Site.surface,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _date(u.date),
            style: siteBody(13, color: Site.muted, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(u.title, style: siteHead(24, height: 1.2)),
          if (u.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(u.text, style: siteBody(15.5, color: Site.muted)),
          ],
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < photos.length; i++)
                  MouseRegion(
                    cursor: SystemMouseCursors.zoomIn,
                    child: GestureDetector(
                      onTap: () => openLightbox(context, photos, i),
                      child: SizedBox(
                        width: context.isPhone ? 130 : 180,
                        height: context.isPhone ? 96 : 130,
                        child: Rounded(
                          radius: 14,
                          child: PhotoImage(photos[i].url),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Scarica un documento: i file caricati sono incorporati nei dati, quelli
/// online si aprono in una nuova scheda.
Future<void> downloadFile(WorksiteFile f) async {
  if (f.data.startsWith('data:')) {
    final bytes = base64Decode(f.data.substring(f.data.indexOf(',') + 1));
    await saveBytes(bytes, f.name, f.mime);
  } else {
    await openUrl(f.data);
  }
}

IconData fileIcon(String name) {
  final ext = name.split('.').last.toLowerCase();
  return switch (ext) {
    'pdf' => Icons.picture_as_pdf_outlined,
    'jpg' || 'jpeg' || 'png' || 'webp' || 'heic' => Icons.image_outlined,
    'doc' || 'docx' || 'txt' || 'rtf' || 'odt' => Icons.description_outlined,
    'xls' || 'xlsx' || 'csv' => Icons.table_chart_outlined,
    'dwg' || 'dxf' => Icons.architecture_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}

class _FileRow extends StatefulWidget {
  const _FileRow({required this.file});
  final WorksiteFile file;

  @override
  State<_FileRow> createState() => _FileRowState();
}

class _FileRowState extends State<_FileRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.file;
    final meta = [
      _date(f.uploadedAt),
      _size(f.size),
    ].where((e) => e.isNotEmpty).join(' · ');
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => downloadFile(f),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hover ? Site.concrete : Site.surface,
            borderRadius: BorderRadius.circular(Radii.card),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Site.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(fileIcon(f.name), color: Site.accentDeep),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: siteBody(
                        15.5,
                        weight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    if (f.note.isNotEmpty)
                      Text(
                        f.note,
                        style: siteBody(14, color: Site.muted, height: 1.4),
                      ),
                    Text(
                      meta,
                      style: siteBody(12.5, color: Site.muted, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _hover ? Site.accent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: _hover ? Site.accent : Site.line),
                ),
                child: Icon(
                  Icons.download_rounded,
                  size: 19,
                  color: _hover ? Site.onAccent : Site.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Il canale con l'impresa: messaggi a nuvoletta e casella per scrivere.
class _Messages extends StatefulWidget {
  const _Messages({required this.worksite});
  final Worksite worksite;

  @override
  State<_Messages> createState() => _MessagesState();
}

class _MessagesState extends State<_Messages> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _c.text.trim();
    if (text.isEmpty) return;
    _c.clear();
    await context.read<AppState>().sendMessage(
      widget.worksite,
      text,
      fromClient: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final msgs = [...widget.worksite.messages]
      ..sort((a, b) => a.date.compareTo(b.date));
    return Container(
      padding: EdgeInsets.all(context.fluid(16, 26)),
      decoration: BoxDecoration(
        color: Site.concrete,
        borderRadius: BorderRadius.circular(Radii.photo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (msgs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Scrivici qui per domande, appuntamenti o modifiche: ti '
                'rispondiamo nel giro di poco.',
                style: siteBody(15, color: Site.muted),
              ),
            ),
          for (final m in msgs) MessageBubble(message: m, mine: m.fromClient),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _c,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Scrivi un messaggio…',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Semantics(
                button: true,
                label: 'Invia messaggio',
                child: Material(
                  color: Site.accent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _send,
                    child: SizedBox(
                      width: 54,
                      height: 54,
                      child: Icon(Icons.send_rounded, color: Site.onAccent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Una nuvoletta della conversazione (usata anche nel gestionale).
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.mine,
    this.otherName = 'M.I.R.O. Costruzioni',
  });
  final WorksiteMessage message;
  final bool mine;
  final String otherName;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final when = DateFormat("d MMM 'alle' HH:mm", 'it_IT').format(m.date);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.isPhone ? 280 : 520),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          decoration: BoxDecoration(
            color: mine ? Site.accent : Site.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!mine)
                Text(
                  otherName,
                  style: siteLabel(12, color: Site.accentDeep, height: 1.3),
                ),
              Text(
                m.text,
                style: siteBody(
                  15,
                  height: 1.45,
                  color: mine ? Site.onAccent : Site.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                when,
                style: siteBody(
                  11.5,
                  height: 1.2,
                  color: (mine ? Site.onAccent : Site.muted).withValues(
                    alpha: 0.75,
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

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _again = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_new.text.length < 8) {
      setState(
        () => _error = 'La nuova password deve avere almeno 8 caratteri.',
      );
      return;
    }
    if (_new.text != _again.text) {
      setState(() => _error = 'Le due password non coincidono.');
      return;
    }
    final ok = await context.read<AppState>().changeOwnPassword(
      _old.text,
      _new.text,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _error = 'La password attuale non è corretta.');
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(const SnackBar(content: Text('Password cambiata.')));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Site.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.photo),
      ),
      title: Text('Cambia password', style: siteHead(28)),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _old,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password attuale'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _new,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nuova password (min. 8 caratteri)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _again,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Ripeti la nuova'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: siteBody(14, color: const Color(0xFFC0392B)),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annulla', style: siteLabel(14, color: Site.muted)),
        ),
        SiteButton('Salva', onTap: _save, icon: Icons.check_rounded),
      ],
    );
  }
}

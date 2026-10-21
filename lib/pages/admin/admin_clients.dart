import 'dart:convert';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../client_area_page.dart' show MessageBubble, downloadFile, fileIcon;
import 'admin_widgets.dart';

/// Password leggibile da dettare o mandare al cliente (niente caratteri
/// ambigui come 0/O o 1/l).
String generatePassword() {
  const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final r = Random.secure();
  return List.generate(10, (_) => chars[r.nextInt(chars.length)]).join();
}

/// Indirizzo dell'area clienti di questo sito.
String clientAreaLink() {
  final base = Uri.base;
  final origin = base.isScheme('http') || base.isScheme('https')
      ? '${base.origin}${base.path}'
      : base.toString();
  return '$origin#/area-clienti';
}

String _fmt(DateTime d) => DateFormat('d MMM y', 'it_IT').format(d);

/// Mostra le credenziali appena create, pronte da copiare per il cliente.
Future<void> showCredentials(
  BuildContext context,
  ClientAccount c,
  String password,
) {
  final text =
      'Ciao ${c.name.split(' ').first}, ecco l\'accesso alla tua area clienti '
      'di M.I.R.O. Costruzioni, dove puoi seguire i lavori e scaricare i documenti.\n\n'
      'Indirizzo: ${clientAreaLink()}\n'
      'Email: ${c.email}\n'
      'Password: $password\n\n'
      'Dopo il primo accesso puoi cambiare la password.';
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Credenziali del cliente'),
      content: SizedBox(
        width: dialogWidth(ctx, 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Copia il messaggio e mandalo al cliente (email o WhatsApp). La password '
              'non si potrà più rivedere: se la perde, reimpostala.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F1EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(text),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Chiudi'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: text));
            if (ctx.mounted) toast(ctx, 'Messaggio copiato.');
          },
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Copia messaggio'),
        ),
      ],
    ),
  );
}

// =================================================================== CLIENTI

class AdminClients extends StatelessWidget {
  const AdminClients({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeader(
          title: 'Clienti',
          subtitle:
              'Gli account dell\'area clienti. Solo tu puoi crearli: dal sito non ci '
              'si può registrare. Ogni cliente vede soltanto i propri cantieri.',
          actions: [
            FilledButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const _ClientDialog(),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Nuovo cliente'),
            ),
          ],
        ),
        if (s.clients.isEmpty)
          const Card(
            child: EmptyState(
              icon: Icons.people_outline_rounded,
              message: 'Nessun cliente ancora. Crea il primo account.',
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [for (final c in s.clients) _ClientRow(client: c)],
            ),
          ),
      ],
    );
  }
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({required this.client});
  final ClientAccount client;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final c = client;
    final n = s.worksitesOf(c.id).length;
    final meta = [
      c.email,
      '$n ${n == 1 ? 'cantiere' : 'cantieri'}',
      c.lastLogin == null
          ? 'mai entrato'
          : 'ultimo accesso ${_fmt(c.lastLogin!)}',
    ].join(' · ');
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (_) => _ClientDialog(existing: c),
        ),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE8E6E1))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: context.brand.withValues(alpha: 0.18),
                foregroundColor: Palette.ink,
                child: Text(
                  c.name.isEmpty ? '?' : c.name.characters.first.toUpperCase(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: body(
                              15,
                              weight: FontWeight.w600,
                              height: 1.3,
                              color: c.active ? Palette.ink : Palette.stone,
                            ),
                          ),
                        ),
                        if (!c.active) ...[
                          const SizedBox(width: 8),
                          const Text(
                            'sospeso',
                            style: TextStyle(
                              color: Color(0xFFB3382A),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: body(13, color: Palette.stone, height: 1.35),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientDialog extends StatefulWidget {
  const _ClientDialog({this.existing});
  final ClientAccount? existing;

  @override
  State<_ClientDialog> createState() => _ClientDialogState();
}

class _ClientDialogState extends State<_ClientDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _email = TextEditingController(text: widget.existing?.email);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late final _notes = TextEditingController(text: widget.existing?.notes);
  late final _pw = TextEditingController(text: generatePassword());
  late bool _active = widget.existing?.active ?? true;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _notes, _pw]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final s = context.read<AppState>();
    final e = widget.existing;
    if (e == null) {
      final pw = _pw.text;
      final c = await s.createClient(
        name: _name.text,
        email: _email.text,
        password: pw,
        phone: _phone.text,
        notes: _notes.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      await showCredentials(context, c, pw);
    } else {
      e
        ..name = _name.text.trim()
        ..email = _email.text
        ..phone = _phone.text.trim()
        ..notes = _notes.text.trim()
        ..active = _active;
      await s.updateClient(e);
      if (!mounted) return;
      Navigator.pop(context);
      toast(context, 'Cliente aggiornato.');
    }
  }

  Future<void> _resetPassword() async {
    final c = widget.existing!;
    final pw = generatePassword();
    final ok = await confirmDialog(
      context,
      'Generare una nuova password per ${c.name}? Quella attuale smetterà di funzionare.',
      confirm: 'Genera',
      title: 'Nuova password',
    );
    if (!ok || !mounted) return;
    await context.read<AppState>().resetClientPassword(c, pw);
    if (!mounted) return;
    Navigator.pop(context);
    await showCredentials(context, c, pw);
  }

  Future<void> _delete() async {
    final c = widget.existing!;
    final ok = await confirmDialog(
      context,
      'Eliminare ${c.name} e tutti i suoi cantieri, documenti e messaggi?',
    );
    if (!ok || !mounted) return;
    await context.read<AppState>().deleteClient(c.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.existing;
    final s = context.read<AppState>();
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null;
    return AlertDialog(
      title: Text(e == null ? 'Nuovo cliente' : 'Modifica cliente'),
      content: SizedBox(
        width: dialogWidth(context, 560),
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Nome e cognome o ragione sociale *',
                  ),
                  validator: required,
                ),
                const SizedBox(height: 14),
                FieldRow(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email (per entrare) *',
                        ),
                        validator: (v) {
                          if (required(v) != null) return 'Campo obbligatorio';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(v!.trim())) {
                            return 'Email non valida';
                          }
                          return s.emailTaken(v, exceptId: e?.id)
                              ? 'Email già usata da un altro cliente'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefono',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (e == null)
                  TextFormField(
                    controller: _pw,
                    decoration: InputDecoration(
                      labelText: 'Password iniziale *',
                      helperText: 'Generata a caso: puoi cambiarla. Il cliente potrà sceglierne una sua.',
                      suffixIcon: IconButton(
                        tooltip: 'Genera un\'altra',
                        onPressed: () =>
                            setState(() => _pw.text = generatePassword()),
                        icon: const Icon(Icons.casino_outlined, size: 20),
                      ),
                    ),
                    validator: (v) =>
                        (v ?? '').length < 8 ? 'Almeno 8 caratteri' : null,
                  ),
                if (e == null) const SizedBox(height: 14),
                TextFormField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Appunti interni (il cliente non li vede)',
                    alignLabelWithHint: true,
                  ),
                ),
                if (e != null) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Accesso attivo'),
                    subtitle: const Text(
                      'Se lo spegni il cliente non può più entrare.',
                    ),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _resetPassword,
                        icon: const Icon(Icons.key_rounded, size: 18),
                        label: const Text('Nuova password'),
                      ),
                      TextButton.icon(
                        onPressed: _delete,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB3382A),
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        label: const Text('Elimina cliente'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(e == null ? 'Crea account' : 'Salva'),
        ),
      ],
    );
  }
}

// ================================================================== CANTIERI

class AdminWorksites extends StatelessWidget {
  const AdminWorksites({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeader(
          title: 'Cantieri',
          subtitle:
              'Quello che ogni cliente vede nella sua area: avanzamento, fasi, '
              'aggiornamenti con foto, documenti e messaggi.',
          actions: [
            FilledButton.icon(
              onPressed: () async {
                if (s.clients.isEmpty) {
                  toast(context, 'Crea prima l\'account del cliente.');
                  context.go('/admin/clienti');
                  return;
                }
                final w = Worksite(
                  clientId: s.clients.first.id,
                  title: 'Nuovo cantiere',
                  status: WorksiteStatus.preparazione,
                );
                await s.saveWorksite(w);
                if (context.mounted) context.go('/admin/cantieri?id=${w.id}');
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuovo cantiere'),
            ),
          ],
        ),
        if (s.worksites.isEmpty)
          const Card(
            child: EmptyState(
              icon: Icons.foundation_outlined,
              message: 'Nessun cantiere. Creane uno e collegalo a un cliente.',
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final w in s.worksites)
                  _WorksiteRow(
                    worksite: w,
                    clientName: s.clientById(w.clientId)?.name ?? '—',
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WorksiteRow extends StatelessWidget {
  const _WorksiteRow({required this.worksite, required this.clientName});
  final Worksite worksite;
  final String clientName;

  @override
  Widget build(BuildContext context) {
    final w = worksite;
    final narrow = isNarrow(context);
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => context.go('/admin/cantieri?id=${w.id}'),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE8E6E1))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: narrow ? 56 : 84,
                  height: narrow ? 42 : 60,
                  child: PhotoImage(w.cover),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: body(15, weight: FontWeight.w600, height: 1.3),
                    ),
                    Text(
                      '$clientName · ${w.status.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: body(13, color: Palette.stone, height: 1.35),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: w.progress / 100,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFE8E6E1),
                        color: context.brand,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('${w.progress}%', style: body(14, weight: FontWeight.w600)),
              if (w.unreadForAdmin > 0) ...[
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Messaggi nuovi dal cliente',
                  child: Badge(
                    label: Text('${w.unreadForAdmin}'),
                    child: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Scheda completa di un cantiere: dati e fasi (si salvano insieme),
/// aggiornamenti, documenti e messaggi (si salvano subito).
class AdminWorksiteEditor extends StatefulWidget {
  const AdminWorksiteEditor({super.key, required this.worksite});
  final Worksite worksite;

  @override
  State<AdminWorksiteEditor> createState() => _AdminWorksiteEditorState();
}

class _AdminWorksiteEditorState extends State<AdminWorksiteEditor> {
  final _form = GlobalKey<FormState>();
  late Worksite _d = Worksite.fromJson(widget.worksite.toJson());
  bool _dirty = false;
  int _rev = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().markRead(widget.worksite, byClient: false);
      }
    });
  }

  void _changed() => setState(() => _dirty = true);

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final w = widget.worksite;
    w
      ..clientId = _d.clientId
      ..title = _d.title.trim()
      ..address = _d.address.trim()
      ..start = _d.start.trim()
      ..end = _d.end.trim()
      ..status = _d.status
      ..progress = _d.progress
      ..phase = _d.phase.trim()
      ..description = _d.description.trim()
      ..cover = _d.cover
      ..steps = [
        for (final st in _d.steps)
          if (st.title.trim().isNotEmpty) st,
      ];
    await context.read<AppState>().saveWorksite(w);
    if (!mounted) return;
    setState(() => _dirty = false);
    toast(context, 'Cantiere salvato: il cliente vede già le modifiche.');
  }

  void _discard() => setState(() {
    _d = Worksite.fromJson(widget.worksite.toJson());
    _dirty = false;
    _rev++;
  });

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      'Eliminare il cantiere "${widget.worksite.title}" con documenti e messaggi?',
    );
    if (!ok || !mounted) return;
    await context.read<AppState>().deleteWorksite(widget.worksite.id);
    if (mounted) context.go('/admin/cantieri');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final w = widget.worksite;
    const gap = SizedBox(height: 14);
    Widget field(
      String label,
      String value,
      void Function(String) set, {
      int maxLines = 1,
      String? helper,
      bool required = false,
    }) => TextFormField(
      initialValue: value,
      minLines: maxLines > 1 ? 3 : null,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        helperText: helper,
        alignLabelWithHint: maxLines > 1,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null
          : null,
      onChanged: (v) {
        set(v);
        _changed();
      },
    );

    final data = Panel(
      title: 'Dati e avanzamento',
      child: KeyedSubtree(
        key: ValueKey(_rev),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: s.clientById(_d.clientId) == null
                    ? null
                    : _d.clientId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Cliente *'),
                items: [
                  for (final c in s.clients)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.name} · ${c.email}'),
                    ),
                ],
                validator: (v) => v == null ? 'Scegli il cliente' : null,
                onChanged: (v) {
                  if (v != null) {
                    _d.clientId = v;
                    _changed();
                  }
                },
              ),
              gap,
              field('Titolo', _d.title, (v) => _d.title = v, required: true),
              gap,
              field('Indirizzo', _d.address, (v) => _d.address = v),
              gap,
              FieldRow(
                children: [
                  Expanded(
                    child: field(
                      'Inizio lavori',
                      _d.start,
                      (v) => _d.start = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: field('Fine prevista', _d.end, (v) => _d.end = v),
                  ),
                ],
              ),
              gap,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final st in WorksiteStatus.values)
                    ChoiceChip(
                      label: Text(st.label),
                      selected: _d.status == st,
                      onSelected: (_) {
                        setState(() => _d.status = st);
                        _changed();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Avanzamento: ${_d.progress}%',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: _d.progress.toDouble(),
                max: 100,
                divisions: 20,
                label: '${_d.progress}%',
                onChanged: (v) {
                  setState(() => _d.progress = v.round());
                  _changed();
                },
              ),
              field(
                'Fase attuale',
                _d.phase,
                (v) => _d.phase = v,
                helper: 'Es. "Impianti" o "Finiture".',
              ),
              gap,
              field(
                'Descrizione per il cliente',
                _d.description,
                (v) => _d.description = v,
                maxLines: 4,
              ),
              gap,
              ImageField(
                label: 'FOTO DI COPERTINA',
                value: _d.cover,
                onChanged: (v) {
                  _d.cover = v;
                  _changed();
                },
              ),
              const SizedBox(height: 22),
              Text('Fasi', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              for (var i = 0; i < _d.steps.length; i++)
                _StepEditor(
                  key: ObjectKey(_d.steps[i]),
                  step: _d.steps[i],
                  onChanged: _changed,
                  onUp: i == 0
                      ? null
                      : () {
                          setState(
                            () => _d.steps.insert(i - 1, _d.steps.removeAt(i)),
                          );
                          _changed();
                        },
                  onDelete: () {
                    setState(() => _d.steps.removeAt(i));
                    _changed();
                  },
                ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _d.steps.add(WorksiteStep(title: '')));
                  _changed();
                },
                icon: const Icon(Icons.add),
                label: const Text('Aggiungi fase'),
              ),
            ],
          ),
        ),
      ),
    );

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isNarrow(context) ? 16 : 36,
              isNarrow(context) ? 20 : 32,
              isNarrow(context) ? 16 : 36,
              48,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.go('/admin/cantieri'),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Tutti i cantieri'),
                      ),
                    ),
                    AdminHeader(
                      title: w.title,
                      subtitle: s.clientById(w.clientId)?.name,
                      actions: [
                        TextButton.icon(
                          onPressed: _delete,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFB3382A),
                          ),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                          ),
                          label: const Text('Elimina cantiere'),
                        ),
                      ],
                    ),
                    storageWarning(s),
                    data,
                    const SizedBox(height: 20),
                    _UpdatesPanel(worksite: w),
                    const SizedBox(height: 20),
                    _FilesPanel(worksite: w),
                    const SizedBox(height: 20),
                    _MessagesPanel(worksite: w),
                  ],
                ),
              ),
            ),
          ),
        ),
        SaveBar(dirty: _dirty, onSave: _save, onDiscard: _discard),
      ],
    );
  }
}

class _StepEditor extends StatelessWidget {
  const _StepEditor({
    super.key,
    required this.step,
    required this.onChanged,
    required this.onUp,
    required this.onDelete,
  });
  final WorksiteStep step;
  final VoidCallback onChanged;
  final VoidCallback? onUp;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    final title = TextFormField(
      initialValue: step.title,
      decoration: const InputDecoration(labelText: 'Fase', isDense: true),
      onChanged: (v) {
        step.title = v;
        onChanged();
      },
    );
    final date = TextFormField(
      initialValue: step.date,
      decoration: const InputDecoration(labelText: 'Quando', isDense: true),
      onChanged: (v) {
        step.date = v;
        onChanged();
      },
    );
    final check = StatefulBuilder(
      builder: (context, set) => Checkbox(
        value: step.done,
        onChanged: (v) {
          set(() => step.done = v ?? false);
          onChanged();
        },
      ),
    );
    final buttons = [
      IconButton(
        tooltip: 'Sposta su',
        onPressed: onUp,
        icon: const Icon(Icons.arrow_upward_rounded, size: 18),
      ),
      IconButton(
        tooltip: 'Togli',
        onPressed: onDelete,
        icon: const Icon(Icons.close_rounded, size: 18),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: narrow
          ? Column(
              children: [
                Row(
                  children: [
                    check,
                    Expanded(child: title),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 48),
                    Expanded(child: date),
                    ...buttons,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Tooltip(message: 'Completata', child: check),
                Expanded(flex: 3, child: title),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: date),
                ...buttons,
              ],
            ),
    );
  }
}

// ------------------------------------------------------------ aggiornamenti

class _UpdatesPanel extends StatelessWidget {
  const _UpdatesPanel({required this.worksite});
  final Worksite worksite;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final list = [...worksite.updates]
      ..sort((a, b) => b.date.compareTo(a.date));
    return Panel(
      title: 'Aggiornamenti',
      subtitle: 'Note e foto dei progressi: il cliente le vede subito.',
      trailing: FilledButton.icon(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => _UpdateDialog(worksite: worksite),
        ),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Nuovo aggiornamento'),
      ),
      child: list.isEmpty
          ? const Text(
              'Nessun aggiornamento pubblicato.',
              style: TextStyle(color: Colors.black54),
            )
          : Column(
              children: [
                for (final u in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: u.photos.isEmpty
                        ? const CircleAvatar(
                            child: Icon(Icons.notes_rounded, size: 18),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 56,
                              height: 42,
                              child: PhotoImage(u.photos.first),
                            ),
                          ),
                    title: Text(u.title),
                    subtitle: Text('${_fmt(u.date)} · ${u.photos.length} foto'),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Azioni',
                      onSelected: (v) async {
                        if (v == 'edit') {
                          await showDialog(
                            context: context,
                            builder: (_) =>
                                _UpdateDialog(worksite: worksite, existing: u),
                          );
                        } else if (await confirmDialog(
                          context,
                          'Eliminare l\'aggiornamento "${u.title}"?',
                        )) {
                          worksite.updates.remove(u);
                          await s.saveWorksite(worksite);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Modifica')),
                        PopupMenuItem(value: 'delete', child: Text('Elimina')),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.worksite, this.existing});
  final Worksite worksite;
  final WorksiteUpdate? existing;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _text = TextEditingController(text: widget.existing?.text);
  late final List<String> _photos = [...?widget.existing?.photos];
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _busy = true);
    try {
      final files = await ImagePicker().pickMultiImage(
        maxWidth: 1600,
        imageQuality: 78,
      );
      for (final f in files) {
        final bytes = await f.readAsBytes();
        final mime = (f.mimeType?.startsWith('image/') ?? false)
            ? f.mimeType!
            : 'image/jpeg';
        _photos.add('data:$mime;base64,${base64Encode(bytes)}');
      }
    } catch (e) {
      if (mounted) toast(context, 'Caricamento non riuscito: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final w = widget.worksite;
    final e = widget.existing;
    if (e == null) {
      w.updates.add(
        WorksiteUpdate(
          title: _title.text.trim(),
          text: _text.text.trim(),
          photos: _photos,
        ),
      );
    } else {
      e
        ..title = _title.text.trim()
        ..text = _text.text.trim()
        ..photos = _photos;
    }
    await context.read<AppState>().saveWorksite(w);
    if (!mounted) return;
    Navigator.pop(context);
    toast(context, 'Aggiornamento pubblicato.');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? 'Nuovo aggiornamento'
            : 'Modifica aggiornamento',
      ),
      content: SizedBox(
        width: dialogWidth(context, 600),
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Titolo *',
                    hintText: 'Es. "Finiti i massetti"',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo obbligatorio'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _text,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Cosa è stato fatto',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Foto (${_photos.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _pick,
                      icon: _busy
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 18,
                            ),
                      label: const Text('Aggiungi foto'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _photos.length; i++)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 96,
                              height: 72,
                              child: PhotoImage(_photos[i]),
                            ),
                          ),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: InkWell(
                              onTap: () => setState(() => _photos.removeAt(i)),
                              child: const CircleAvatar(
                                radius: 11,
                                backgroundColor: Colors.black54,
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: const Text('Pubblica'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- documenti

/// File più grandi di così riempirebbero subito l'archivio del browser.
const maxFileBytes = 2 * 1024 * 1024;

class _FilesPanel extends StatefulWidget {
  const _FilesPanel({required this.worksite});
  final Worksite worksite;

  @override
  State<_FilesPanel> createState() => _FilesPanelState();
}

class _FilesPanelState extends State<_FilesPanel> {
  bool _busy = false;

  static String _mimeOf(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'txt' => 'text/plain',
      'doc' => 'application/msword',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      _ => 'application/octet-stream',
    };
  }

  Future<void> _upload() async {
    setState(() => _busy = true);
    final w = widget.worksite;
    final s = context.read<AppState>();
    final skipped = <String>[];
    try {
      final files = await FilePicker.pickFiles();
      for (final f in files) {
        final bytes = await f.readAsBytes();
        if (bytes.length > maxFileBytes) {
          skipped.add(f.name);
          continue;
        }
        final mime = _mimeOf(f.name);
        w.files.add(
          WorksiteFile(
            name: f.name,
            mime: mime,
            size: bytes.length,
            data: 'data:$mime;base64,${base64Encode(bytes)}',
          ),
        );
      }
      if (files.isNotEmpty) await s.saveWorksite(w);
      if (mounted && skipped.isNotEmpty) {
        toast(
          context,
          'Troppo grandi (oltre 2 MB), non caricati: ${skipped.join(', ')}. '
          'Per file grandi usa "Da indirizzo" con un link (es. Google Drive).',
          error: true,
        );
      }
    } catch (e) {
      if (mounted) toast(context, 'Caricamento non riuscito: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addLink() async {
    final name = TextEditingController();
    final url = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Documento da indirizzo'),
        content: SizedBox(
          width: dialogWidth(c, 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Nome (es. Planimetria.pdf)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: url,
                decoration: const InputDecoration(
                  labelText: 'Link (Google Drive, Dropbox…)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
    if (ok == true && url.text.trim().isNotEmpty && mounted) {
      widget.worksite.files.add(
        WorksiteFile(
          name: name.text.trim().isEmpty ? 'Documento' : name.text.trim(),
          data: url.text.trim(),
        ),
      );
      await context.read<AppState>().saveWorksite(widget.worksite);
    }
    name.dispose();
    url.dispose();
  }

  Future<void> _editNote(WorksiteFile f) async {
    final c = TextEditingController(text: f.note);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(f.name),
        content: SizedBox(
          width: dialogWidth(ctx, 460),
          child: TextField(
            controller: c,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Nota per il cliente',
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      f.note = c.text.trim();
      await context.read<AppState>().saveWorksite(widget.worksite);
    }
    c.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.worksite;
    final s = context.read<AppState>();
    return Panel(
      title: 'Documenti',
      subtitle:
          'Preventivi, contratti, planimetrie, foto: il cliente li scarica dalla sua area. '
          'Massimo 2 MB per file finché i dati restano nel browser.',
      trailing: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: _busy ? null : _upload,
            icon: _busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Carica file'),
          ),
          OutlinedButton.icon(
            onPressed: _addLink,
            icon: const Icon(Icons.link_rounded, size: 18),
            label: const Text('Da indirizzo'),
          ),
        ],
      ),
      child: w.files.isEmpty
          ? const Text(
              'Nessun documento caricato.',
              style: TextStyle(color: Colors.black54),
            )
          : Column(
              children: [
                for (final f in w.files)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(fileIcon(f.name)),
                    title: Text(f.name),
                    subtitle: Text(
                      [
                        _fmt(f.uploadedAt),
                        if (f.note.isNotEmpty) f.note,
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Azioni',
                      onSelected: (v) async {
                        switch (v) {
                          case 'note':
                            await _editNote(f);
                          case 'download':
                            await downloadFile(f);
                          case 'delete':
                            if (await confirmDialog(
                              context,
                              'Eliminare "${f.name}"?',
                            )) {
                              w.files.remove(f);
                              await s.saveWorksite(w);
                            }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'note', child: Text('Nota')),
                        PopupMenuItem(
                          value: 'download',
                          child: Text('Scarica'),
                        ),
                        PopupMenuItem(value: 'delete', child: Text('Elimina')),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

// ----------------------------------------------------------------- messaggi

class _MessagesPanel extends StatefulWidget {
  const _MessagesPanel({required this.worksite});
  final Worksite worksite;

  @override
  State<_MessagesPanel> createState() => _MessagesPanelState();
}

class _MessagesPanelState extends State<_MessagesPanel> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    _c.clear();
    await context.read<AppState>().sendMessage(
      widget.worksite,
      t,
      fromClient: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final w = widget.worksite;
    final name = s.clientById(w.clientId)?.name ?? 'Cliente';
    final msgs = [...w.messages]..sort((a, b) => a.date.compareTo(b.date));
    return Panel(
      title: 'Messaggi',
      subtitle: 'Il canale con il cliente.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (msgs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Nessun messaggio.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          for (final m in msgs)
            MessageBubble(message: m, mine: !m.fromClient, otherName: name),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _c,
                  minLines: 1,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Rispondi al cliente',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _send,
                tooltip: 'Invia',
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

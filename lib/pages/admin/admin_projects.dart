import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/site_theme.dart';
import '../../widgets/common.dart';
import 'admin_widgets.dart';

// ================================================================= PROGETTI

class AdminProjects extends StatelessWidget {
  const AdminProjects({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeader(
          title: 'Progetti',
          subtitle:
              'I lavori mostrati sul sito. Trascina per riordinare; la stella li mette in evidenza in Home '
              'e nella prima schermata.',
          actions: [
            FilledButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const _ProjectDialog(),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuovo progetto'),
            ),
          ],
        ),
        storageWarning(s),
        Card(
          clipBehavior: Clip.antiAlias,
          child: s.projects.isEmpty
              ? const EmptyState(
                  icon: Icons.apartment_outlined,
                  message: 'Nessun progetto ancora. Aggiungi il primo.',
                )
              : ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: s.projects.length,
                  onReorderItem: (o, n) =>
                      s.setProjects(moveItem(s.projects, o, n)),
                  itemBuilder: (context, i) {
                    final p = s.projects[i];
                    final meta = [
                      p.category,
                      p.location,
                      p.year,
                      '${p.photos.length} foto',
                    ].where((e) => e.trim().isNotEmpty).join(' · ');
                    return AdminListRow(
                      key: ValueKey(p.id),
                      index: i,
                      image: p.coverUrl,
                      title: p.title,
                      subtitle: meta,
                      dimmed: !p.published,
                      leadingExtra: p.status == ProjectStatus.inCorso
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              color: Site.accent,
                              child: Text(
                                'IN CORSO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Site.onAccent,
                                ),
                              ),
                            )
                          : null,
                      trailing: [
                        IconButton(
                          tooltip: p.featured
                              ? 'In evidenza'
                              : 'Metti in evidenza',
                          onPressed: () {
                            p.featured = !p.featured;
                            s.setProjects([...s.projects]);
                          },
                          icon: Icon(
                            p.featured
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: p.featured
                                ? const Color(0xFFD08A16)
                                : Colors.black38,
                          ),
                        ),
                        IconButton(
                          tooltip: p.published
                              ? 'Visibile sul sito'
                              : 'Nascosto',
                          onPressed: () {
                            p.published = !p.published;
                            s.setProjects([...s.projects]);
                          },
                          icon: Icon(
                            p.published
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: p.published
                                ? Colors.black87
                                : Colors.black38,
                          ),
                        ),
                      ],
                      onEdit: () => showDialog(
                        context: context,
                        builder: (_) => _ProjectDialog(existing: p),
                      ),
                      onDelete: () async {
                        if (await confirmDialog(
                          context,
                          'Eliminare il progetto “${p.title}”?',
                        )) {
                          s.setProjects(
                            s.projects.where((e) => e.id != p.id).toList(),
                          );
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ProjectDialog extends StatefulWidget {
  const _ProjectDialog({this.existing});
  final Project? existing;

  @override
  State<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<_ProjectDialog> {
  final _form = GlobalKey<FormState>();
  late final Project _d = widget.existing == null
      ? Project(title: '')
      : Project.fromJson(widget.existing!.toJson());
  late final _category = TextEditingController(text: _d.category);
  bool _busy = false;
  String? _photosError;

  @override
  void dispose() {
    _category.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    setState(() => _busy = true);
    try {
      final files = await ImagePicker().pickMultiImage(
        maxWidth: 1800,
        imageQuality: 82,
      );
      for (final f in files) {
        final bytes = await f.readAsBytes();
        final mime = (f.mimeType?.startsWith('image/') ?? false)
            ? f.mimeType!
            : 'image/jpeg';
        _d.photos.add(
          ProjectPhoto(url: 'data:$mime;base64,${base64Encode(bytes)}'),
        );
      }
      if (files.isNotEmpty) _photosError = null;
    } catch (e) {
      if (mounted) toast(context, 'Caricamento non riuscito: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addByUrl() async {
    var url = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Aggiungi foto'),
        content: SizedBox(
          width: dialogWidth(c, 480),
          child: ImageField(
            label: 'Fotografia',
            value: '',
            onChanged: (v) => url = v,
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
    if (ok == true && url.trim().isNotEmpty && mounted) {
      setState(() {
        _d.photos.add(ProjectPhoto(url: url.trim()));
        _photosError = null;
      });
    }
  }

  void _move(int i, int delta) => setState(() {
    final j = i + delta;
    if (j < 0 || j >= _d.photos.length) return;
    _d.photos.insert(j, _d.photos.removeAt(i));
  });

  void _save() {
    final ok = _form.currentState!.validate();
    // Le foto senza indirizzo si scartano anche dall'elenco mostrato:
    // altrimenti, se il salvataggio viene respinto, i pulsanti delle righe
    // agirebbero sulla foto sbagliata.
    setState(() {
      _d.photos.removeWhere((p) => p.url.trim().isEmpty);
      if (_d.photos.isEmpty && _d.cover.trim().isEmpty) {
        _photosError = 'Aggiungi almeno una foto o una copertina.';
      }
    });
    if (!ok || _d.coverUrl.trim().isEmpty) return;
    _d.category = _category.text.trim();
    final s = context.read<AppState>();
    final list = [...s.projects];
    if (widget.existing == null) {
      list.insert(0, _d);
    } else {
      final i = list.indexWhere((e) => e.id == _d.id);
      if (i >= 0) list[i] = _d;
    }
    s.setProjects(list);
    Navigator.pop(context);
    toast(context, 'Progetto salvato.');
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.read<AppState>().content.categories;
    const gap = SizedBox(height: 16);
    Widget text(
      String label,
      String value,
      ValueChanged<String> set, {
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
        helperMaxLines: 2,
        alignLabelWithHint: maxLines > 1,
      ),
      onChanged: set,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null
          : null,
    );
    final narrow = isNarrow(context);

    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Nuovo progetto' : 'Modifica progetto',
      ),
      content: SizedBox(
        width: dialogWidth(context, 760),
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text(
                  'Titolo',
                  _d.title,
                  (v) => _d.title = v,
                  required: true,
                  helper: 'Es. "Villa Le Querce" o "Residenza Aurora".',
                ),
                gap,
                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    helperText: 'Serve ai filtri della pagina Progetti. Le categorie si ordinano da "Identità e contatti".',
                    helperMaxLines: 2,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in cats)
                      ChoiceChip(
                        label: Text(c),
                        selected:
                            _category.text.trim().toLowerCase() ==
                            c.toLowerCase(),
                        onSelected: (_) => setState(() => _category.text = c),
                      ),
                  ],
                ),
                gap,
                FieldRow(
                  children: [
                    Expanded(
                      child: text('Luogo', _d.location, (v) => _d.location = v),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: text('Anno', _d.year, (v) => _d.year = v)),
                  ],
                ),
                gap,
                FieldRow(
                  children: [
                    Expanded(
                      child: text(
                        'Committente',
                        _d.client,
                        (v) => _d.client = v,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: text(
                        'Superficie (es. 420 m²)',
                        _d.area,
                        (v) => _d.area = v,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: text(
                        'Durata (es. 16 mesi)',
                        _d.duration,
                        (v) => _d.duration = v,
                      ),
                    ),
                  ],
                ),
                gap,
                SegmentedButton<ProjectStatus>(
                  segments: [
                    for (final st in ProjectStatus.values)
                      ButtonSegment(value: st, label: Text(st.label)),
                  ],
                  selected: {_d.status},
                  onSelectionChanged: (v) =>
                      setState(() => _d.status = v.first),
                ),
                gap,
                text(
                  'Descrizione breve',
                  _d.summary,
                  (v) => _d.summary = v,
                  helper: 'Una frase: compare sotto il titolo e nelle schede.',
                ),
                gap,
                text(
                  'Racconto del progetto',
                  _d.description,
                  (v) => _d.description = v,
                  maxLines: 8,
                  helper: 'Lascia una riga vuota per andare a capo con un nuovo paragrafo.',
                ),
                const SizedBox(height: 22),
                Text(
                  'Interventi eseguiti',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                StringListEditor(
                  items: _d.works,
                  addLabel: 'Nuovo intervento',
                  onChanged: (l) => _d.works = l,
                ),
                const SizedBox(height: 24),
                ImageField(
                  label: 'COPERTINA (SE VUOTA SI USA LA PRIMA FOTO)',
                  aspect: 4 / 3,
                  value: _d.cover,
                  onChanged: (v) => _d.cover = v,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Galleria (${_d.photos.length} foto)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (_busy)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _upload,
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      label: const Text('Carica dal dispositivo'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _addByUrl,
                      icon: const Icon(Icons.link_rounded, size: 18),
                      label: const Text('Da indirizzo'),
                    ),
                  ],
                ),
                if (_photosError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _photosError!,
                      style: const TextStyle(
                        color: Color(0xFFB3382A),
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                for (var i = 0; i < _d.photos.length; i++)
                  _PhotoRow(
                    // Chiave per oggetto: regge anche id ripetuti in un
                    // backup modificato a mano.
                    key: ObjectKey(_d.photos[i]),
                    photo: _d.photos[i],
                    number: i + 1,
                    narrow: narrow,
                    onUp: i > 0 ? () => _move(i, -1) : null,
                    onDown: i < _d.photos.length - 1 ? () => _move(i, 1) : null,
                    onDelete: () => setState(() => _d.photos.removeAt(i)),
                  ),
                const SizedBox(height: 18),
                Text(
                  'Prima e dopo (facoltativo)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Con la foto "prima" sulla pagina del progetto compare il confronto da trascinare.',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 14),
                ImageField(
                  label: 'PRIMA',
                  aspect: 16 / 9,
                  value: _d.before,
                  onChanged: (v) => _d.before = v,
                ),
                const SizedBox(height: 16),
                ImageField(
                  label: 'DOPO (SE VUOTA SI USA LA COPERTINA)',
                  aspect: 16 / 9,
                  value: _d.after,
                  onChanged: (v) => _d.after = v,
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('In evidenza in Home'),
                  value: _d.featured,
                  onChanged: (v) => setState(() => _d.featured = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visibile sul sito'),
                  value: _d.published,
                  onChanged: (v) => setState(() => _d.published = v),
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
          child: const Text('Salva'),
        ),
      ],
    );
  }
}

/// Una foto del progetto: anteprima, didascalia e ordine.
class _PhotoRow extends StatelessWidget {
  const _PhotoRow({
    super.key,
    required this.photo,
    required this.number,
    required this.narrow,
    required this.onUp,
    required this.onDown,
    required this.onDelete,
  });
  final ProjectPhoto photo;
  final int number;
  final bool narrow;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final thumb = narrow ? 56.0 : 80.0;
    final index = SizedBox(
      width: 26,
      child: Text(
        '$number',
        style: const TextStyle(color: Colors.black45, fontSize: 13),
      ),
    );
    final preview = ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        width: thumb,
        height: thumb * 0.72,
        child: PhotoImage(photo.url),
      ),
    );
    final caption = TextFormField(
      initialValue: photo.caption,
      decoration: const InputDecoration(labelText: 'Didascalia', isDense: true),
      onChanged: (v) => photo.caption = v,
    );
    final buttons = [
      IconButton(
        tooltip: 'Sposta su',
        onPressed: onUp,
        icon: const Icon(Icons.arrow_upward_rounded, size: 18),
      ),
      IconButton(
        tooltip: 'Sposta giù',
        onPressed: onDown,
        icon: const Icon(Icons.arrow_downward_rounded, size: 18),
      ),
      IconButton(
        tooltip: 'Togli foto',
        onPressed: onDelete,
        icon: const Icon(Icons.close_rounded, size: 18),
      ),
    ];
    // Su telefono la finestra è stretta: i pulsanti vanno sotto la foto.
    if (narrow) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          children: [
            Row(
              children: [
                preview,
                const SizedBox(width: 12),
                Expanded(child: caption),
              ],
            ),
            Row(children: [index, const Spacer(), ...buttons]),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          index,
          preview,
          const SizedBox(width: 12),
          Expanded(child: caption),
          ...buttons,
        ],
      ),
    );
  }
}

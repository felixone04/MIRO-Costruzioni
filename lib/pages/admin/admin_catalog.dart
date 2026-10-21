import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_widgets.dart';

// ================================================================== SERVIZI

class AdminServices extends StatelessWidget {
  const AdminServices({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeader(
          title: 'SERVIZI',
          subtitle: 'Cosa fa l\'impresa: compaiono in Home e nella pagina Servizi. Trascina per riordinare.',
          actions: [
            FilledButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const _ServiceDialog(),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuovo servizio'),
            ),
          ],
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: s.services.isEmpty
              ? const EmptyState(
                  icon: Icons.construction_outlined,
                  message: 'Nessun servizio. Aggiungi il primo.',
                )
              : ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: s.services.length,
                  onReorderItem: (o, n) =>
                      s.setServices(moveItem(s.services, o, n)),
                  itemBuilder: (context, i) {
                    final it = s.services[i];
                    return AdminListRow(
                      key: ValueKey(it.id),
                      index: i,
                      image: it.image,
                      title: it.title,
                      subtitle: it.text,
                      dimmed: !it.active,
                      trailing: [
                        IconButton(
                          tooltip: it.active ? 'Visibile sul sito' : 'Nascosto',
                          onPressed: () {
                            it.active = !it.active;
                            s.setServices([...s.services]);
                          },
                          icon: Icon(
                            it.active
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: it.active ? Colors.black87 : Colors.black38,
                          ),
                        ),
                      ],
                      onEdit: () => showDialog(
                        context: context,
                        builder: (_) => _ServiceDialog(existing: it),
                      ),
                      onDelete: () async {
                        if (await confirmDialog(
                          context,
                          'Eliminare il servizio “${it.title}”?',
                        )) {
                          s.setServices(
                            s.services.where((e) => e.id != it.id).toList(),
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

class _ServiceDialog extends StatefulWidget {
  const _ServiceDialog({this.existing});
  final ServiceItem? existing;

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  final _form = GlobalKey<FormState>();
  late final ServiceItem _d = widget.existing == null
      ? ServiceItem(title: '')
      : ServiceItem.fromJson(widget.existing!.toJson());

  void _save() {
    if (!_form.currentState!.validate()) return;
    final s = context.read<AppState>();
    final list = [...s.services];
    final i = list.indexWhere((e) => e.id == _d.id);
    if (i >= 0) {
      list[i] = _d;
    } else {
      list.add(_d);
    }
    s.setServices(list);
    Navigator.pop(context);
    toast(context, 'Servizio salvato.');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Nuovo servizio' : 'Modifica servizio',
      ),
      content: SizedBox(
        width: dialogWidth(context, 640),
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: _d.title,
                  decoration: const InputDecoration(labelText: 'Nome *'),
                  onChanged: (v) => _d.title = v,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo obbligatorio'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _d.text,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Descrizione',
                    alignLabelWithHint: true,
                  ),
                  onChanged: (v) => _d.text = v,
                ),
                const SizedBox(height: 20),
                Text(
                  'Punti chiave',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                StringListEditor(
                  items: _d.points,
                  addLabel: 'Nuovo punto (es. "Classe energetica A")',
                  onChanged: (l) => _d.points = l,
                ),
                const SizedBox(height: 22),
                ImageField(
                  label: 'FOTO',
                  aspect: 4 / 3,
                  value: _d.image,
                  onChanged: (v) => _d.image = v,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visibile sul sito'),
                  value: _d.active,
                  onChanged: (v) => setState(() => _d.active = v),
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
        FilledButton(onPressed: _save, child: const Text('Salva')),
      ],
    );
  }
}

// ============================================================ TESTIMONIANZE

class AdminTestimonials extends StatelessWidget {
  const AdminTestimonials({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeader(
          title: 'TESTIMONIANZE',
          subtitle: 'Le parole dei clienti che scorrono in Home. Trascina per riordinare.',
          actions: [
            FilledButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const _TestimonialDialog(),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuova testimonianza'),
            ),
          ],
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: s.testimonials.isEmpty
              ? const EmptyState(
                  icon: Icons.format_quote_outlined,
                  message: 'Nessuna testimonianza. Aggiungi la prima.',
                )
              : ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: s.testimonials.length,
                  onReorderItem: (o, n) =>
                      s.setTestimonials(moveItem(s.testimonials, o, n)),
                  itemBuilder: (context, i) {
                    final t = s.testimonials[i];
                    return Material(
                      key: ValueKey(t.id),
                      color: Colors.white,
                      child: InkWell(
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => _TestimonialDialog(existing: t),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFE8E6E1)),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ReorderableDragStartListener(
                                index: i,
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.drag_indicator_rounded,
                                    color: Colors.black38,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Opacity(
                                  opacity: t.published ? 1 : 0.5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '“${t.text}”',
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        [t.name, t.role]
                                            .where((e) => e.isNotEmpty)
                                            .join(' · '),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: t.published
                                    ? 'Visibile sul sito'
                                    : 'Nascosta',
                                onPressed: () {
                                  t.published = !t.published;
                                  s.setTestimonials([...s.testimonials]);
                                },
                                icon: Icon(
                                  t.published
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: t.published
                                      ? Colors.black87
                                      : Colors.black38,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Elimina',
                                onPressed: () async {
                                  if (await confirmDialog(
                                    context,
                                    'Eliminare la testimonianza di ${t.name}?',
                                  )) {
                                    s.setTestimonials(
                                      s.testimonials
                                          .where((e) => e.id != t.id)
                                          .toList(),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TestimonialDialog extends StatefulWidget {
  const _TestimonialDialog({this.existing});
  final Testimonial? existing;

  @override
  State<_TestimonialDialog> createState() => _TestimonialDialogState();
}

class _TestimonialDialogState extends State<_TestimonialDialog> {
  final _form = GlobalKey<FormState>();
  late final Testimonial _d = widget.existing == null
      ? Testimonial(name: '', text: '')
      : Testimonial.fromJson(widget.existing!.toJson());

  void _save() {
    if (!_form.currentState!.validate()) return;
    final s = context.read<AppState>();
    final list = [...s.testimonials];
    final i = list.indexWhere((e) => e.id == _d.id);
    if (i >= 0) {
      list[i] = _d;
    } else {
      list.add(_d);
    }
    s.setTestimonials(list);
    Navigator.pop(context);
    toast(context, 'Testimonianza salvata.');
  }

  @override
  Widget build(BuildContext context) {
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null;
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? 'Nuova testimonianza'
            : 'Modifica testimonianza',
      ),
      content: SizedBox(
        width: dialogWidth(context, 560),
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _d.text,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Testo *',
                    alignLabelWithHint: true,
                  ),
                  onChanged: (v) => _d.text = v,
                  validator: required,
                ),
                const SizedBox(height: 16),
                FieldRow(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _d.name,
                        decoration: const InputDecoration(labelText: 'Nome *'),
                        onChanged: (v) => _d.name = v,
                        validator: required,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        initialValue: _d.role,
                        decoration: const InputDecoration(
                          labelText: 'Progetto o ruolo',
                        ),
                        onChanged: (v) => _d.role = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
        FilledButton(onPressed: _save, child: const Text('Salva')),
      ],
    );
  }
}

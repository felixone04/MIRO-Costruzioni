import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_widgets.dart';

/// Pagina di amministrazione scorrevole con margini coerenti.
class AdminPageScroll extends StatelessWidget {
  const AdminPageScroll({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 720;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        mobile ? 16 : 36,
        mobile ? 20 : 32,
        mobile ? 16 : 36,
        48,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

/// Editor a bozza dei contenuti del sito: le modifiche si applicano solo al
/// clic su "Salva", e si possono annullare.
class DraftEditor extends StatefulWidget {
  const DraftEditor({
    super.key,
    required this.title,
    this.subtitle,
    required this.builder,
  });
  final String title;
  final String? subtitle;
  final List<Widget> Function(
    BuildContext context,
    SiteContent draft,
    VoidCallback changed,
  )
  builder;

  @override
  State<DraftEditor> createState() => _DraftEditorState();
}

class _DraftEditorState extends State<DraftEditor> {
  late SiteContent _draft = context.read<AppState>().content.copy();
  bool _dirty = false;
  int _rev = 0;

  void _rebuild() => setState(() => _dirty = true);

  Future<void> _save() async {
    await context.read<AppState>().updateContent(_draft);
    if (!mounted) return;
    setState(() {
      _draft = context.read<AppState>().content.copy();
      _dirty = false;
    });
    toast(context, 'Modifiche salvate: il sito è aggiornato.');
  }

  void _discard() => setState(() {
    _draft = context.read<AppState>().content.copy();
    _dirty = false;
    _rev++;
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AdminPageScroll(
            child: KeyedSubtree(
              key: ValueKey(_rev),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminHeader(title: widget.title, subtitle: widget.subtitle),
                  for (final w in widget.builder(
                    context,
                    _draft,
                    _rebuild,
                  )) ...[w, const SizedBox(height: 20)],
                ],
              ),
            ),
          ),
        ),
        SaveBar(dirty: _dirty, onSave: _save, onDiscard: _discard),
      ],
    );
  }
}

const _gap = SizedBox(height: 16);

/// Campo di testo collegato a un valore della bozza.
Widget _field(
  String label,
  String value,
  void Function(String) set,
  VoidCallback changed, {
  int maxLines = 1,
  String? helper,
}) => BoundField(
  label: label,
  value: value,
  maxLines: maxLines,
  helper: helper,
  onChanged: (v) {
    set(v);
    changed();
  },
);

Widget _image(
  String label,
  String value,
  void Function(String) set,
  VoidCallback changed, {
  double aspect = 16 / 10,
}) => ImageField(
  label: label.toUpperCase(),
  value: value,
  aspect: aspect,
  onChanged: (v) {
    set(v);
    changed();
  },
);

Widget _strings(
  List<String> list,
  VoidCallback changed, {
  required String addLabel,
}) => StringListEditor(
  items: list,
  addLabel: addLabel,
  onChanged: (l) {
    list
      ..clear()
      ..addAll(l);
    changed();
  },
);

/// Editor di un elenco di tappe (anno/numero, titolo, testo).
Widget _milestones(
  List<Milestone> list,
  VoidCallback changed, {
  required String item,
  required String numberLabel,
  required String addLabel,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    for (var i = 0; i < list.length; i++)
      ItemCard(
        key: ObjectKey(list[i]),
        title: '$item ${i + 1}',
        onUp: i == 0
            ? null
            : () {
                list.insert(i - 1, list.removeAt(i));
                changed();
              },
        onDown: i == list.length - 1
            ? null
            : () {
                list.insert(i + 1, list.removeAt(i));
                changed();
              },
        onDelete: () {
          list.removeAt(i);
          changed();
        },
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: _field(
                    numberLabel,
                    list[i].year,
                    (v) => list[i].year = v,
                    changed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    'Titolo',
                    list[i].title,
                    (v) => list[i].title = v,
                    changed,
                  ),
                ),
              ],
            ),
            _gap,
            _field(
              'Testo',
              list[i].text,
              (v) => list[i].text = v,
              changed,
              maxLines: 3,
            ),
          ],
        ),
      ),
    OutlinedButton.icon(
      onPressed: () {
        list.add(
          Milestone(
            year: (list.length + 1).toString().padLeft(2, '0'),
            title: '',
            text: '',
          ),
        );
        changed();
      },
      icon: const Icon(Icons.add),
      label: Text(addLabel),
    ),
  ],
);

/// Editor di coppie titolo/testo (numeri, valori).
Widget _highlights(
  List<Highlight> list,
  VoidCallback changed, {
  required String titleLabel,
  required String textLabel,
  required String addLabel,
  int textLines = 1,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    for (var i = 0; i < list.length; i++)
      ItemCard(
        key: ObjectKey(list[i]),
        onUp: i == 0
            ? null
            : () {
                list.insert(i - 1, list.removeAt(i));
                changed();
              },
        onDown: i == list.length - 1
            ? null
            : () {
                list.insert(i + 1, list.removeAt(i));
                changed();
              },
        onDelete: () {
          list.removeAt(i);
          changed();
        },
        child: FieldRow(
          children: [
            SizedBox(
              width: 170,
              child: _field(
                titleLabel,
                list[i].title,
                (v) => list[i].title = v,
                changed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                textLabel,
                list[i].text,
                (v) => list[i].text = v,
                changed,
                maxLines: textLines,
              ),
            ),
          ],
        ),
      ),
    OutlinedButton.icon(
      onPressed: () {
        list.add(Highlight(title: '', text: ''));
        changed();
      },
      icon: const Icon(Icons.add),
      label: Text(addLabel),
    ),
  ],
);

const _titleHelper =
    'Vai a capo per la riga successiva: l\'ultima riga appare in corsivo, colorata.';

// ====================================================================== HOME

class AdminHomeEditor extends StatelessWidget {
  const AdminHomeEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return DraftEditor(
      title: 'Pagina Home',
      subtitle: 'I testi della prima pagina. Le foto della prima schermata sono le copertine dei progetti in evidenza.',
      builder: (context, d, changed) => [
        Panel(
          title: 'Prima schermata',
          trailing: TextButton.icon(
            onPressed: () => context.go('/admin/progetti'),
            icon: const Icon(Icons.star_outline_rounded, size: 18),
            label: const Text('Scegli i progetti in evidenza'),
          ),
          child: Column(
            children: [
              _field(
                'Etichetta',
                d.heroKicker,
                (v) => d.heroKicker = v,
                changed,
              ),
              _gap,
              _field(
                'Titolo',
                d.heroTitle,
                (v) => d.heroTitle = v,
                changed,
                maxLines: 3,
                helper: _titleHelper,
              ),
              _gap,
              _field(
                'Sottotitolo',
                d.heroSubtitle,
                (v) => d.heroSubtitle = v,
                changed,
                maxLines: 3,
              ),
            ],
          ),
        ),
        Panel(
          title: 'Presentazione e numeri',
          subtitle: 'I numeri "contano" fino al valore quando compaiono (es. 420+, 180k).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(
                'Etichetta',
                d.introKicker,
                (v) => d.introKicker = v,
                changed,
              ),
              _gap,
              _field(
                'Titolo',
                d.introTitle,
                (v) => d.introTitle = v,
                changed,
                maxLines: 3,
                helper: _titleHelper,
              ),
              _gap,
              _field(
                'Testo',
                d.introText,
                (v) => d.introText = v,
                changed,
                maxLines: 5,
              ),
              const SizedBox(height: 22),
              _highlights(
                d.stats,
                changed,
                titleLabel: 'Numero',
                textLabel: 'Descrizione',
                addLabel: 'Aggiungi numero',
              ),
            ],
          ),
        ),
        Panel(
          title: 'Progetti',
          subtitle:
              'Il titolo della sezione in Home e in cima alla pagina Progetti.',
          child: Column(
            children: [
              _field(
                'Etichetta',
                d.projectsKicker,
                (v) => d.projectsKicker = v,
                changed,
              ),
              _gap,
              _field(
                'Titolo',
                d.projectsTitle,
                (v) => d.projectsTitle = v,
                changed,
                maxLines: 3,
                helper: _titleHelper,
              ),
              _gap,
              _field(
                'Testo',
                d.projectsText,
                (v) => d.projectsText = v,
                changed,
                maxLines: 3,
              ),
            ],
          ),
        ),
        Panel(
          title: 'Pagina Servizi',
          subtitle: 'Il titolo e il testo in cima alla pagina Servizi.',
          trailing: TextButton.icon(
            onPressed: () => context.go('/admin/servizi'),
            icon: const Icon(Icons.construction_outlined, size: 18),
            label: const Text('Gestisci i servizi'),
          ),
          child: Column(
            children: [
              _field(
                'Etichetta',
                d.servicesKicker,
                (v) => d.servicesKicker = v,
                changed,
              ),
              _gap,
              _field(
                'Titolo',
                d.servicesTitle,
                (v) => d.servicesTitle = v,
                changed,
                maxLines: 3,
                helper: _titleHelper,
              ),
              _gap,
              _field(
                'Testo',
                d.servicesText,
                (v) => d.servicesText = v,
                changed,
                maxLines: 3,
              ),
            ],
          ),
        ),
        Panel(
          title: 'Nastro scorrevole',
          subtitle: 'Le parole che scorrono a tutta larghezza.',
          child: _strings(d.ticker, changed, addLabel: 'Nuova parola'),
        ),
      ],
    );
  }
}

// =================================================================== AZIENDA

class AdminAboutEditor extends StatelessWidget {
  const AdminAboutEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return DraftEditor(
      title: 'Azienda',
      subtitle: 'Storia, valori, tappe e persone della pagina Azienda.',
      builder: (context, d, changed) => [
        Panel(
          title: 'Apertura',
          child: Column(
            children: [
              _field(
                'Etichetta',
                d.aboutKicker,
                (v) => d.aboutKicker = v,
                changed,
              ),
              _gap,
              _field(
                'Titolo',
                d.aboutTitle,
                (v) => d.aboutTitle = v,
                changed,
                maxLines: 3,
                helper: _titleHelper,
              ),
              _gap,
              _field(
                'Introduzione',
                d.aboutIntro,
                (v) => d.aboutIntro = v,
                changed,
                maxLines: 3,
              ),
              _gap,
              _image(
                'Foto di apertura',
                d.aboutImage,
                (v) => d.aboutImage = v,
                changed,
              ),
            ],
          ),
        ),
        Panel(
          title: 'La storia',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(
                'Testo',
                d.aboutText,
                (v) => d.aboutText = v,
                changed,
                maxLines: 10,
                helper: 'Lascia una riga vuota per un nuovo paragrafo.',
              ),
              _gap,
              _image(
                'Seconda foto',
                d.aboutImage2,
                (v) => d.aboutImage2 = v,
                changed,
              ),
              const SizedBox(height: 22),
              const Text(
                'Certificazioni',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _strings(
                d.certifications,
                changed,
                addLabel: 'Nuova certificazione',
              ),
            ],
          ),
        ),
        Panel(
          title: 'Valori',
          subtitle: 'Le iniziali dei valori compaiono come grandi lettere.',
          child: _highlights(
            d.values,
            changed,
            titleLabel: 'Valore',
            textLabel: 'Descrizione',
            addLabel: 'Aggiungi valore',
            textLines: 2,
          ),
        ),
        Panel(
          title: 'Le tappe',
          child: _milestones(
            d.timeline,
            changed,
            item: 'Tappa',
            numberLabel: 'Anno',
            addLabel: 'Aggiungi tappa',
          ),
        ),
        Panel(
          title: 'Le persone',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < d.team.length; i++)
                ItemCard(
                  key: ObjectKey(d.team[i]),
                  title: d.team[i].name.isEmpty
                      ? 'Persona ${i + 1}'
                      : d.team[i].name,
                  onUp: i == 0
                      ? null
                      : () {
                          d.team.insert(i - 1, d.team.removeAt(i));
                          changed();
                        },
                  onDown: i == d.team.length - 1
                      ? null
                      : () {
                          d.team.insert(i + 1, d.team.removeAt(i));
                          changed();
                        },
                  onDelete: () {
                    d.team.removeAt(i);
                    changed();
                  },
                  child: Column(
                    children: [
                      FieldRow(
                        children: [
                          Expanded(
                            child: _field(
                              'Nome',
                              d.team[i].name,
                              (v) => d.team[i].name = v,
                              changed,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              'Ruolo',
                              d.team[i].role,
                              (v) => d.team[i].role = v,
                              changed,
                            ),
                          ),
                        ],
                      ),
                      _gap,
                      _image(
                        'Foto',
                        d.team[i].photo,
                        (v) => d.team[i].photo = v,
                        changed,
                        aspect: 4 / 5,
                      ),
                    ],
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () {
                  d.team.add(TeamMember(name: '', role: ''));
                  changed();
                },
                icon: const Icon(Icons.add),
                label: const Text('Aggiungi persona'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ========================================================= IDENTITÀ E CONTATTI

class AdminIdentityEditor extends StatelessWidget {
  const AdminIdentityEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return DraftEditor(
      title: 'Identità e contatti',
      subtitle:
          'Nome, logo, recapiti, modulo contatti e categorie dei progetti.',
      builder: (context, d, changed) => [
        Panel(
          title: 'Identità',
          child: Column(
            children: [
              FieldRow(
                children: [
                  Expanded(
                    child: _field(
                      'Ragione sociale',
                      d.companyName,
                      (v) => d.companyName = v,
                      changed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      'Nome breve (nel logo)',
                      d.shortName,
                      (v) => d.shortName = v,
                      changed,
                    ),
                  ),
                ],
              ),
              _gap,
              _field('Slogan', d.tagline, (v) => d.tagline = v, changed),
              _gap,
              _field(
                'Testo del piè di pagina',
                d.footerText,
                (v) => d.footerText = v,
                changed,
                maxLines: 3,
              ),
              _gap,
              _image(
                'Logo (facoltativo: se vuoto si usa il logo disegnato)',
                d.logo,
                (v) => d.logo = v,
                changed,
                aspect: 3,
              ),
            ],
          ),
        ),
        Panel(
          title: 'Recapiti',
          child: Column(
            children: [
              FieldRow(
                children: [
                  Expanded(
                    child: _field(
                      'Telefono',
                      d.contacts.phone,
                      (v) => d.contacts.phone = v,
                      changed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      'WhatsApp',
                      d.contacts.whatsapp,
                      (v) => d.contacts.whatsapp = v,
                      changed,
                    ),
                  ),
                ],
              ),
              _gap,
              FieldRow(
                children: [
                  Expanded(
                    child: _field(
                      'Email',
                      d.contacts.email,
                      (v) => d.contacts.email = v,
                      changed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      'PEC',
                      d.contacts.pec,
                      (v) => d.contacts.pec = v,
                      changed,
                    ),
                  ),
                ],
              ),
              _gap,
              _field(
                'Indirizzo della sede',
                d.contacts.address,
                (v) => d.contacts.address = v,
                changed,
              ),
              _gap,
              FieldRow(
                children: [
                  Expanded(
                    child: _field(
                      'Orari ufficio',
                      d.contacts.hours,
                      (v) => d.contacts.hours = v,
                      changed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      'Partita IVA',
                      d.contacts.vat,
                      (v) => d.contacts.vat = v,
                      changed,
                    ),
                  ),
                ],
              ),
              _gap,
              FieldRow(
                children: [
                  Expanded(
                    child: _field(
                      'Instagram (link)',
                      d.contacts.instagram,
                      (v) => d.contacts.instagram = v,
                      changed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      'Facebook (link)',
                      d.contacts.facebook,
                      (v) => d.contacts.facebook = v,
                      changed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      'LinkedIn (link)',
                      d.contacts.linkedin,
                      (v) => d.contacts.linkedin = v,
                      changed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Panel(
          title: 'Pagina e modulo contatti',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(
                'Titolo',
                d.contactTitle,
                (v) => d.contactTitle = v,
                changed,
                maxLines: 3,
                helper: _titleHelper,
              ),
              _gap,
              _field(
                'Testo',
                d.contactText,
                (v) => d.contactText = v,
                changed,
                maxLines: 3,
              ),
              const SizedBox(height: 22),
              const Text(
                'Tipi di lavoro (scelta nel modulo)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _strings(d.requestTypes, changed, addLabel: 'Nuovo tipo'),
            ],
          ),
        ),
        Panel(
          title: 'Categorie dei progetti',
          subtitle: 'L\'ordine dei filtri nella pagina Progetti.',
          child: _strings(d.categories, changed, addLabel: 'Nuova categoria'),
        ),
      ],
    );
  }
}

import 'dart:math';

int _idSeq = 0;

/// Genera un id univoco leggero (niente dipendenze extra). Il contatore
/// evita doppioni anche quando se ne creano molti nello stesso istante.
String newId() {
  final r = Random();
  return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${(_idSeq++).toRadixString(36)}'
      '${r.nextInt(1 << 20).toRadixString(36)}';
}

List<T> _list<T>(Object? v, T Function(Map<String, dynamic>) f) => [
  if (v is List)
    for (final e in v)
      if (e is Map) f(Map<String, dynamic>.from(e)),
];

List<String> _strings(Object? v) =>
    v is List ? [for (final e in v) '$e'] : <String>[];

/// Titolo + testo breve (numeri dell'impresa, valori).
class Highlight {
  String title;
  String text;
  Highlight({required this.title, required this.text});

  factory Highlight.fromJson(Map<String, dynamic> j) =>
      Highlight(title: j['title'] ?? '', text: j['text'] ?? '');
  Map<String, dynamic> toJson() => {'title': title, 'text': text};
}

/// Una tappa (anno della storia o passaggio del metodo di lavoro).
class Milestone {
  String year;
  String title;
  String text;
  Milestone({required this.year, required this.title, required this.text});

  factory Milestone.fromJson(Map<String, dynamic> j) => Milestone(
    year: j['year'] ?? '',
    title: j['title'] ?? '',
    text: j['text'] ?? '',
  );
  Map<String, dynamic> toJson() => {'year': year, 'title': title, 'text': text};
}

class TeamMember {
  String id;
  String name;
  String role;
  String photo;
  TeamMember({
    String? id,
    required this.name,
    required this.role,
    this.photo = '',
  }) : id = id ?? newId();

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
    id: j['id'],
    name: j['name'] ?? '',
    role: j['role'] ?? '',
    photo: j['photo'] ?? '',
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'photo': photo,
  };
}

class Contacts {
  String phone;
  String whatsapp;
  String email;
  String pec;
  String address;
  String hours;
  String instagram;
  String facebook;
  String linkedin;
  String vat;
  Contacts({
    this.phone = '',
    this.whatsapp = '',
    this.email = '',
    this.pec = '',
    this.address = '',
    this.hours = '',
    this.instagram = '',
    this.facebook = '',
    this.linkedin = '',
    this.vat = '',
  });

  factory Contacts.fromJson(Map<String, dynamic> j) => Contacts(
    phone: j['phone'] ?? '',
    whatsapp: j['whatsapp'] ?? '',
    email: j['email'] ?? '',
    pec: j['pec'] ?? '',
    address: j['address'] ?? '',
    hours: j['hours'] ?? '',
    instagram: j['instagram'] ?? '',
    facebook: j['facebook'] ?? '',
    linkedin: j['linkedin'] ?? '',
    vat: j['vat'] ?? '',
  );
  Map<String, dynamic> toJson() => {
    'phone': phone,
    'whatsapp': whatsapp,
    'email': email,
    'pec': pec,
    'address': address,
    'hours': hours,
    'instagram': instagram,
    'facebook': facebook,
    'linkedin': linkedin,
    'vat': vat,
  };
}

/// Tutti i testi e le immagini modificabili del sito.
class SiteContent {
  // Identità
  String companyName;
  String shortName;
  String tagline;
  String logo; // vuoto = logo disegnato
  String footerText;

  // Home
  String heroKicker;
  String heroTitle;
  String heroSubtitle;
  String introKicker;
  String introTitle;
  String introText;
  List<Highlight> stats;
  String projectsKicker;
  String projectsTitle;
  String projectsText;
  String servicesKicker;
  String servicesTitle;
  String servicesText;
  List<String> ticker;
  String processKicker;
  String processTitle;
  List<Milestone> process;
  String quoteText;
  String quoteAuthor;
  String quoteImage;
  String ctaTitle;
  String ctaText;
  String ctaImage;

  // Azienda
  String aboutKicker;
  String aboutTitle;
  String aboutIntro;
  String aboutText;
  String aboutImage;
  String aboutImage2;
  List<Highlight> values;
  List<Milestone> timeline;
  List<TeamMember> team;
  List<String> certifications;

  // Contatti e modulo
  Contacts contacts;
  List<String> requestTypes;
  List<String> timings;
  String contactTitle;
  String contactText;
  String contactImage;

  /// Categorie dei progetti (filtri della pagina Progetti).
  List<String> categories;

  SiteContent({
    required this.companyName,
    required this.shortName,
    required this.tagline,
    this.logo = '',
    this.footerText = '',
    this.heroKicker = '',
    this.heroTitle = '',
    this.heroSubtitle = '',
    this.introKicker = '',
    this.introTitle = '',
    this.introText = '',
    List<Highlight>? stats,
    this.projectsKicker = '',
    this.projectsTitle = '',
    this.projectsText = '',
    this.servicesKicker = '',
    this.servicesTitle = '',
    this.servicesText = '',
    List<String>? ticker,
    this.processKicker = '',
    this.processTitle = '',
    List<Milestone>? process,
    this.quoteText = '',
    this.quoteAuthor = '',
    this.quoteImage = '',
    this.ctaTitle = '',
    this.ctaText = '',
    this.ctaImage = '',
    this.aboutKicker = '',
    this.aboutTitle = '',
    this.aboutIntro = '',
    this.aboutText = '',
    this.aboutImage = '',
    this.aboutImage2 = '',
    List<Highlight>? values,
    List<Milestone>? timeline,
    List<TeamMember>? team,
    List<String>? certifications,
    Contacts? contacts,
    List<String>? requestTypes,
    List<String>? timings,
    this.contactTitle = '',
    this.contactText = '',
    this.contactImage = '',
    List<String>? categories,
  }) : stats = stats ?? [],
       ticker = ticker ?? [],
       process = process ?? [],
       values = values ?? [],
       timeline = timeline ?? [],
       team = team ?? [],
       certifications = certifications ?? [],
       contacts = contacts ?? Contacts(),
       requestTypes = requestTypes ?? [],
       timings = timings ?? [],
       categories = categories ?? [];

  /// Legge i dati salvati; i campi mancanti (versioni precedenti) prendono
  /// il valore di [d], i contenuti di esempio.
  factory SiteContent.fromJson(Map<String, dynamic> j, SiteContent d) {
    String s(String k, String def) => j[k] is String ? j[k] as String : def;
    List<String> l(String k, List<String> def) =>
        j[k] is List ? _strings(j[k]) : def;
    return SiteContent(
      companyName: s('companyName', d.companyName),
      shortName: s('shortName', d.shortName),
      tagline: s('tagline', d.tagline),
      logo: s('logo', d.logo),
      footerText: s('footerText', d.footerText),
      heroKicker: s('heroKicker', d.heroKicker),
      heroTitle: s('heroTitle', d.heroTitle),
      heroSubtitle: s('heroSubtitle', d.heroSubtitle),
      introKicker: s('introKicker', d.introKicker),
      introTitle: s('introTitle', d.introTitle),
      introText: s('introText', d.introText),
      stats: j['stats'] is List
          ? _list(j['stats'], Highlight.fromJson)
          : d.stats,
      projectsKicker: s('projectsKicker', d.projectsKicker),
      projectsTitle: s('projectsTitle', d.projectsTitle),
      projectsText: s('projectsText', d.projectsText),
      servicesKicker: s('servicesKicker', d.servicesKicker),
      servicesTitle: s('servicesTitle', d.servicesTitle),
      servicesText: s('servicesText', d.servicesText),
      ticker: l('ticker', d.ticker),
      processKicker: s('processKicker', d.processKicker),
      processTitle: s('processTitle', d.processTitle),
      process: j['process'] is List
          ? _list(j['process'], Milestone.fromJson)
          : d.process,
      quoteText: s('quoteText', d.quoteText),
      quoteAuthor: s('quoteAuthor', d.quoteAuthor),
      quoteImage: s('quoteImage', d.quoteImage),
      ctaTitle: s('ctaTitle', d.ctaTitle),
      ctaText: s('ctaText', d.ctaText),
      ctaImage: s('ctaImage', d.ctaImage),
      aboutKicker: s('aboutKicker', d.aboutKicker),
      aboutTitle: s('aboutTitle', d.aboutTitle),
      aboutIntro: s('aboutIntro', d.aboutIntro),
      aboutText: s('aboutText', d.aboutText),
      aboutImage: s('aboutImage', d.aboutImage),
      aboutImage2: s('aboutImage2', d.aboutImage2),
      values: j['values'] is List
          ? _list(j['values'], Highlight.fromJson)
          : d.values,
      timeline: j['timeline'] is List
          ? _list(j['timeline'], Milestone.fromJson)
          : d.timeline,
      team: j['team'] is List ? _list(j['team'], TeamMember.fromJson) : d.team,
      certifications: l('certifications', d.certifications),
      contacts: j['contacts'] is Map
          ? Contacts.fromJson(Map<String, dynamic>.from(j['contacts']))
          : d.contacts,
      requestTypes: l('requestTypes', d.requestTypes),
      timings: l('timings', d.timings),
      contactTitle: s('contactTitle', d.contactTitle),
      contactText: s('contactText', d.contactText),
      contactImage: s('contactImage', d.contactImage),
      categories: l('categories', d.categories),
    );
  }

  Map<String, dynamic> toJson() => {
    'companyName': companyName,
    'shortName': shortName,
    'tagline': tagline,
    'logo': logo,
    'footerText': footerText,
    'heroKicker': heroKicker,
    'heroTitle': heroTitle,
    'heroSubtitle': heroSubtitle,
    'introKicker': introKicker,
    'introTitle': introTitle,
    'introText': introText,
    'stats': stats.map((e) => e.toJson()).toList(),
    'projectsKicker': projectsKicker,
    'projectsTitle': projectsTitle,
    'projectsText': projectsText,
    'servicesKicker': servicesKicker,
    'servicesTitle': servicesTitle,
    'servicesText': servicesText,
    'ticker': ticker,
    'processKicker': processKicker,
    'processTitle': processTitle,
    'process': process.map((e) => e.toJson()).toList(),
    'quoteText': quoteText,
    'quoteAuthor': quoteAuthor,
    'quoteImage': quoteImage,
    'ctaTitle': ctaTitle,
    'ctaText': ctaText,
    'ctaImage': ctaImage,
    'aboutKicker': aboutKicker,
    'aboutTitle': aboutTitle,
    'aboutIntro': aboutIntro,
    'aboutText': aboutText,
    'aboutImage': aboutImage,
    'aboutImage2': aboutImage2,
    'values': values.map((e) => e.toJson()).toList(),
    'timeline': timeline.map((e) => e.toJson()).toList(),
    'team': team.map((e) => e.toJson()).toList(),
    'certifications': certifications,
    'contacts': contacts.toJson(),
    'requestTypes': requestTypes,
    'timings': timings,
    'contactTitle': contactTitle,
    'contactText': contactText,
    'contactImage': contactImage,
    'categories': categories,
  };

  SiteContent copy() => SiteContent.fromJson(toJson(), this);
}

// ------------------------------------------------------------------ progetti

enum ProjectStatus { completato, inCorso }

extension ProjectStatusLabel on ProjectStatus {
  String get label => switch (this) {
    ProjectStatus.completato => 'Completato',
    ProjectStatus.inCorso => 'In corso',
  };
}

class ProjectPhoto {
  String url;
  String caption;
  ProjectPhoto({required this.url, this.caption = ''});

  factory ProjectPhoto.fromJson(Map<String, dynamic> j) =>
      ProjectPhoto(url: j['url'] ?? '', caption: j['caption'] ?? '');
  Map<String, dynamic> toJson() => {'url': url, 'caption': caption};
}

/// Un lavoro realizzato (o in corso) dall'impresa.
class Project {
  String id;
  String title;
  String category;
  String location;
  String year;
  String client;
  String area; // superficie, testo libero (es. "1.250 m²")
  String duration; // es. "14 mesi"
  ProjectStatus status;
  String summary; // una riga per le schede
  String description; // racconto del progetto
  List<String> works; // interventi eseguiti
  String cover;
  List<ProjectPhoto> photos;
  String before; // foto "prima" per il confronto
  String after; // foto "dopo" (se vuota si usa la copertina)
  bool featured;
  bool published;

  Project({
    String? id,
    required this.title,
    this.category = '',
    this.location = '',
    this.year = '',
    this.client = '',
    this.area = '',
    this.duration = '',
    this.status = ProjectStatus.completato,
    this.summary = '',
    this.description = '',
    List<String>? works,
    this.cover = '',
    List<ProjectPhoto>? photos,
    this.before = '',
    this.after = '',
    this.featured = false,
    this.published = true,
  }) : id = id ?? newId(),
       works = works ?? [],
       photos = photos ?? [];

  /// Copertina effettiva: quella scelta o la prima foto.
  String get coverUrl => cover.trim().isNotEmpty
      ? cover
      : (photos.isNotEmpty ? photos.first.url : '');

  bool get hasComparison => before.trim().isNotEmpty;
  String get afterUrl => after.trim().isNotEmpty ? after : coverUrl;

  factory Project.fromJson(Map<String, dynamic> j) => Project(
    id: j['id'],
    title: j['title'] ?? '',
    category: j['category'] ?? '',
    location: j['location'] ?? '',
    year: j['year'] ?? '',
    client: j['client'] ?? '',
    area: j['area'] ?? '',
    duration: j['duration'] ?? '',
    status: ProjectStatus.values.firstWhere(
      (e) => e.name == j['status'],
      orElse: () => ProjectStatus.completato,
    ),
    summary: j['summary'] ?? '',
    description: j['description'] ?? '',
    works: _strings(j['works']),
    cover: j['cover'] ?? '',
    photos: _list(j['photos'], ProjectPhoto.fromJson),
    before: j['before'] ?? '',
    after: j['after'] ?? '',
    featured: j['featured'] ?? false,
    published: j['published'] ?? true,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'location': location,
    'year': year,
    'client': client,
    'area': area,
    'duration': duration,
    'status': status.name,
    'summary': summary,
    'description': description,
    'works': works,
    'cover': cover,
    'photos': photos.map((e) => e.toJson()).toList(),
    'before': before,
    'after': after,
    'featured': featured,
    'published': published,
  };
}

/// Un servizio dell'impresa (nuove costruzioni, ristrutturazioni…).
class ServiceItem {
  String id;
  String title;
  String text;
  String image;
  List<String> points;
  bool active;
  ServiceItem({
    String? id,
    required this.title,
    this.text = '',
    this.image = '',
    List<String>? points,
    this.active = true,
  }) : id = id ?? newId(),
       points = points ?? [];

  factory ServiceItem.fromJson(Map<String, dynamic> j) => ServiceItem(
    id: j['id'],
    title: j['title'] ?? '',
    text: j['text'] ?? '',
    image: j['image'] ?? '',
    points: _strings(j['points']),
    active: j['active'] ?? true,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'text': text,
    'image': image,
    'points': points,
    'active': active,
  };
}

/// Parole di un cliente (inserite dal gestionale).
class Testimonial {
  String id;
  String name;
  String role; // es. "Committente · Villa Le Querce"
  String text;
  bool published;
  Testimonial({
    String? id,
    required this.name,
    this.role = '',
    required this.text,
    this.published = true,
  }) : id = id ?? newId();

  factory Testimonial.fromJson(Map<String, dynamic> j) => Testimonial(
    id: j['id'],
    name: j['name'] ?? '',
    role: j['role'] ?? '',
    text: j['text'] ?? '',
    published: j['published'] ?? true,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'text': text,
    'published': published,
  };
}

// ------------------------------------------------------------------ richieste

enum RequestStatus {
  nuova,
  contattata,
  sopralluogo,
  preventivo,
  acquisita,
  archiviata,
}

extension RequestStatusLabel on RequestStatus {
  String get label => switch (this) {
    RequestStatus.nuova => 'Nuova',
    RequestStatus.contattata => 'Contattata',
    RequestStatus.sopralluogo => 'Sopralluogo',
    RequestStatus.preventivo => 'Preventivo inviato',
    RequestStatus.acquisita => 'Lavoro acquisito',
    RequestStatus.archiviata => 'Archiviata',
  };
}

/// Richiesta arrivata dal modulo contatti del sito.
class ContactRequest {
  String id;
  DateTime createdAt;
  String name;
  String phone;
  String email;
  String city;
  String type; // tipo di intervento
  String timing;
  String area;
  String message;
  String projectRef; // progetto da cui è partita ("vorrei qualcosa di simile")
  RequestStatus status;
  String? appointmentId;
  String notes; // appunti interni

  ContactRequest({
    String? id,
    DateTime? createdAt,
    required this.name,
    required this.phone,
    required this.email,
    this.city = '',
    this.type = '',
    this.timing = '',
    this.area = '',
    this.message = '',
    this.projectRef = '',
    this.status = RequestStatus.nuova,
    this.appointmentId,
    this.notes = '',
  }) : id = id ?? newId(),
       createdAt = createdAt ?? DateTime.now();

  /// Riga riassuntiva: intervento e città.
  String get summary => [
    if (type.trim().isNotEmpty) type.trim(),
    if (city.trim().isNotEmpty) city.trim(),
  ].join(' · ');

  factory ContactRequest.fromJson(Map<String, dynamic> j) => ContactRequest(
    id: j['id'],
    createdAt: DateTime.tryParse(j['createdAt'] ?? ''),
    name: j['name'] ?? '',
    phone: j['phone'] ?? '',
    email: j['email'] ?? '',
    city: j['city'] ?? '',
    type: j['type'] ?? '',
    timing: j['timing'] ?? '',
    area: j['area'] ?? '',
    message: j['message'] ?? '',
    projectRef: j['projectRef'] ?? '',
    status: RequestStatus.values.firstWhere(
      (e) => e.name == j['status'],
      orElse: () => RequestStatus.nuova,
    ),
    appointmentId: j['appointmentId'],
    notes: j['notes'] ?? '',
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'name': name,
    'phone': phone,
    'email': email,
    'city': city,
    'type': type,
    'timing': timing,
    'area': area,
    'message': message,
    'projectRef': projectRef,
    'status': status.name,
    'appointmentId': appointmentId,
    'notes': notes,
  };
}

class Appointment {
  String id;
  String title;
  DateTime start;
  DateTime end;
  bool allDay;
  String location;
  String notes;
  String? requestId;
  String? googleEventId;

  Appointment({
    String? id,
    required this.title,
    required this.start,
    required this.end,
    this.allDay = false,
    this.location = '',
    this.notes = '',
    this.requestId,
    this.googleEventId,
  }) : id = id ?? newId();

  factory Appointment.fromJson(Map<String, dynamic> j) => Appointment(
    id: j['id'],
    title: j['title'] ?? '',
    start: DateTime.tryParse(j['start'] ?? '') ?? DateTime.now(),
    end: DateTime.tryParse(j['end'] ?? '') ?? DateTime.now(),
    allDay: j['allDay'] ?? false,
    location: j['location'] ?? '',
    notes: j['notes'] ?? '',
    requestId: j['requestId'],
    googleEventId: j['googleEventId'],
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'allDay': allDay,
    'location': location,
    'notes': notes,
    'requestId': requestId,
    'googleEventId': googleEventId,
  };
}

/// Chi vede il pulsante "Colori" sul sito.
enum SwitcherMode { tutti, link, nessuno }

extension SwitcherModeLabel on SwitcherMode {
  String get label => switch (this) {
    SwitcherMode.tutti => 'Visibile a tutti',
    SwitcherMode.link => 'Solo con il link di prova',
    SwitcherMode.nessuno => 'Nascosto',
  };
}

/// Colori del sito: tavolozza predefinita, quelle proposte ai visitatori e
/// chi vede il pulsante.
class LookSettings {
  String defaultTheme;
  List<String> hidden; // tavolozze da non proporre
  SwitcherMode switcher;
  LookSettings({
    this.defaultTheme = 'cantiere',
    List<String>? hidden,
    this.switcher = SwitcherMode.tutti,
  }) : hidden = hidden ?? [];

  factory LookSettings.fromJson(Map<String, dynamic> j) => LookSettings(
    defaultTheme: j['defaultTheme'] ?? 'cantiere',
    hidden: _strings(j['hidden']),
    switcher: SwitcherMode.values.firstWhere(
      (e) => e.name == j['switcher'],
      orElse: () => SwitcherMode.tutti,
    ),
  );
  Map<String, dynamic> toJson() => {
    'defaultTheme': defaultTheme,
    'hidden': hidden,
    'switcher': switcher.name,
  };
}

/// Impostazioni riservate al titolare (non pubbliche).
class AdminSettings {
  String passwordHash;
  String passwordSalt;
  String googleClientId;
  bool googleWasConnected;

  /// Fine della sessione "ricordami" su questo dispositivo.
  DateTime? sessionUntil;
  AdminSettings({
    this.passwordHash = '',
    this.passwordSalt = '',
    this.googleClientId = '',
    this.googleWasConnected = false,
    this.sessionUntil,
  });

  factory AdminSettings.fromJson(Map<String, dynamic> j) => AdminSettings(
    passwordHash: j['passwordHash'] ?? '',
    passwordSalt: j['passwordSalt'] ?? '',
    googleClientId: j['googleClientId'] ?? '',
    googleWasConnected: j['googleWasConnected'] ?? false,
    sessionUntil: DateTime.tryParse(j['sessionUntil'] ?? ''),
  );
  Map<String, dynamic> toJson() => {
    'passwordHash': passwordHash,
    'passwordSalt': passwordSalt,
    'googleClientId': googleClientId,
    'googleWasConnected': googleWasConnected,
    'sessionUntil': sessionUntil?.toIso8601String(),
  };
}

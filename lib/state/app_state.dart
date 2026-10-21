import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';
import '../data/repository.dart';
import '../data/seed.dart';
import '../models/models.dart';
import '../services/google_calendar_service.dart';
import '../services/google_token.dart';
import '../theme/site_theme.dart';

class AppState extends ChangeNotifier {
  AppState(this.repo);
  final Repository repo;

  bool loaded = false;
  bool adminAuthenticated = false;

  late SiteContent content;
  List<Project> projects = [];
  List<ServiceItem> services = [];
  List<Testimonial> testimonials = [];
  List<ContactRequest> requests = [];
  List<Appointment> appointments = [];
  LookSettings look = LookSettings();
  AdminSettings settings = AdminSettings();

  final GoogleCalendarService calendar = GoogleCalendarService();

  // ---------------------------------------------------------------- load

  Future<void> load() async {
    final seed = Seed.content();
    final c = await repo.read('content');
    content = c is Map
        ? SiteContent.fromJson(Map<String, dynamic>.from(c), seed)
        : seed;

    projects = await _list('projects', Project.fromJson) ?? Seed.projects();
    services = await _list('services', ServiceItem.fromJson) ?? Seed.services();
    testimonials =
        await _list('testimonials', Testimonial.fromJson) ??
        Seed.testimonials();
    requests = await _list('requests', ContactRequest.fromJson) ?? [];
    appointments = await _list('appointments', Appointment.fromJson) ?? [];

    final l = await repo.read('look');
    look = l is Map
        ? LookSettings.fromJson(Map<String, dynamic>.from(l))
        : LookSettings();

    final s = await repo.read('settings');
    settings = s is Map
        ? AdminSettings.fromJson(Map<String, dynamic>.from(s))
        : AdminSettings();
    final until = settings.sessionUntil;
    adminAuthenticated = until != null && DateTime.now().isBefore(until);

    loaded = true;
    notifyListeners();
  }

  Future<List<T>?> _list<T>(
    String key,
    T Function(Map<String, dynamic>) f,
  ) async {
    final v = await repo.read(key);
    if (v is! List) return null;
    return [
      for (final e in v)
        if (e is Map) f(Map<String, dynamic>.from(e)),
    ];
  }

  Future<void> _persist(String key, Object json) async {
    await repo.write(key, json);
    notifyListeners();
  }

  // ---------------------------------------------------------------- colori

  /// Tavolozza scelta da chi sta guardando il sito (solo per questa visita).
  String? _visitorTheme;

  /// Il link di prova (?prova=1) mostra il pulsante "Colori" anche quando è
  /// riservato.
  bool trialUnlocked = false;

  SiteTheme? themeById(String? id) {
    for (final t in builtInThemes) {
      if (t.id == id) return t;
    }
    return null;
  }

  SiteTheme get defaultTheme =>
      themeById(look.defaultTheme) ?? builtInThemes.first;

  /// Tavolozze proposte dal pulsante (la predefinita c'è sempre).
  List<SiteTheme> get offeredThemes => [
    for (final t in builtInThemes)
      if (!look.hidden.contains(t.id) || t.id == defaultTheme.id) t,
  ];

  /// La tavolozza con cui si vede ora il sito.
  SiteTheme get currentTheme => themeById(_visitorTheme) ?? defaultTheme;

  bool get switcherVisible =>
      look.switcher == SwitcherMode.tutti ||
      (look.switcher == SwitcherMode.link && trialUnlocked);

  void selectTheme(String id) {
    if (themeById(id) == null || id == currentTheme.id) return;
    _visitorTheme = id;
    notifyListeners();
  }

  /// Legge i parametri del link: `?prova=1` sblocca il pulsante dei colori,
  /// `?tema=progetto` apre il sito con quella tavolozza (da mandare a un
  /// cliente).
  void applyLinkParams(Map<String, String> q) {
    var changed = false;
    if (q['prova'] == '1' && !trialUnlocked) {
      trialUnlocked = true;
      changed = true;
    }
    final t = q['tema'];
    if (t != null && themeById(t) != null && t != _visitorTheme) {
      _visitorTheme = t;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  Future<void> setLook(LookSettings l) {
    look = l;
    return _persist('look', l.toJson());
  }

  // -------------------------------------------------------- public views

  List<Project> get publishedProjects =>
      projects.where((p) => p.published).toList();

  /// Progetti in evidenza in Home (se nessuno è segnato, i primi pubblicati).
  List<Project> get featuredProjects {
    final f = publishedProjects.where((p) => p.featured).toList();
    return f.isNotEmpty ? f : publishedProjects.take(4).toList();
  }

  /// Le foto della prima schermata: le copertine dei progetti in evidenza.
  List<Project> get heroProjects => featuredProjects
      .where((p) => p.coverUrl.trim().isNotEmpty)
      .take(6)
      .toList();

  List<ServiceItem> get activeServices =>
      services.where((s) => s.active).toList();
  List<Testimonial> get publishedTestimonials =>
      testimonials.where((t) => t.published).toList();

  /// Categorie che hanno almeno un progetto pubblicato, nell'ordine scelto
  /// nel gestionale (più quelle scritte solo nei progetti).
  List<String> get usedCategories {
    final used = {for (final p in publishedProjects) p.category.trim()}
      ..remove('');
    return [
      for (final c in content.categories)
        if (used.remove(c)) c,
      ...used,
    ];
  }

  Project? projectById(String? id) {
    for (final p in projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  ContactRequest? requestById(String? id) {
    if (id == null) return null;
    for (final r in requests) {
      if (r.id == id) return r;
    }
    return null;
  }

  int get newRequests =>
      requests.where((r) => r.status == RequestStatus.nuova).length;

  // ------------------------------------------------------------ mutations

  Future<void> updateContent(SiteContent c) {
    content = c;
    return _persist('content', c.toJson());
  }

  Future<void> setProjects(List<Project> list) {
    projects = list;
    return _persist('projects', list.map((e) => e.toJson()).toList());
  }

  Future<void> setServices(List<ServiceItem> list) {
    services = list;
    return _persist('services', list.map((e) => e.toJson()).toList());
  }

  Future<void> setTestimonials(List<Testimonial> list) {
    testimonials = list;
    return _persist('testimonials', list.map((e) => e.toJson()).toList());
  }

  Future<void> _persistRequests() =>
      _persist('requests', requests.map((e) => e.toJson()).toList());

  Future<void> addRequest(ContactRequest r) {
    requests = [r, ...requests];
    return _persistRequests();
  }

  Future<void> updateRequest(ContactRequest r) {
    requests = [for (final e in requests) e.id == r.id ? r : e];
    return _persistRequests();
  }

  Future<void> deleteRequest(String id) {
    requests = requests.where((e) => e.id != id).toList();
    return _persistRequests();
  }

  Future<void> _persistAppointments() =>
      _persist('appointments', appointments.map((e) => e.toJson()).toList());

  // ---------------------------------------------------------- appointments

  /// Salva l'appuntamento in locale e, se Google è collegato, anche su Google
  /// Calendar. Restituisce un avviso se la sincronizzazione non è riuscita.
  Future<String?> saveAppointment(Appointment a) async {
    String? warning;
    if (calendar.connected) {
      try {
        if (a.googleEventId == null) {
          a.googleEventId = await calendar.insert(a);
        } else {
          await calendar.update(a);
        }
      } on GoogleAuthException catch (e) {
        warning = e.message;
      } catch (e) {
        warning = 'Sincronizzazione con Google non riuscita: $e';
      }
    } else if (settings.googleWasConnected) {
      warning = 'Appuntamento salvato solo qui: ricollega Google Calendar per sincronizzarlo.';
    }
    final i = appointments.indexWhere((e) => e.id == a.id);
    if (i >= 0) {
      appointments[i] = a;
    } else {
      appointments = [...appointments, a];
    }
    await _persistAppointments();
    return warning;
  }

  Future<String?> deleteAppointment(Appointment a) async {
    String? warning;
    if (a.googleEventId != null && calendar.connected) {
      try {
        await calendar.delete(a.googleEventId!);
      } on GoogleAuthException catch (e) {
        warning = e.message;
      } catch (e) {
        warning = 'Impossibile eliminarlo anche da Google Calendar: $e';
      }
    } else if (a.googleEventId != null) {
      warning = 'Eliminato qui, ma resta su Google Calendar: ricollegalo per rimuoverlo anche lì.';
    }
    appointments = appointments.where((e) => e.id != a.id).toList();
    for (final r in requests) {
      if (r.appointmentId == a.id) r.appointmentId = null;
    }
    await _persistRequests();
    await _persistAppointments();
    return warning;
  }

  /// Invia a Google gli appuntamenti locali non ancora sincronizzati.
  Future<int> pushUnsyncedToGoogle() async {
    var n = 0;
    try {
      for (final a in appointments.where((e) => e.googleEventId == null)) {
        a.googleEventId = await calendar.insert(a);
        n++;
      }
    } finally {
      // Anche se uno degli invii fallisce, quelli già riusciti vanno salvati:
      // altrimenti al prossimo tentativo finirebbero doppi su Google.
      if (n > 0) await _persistAppointments();
    }
    return n;
  }

  // ----------------------------------------------------- Google Calendar

  String get googleClientId => settings.googleClientId.trim().isNotEmpty
      ? settings.googleClientId.trim()
      : AppConfig.googleClientId;

  bool get googleConfigured => googleClientId.isNotEmpty;

  Future<void> connectGoogle() async {
    await calendar.connect(googleClientId);
    settings.googleWasConnected = true;
    await _persist('settings', settings.toJson());
  }

  Future<void> disconnectGoogle() async {
    calendar.disconnect();
    settings.googleWasConnected = false;
    await _persist('settings', settings.toJson());
  }

  Future<void> saveGoogleClientId(String id) {
    settings.googleClientId = id.trim();
    return _persist('settings', settings.toJson());
  }

  // ------------------------------------------------------------ admin auth

  bool get hasAdminPassword => settings.passwordHash.isNotEmpty;

  String _hash(String salt, String pw) =>
      sha256.convert(utf8.encode('$salt::$pw')).toString();

  Future<void> setAdminPassword(String pw, {bool remember = true}) async {
    final r = Random.secure();
    final salt = base64Url.encode(
      List<int>.generate(16, (_) => r.nextInt(256)),
    );
    settings.passwordSalt = salt;
    settings.passwordHash = _hash(salt, pw);
    adminAuthenticated = true;
    if (remember) _rememberSession();
    await _persist('settings', settings.toJson());
  }

  /// Verifica la password senza modificare lo stato di accesso.
  bool checkPassword(String pw) =>
      hasAdminPassword &&
      _hash(settings.passwordSalt, pw) == settings.passwordHash;

  Future<bool> login(String pw, {bool remember = true}) async {
    if (!checkPassword(pw)) return false;
    adminAuthenticated = true;
    if (remember) {
      _rememberSession();
      await _persist('settings', settings.toJson());
    } else {
      notifyListeners();
    }
    return true;
  }

  void _rememberSession() =>
      settings.sessionUntil = DateTime.now().add(const Duration(days: 30));

  Future<void> logout() async {
    adminAuthenticated = false;
    settings.sessionUntil = null;
    await _persist('settings', settings.toJson());
  }

  /// Caratteri occupati dalle immagini incorporate (data URL) nell'archivio del
  /// browser, che ha un limite di circa 5 MB.
  int get embeddedImageChars {
    var n = 0;
    void add(String u) {
      if (u.startsWith('data:')) n += u.length;
    }

    for (final p in projects) {
      add(p.cover);
      add(p.before);
      add(p.after);
      for (final f in p.photos) {
        add(f.url);
      }
    }
    for (final s in services) {
      add(s.image);
    }
    for (final t in content.team) {
      add(t.photo);
    }
    for (final u in [
      content.logo,
      content.aboutImage,
      content.aboutImage2,
      content.contactImage,
    ]) {
      add(u);
    }
    return n;
  }

  static const _sections = [
    'content',
    'projects',
    'services',
    'testimonials',
    'requests',
    'appointments',
    'look',
  ];

  /// Copia di sicurezza di tutti i dati in un'unica stringa JSON.
  String exportBackup() => const JsonEncoder.withIndent(' ').convert({
    'version': 1,
    'content': content.toJson(),
    'projects': projects.map((e) => e.toJson()).toList(),
    'services': services.map((e) => e.toJson()).toList(),
    'testimonials': testimonials.map((e) => e.toJson()).toList(),
    'requests': requests.map((e) => e.toJson()).toList(),
    'appointments': appointments.map((e) => e.toJson()).toList(),
    'look': look.toJson(),
  });

  Future<void> importBackup(String raw) async {
    const invalid = FormatException(
      'Il testo incollato non è una copia di sicurezza valida.',
    );
    final Object? j;
    try {
      j = jsonDecode(raw);
    } on FormatException {
      throw invalid;
    }
    if (j is! Map || j['content'] is! Map) throw invalid;
    // Prima di sovrascrivere i dati attuali verifica che ogni sezione si possa
    // leggere: un backup rovinato renderebbe il sito inutilizzabile anche
    // dopo aver ricaricato la pagina.
    final parsers = <String, Object Function(Map<String, dynamic>)>{
      'projects': Project.fromJson,
      'services': ServiceItem.fromJson,
      'testimonials': Testimonial.fromJson,
      'requests': ContactRequest.fromJson,
      'appointments': Appointment.fromJson,
    };
    try {
      SiteContent.fromJson(
        Map<String, dynamic>.from(j['content'] as Map),
        Seed.content(),
      );
      for (final MapEntry(key: k, value: parse) in parsers.entries) {
        final v = j[k];
        if (v == null) continue;
        for (final e in v as List) {
          parse(Map<String, dynamic>.from(e as Map));
        }
      }
      if (j['look'] != null) {
        LookSettings.fromJson(Map<String, dynamic>.from(j['look'] as Map));
      }
    } catch (_) {
      throw invalid;
    }
    for (final k in _sections) {
      if (j[k] != null) await repo.write(k, j[k] as Object);
    }
    await load();
  }

  /// Rimette i contenuti di esempio. Richieste e appuntamenti restano.
  Future<void> resetAll() async {
    await repo.write('content', Seed.content().toJson());
    await repo.write(
      'projects',
      Seed.projects().map((e) => e.toJson()).toList(),
    );
    await repo.write(
      'services',
      Seed.services().map((e) => e.toJson()).toList(),
    );
    await repo.write(
      'testimonials',
      Seed.testimonials().map((e) => e.toJson()).toList(),
    );
    await load();
  }
}

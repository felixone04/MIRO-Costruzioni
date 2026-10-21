import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miro_costruzioni/data/seed.dart';
import 'package:miro_costruzioni/models/models.dart';
import 'package:miro_costruzioni/state/app_state.dart';
import 'package:miro_costruzioni/theme/site_theme.dart';
import 'package:miro_costruzioni/widgets/theme_switcher.dart';

import 'support/harness.dart';

void main() {
  setUpAll(setUpTestEnv);

  group('Pagine su ogni schermo', () {
    const pages = [
      '/',
      '/progetti',
      '/progetti/p-casa-bianca',
      '/progetti/inesistente',
      '/servizi',
      '/azienda',
      '/contatti',
      '/servizi?s=s-restauro',
      '/area-clienti',
      '/admin',
    ];
    for (final size in screenSizes) {
      testWidgets('si aprono e si scorrono senza errori a ${sizeName(size)}', (
        t,
      ) async {
        final s = await loadState();
        await pumpApp(t, s, size: size);
        for (final p in pages) {
          await goTo(t, p);
          if (!p.startsWith('/admin')) await scrollThrough(t);
          expect(t.takeException(), isNull, reason: 'pagina $p');
        }
        await disposeApp(t);
      });
    }
  });

  group('Gestionale su ogni schermo', () {
    const sections = [
      'panoramica',
      'richieste',
      'calendario',
      'progetti',
      'servizi',
      'testimonianze',
      'stile',
      'home',
      'azienda',
      'contatti',
      'impostazioni',
      'clienti',
      'cantieri',
      'cantieri?id=w-demo',
    ];
    for (final size in [screenSizes[0], screenSizes[2], screenSizes[4]]) {
      testWidgets('tutte le sezioni a ${sizeName(size)}', (t) async {
        final s = await loadState();
        await s.setAdminPassword('password-di-prova');
        await s.addRequest(
          ContactRequest(
            name: 'Mario Rossi',
            phone: '+39 333 000 0000',
            email: 'mario@example.com',
            city: 'Bari',
            type: 'Ristrutturazione',
            message: 'Vorrei rifare casa.',
          ),
        );
        await pumpApp(t, s, location: '/admin', size: size);
        for (final sec in sections) {
          await goTo(t, '/admin/$sec');
          expect(t.takeException(), isNull, reason: 'sezione $sec');
        }
        await disposeApp(t);
      });
    }
  });

  testWidgets('il modulo contatti salva la richiesta', (t) async {
    final s = await loadState();
    await pumpApp(t, s, location: '/contatti', size: const Size(1440, 900));
    final fields = find.byType(TextFormField);
    await t.enterText(fields.at(0), 'Giulia Bianchi');
    await t.enterText(fields.at(1), '+39 333 1234567');
    await t.enterText(fields.at(2), 'giulia@example.com');
    await t.enterText(fields.at(3), 'Monopoli');
    await bringIntoView(t, find.text('Ristrutturazione'));
    await t.tap(find.text('Ristrutturazione'));
    await t.pump();
    await bringIntoView(t, find.byType(CheckboxListTile));
    await t.tap(find.byType(CheckboxListTile));
    await t.pump();
    await bringIntoView(t, find.text('Invia'));
    await t.tap(find.text('Invia'));
    await settle(t, 1600);
    expect(s.requests, hasLength(1));
    expect(s.requests.first.name, 'Giulia Bianchi');
    expect(s.requests.first.type, 'Ristrutturazione');
    expect(find.text('Richiesta inviata'), findsOneWidget);
    await disposeApp(t);
  });

  testWidgets('il modulo blocca l\'invio senza consenso', (t) async {
    final s = await loadState();
    await pumpApp(t, s, location: '/contatti', size: const Size(390, 844));
    final fields = find.byType(TextFormField);
    await t.enterText(fields.at(0), 'Luca');
    await t.enterText(fields.at(1), '3331234567');
    await t.enterText(fields.at(2), 'luca@example.com');
    await bringIntoView(t, find.text('Invia'));
    await t.tap(find.text('Invia'));
    await settle(t, 800);
    expect(s.requests, isEmpty);
    expect(
      find.text('Serve il consenso per inviare il messaggio.'),
      findsOneWidget,
    );
    await disposeApp(t);
  });

  group('Colori', () {
    testWidgets('il pulsante "Colori" cambia la tavolozza di tutto il sito', (
      t,
    ) async {
      final s = await loadState();
      await pumpApp(t, s);
      expect(find.byType(ThemeSwitcher), findsOneWidget);
      expect(Site.current.id, 'sabbia');

      await t.tap(find.text('Colori'));
      await settle(t, 600);
      await t.tap(find.text('Bordeaux'));
      await settle(t, 1200);
      expect(s.currentTheme.id, 'bordeaux');
      expect(Site.accent, builtInThemes[3].accent);
      expect(t.takeException(), isNull);
      await disposeApp(t);
    });

    testWidgets('solo con il link di prova, se così scelto nel gestionale', (
      t,
    ) async {
      final s = await loadState();
      await s.setLook(LookSettings(switcher: SwitcherMode.link));
      await pumpApp(t, s);
      expect(find.byType(ThemeSwitcher), findsNothing);
      s.applyLinkParams({'prova': '1'});
      await settle(t, 600);
      expect(find.byType(ThemeSwitcher), findsOneWidget);
      await disposeApp(t);
    });

    test('il link ?tema= apre il sito con quella tavolozza', () async {
      final s = await loadState();
      s.applyLinkParams({'tema': 'terra'});
      expect(s.currentTheme.id, 'terra');
      s.applyLinkParams({'tema': 'inesistente'});
      expect(s.currentTheme.id, 'terra');
    });

    test('predefinita e tavolozze nascoste', () async {
      final s = await loadState();
      await s.setLook(
        LookSettings(defaultTheme: 'bordeaux', hidden: ['bordeaux', 'salvia']),
      );
      expect(s.currentTheme.id, 'bordeaux');
      // La predefinita resta proposta anche se segnata come nascosta.
      final ids = s.offeredThemes.map((e) => e.id);
      expect(ids, contains('bordeaux'));
      expect(ids, isNot(contains('salvia')));
    });
  });

  group('Area clienti', () {
    for (final size in [screenSizes[0], screenSizes[2], screenSizes[4]]) {
      testWidgets(
        'il cliente entra e vede il suo cantiere a ${sizeName(size)}',
        (t) async {
          final s = await loadState();
          await pumpApp(t, s, location: '/area-clienti', size: size);
          final fields = find.byType(TextField);
          await t.enterText(fields.at(0), Seed.demoEmail);
          await t.enterText(fields.at(1), Seed.demoPassword);
          await bringIntoView(t, find.text('Entra'));
          await t.tap(find.text('Entra'));
          await settle(t, 1200);
          expect(s.currentClient?.email, Seed.demoEmail);
          expect(find.text('Casa Lorusso, ristrutturazione'), findsOneWidget);

          await goTo(t, '/area-clienti/w-demo');
          await scrollThrough(t);
          expect(t.takeException(), isNull);
          expect(find.text('Documenti'), findsOneWidget);
          // Aprendo il cantiere i messaggi dell'impresa risultano letti.
          expect(s.worksiteById('w-demo')!.unreadForClient, 0);

          await t.enterText(find.byType(TextField).last, 'Ci vediamo sabato.');
          await bringIntoView(t, find.bySemanticsLabel('Invia messaggio'));
          await t.tap(find.bySemanticsLabel('Invia messaggio'));
          await settle(t, 600);
          expect(
            s.worksiteById('w-demo')!.messages.last.text,
            'Ci vediamo sabato.',
          );
          expect(s.worksiteById('w-demo')!.messages.last.fromClient, isTrue);
          await disposeApp(t);
        },
      );
    }

    test('password sbagliata, account sospeso e clienti separati', () async {
      final s = await loadState();
      expect(await s.clientLogin(Seed.demoEmail, 'sbagliata'), isNotNull);
      expect(s.currentClient, isNull);

      final other = await s.createClient(
        name: 'Rossi Srl',
        email: ' Info@Rossi.IT ',
        password: 'password-rossi',
      );
      expect(other.email, 'info@rossi.it');
      expect(s.emailTaken('INFO@rossi.it'), isTrue);
      expect(await s.clientLogin('info@rossi.it', 'password-rossi'), isNull);
      // Rossi non ha cantieri: quello di prova è di un altro cliente.
      expect(s.worksitesOf(s.currentClient!.id), isEmpty);

      other.active = false;
      await s.updateClient(other);
      expect(s.currentClient, isNull);
      expect(
        await s.clientLogin('info@rossi.it', 'password-rossi'),
        contains('sospeso'),
      );

      await s.resetClientPassword(other, 'nuova-password');
      other.active = true;
      await s.updateClient(other);
      expect(await s.clientLogin('info@rossi.it', 'password-rossi'), isNotNull);
      expect(await s.clientLogin('info@rossi.it', 'nuova-password'), isNull);
    });

    test('la sessione del cliente resta dopo il riavvio', () async {
      final repo = MemoryRepository();
      final a = AppState(repo);
      await a.load();
      await a.clientLogin(Seed.demoEmail, Seed.demoPassword);
      final b = AppState(repo);
      await b.load();
      expect(b.currentClient?.email, Seed.demoEmail);
      await b.clientLogout();
      final c = AppState(repo);
      await c.load();
      expect(c.currentClient, isNull);
    });

    test('il cliente cambia la propria password', () async {
      final s = await loadState();
      await s.clientLogin(Seed.demoEmail, Seed.demoPassword);
      expect(await s.changeOwnPassword('sbagliata', 'nuova-password'), isFalse);
      expect(
        await s.changeOwnPassword(Seed.demoPassword, 'nuova-password'),
        isTrue,
      );
      await s.clientLogout();
      expect(await s.clientLogin(Seed.demoEmail, 'nuova-password'), isNull);
    });

    test('eliminare un cliente toglie anche i suoi cantieri', () async {
      final s = await loadState();
      expect(s.worksitesOf('c-demo'), isNotEmpty);
      await s.deleteClient('c-demo');
      expect(s.worksites, isEmpty);
      expect(s.clients, isEmpty);
    });
  });

  group('Dati', () {
    test('backup e ripristino conservano progetti e richieste', () async {
      final a = await loadState();
      a.projects.first.title = 'Titolo cambiato';
      await a.setProjects([...a.projects]);
      await a.addRequest(
        ContactRequest(name: 'Anna', phone: '1234567', email: 'a@b.it'),
      );
      final backup = a.exportBackup();

      final b = await loadState();
      await b.importBackup(backup);
      expect(b.projects.first.title, 'Titolo cambiato');
      expect(b.requests.single.name, 'Anna');
    });

    test('un backup non valido non tocca i dati', () async {
      final s = await loadState();
      final before = s.projects.length;
      await expectLater(
        s.importBackup('{"content": {}, "projects": [1, 2]}'),
        throwsA(isA<FormatException>()),
      );
      expect(s.projects.length, before);
    });

    test('password del gestionale', () async {
      final s = await loadState();
      expect(s.hasAdminPassword, isFalse);
      await s.setAdminPassword('segretissima');
      await s.logout();
      expect(await s.login('sbagliata'), isFalse);
      expect(await s.login('segretissima'), isTrue);
    });

    test('categorie usate nell\'ordine scelto', () async {
      final s = await loadState();
      expect(s.usedCategories.first, 'Residenziale');
      expect(s.usedCategories, contains('Industriale'));
      for (final p in s.projects.where((p) => p.category == 'Industriale')) {
        p.published = false;
      }
      expect(s.usedCategories, isNot(contains('Industriale')));
    });
  });
}

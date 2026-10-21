# M.I.R.O. Costruzioni – sito dei progetti (Flutter Web)

Sito vetrina per un'impresa edile, con portfolio dei progetti realizzati, modulo contatti e gestionale completo. Scritto in Flutter (solo web), responsive per telefono, tablet, PC e TV.

Stile "da cantiere": grafite e cemento, titoli condensati in maiuscolo, etichette tecniche in carattere monospazio, griglia da tavola tecnica sopra le foto. Il logo (due tetti a capanna che formano una "M") è **di prova** e si sostituisce dal gestionale.

| Pagina | Percorso | Cosa fa |
|---|---|---|
| Home | `/#/` | Prima schermata con le copertine dei progetti in evidenza che si alternano (dissolvenza + zoom lento), parallasse e avanzamento; numeri che "contano"; nastro scorrevole dei servizi; progetti in evidenza impaginati a rivista; servizi a fisarmonica con foto; metodo in 4 fasi; citazione con parallasse; testimonianze; invito finale |
| Progetti | `/#/progetti` | Tutti i progetti con filtri per categoria e stato (completati / in corso) |
| Progetto | `/#/progetti/<id>` | Scheda tecnica (luogo, anno, committente, superficie, durata, stato), racconto, interventi eseguiti, **confronto prima/dopo da trascinare**, galleria con visualizzatore a tutto schermo, progetto successivo |
| Servizi | `/#/servizi` | Ogni servizio con foto, punti chiave e "Richiedi un sopralluogo" |
| Azienda | `/#/azienda` | Storia, certificazioni, valori (le iniziali formano M.I.R.O.), tappe, persone |
| Contatti | `/#/contatti` | Recapiti e modulo di richiesta (precompilato se si arriva da un servizio o da un progetto) |
| Gestionale | `/#/admin` | Gestione di progetti, servizi, testi, richieste e calendario |

Ogni sezione compare con dissolvenze e scorrimenti quando entra nello schermo; la barra in alto si nasconde scorrendo in giù e ricompare risalendo.

## Il pulsante "Colori"

Lo stesso sito si può mostrare con **7 tavolozze** (Ocra cantiere, Cotto e argilla, Blu progetto, Verde oliva, Rosso mattone, Giallo sicurezza, Nero e oro): il pulsante in basso a sinistra le applica al volo, con una dissolvenza dei colori su tutta la pagina.

Dal gestionale → **Stile e colori**:

- scegli la **tavolozza predefinita** (la stella);
- scegli **chi vede il pulsante**: tutti, solo con il link di prova (`/#/?prova=1`) oppure nessuno;
- scegli quali tavolozze **proporre**;
- copia il **link per il cliente** (`/#/?tema=progetto`): il sito si apre già con quei colori.

## Avvio

```bash
flutter pub get
flutter run -d chrome
```

Build di produzione: `flutter build web --release` (output in `build/web`).
Per provarla dal telefono sulla stessa Wi-Fi: `dart run tool/serve_release.dart` (porta 8080).

Test (tutte le pagine e il gestionale su 7 misure di schermo, dal telefono da 320 px alla TV 4K, più modulo contatti, colori e backup): `flutter test`.

> Nota: usa `google_fonts` 8.x. La 9.x dipende dal nuovo pacchetto `material_ui` ed è incompatibile con il `material.dart` di Flutter 3.47.

## Gestionale

Al primo accesso (`/#/admin`, oppure "Area riservata" in fondo al sito) si crea la password. Sezioni:

- **Panoramica** – richieste nuove, prossimi appuntamenti, progetti pubblicati, cantieri in corso
- **Richieste** – i messaggi dal modulo contatti con tipo di intervento, località, superficie, tempi e progetto di partenza; stato (nuova → contattata → sopralluogo → preventivo inviato → lavoro acquisito → archiviata), ricerca, contatto rapido (telefono / WhatsApp / email), appunti interni, "Fissa sopralluogo"
- **Calendario** – vista mensile + agenda, sincronizzato con Google Calendar
- **Progetti** – titolo, categoria, luogo, anno, committente, superficie, durata, stato, descrizioni, interventi, copertina, galleria con didascalie, foto prima/dopo; stella per metterli in evidenza (Home e prima schermata), visibilità, ordine trascinando
- **Servizi** e **Testimonianze**
- **Stile e colori** – vedi sopra
- **Pagina Home / Azienda / Identità e contatti** – tutti i testi, le immagini, i recapiti, le voci del modulo e le categorie dei progetti
- **Impostazioni** – Client ID Google, password, backup/ripristino

## Google Calendar

Gli appuntamenti si scrivono nel **calendario principale** dell'account Google con cui si fa l'accesso.
Serve una sola volta un Client ID OAuth (Gestionale → Impostazioni spiega i passaggi e mostra l'indirizzo da autorizzare). Lo scope richiesto è solo `calendar.events`.

## Pubblicazione

A ogni push su `master` la GitHub Action `.github/workflows/deploy.yml` ricompila il sito e lo pubblica su GitHub Pages.

## Dove stanno i dati (importante)

Per ora **tutti i dati sono nel browser** (localStorage) tramite `LocalRepository`:

- le richieste inviate dai visitatori restano nel *loro* browser, non arrivano al titolare;
- le modifiche fatte nel gestionale si vedono solo da quel browser;
- le foto caricate dal computer sono incorporate nei dati (limite ~5 MB totali): per molte foto conviene usare indirizzi (URL) di immagini già online.

Per un sito reale serve un archivio online condiviso: basta implementare i due metodi di `Repository` (`lib/data/repository.dart`) con Firebase/Supabase/API proprie e sostituire `LocalRepository` in `lib/main.dart`.

## Struttura

```
lib/
  main.dart, app.dart          avvio, router, link ?prova= / ?tema=
  models/models.dart           contenuti, progetti, servizi, testimonianze, richieste, appuntamenti, colori
  data/                        Repository (+ implementazione locale) e dati di esempio
  state/app_state.dart         stato dell'app e operazioni
  services/                    Google Identity Services + API Calendar
  theme/site_theme.dart        le tavolozze e i caratteri del sito
  theme/theme_fader.dart       dissolvenza dei colori al cambio di tavolozza
  theme/app_theme.dart         tema del gestionale, misure responsive, scala per TV
  widgets/                     logo, sezioni della Home, scheda progetto, prima/dopo, galleria, pulsante colori, navigazione, piè di pagina
  pages/                       home, progetti, servizi, azienda, contatti
  pages/admin/                 gestionale
test/                          test di pagine e gestionale su 7 misure di schermo, modulo, colori, backup
```

I contenuti di esempio (testi, foto Unsplash, contatti e persone fittizi) vanno sostituiti dal gestionale.

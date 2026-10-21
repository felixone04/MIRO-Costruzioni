# M.I.R.O. Costruzioni – sito, area clienti e gestionale (Flutter Web)

Sito di un'impresa edile con portfolio dei progetti, pagina dei servizi, area clienti riservata e gestionale. Scritto in Flutter (solo web), responsive per telefono, tablet, PC e TV.

Stile caldo e "fatto a mano": titoli in Fraunces (serif morbido, ultima riga in corsivo colorato), testo in DM Sans, angoli arrotondati su foto, schede e pulsanti, transizioni a ogni scorrimento. Il logo (due tetti a capanna che formano una "M") è **di prova** e si sostituisce dal gestionale.

| Pagina | Percorso | Cosa contiene |
|---|---|---|
| Home | `/#/` | Prima schermata con le foto dei progetti in evidenza che si alternano, chi siamo con i numeri, nastro scorrevole dei servizi, ultimi progetti, recapiti |
| Progetti | `/#/progetti` | Tutti i progetti, con filtri discreti per categoria |
| Progetto | `/#/progetti/<id>` | Scheda, racconto, lavori eseguiti, confronto prima/dopo da trascinare, galleria a tutto schermo, progetto successivo |
| Servizi | `/#/servizi` | I tipi di lavoro come filtri discreti: per ognuno descrizione, foto e lavori collegati |
| Azienda | `/#/azienda` | Storia, valori, tappe, persone, parole dei clienti |
| Contatti | `/#/contatti` | Recapiti e modulo (arriva nel gestionale in "Richieste") |
| Area clienti | `/#/area-clienti` | Accesso riservato ai clienti: avanzamento, fasi, aggiornamenti con foto, documenti da scaricare, messaggi |
| Gestionale | `/#/admin` | Gestione di tutto il sito, dei clienti e dei cantieri |

## Area clienti

Un canale privato tra l'impresa e ogni cliente (privato o azienda).

- **Nessuno può registrarsi dal sito**: gli account li crea solo il titolare in Gestionale → **Clienti**. Alla creazione il gestionale genera una password e prepara il messaggio da mandare al cliente con indirizzo, email e password.
- Ogni cliente vede **solo i propri cantieri**. Da Clienti si può sospendere l'accesso, generare una nuova password o eliminare il cliente con i suoi cantieri.
- In Gestionale → **Cantieri**, per ogni cantiere:
  - dati, stato e **avanzamento in percentuale**, fase attuale, foto di copertina;
  - **fasi** da spuntare man mano;
  - **aggiornamenti** con testo e foto, visibili subito al cliente;
  - **documenti** da scaricare (PDF, foto, fogli di calcolo…, fino a 2 MB l'uno) oppure link a file più grandi (Google Drive, Dropbox), ognuno con una nota;
  - **messaggi**: il cliente scrive dalla sua area, tu rispondi da qui. I messaggi non letti compaiono come numero accanto a "Cantieri".
- Il cliente può cambiare la propria password e restare collegato su quel dispositivo.

**Cliente di prova** (creato al primo avvio, si elimina da Gestionale → Clienti):
email `demo@mirocostruzioni.it`, password `cantiere2026`.

## Il pulsante "Colori"

Sei tavolozze, tre chiare (Sabbia – beige con #CD5C5C –, Calce, Salvia) e tre scure (Bordeaux, Terra, Notte), applicate al volo con una dissolvenza. Da Gestionale → **Stile e colori** scegli la predefinita, quali proporre e chi vede il pulsante (tutti, solo con `/#/?prova=1`, nessuno); il link `/#/?tema=bordeaux` apre il sito già con quei colori.

## Dove stanno i dati (importante)

Per ora **tutti i dati sono nel browser** (localStorage) tramite `LocalRepository`:

- richieste, account dei clienti, documenti e messaggi si vedono **solo nel browser in cui sono stati inseriti**: un cliente dal suo telefono non vedrebbe i cantieri creati dal tuo PC;
- l'area clienti quindi oggi serve a **provare e mostrare** il funzionamento;
- foto e documenti caricati occupano lo spazio del browser (circa 5 MB in tutto).

Per usarla davvero con i clienti serve un archivio online condiviso (es. **Supabase**: database, accessi e archivio file). Tutta l'app passa da `Repository` (`lib/data/repository.dart`): basta un'implementazione online al posto di `LocalRepository` in `lib/main.dart`; per l'area clienti andranno spostati online anche l'accesso (account veri invece delle password salvate nel browser) e i file (archivio con permessi per cliente).

## Avvio

```bash
flutter pub get
flutter run -d chrome
```

Build di produzione: `flutter build web --release` (output in `build/web`).
Per provarla dal telefono sulla stessa Wi-Fi: `dart run tool/serve_release.dart` (porta 8080).

Test (tutte le pagine, l'area clienti e il gestionale su 7 misure di schermo, dal telefono da 320 px alla TV 4K, più modulo contatti, accessi dei clienti, colori e backup): `flutter test`.

> Nota: usa `google_fonts` 8.x. La 9.x dipende dal nuovo pacchetto `material_ui` ed è incompatibile con il `material.dart` di Flutter 3.47.

## Gestionale

Al primo accesso (`/#/admin`, oppure "Area riservata" in fondo al sito) si crea la password. Sezioni:

- **Panoramica**, **Richieste** (dal modulo contatti, con stati e "Fissa sopralluogo"), **Calendario** (con Google Calendar)
- **Clienti** e **Cantieri** – l'area clienti, vedi sopra
- **Progetti**, **Servizi** (con le categorie di lavori da mostrare), **Testimonianze**
- **Stile e colori**, **Pagina Home**, **Azienda**, **Identità e contatti**
- **Impostazioni** – Client ID Google, password, backup/ripristino (il backup comprende anche clienti e cantieri)

## Google Calendar

Gli appuntamenti si scrivono nel calendario principale dell'account Google con cui si fa l'accesso. Serve una sola volta un Client ID OAuth (Gestionale → Impostazioni spiega i passaggi). Lo scope richiesto è solo `calendar.events`.

## Pubblicazione

A ogni push su `master` la GitHub Action `.github/workflows/deploy.yml` ricompila il sito e lo pubblica su GitHub Pages.

## Struttura

```
lib/
  main.dart, app.dart          avvio, router, link ?prova= / ?tema=
  models/models.dart           contenuti, progetti, servizi, richieste, appuntamenti, clienti, cantieri, colori
  data/                        Repository (+ implementazione locale) e dati di esempio
  state/app_state.dart         stato dell'app, accessi del gestionale e dei clienti
  services/                    Google Calendar, download dei file
  theme/                       tavolozze, caratteri, dissolvenza dei colori, tema del gestionale
  widgets/                     logo, sezioni della Home, schede, prima/dopo, galleria, pulsante colori, navigazione
  pages/                       home, progetti, servizi, azienda, contatti, area clienti
  pages/admin/                 gestionale
test/                          test su 7 misure di schermo, area clienti, modulo, colori, backup
```

I contenuti di esempio (testi, foto Unsplash, contatti, persone e il cliente di prova) vanno sostituiti dal gestionale.

# M.I.R.O. Costruzioni – sito, area clienti e gestionale

Sito di un'impresa edile con portfolio dei progetti, pagina dei servizi, area clienti riservata e gestionale. Scritto in **HTML, CSS, JavaScript e PHP** (nessun framework, nessuna compilazione), con database **MySQL**: pensato per l'hosting **Hostinger**. Responsive per telefono, tablet, PC e TV.

Stile caldo e "fatto a mano": titoli in Fraunces (serif morbido, ultima riga in corsivo colorato), testo in DM Sans, angoli arrotondati su foto, schede e pulsanti, dissolvenze allo scorrimento. Il logo (due tetti a capanna che formano una "M") è **di prova** e si sostituisce dal gestionale.

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

## Pubblicazione su Hostinger

1. **Database** – hPanel → *Database* → *Database MySQL*: crea un database e un utente (es. `u123456789_miro`) e annota nome, utente e password.
2. **File** – hPanel → *File Manager* (o FTP): carica in `public_html` `index.php`, `api.php`, `.htaccess`, `manifest.json` e le cartelle `assets/`, `inc/`, `data/`, `uploads/`. Il file `.htaccess` è nascosto: assicurati che venga copiato.
3. **Credenziali** – in `public_html/inc/` copia `config.local.example.php` come **`config.local.php`** e inserisci i dati del database. Questo file resta solo sul server e non va su GitHub.
4. **PHP** – hPanel → *Avanzate* → *Configurazione PHP*: versione **8.1 o superiore** (estensioni `pdo_mysql` e `gd` attive, lo sono di default). Per caricare documenti grandi alza `upload_max_filesize` e `post_max_size` (es. 25M): il limite del sito è 20 MB per file (`inc/config.php`).
5. **Dominio e HTTPS** – collega il dominio in hPanel e attiva il certificato SSL gratuito: `.htaccess` porta automaticamente tutto su `https://`.
6. Apri `https://tuodominio.it/#/admin`: al **primo accesso** scegli la password del gestionale. Le tabelle (prefisso `miro_`) e i contenuti di esempio si creano da soli alla prima visita.

Per aggiornare il sito basta ricaricare i file modificati (senza toccare `inc/config.local.php`, `uploads/` e `data/`).

## Anteprima su GitHub Pages

**https://felixone04.github.io/MIRO-Costruzioni/** mostra il sito con i contenuti di esempio, per vederne la grafica prima che sia su Hostinger. GitHub Pages non esegue PHP, quindi a ogni push su `master` la GitHub Action `.github/workflows/anteprima.yml` lancia `php demo/build.php` e pubblica una copia statica. In quella copia `demo/demo.js` fa le veci di `api.php` dentro il browser.

- Tutte le pagine, le animazioni e il pulsante "Colori" sono quelli veri.
- Gestionale e area clienti si possono provare, ma i dati restano **solo nel browser di chi li modifica** (al primo accesso a `/#/admin` si sceglie una password qualsiasi). Nessun altro vede le modifiche.
- Nell'anteprima i documenti caricati possono essere al massimo di 1 MB.

La cartella `demo/` serve solo all'anteprima: su Hostinger non va caricata (non fa danni se c'è).

## Area clienti

Un canale privato tra l'impresa e ogni cliente (privato o azienda).

- **Nessuno può registrarsi dal sito**: gli account li crea solo il titolare in Gestionale → **Clienti**. Alla creazione il gestionale genera una password e prepara il messaggio da mandare al cliente con indirizzo, email e password.
- Ogni cliente vede **solo i propri cantieri**. Da Clienti si può sospendere l'accesso, generare una nuova password o eliminare il cliente con i suoi cantieri.
- In Gestionale → **Cantieri**, per ogni cantiere:
  - dati, stato e **avanzamento in percentuale**, fase attuale, foto di copertina;
  - **fasi** da spuntare man mano;
  - **aggiornamenti** con testo e foto, visibili subito al cliente;
  - **documenti** da scaricare (PDF, foto, fogli di calcolo…, fino a 20 MB l'uno) oppure link a file più grandi (Google Drive, Dropbox), ognuno con una nota;
  - **messaggi**: il cliente scrive dalla sua area, tu rispondi da qui. I messaggi non letti compaiono come numero accanto a "Cantieri".
- Il cliente può cambiare la propria password e restare collegato su quel dispositivo per 30 giorni.
- I documenti stanno in `uploads/files`, che non è raggiungibile direttamente: si scaricano solo da `api.php`, dopo aver controllato che il cantiere sia del cliente collegato.

**Cliente di prova** (creato al primo avvio, si elimina da Gestionale → Clienti):
email `demo@mirocostruzioni.it`, password `cantiere2026`.

## Il pulsante "Colori"

Sei tavolozze, tre chiare (Sabbia – beige con #CD5C5C –, Calce, Salvia) e tre scure (Bordeaux, Terra, Notte), applicate al volo con una dissolvenza. Da Gestionale → **Stile e colori** scegli la predefinita, quali proporre e chi vede il pulsante (tutti, solo con `/#/?prova=1`, nessuno); il link `/#/?tema=bordeaux` apre il sito già con quei colori.

## Gestionale

Al primo accesso (`/#/admin`, oppure "Area riservata" in fondo al sito) si crea la password. Sezioni:

- **Panoramica**, **Richieste** (dal modulo contatti, con stati e "Fissa sopralluogo"), **Calendario** (con Google Calendar)
- **Clienti** e **Cantieri** – l'area clienti, vedi sopra
- **Progetti**, **Servizi** (con le categorie di lavori da mostrare), **Testimonianze**
- **Stile e colori**, **Pagina Home**, **Azienda**, **Identità e contatti**
- **Impostazioni** – Client ID Google, password, backup/ripristino in un file JSON (comprende clienti, cantieri e messaggi; i documenti caricati restano nella cartella `uploads/files`)

Sicurezza: password cifrate con `password_hash`, sessioni PHP con token CSRF, blocco temporaneo dopo 8 tentativi di accesso sbagliati in 15 minuti, cartelle `inc/`, `data/` e `uploads/files/` chiuse da `.htaccess`.

## Google Calendar

Gli appuntamenti si scrivono nel calendario principale dell'account Google con cui si fa l'accesso. Serve una sola volta un Client ID OAuth (Gestionale → Impostazioni spiega i passaggi; tra le origini autorizzate va messo l'indirizzo del dominio). Lo scope richiesto è solo `calendar.events`.

## Prova in locale

Serve PHP 8.1+ con `pdo_sqlite`. In locale si può usare SQLite al posto di MySQL:

```bash
MIRO_DB=sqlite php -S 127.0.0.1:8094
```

(su Windows PowerShell: `$env:MIRO_DB='sqlite'; php -S 127.0.0.1:8094`) e poi apri `http://127.0.0.1:8094`. Il database di prova si crea in `data/miro.sqlite`.

## Struttura

```
index.php                pagina unica: carica i dati iniziali e gli script
api.php                  tutte le operazioni (sito, area clienti, gestionale)
inc/
  config.php             impostazioni (database, limiti foto e documenti)
  config.local.example.php   modello per le credenziali di Hostinger
  db.php                 tabelle, contenuti, clienti, cantieri, documenti
  auth.php               sessioni, accessi, CSRF, tentativi
  funzioni.php           risposte JSON, foto ridimensionate
  seed.json              contenuti di esempio e cliente di prova
assets/
  css/site.css           sito pubblico e area clienti
  css/admin.css          gestionale
  js/core.js             tavolozze, router, intestazione, animazioni, visore foto
  js/site.js             pagine pubbliche
  js/client.js           area clienti
  js/admin.js            gestionale: componenti, accesso, Panoramica, Richieste, Calendario, Impostazioni
  js/admin-pages.js      gestionale: Clienti, Cantieri, Progetti, Servizi, Testimonianze, Stile, testi del sito
  js/gcal.js             Google Calendar
  img/                   icone
uploads/img              foto caricate dal gestionale
uploads/files            documenti dei cantieri (protetti)
data/                    database SQLite per le prove in locale
demo/                    anteprima statica per GitHub Pages (build.php, demo.js)
.github/workflows/       pubblicazione dell'anteprima
```

I contenuti di esempio (testi, foto Unsplash, contatti, persone e il cliente di prova) vanno sostituiti dal gestionale.

La prima versione del sito, in Flutter, resta nella cronologia di git (commit `8e4d0cd`).

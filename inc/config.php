<?php
/*
 * CONFIGURAZIONE DEL SITO M.I.R.O. COSTRUZIONI
 *
 * Non scrivere qui le credenziali del database: mettile in
 * inc/config.local.php (copia inc/config.local.example.php). Quel file non
 * viene caricato su GitHub.
 *
 * ── Su Hostinger ───────────────────────────────────────────────
 * hPanel → Database → Database MySQL: crea un database e un utente.
 * Hostinger mostra nome del database, utente (es. u123456789_miro) e la
 * password scelta; l'host è "localhost".
 *
 * ── In locale (prove sul tuo PC) ───────────────────────────────
 * Con la variabile d'ambiente MIRO_DB=sqlite il database è un file
 * (data/miro.sqlite) e non serve MySQL.
 */
$config = [
    'db' => [
        'driver'   => 'mysql',
        'host'     => 'localhost',
        'nome'     => '',
        'utente'   => '',
        'password' => '',
        'prefisso' => 'miro_',                      // prefisso delle tabelle
        'sqlite'   => __DIR__ . '/../data/miro.sqlite',
    ],

    // Password del gestionale al primo avvio: dopo il primo accesso va cambiata
    // da Gestionale → Impostazioni (il gestionale lo ricorda finché non lo fai).
    'password_iniziale' => 'admin123',

    // Lato lungo massimo (in pixel) delle foto caricate dal gestionale
    'foto_max_px' => 1800,

    // Dimensione massima di un documento per i clienti (in MB). Non può superare
    // il limite del server (upload_max_filesize: su Hostinger si cambia da
    // hPanel → Avanzate → Configurazione PHP).
    'documento_max_mb' => 20,

    // Casella dell'azienda da cui partono gli avvisi (nuove richieste, messaggi,
    // aggiornamenti ai clienti). Si compila in inc/config.local.php: finché è
    // vuota il sito non manda email.
    'email' => [
        'host'      => '',      // server di invio, es. smtp.hostinger.com
        'porta'     => 465,     // 465 con 'ssl', 587 con 'tls'
        'sicurezza' => 'ssl',
        'utente'    => '',      // di solito l'indirizzo completo
        'password'  => '',
        'mittente'  => '',      // indirizzo da cui partono le email
        'nome'      => '',      // nome mostrato (vuoto = ragione sociale)
        'avvisi'    => '',      // dove ricevere gli avvisi (vuoto = mittente)
    ],
];

if (is_file(__DIR__ . '/config.local.php')) {
    $config = array_replace_recursive($config, require __DIR__ . '/config.local.php');
}
if (getenv('MIRO_DB') === 'sqlite') {
    $config['db']['driver'] = 'sqlite';
}
return $config;

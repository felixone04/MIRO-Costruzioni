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

    // Lato lungo massimo (in pixel) delle foto caricate dal gestionale
    'foto_max_px' => 1800,

    // Dimensione massima di un documento per i clienti (in MB). Non può superare
    // il limite del server (upload_max_filesize: su Hostinger si cambia da
    // hPanel → Avanzate → Configurazione PHP).
    'documento_max_mb' => 20,
];

if (is_file(__DIR__ . '/config.local.php')) {
    $config = array_replace_recursive($config, require __DIR__ . '/config.local.php');
}
if (getenv('MIRO_DB') === 'sqlite') {
    $config['db']['driver'] = 'sqlite';
}
return $config;

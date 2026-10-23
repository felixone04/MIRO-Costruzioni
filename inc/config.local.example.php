<?php
/*
 * Copia questo file come  inc/config.local.php  e inserisci i dati del
 * database creato su Hostinger (hPanel → Database → Database MySQL).
 * config.local.php resta solo sul server: non va caricato su GitHub.
 */
return [
    'db' => [
        'host'     => 'localhost',
        'nome'     => 'u123456789_miro',      // ← nome del database
        'utente'   => 'u123456789_miro',      // ← utente del database
        'password' => 'la-password-scelta',   // ← password dell'utente
    ],

    // Avvisi via email: lascia così finché non decidi la casella dell'azienda.
    // Esempi di server di invio:
    //   Hostinger   smtp.hostinger.com   porta 465  'ssl'
    //   Gmail       smtp.gmail.com       porta 465  'ssl'  (serve una "password per le app")
    //   Aruba       smtps.aruba.it       porta 465  'ssl'
    //   Outlook     smtp.office365.com   porta 587  'tls'
    'email' => [
        'host'      => '',                   // ← es. smtp.hostinger.com
        'porta'     => 465,
        'sicurezza' => 'ssl',
        'utente'    => '',                   // ← es. info@mirocostruzioni.it
        'password'  => '',                   // ← password della casella
        'mittente'  => '',                   // ← es. info@mirocostruzioni.it
        'avvisi'    => '',                   // ← dove ricevere gli avvisi (vuoto = mittente)
    ],
];

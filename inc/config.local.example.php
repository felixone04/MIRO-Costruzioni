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
];

<?php
/*
 * Pagina unica del sito: ogni indirizzo (/, /progetti/villa-le-querce,
 * /area-clienti, /admin…) arriva qui grazie a .htaccess. Il sito pubblico,
 * l'area clienti e il gestionale sono disegnati da JavaScript; titolo,
 * descrizione e foto della pagina sono già nell'HTML per Google e per
 * l'anteprima dei link condivisi.
 */
require_once __DIR__ . '/inc/funzioni.php';

// Anteprima statica per GitHub Pages (demo/build.php): niente database né
// sessioni, i dati di esempio vivono nel browser grazie a demo/demo.js.
$demo = defined('MIRO_ANTEPRIMA');
if ($demo) {
    $seed = json_decode(file_get_contents(__DIR__ . '/inc/seed.json'), true);
    $dati = ['content' => $seed['content'], 'projects' => array_values(array_filter($seed['projects'], fn($p) => $p['published'] ?? true))];
    $base = MIRO_BASE;
} else {
    avvia_sessione();
    $avvio = dati_avvio();
    $dati = $avvio;
    $base = percorso_base();
}
$c = $dati['content'];
$percorso = trim(substr(parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/', strlen($base) - 1), '/');
$meta = meta_pagina($demo ? '' : rawurldecode($percorso), $dati);
http_response_code($meta['status']);

$json = fn($x) => json_encode($x, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_HEX_TAG | JSON_HEX_AMP);
$e = fn($s) => htmlspecialchars((string) $s, ENT_QUOTES, 'UTF-8');
$v = fn($f) => $f . '?v=' . filemtime(__DIR__ . '/' . $f); // niente vecchie copie in memoria
$url = indirizzo_sito() . ($meta['status'] === 200 ? $percorso : '');
$foto = url_assoluto($meta['image']);
header('Content-Type: text/html; charset=utf-8');
?><!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <base href="<?= $e($base) ?>">
  <title><?= $e($meta['title']) ?></title>
  <meta name="description" content="<?= $e($meta['description']) ?>">
<?php if ($meta['noindex'] || $demo): ?>
  <meta name="robots" content="noindex">
<?php else: ?>
  <link rel="canonical" href="<?= $e($url) ?>">
<?php endif ?>
  <meta property="og:type" content="website">
  <meta property="og:locale" content="it_IT">
  <meta property="og:site_name" content="<?= $e($c['companyName'] ?? '') ?>">
  <meta property="og:title" content="<?= $e($meta['title']) ?>">
  <meta property="og:description" content="<?= $e($meta['description']) ?>">
  <meta property="og:url" content="<?= $e($url) ?>">
<?php if ($foto): ?>
  <meta property="og:image" content="<?= $e($foto) ?>">
  <meta name="twitter:card" content="summary_large_image">
<?php endif ?>
  <meta name="theme-color" content="#F4EEE4">
  <link rel="icon" type="image/png" href="assets/img/favicon.png">
  <link rel="apple-touch-icon" href="assets/img/Icon-192.png">
  <link rel="manifest" href="manifest.json">
  <link rel="preload" href="assets/fonts/fraunces-latin.woff2" as="font" type="font/woff2" crossorigin>
  <link rel="preload" href="assets/fonts/material-symbols-rounded.woff2" as="font" type="font/woff2" crossorigin>
  <link rel="stylesheet" href="<?= $v('assets/fonts/fonts.css') ?>">
  <link rel="stylesheet" href="<?= $v('assets/css/site.css') ?>">
  <script type="application/ld+json"><?= $json(scheda_impresa($c)) ?></script>
  <style>
    #splash { position: fixed; inset: 0; z-index: 9999; display: flex; flex-direction: column; align-items: center; justify-content: center;
      background: #F4EEE4; color: #3B2B27; padding: 0 32px; transition: opacity .8s ease, visibility .8s ease; }
    #splash.hide { opacity: 0; visibility: hidden; }
    #splash .row { display: flex; align-items: center; gap: 16px; }
    #splash svg { width: clamp(52px, 12vw, 70px); height: auto; }
    #splash svg rect { transform-origin: center; transform: scale(0); animation: sp-pop .6s cubic-bezier(.2,.8,.2,1) .05s forwards; }
    #splash svg path { stroke-dasharray: 220; stroke-dashoffset: 220; animation: sp-draw 1s ease .35s forwards; }
    #splash .name { font-family: 'Fraunces', Georgia, serif; font-weight: 500; font-size: clamp(34px, 9vw, 54px); line-height: 1;
      opacity: 0; transform: translateX(-8px); animation: sp-show .9s cubic-bezier(.2,.7,.2,1) .45s forwards; }
    #splash .name small { display: block; margin-top: 6px; font-family: 'DM Sans', Arial, sans-serif; font-weight: 500;
      font-size: clamp(12px, 3vw, 15px); color: rgba(59,43,39,.65); }
    #splash .bar { width: min(180px, 46vw); height: 3px; border-radius: 3px; margin-top: 38px; background: rgba(59,43,39,.12); overflow: hidden; }
    #splash .bar b { display: block; height: 100%; background: #CD5C5C; border-radius: 3px; transform-origin: left; transform: scaleX(0); animation: sp-fill 1.6s ease-in-out forwards; }
    #splash.wait .name { animation-play-state: paused; } /* la scritta parte quando c'è il suo carattere */
    @keyframes sp-show { to { opacity: 1; transform: none; } }
    @keyframes sp-pop { to { transform: scale(1); } }
    @keyframes sp-draw { to { stroke-dashoffset: 0; } }
    @keyframes sp-fill { to { transform: scaleX(1); } }
  </style>
</head>
<body>
  <div id="splash" aria-label="<?= $e($c['companyName'] ?? '') ?>, caricamento">
    <div class="row">
      <svg viewBox="0 0 100 100" aria-hidden="true">
        <rect width="100" height="100" rx="26" fill="#CD5C5C"/>
        <path d="M22 74 V47 L36 30 L50 47 L64 30 L78 47 V74 M50 62 V74" fill="none" stroke="#fff" stroke-width="8" stroke-linejoin="round" stroke-linecap="round"/>
      </svg>
      <div class="name"><?= $e($c['shortName'] ?? 'M.I.R.O.') ?><small>Costruzioni</small></div>
    </div>
    <div class="bar"><b></b></div>
  </div>
  <script>
    // Niente cambio di carattere a metà animazione: aspetta Fraunces (al massimo 0,8 secondi).
    (function () {
      var s = document.getElementById('splash');
      if (!document.fonts || !document.fonts.load) return;
      s.classList.add('wait');
      var go = function () { s.classList.remove('wait'); };
      document.fonts.load('500 1em Fraunces').then(go, go);
      setTimeout(go, 800);
    })();
  </script>

  <div id="app"></div>
  <noscript>
    <p style="padding:40px;font-family:sans-serif">Per vedere il sito attiva JavaScript nel browser.
      Telefono: <?= $e($c['contacts']['phone'] ?? '') ?> · Email: <?= $e($c['contacts']['email'] ?? '') ?></p>
  </noscript>

<?php if ($demo): ?>
  <script>window.__SEED__ = <?= $json($seed) ?>;</script>
  <script src="<?= $v('demo/demo.js') ?>"></script>
<?php else: ?>
  <script>window.__BOOT__ = <?= $json($avvio) ?>;</script>
<?php endif ?>
  <script src="<?= $v('assets/js/core.js') ?>"></script>
  <script src="<?= $v('assets/js/site.js') ?>"></script>
  <script src="<?= $v('assets/js/client.js') ?>"></script>
  <script>
    window.MIRO_ADMIN = { css: <?= json_encode($v('assets/css/admin.css')) ?>, js: [<?= json_encode($v('assets/js/gcal.js')) ?>, <?= json_encode($v('assets/js/admin.js')) ?>, <?= json_encode($v('assets/js/admin-pages.js')) ?>] };
    MIRO.start();
  </script>
</body>
</html>

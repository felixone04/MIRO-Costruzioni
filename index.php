<?php
/*
 * Pagina unica del sito: il sito pubblico, l'area clienti e il gestionale
 * (#/admin) sono disegnati da JavaScript a partire dai dati qui sotto.
 */
require_once __DIR__ . '/inc/funzioni.php';

// Anteprima statica per GitHub Pages (demo/build.php): niente database né
// sessioni, i dati di esempio vivono nel browser grazie a demo/demo.js.
$demo = defined('MIRO_ANTEPRIMA');
if ($demo) {
    $seed = json_decode(file_get_contents(__DIR__ . '/inc/seed.json'), true);
    $c = $seed['content'];
} else {
    avvia_sessione();
    $avvio = dati_avvio();
    $c = $avvio['content'];
}
$json = fn($x) => json_encode($x, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_HEX_TAG | JSON_HEX_AMP);
$titolo = ($c['companyName'] ?? 'M.I.R.O. Costruzioni') . ' · ' . ($c['tagline'] ?? '');
$descrizione = ($c['companyName'] ?? '') . ': ' . ($c['heroSubtitle'] ?? '');
$e = fn($s) => htmlspecialchars((string) $s, ENT_QUOTES, 'UTF-8');
$v = fn($f) => $f . '?v=' . filemtime(__DIR__ . '/' . $f); // niente vecchie copie in memoria
header('Content-Type: text/html; charset=utf-8');
?><!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><?= $e($titolo) ?></title>
  <meta name="description" content="<?= $e($descrizione) ?>">
  <meta name="theme-color" content="#F4EEE4">
  <link rel="icon" type="image/png" href="assets/img/favicon.png">
  <link rel="apple-touch-icon" href="assets/img/Icon-192.png">
  <link rel="manifest" href="manifest.json">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght@0,9..144,400;0,9..144,500;0,9..144,600;1,9..144,400;1,9..144,500&family=DM+Sans:opsz,wght@9..40,400;9..40,500;9..40,600;9..40,700&display=swap" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@20..48,300..500,0..1,0&display=block" rel="stylesheet">
  <link rel="stylesheet" href="<?= $v('assets/css/site.css') ?>">
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
  <!-- Google Identity Services: serve per collegare Google Calendar dal gestionale -->
  <script src="https://accounts.google.com/gsi/client" async defer></script>
</body>
</html>

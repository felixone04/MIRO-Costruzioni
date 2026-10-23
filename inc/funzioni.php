<?php
/*
 * Funzioni comuni: risposte JSON, dati pubblici del sito, caricamento foto.
 */

require_once __DIR__ . '/db.php';
require_once __DIR__ . '/auth.php';

function rispondi(array $dati, int $codice = 200): never
{
    http_response_code($codice);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    echo json_encode($dati, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

/** Corpo JSON della richiesta. */
function corpo(): array
{
    static $c = null;
    if ($c !== null) return $c;
    $c = json_decode(file_get_contents('php://input') ?: '[]', true);
    return $c = is_array($c) ? $c : [];
}

function campo(string $k, $predefinito = '')
{
    return corpo()[$k] ?? $predefinito;
}

/** Tutto ciò che il sito pubblico deve sapere all'avvio. */
function dati_avvio(): array
{
    inizializza();
    $projects = array_values(array_filter(kv_get('projects', []), fn($p) => $p['published'] ?? true));
    $services = array_values(array_filter(kv_get('services', []), fn($s) => $s['active'] ?? true));
    $testimonials = array_values(array_filter(kv_get('testimonials', []), fn($t) => $t['published'] ?? true));
    $c = cliente_corrente();
    return [
        'csrf' => csrf(),
        'content' => kv_get('content', []),
        'projects' => $projects,
        'services' => $services,
        'testimonials' => $testimonials,
        'look' => kv_get('look', ['defaultTheme' => 'sabbia', 'hidden' => [], 'switcher' => 'tutti']),
        'client' => $c ? cliente_pubblico($c) : null,
        'admin' => is_admin(),
        'adminSetup' => !admin_ha_password(),
    ];
}

// --------------------------------------------------------------- foto

/**
 * Salva una foto caricata dal gestionale in uploads/img, ridimensionata al lato
 * lungo massimo. Restituisce l'indirizzo relativo da usare nel sito.
 */
function salva_foto(array $file): string
{
    if (($file['error'] ?? 1) !== UPLOAD_ERR_OK) {
        throw new RuntimeException('Caricamento non riuscito (file troppo grande?).');
    }
    $info = @getimagesize($file['tmp_name']);
    $tipi = [IMAGETYPE_JPEG => 'jpg', IMAGETYPE_PNG => 'png', IMAGETYPE_WEBP => 'webp', IMAGETYPE_GIF => 'gif'];
    if (!$info || !isset($tipi[$info[2]])) {
        throw new RuntimeException('Il file non è una foto (JPG, PNG, WebP o GIF).');
    }
    $est = $tipi[$info[2]];
    $nome = date('Ym') . '-' . bin2hex(random_bytes(8)) . '.' . $est;
    $dest = __DIR__ . '/../uploads/img/' . $nome;
    $max = (int) config()['foto_max_px'];
    [$w, $h] = $info;
    if (function_exists('imagecreatetruecolor') && max($w, $h) > $max && $est !== 'gif') {
        $src = match ($est) {
            'jpg' => imagecreatefromjpeg($file['tmp_name']),
            'png' => imagecreatefrompng($file['tmp_name']),
            'webp' => imagecreatefromwebp($file['tmp_name']),
        };
        $k = $max / max($w, $h);
        $nw = (int) round($w * $k);
        $nh = (int) round($h * $k);
        $dst = imagecreatetruecolor($nw, $nh);
        if ($est !== 'jpg') {
            imagealphablending($dst, false);
            imagesavealpha($dst, true);
        }
        imagecopyresampled($dst, $src, 0, 0, 0, 0, $nw, $nh, $w, $h);
        match ($est) {
            'jpg' => imagejpeg($dst, $dest, 82),
            'png' => imagepng($dst, $dest, 7),
            'webp' => imagewebp($dst, $dest, 82),
        };
    } else {
        move_uploaded_file($file['tmp_name'], $dest);
    }
    return 'uploads/img/' . $nome;
}

/** Normalizza l'elenco $_FILES['x'] (anche multiplo) in una lista di file. */
function file_caricati(string $campo): array
{
    $f = $_FILES[$campo] ?? null;
    if (!$f) return [];
    if (!is_array($f['name'])) return [$f];
    $out = [];
    foreach ($f['name'] as $i => $n) {
        $out[] = ['name' => $n, 'type' => $f['type'][$i], 'tmp_name' => $f['tmp_name'][$i],
            'error' => $f['error'][$i], 'size' => $f['size'][$i]];
    }
    return $out;
}

<?php
/*
 * Crea l'anteprima statica del sito per GitHub Pages:
 *     php demo/build.php [cartella]      (predefinita: _site)
 * La pagina è index.php con i contenuti di esempio; demo/demo.js fa le veci
 * di api.php nel browser. Su Hostinger questa cartella non serve.
 */
define('MIRO_ANTEPRIMA', true);

$radice = dirname(__DIR__);
$uscita = $argv[1] ?? $radice . '/_site';

function copia(string $da, string $a): void
{
    if (is_dir($da)) {
        @mkdir($a, 0777, true);
        foreach (scandir($da) as $f) {
            if ($f !== '.' && $f !== '..') copia("$da/$f", "$a/$f");
        }
    } else {
        copy($da, $a);
    }
}

@mkdir($uscita, 0777, true);
ob_start();
require $radice . '/index.php';
file_put_contents("$uscita/index.html", ob_get_clean());

copia("$radice/assets", "$uscita/assets");
@mkdir("$uscita/demo");
copia("$radice/demo/demo.js", "$uscita/demo/demo.js");
copy("$radice/manifest.json", "$uscita/manifest.json");
touch("$uscita/.nojekyll");

echo "Anteprima creata in $uscita\n";

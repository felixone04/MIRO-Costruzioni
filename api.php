<?php
/*
 * API del sito: ogni richiesta è  api.php?a=AZIONE.
 * Le letture usano GET, le modifiche POST con corpo JSON (o multipart per i
 * file) e il token anti-falsificazione nell'intestazione X-CSRF.
 */

require_once __DIR__ . '/inc/funzioni.php';

set_exception_handler(function (Throwable $e) {
    error_log('[MIRO] ' . $e);
    rispondi(['errore' => $e instanceof RuntimeException ? $e->getMessage() : 'Errore del server.'], 500);
});

avvia_sessione();
inizializza();
$a = $_GET['a'] ?? '';
$post = $_SERVER['REQUEST_METHOD'] === 'POST';
if ($post) controlla_csrf();

// ================================================================ PUBBLICO

if ($a === 'boot') rispondi(dati_avvio());

if ($a === 'contact' && $post) {
    // Campo trappola: i robot lo compilano, le persone non lo vedono.
    if (trim((string) campo('website')) !== '') rispondi(['ok' => true]);
    $nome = trim((string) campo('name'));
    $tel = trim((string) campo('phone'));
    $email = trim((string) campo('email'));
    if ($nome === '' || $tel === '' || !filter_var($email, FILTER_VALIDATE_EMAIL) || !campo('privacy')) {
        rispondi(['errore' => 'Controlla i campi obbligatori.'], 422);
    }
    $r = [
        'id' => nuovo_id(),
        'createdAt' => adesso(),
        'name' => mb_substr($nome, 0, 120),
        'phone' => mb_substr($tel, 0, 40),
        'email' => mb_substr($email, 0, 190),
        'city' => mb_substr(trim((string) campo('city')), 0, 120),
        'type' => mb_substr(trim((string) campo('type')), 0, 120),
        'timing' => '',
        'area' => '',
        'message' => mb_substr(trim((string) campo('message')), 0, 4000),
        'projectRef' => '',
        'status' => 'nuova',
        'appointmentId' => null,
        'notes' => '',
    ];
    salva_richiesta($r);
    rispondi(['ok' => true]);
}

// ============================================================ AREA CLIENTI

if ($a === 'client.login' && $post) {
    controlla_tentativi('cliente');
    $r = cliente_da_email((string) campo('email'));
    if (!$r || !verifica_password_cliente($r, (string) campo('password'))) {
        segna_tentativo('cliente');
        rispondi(['errore' => 'Email o password non corrette.'], 401);
    }
    if (!$r['attivo']) rispondi(['errore' => "Questo accesso è stato sospeso: contatta l'impresa."], 403);
    $_SESSION['cliente'] = $r['id'];
    ricorda('cliente', (bool) campo('remember', true));
    $c = cliente_pubblico($r);
    $c['lastLogin'] = adesso();
    salva_cliente($c);
    rispondi(['client' => $c, 'csrf' => csrf()]);
}

if ($a === 'client.logout' && $post) {
    unset($_SESSION['cliente'], $_SESSION['cliente_fino']);
    rispondi(['ok' => true]);
}

if ($a === 'client.worksites') {
    $c = richiedi_cliente();
    $s = db()->prepare('SELECT * FROM ' . t('cantieri') . ' WHERE cliente = ?');
    $s->execute([$c['id']]);
    rispondi(['worksites' => array_map('cantiere_completo', $s->fetchAll())]);
}

/** Il cantiere, solo se è del cliente collegato. */
function cantiere_del_cliente(string $id): array
{
    $c = richiedi_cliente();
    $w = cantiere_da_id($id);
    if (!$w || $w['cliente'] !== $c['id']) rispondi(['errore' => 'Cantiere non trovato.'], 404);
    return $w;
}

if ($a === 'client.message' && $post) {
    $w = cantiere_del_cliente((string) campo('worksiteId'));
    $testo = trim((string) campo('text'));
    if ($testo === '') rispondi(['errore' => 'Scrivi un messaggio.'], 422);
    nuovo_messaggio($w['id'], $testo, true);
    rispondi(['worksite' => cantiere_completo($w)]);
}

if ($a === 'client.read' && $post) {
    $w = cantiere_del_cliente((string) campo('worksiteId'));
    db()->prepare('UPDATE ' . t('messaggi') . ' SET letto = 1 WHERE cantiere = ? AND dal_cliente = 0')->execute([$w['id']]);
    rispondi(['ok' => true]);
}

if ($a === 'client.password' && $post) {
    $c = richiedi_cliente();
    $nuova = (string) campo('new');
    if (!verifica_password_cliente($c, (string) campo('old'))) {
        rispondi(['errore' => 'La password attuale non è corretta.'], 422);
    }
    if (mb_strlen($nuova) < 8) rispondi(['errore' => 'La nuova password deve avere almeno 8 caratteri.'], 422);
    db()->prepare('UPDATE ' . t('clienti') . ' SET password = ? WHERE id = ?')
        ->execute([password_hash($nuova, PASSWORD_DEFAULT), $c['id']]);
    rispondi(['ok' => true]);
}

// Download di un documento: lo può scaricare il cliente del cantiere o il titolare.
if ($a === 'file') {
    $s = db()->prepare('SELECT * FROM ' . t('documenti') . ' WHERE id = ?');
    $s->execute([$_GET['id'] ?? '']);
    $f = $s->fetch();
    $w = $f ? cantiere_da_id($f['cantiere']) : null;
    $c = cliente_corrente();
    if (!$f || !$w || !(is_admin() || ($c && $c['id'] === $w['cliente']))) {
        http_response_code(404);
        exit('Documento non trovato.');
    }
    if ($f['link']) {
        header('Location: ' . $f['file']);
        exit;
    }
    $path = cartella_documenti() . '/' . basename($f['file']);
    if (!is_file($path)) {
        http_response_code(404);
        exit('Documento non più disponibile.');
    }
    header('Content-Type: ' . ($f['tipo'] ?: 'application/octet-stream'));
    header('Content-Length: ' . filesize($path));
    header("Content-Disposition: attachment; filename*=UTF-8''" . rawurlencode($f['nome']));
    header('X-Content-Type-Options: nosniff');
    header('Cache-Control: private, no-store');
    readfile($path);
    exit;
}

// ================================================================ GESTIONALE

if ($a === 'admin.setup' && $post) {
    if (admin_ha_password()) rispondi(['errore' => 'La password esiste già.'], 409);
    $pw = (string) campo('password');
    if (mb_strlen($pw) < 8) rispondi(['errore' => 'La password deve avere almeno 8 caratteri.'], 422);
    kv_set('admin', ['hash' => password_hash($pw, PASSWORD_DEFAULT)]);
    $_SESSION['admin'] = true;
    ricorda('admin', (bool) campo('remember', true));
    rispondi(['ok' => true, 'csrf' => csrf()]);
}

if ($a === 'admin.login' && $post) {
    controlla_tentativi('admin');
    if (!password_verify((string) campo('password'), kv_get('admin')['hash'] ?? '')) {
        segna_tentativo('admin');
        rispondi(['errore' => 'Password non corretta.'], 401);
    }
    $_SESSION['admin'] = true;
    ricorda('admin', (bool) campo('remember', true));
    rispondi(['ok' => true, 'csrf' => csrf()]);
}

if ($a === 'admin.logout' && $post) {
    unset($_SESSION['admin'], $_SESSION['admin_fino']);
    rispondi(['ok' => true]);
}

// Da qui in poi serve l'accesso al gestionale.
if (str_starts_with($a, 'admin.')) richiedi_admin();

if ($a === 'admin.all') rispondi(tutti_i_dati(false));

if ($a === 'admin.password' && $post) {
    if (!password_verify((string) campo('old'), kv_get('admin')['hash'] ?? '')) {
        rispondi(['errore' => 'Password attuale non corretta.'], 422);
    }
    if (mb_strlen((string) campo('new')) < 8) rispondi(['errore' => 'Almeno 8 caratteri.'], 422);
    kv_set('admin', ['hash' => password_hash((string) campo('new'), PASSWORD_DEFAULT)]);
    rispondi(['ok' => true]);
}

// Documenti JSON interi (testi, progetti, servizi, testimonianze, colori, impostazioni).
$documenti = [
    'admin.content' => 'content', 'admin.projects' => 'projects', 'admin.services' => 'services',
    'admin.testimonials' => 'testimonials', 'admin.look' => 'look', 'admin.settings' => 'settings',
];
if (isset($documenti[$a]) && $post) {
    $v = campo('value', null);
    if (!is_array($v)) rispondi(['errore' => 'Dati non validi.'], 422);
    kv_set($documenti[$a], $v);
    rispondi(['ok' => true]);
}

if ($a === 'admin.image' && $post) {
    $urls = array_map('salva_foto', file_caricati('files'));
    rispondi(['urls' => $urls]);
}

// ---------------------------------------------------------- richieste

function salva_richiesta(array $r): void
{
    db()->prepare('REPLACE INTO ' . t('richieste') . ' (id, creata, dati) VALUES (?, ?, ?)')
        ->execute([$r['id'], $r['createdAt'] ?? adesso(), json_encode($r, JSON_UNESCAPED_UNICODE)]);
}

if ($a === 'admin.request' && $post) {
    salva_richiesta(campo('value', []));
    rispondi(['ok' => true]);
}

if ($a === 'admin.request.delete' && $post) {
    db()->prepare('DELETE FROM ' . t('richieste') . ' WHERE id = ?')->execute([campo('id')]);
    rispondi(['ok' => true]);
}

if ($a === 'admin.appointment' && $post) {
    $v = campo('value', []);
    db()->prepare('REPLACE INTO ' . t('appuntamenti') . ' (id, dati) VALUES (?, ?)')
        ->execute([$v['id'], json_encode($v, JSON_UNESCAPED_UNICODE)]);
    rispondi(['ok' => true]);
}

if ($a === 'admin.appointment.delete' && $post) {
    db()->prepare('DELETE FROM ' . t('appuntamenti') . ' WHERE id = ?')->execute([campo('id')]);
    rispondi(['ok' => true]);
}

// ------------------------------------------------------------- clienti

if ($a === 'admin.client' && $post) {
    $c = campo('value', []);
    $email = normalizza_email((string) ($c['email'] ?? ''));
    if (trim($c['name'] ?? '') === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        rispondi(['errore' => 'Nome ed email sono obbligatori.'], 422);
    }
    $altro = cliente_da_email($email);
    if ($altro && $altro['id'] !== ($c['id'] ?? '')) {
        rispondi(['errore' => 'Email già usata da un altro cliente.'], 409);
    }
    $nuovo = empty($c['id']) || !cliente_da_id($c['id']);
    $pw = (string) campo('password', '');
    if ($nuovo && mb_strlen($pw) < 8) rispondi(['errore' => 'La password deve avere almeno 8 caratteri.'], 422);
    $c['id'] = $c['id'] ?: nuovo_id();
    if ($nuovo) $c['createdAt'] = adesso();
    else {
        $vecchio = cliente_pubblico(cliente_da_id($c['id']));
        $c['createdAt'] = $vecchio['createdAt'];
        $c['lastLogin'] = $vecchio['lastLogin'];
    }
    salva_cliente($c, $pw !== '' ? password_hash($pw, PASSWORD_DEFAULT) : null);
    rispondi(['client' => cliente_pubblico(cliente_da_id($c['id']))]);
}

if ($a === 'admin.client.delete' && $post) {
    $id = (string) campo('id');
    $s = db()->prepare('SELECT id FROM ' . t('cantieri') . ' WHERE cliente = ?');
    $s->execute([$id]);
    foreach ($s->fetchAll(PDO::FETCH_COLUMN) as $w) elimina_cantiere($w);
    db()->prepare('DELETE FROM ' . t('clienti') . ' WHERE id = ?')->execute([$id]);
    rispondi(['ok' => true]);
}

// ------------------------------------------------------------ cantieri

/** Il cantiere aggiornato, come lo vede il gestionale. */
function rispondi_cantiere(string $id): never
{
    $w = cantiere_da_id($id);
    if (!$w) rispondi(['errore' => 'Cantiere non trovato.'], 404);
    rispondi(['worksite' => cantiere_completo($w)]);
}

if ($a === 'admin.worksite' && $post) {
    $w = campo('value', []);
    if (empty($w['id']) || !cliente_da_id($w['clientId'] ?? '')) {
        rispondi(['errore' => 'Scegli il cliente del cantiere.'], 422);
    }
    salva_cantiere($w);
    rispondi_cantiere($w['id']);
}

if ($a === 'admin.worksite.delete' && $post) {
    elimina_cantiere((string) campo('id'));
    rispondi(['ok' => true]);
}

if ($a === 'admin.file.upload' && $post) {
    $wid = (string) ($_POST['worksiteId'] ?? '');
    if (!cantiere_da_id($wid)) rispondi(['errore' => 'Cantiere non trovato.'], 404);
    $max = (int) config()['documento_max_mb'] * 1024 * 1024;
    $saltati = [];
    foreach (file_caricati('files') as $f) {
        if ($f['error'] !== UPLOAD_ERR_OK || $f['size'] > $max) {
            $saltati[] = $f['name'];
            continue;
        }
        $nome = salva_documento(file_get_contents($f['tmp_name']));
        $tipo = (new finfo(FILEINFO_MIME_TYPE))->file(cartella_documenti() . '/' . $nome) ?: 'application/octet-stream';
        db()->prepare('INSERT INTO ' . t('documenti') . ' (id, cantiere, nome, tipo, peso, file, link, nota, caricato) VALUES (?,?,?,?,?,?,0,?,?)')
            ->execute([nuovo_id(), $wid, mb_substr(basename($f['name']), 0, 255), $tipo, $f['size'], $nome, '', adesso()]);
    }
    $w = cantiere_completo(cantiere_da_id($wid));
    rispondi(['worksite' => $w, 'skipped' => $saltati]);
}

if ($a === 'admin.file.link' && $post) {
    $wid = (string) campo('worksiteId');
    $url = trim((string) campo('url'));
    if (!cantiere_da_id($wid) || !preg_match('#^https?://#i', $url)) {
        rispondi(['errore' => 'Inserisci un link che inizi con https://'], 422);
    }
    db()->prepare('INSERT INTO ' . t('documenti') . ' (id, cantiere, nome, tipo, peso, file, link, nota, caricato) VALUES (?,?,?,?,0,?,1,?,?)')
        ->execute([nuovo_id(), $wid, trim((string) campo('name')) ?: 'Documento', '', $url, '', adesso()]);
    rispondi_cantiere($wid);
}

if ($a === 'admin.file.note' && $post) {
    db()->prepare('UPDATE ' . t('documenti') . ' SET nota = ? WHERE id = ?')->execute([trim((string) campo('note')), campo('id')]);
    rispondi_cantiere((string) campo('worksiteId'));
}

if ($a === 'admin.file.delete' && $post) {
    $s = db()->prepare('SELECT * FROM ' . t('documenti') . ' WHERE id = ?');
    $s->execute([campo('id')]);
    if ($f = $s->fetch()) {
        if (!$f['link']) @unlink(cartella_documenti() . '/' . basename($f['file']));
        db()->prepare('DELETE FROM ' . t('documenti') . ' WHERE id = ?')->execute([$f['id']]);
    }
    rispondi_cantiere((string) campo('worksiteId'));
}

function nuovo_messaggio(string $cantiere, string $testo, bool $dalCliente): void
{
    db()->prepare('INSERT INTO ' . t('messaggi') . ' (id, cantiere, dal_cliente, testo, data, letto) VALUES (?,?,?,?,?,0)')
        ->execute([nuovo_id(), $cantiere, $dalCliente ? 1 : 0, mb_substr($testo, 0, 4000), adesso()]);
}

if ($a === 'admin.message' && $post) {
    $wid = (string) campo('worksiteId');
    $testo = trim((string) campo('text'));
    if (!cantiere_da_id($wid) || $testo === '') rispondi(['errore' => 'Scrivi un messaggio.'], 422);
    nuovo_messaggio($wid, $testo, false);
    rispondi_cantiere($wid);
}

if ($a === 'admin.read' && $post) {
    db()->prepare('UPDATE ' . t('messaggi') . ' SET letto = 1 WHERE cantiere = ? AND dal_cliente = 1')->execute([campo('worksiteId')]);
    rispondi(['ok' => true]);
}

// ----------------------------------------------------------- backup

/** Tutti i dati, nel formato del backup (uguale alla versione precedente). */
function tutti_i_dati(bool $backup): array
{
    $richieste = array_map(fn($r) => json_decode($r['dati'], true),
        db()->query('SELECT dati FROM ' . t('richieste') . ' ORDER BY creata DESC')->fetchAll());
    $appuntamenti = array_map(fn($r) => json_decode($r['dati'], true),
        db()->query('SELECT dati FROM ' . t('appuntamenti'))->fetchAll());
    $righe = db()->query('SELECT * FROM ' . t('clienti'))->fetchAll();
    $clienti = array_map(function ($r) use ($backup) {
        $c = cliente_pubblico($r);
        if ($backup) $c['passwordHash'] = $r['password'];
        return $c;
    }, $righe);
    usort($clienti, fn($a, $b) => strcmp($a['createdAt'] ?? '', $b['createdAt'] ?? ''));
    $cantieri = array_map('cantiere_completo', db()->query('SELECT * FROM ' . t('cantieri'))->fetchAll());
    $d = [
        'version' => 2,
        'content' => kv_get('content', []),
        'projects' => kv_get('projects', []),
        'services' => kv_get('services', []),
        'testimonials' => kv_get('testimonials', []),
        'requests' => $richieste,
        'appointments' => $appuntamenti,
        'look' => kv_get('look', []),
        'clients' => $clienti,
        'worksites' => $cantieri,
    ];
    if (!$backup) $d['settings'] = kv_get('settings', ['googleClientId' => '', 'googleWasConnected' => false]);
    return $d;
}

if ($a === 'admin.backup') {
    header('Content-Disposition: attachment; filename="miro-backup-' . date('Y-m-d') . '.json"');
    rispondi(tutti_i_dati(true));
}

if ($a === 'admin.restore' && $post) {
    $j = campo('value', null);
    if (!is_array($j) || !is_array($j['content'] ?? null)) {
        rispondi(['errore' => 'Il testo incollato non è una copia di sicurezza valida.'], 422);
    }
    $pdo = db();
    $pdo->beginTransaction();
    try {
        foreach (['content', 'projects', 'services', 'testimonials', 'look'] as $k) {
            if (isset($j[$k]) && is_array($j[$k])) kv_set($k, $j[$k]);
        }
        if (isset($j['requests'])) {
            $pdo->exec('DELETE FROM ' . t('richieste'));
            foreach ($j['requests'] as $r) salva_richiesta($r);
        }
        if (isset($j['appointments'])) {
            $pdo->exec('DELETE FROM ' . t('appuntamenti'));
            foreach ($j['appointments'] as $ap) {
                $pdo->prepare('REPLACE INTO ' . t('appuntamenti') . ' (id, dati) VALUES (?, ?)')
                    ->execute([$ap['id'], json_encode($ap, JSON_UNESCAPED_UNICODE)]);
            }
        }
        if (isset($j['clients'])) {
            foreach ($pdo->query('SELECT id FROM ' . t('cantieri'))->fetchAll(PDO::FETCH_COLUMN) as $w) elimina_cantiere($w);
            $pdo->exec('DELETE FROM ' . t('clienti'));
            foreach ($j['clients'] as $c) {
                // Password della versione precedente (sha256 + sale) o di questa.
                $hash = !empty($c['passwordSalt'])
                    ? 'legacy:' . $c['passwordSalt'] . ':' . $c['passwordHash']
                    : ($c['passwordHash'] ?? '');
                salva_cliente($c, $hash ?: null);
            }
            foreach ($j['worksites'] ?? [] as $w) importa_cantiere($w);
        }
        $pdo->commit();
    } catch (Throwable $e) {
        $pdo->rollBack();
        rispondi(['errore' => 'Il backup non si può leggere: nessun dato è stato cambiato.'], 422);
    }
    rispondi(tutti_i_dati(false));
}

if ($a === 'admin.reset' && $post) {
    carica_contenuti_esempio();
    rispondi(tutti_i_dati(false));
}

rispondi(['errore' => 'Azione sconosciuta.'], 404);

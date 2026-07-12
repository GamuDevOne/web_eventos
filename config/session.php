<?php

declare(strict_types=1);

if (session_status() === PHP_SESSION_ACTIVE) {
    return;
}

ini_set('session.use_strict_mode', '1');
ini_set('session.use_only_cookies', '1');
ini_set('session.cookie_httponly', '1');
ini_set('session.cookie_samesite', 'Lax');

$isHttps = isset($_SERVER['HTTPS'])
    && $_SERVER['HTTPS'] !== ''
    && $_SERVER['HTTPS'] !== 'off';

session_set_cookie_params([
    'lifetime' => 0,
    'path' => '/',
    'domain' => '',
    'secure' => $isHttps,
    'httponly' => true,
    'samesite' => 'Lax'
]);

session_start();
$tiempoMaximoInactividad = 1800; // 30 minutos

if (
    isset($_SESSION['ultima_actividad']) &&
    (time() - $_SESSION['ultima_actividad']) > $tiempoMaximoInactividad
) {
    $_SESSION = [];

    if (ini_get('session.use_cookies')) {
        $params = session_get_cookie_params();

        setcookie(session_name(), '', [
    'expires' => time() - 42000,
    'path' => $params['path'],
    'domain' => $params['domain'],
    'secure' => $params['secure'],
    'httponly' => $params['httponly'],
    'samesite' => 'Lax'
]);
    }

    session_destroy();

    http_response_code(401);

    echo json_encode([
        'status' => 'error',
        'mensaje' => 'La sesión expiró por inactividad. Inicia sesión nuevamente.'
    ], JSON_UNESCAPED_UNICODE);

    exit;
}

if (!empty($_SESSION['usuario_id'])) {
    $_SESSION['ultima_actividad'] = time();
}
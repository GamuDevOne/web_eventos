<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/session.php';
require_once __DIR__ . '/../config/database.php';

require_once __DIR__ . '/helpers/Response.php';
require_once __DIR__ . '/helpers/Validator.php';
require_once __DIR__ . '/helpers/ExceptionHandler.php';

require_once __DIR__ . '/middleware/AuthMiddleware.php';

require_once __DIR__ . '/controllers/EventoController.php';
require_once __DIR__ . '/controllers/UsuarioController.php';
require_once __DIR__ . '/controllers/ConferencistaController.php';

ExceptionHandler::register();

header('Content-Type: application/json; charset=UTF-8');

$method = $_SERVER['REQUEST_METHOD'];

$path = parse_url(
    $_SERVER['REQUEST_URI'],
    PHP_URL_PATH
);

$segments = array_values(
    array_filter(
        explode('/', trim($path, '/'))
    )
);

/*
 * Busca el recurso dentro de la URL:
 * eventos, usuarios o conferencistas.
 */
$resource = null;
$action = null;

foreach ($segments as $position => $segment) {
    if (
        in_array(
            $segment,
            ['eventos', 'usuarios', 'conferencistas'],
            true
        )
    ) {
        $resource = $segment;
        $action = $segments[$position + 1] ?? null;
        break;
    }
}

$route = "{$method}:{$resource}:{$action}";

switch ($route) {
    /*
     * Usuarios
     */
    case 'POST:usuarios:registro':
        $controller = new UsuarioController();
        $controller->registro();
        break;

    case 'POST:usuarios:login':
        $controller = new UsuarioController();
        $controller->login();
        break;

    case 'POST:usuarios:logout':
        $controller = new UsuarioController();
        $controller->logout();
        break;

    /*
     * Eventos
     */
    case 'POST:eventos:crear':
        $controller = new EventoController();
        $controller->crear();
        break;

    case 'POST:eventos:inscribir':
        $controller = new EventoController();
        $controller->inscribir();
        break;

    case 'GET:eventos:ocupacion':
        $controller = new EventoController();
        $controller->ocupacion();
        break;

    case 'GET:eventos:listar':
        $controller = new EventoController();
        $controller->listar();
        break;

    case 'POST:eventos:asistencia':
        $controller = new EventoController();
        $controller->asistencia();
        break;

    case 'POST:eventos:acreditacion':
        $controller = new EventoController();
        $controller->acreditacion();
        break;

    /*
     * Conferencistas
     */
    case 'POST:conferencistas:crear':
        $controller = new ConferencistaController();
        $controller->crear();
        break;

    case 'GET:conferencistas:listar':
        $controller = new ConferencistaController();
        $controller->listar();
        break;

    default:
        Response::error(
            'Endpoint no encontrado.',
            404
        );
}
<?php
session_start();
header("Content-Type: application/json");
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/controllers/EventoController.php';
require_once __DIR__ . '/controllers/UsuarioController.php';
require_once __DIR__ . '/controllers/ConferencistaController.php';

$method = $_SERVER['REQUEST_METHOD'];
$uri = explode('/', trim(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH), '/'));

$recursos = ['eventos', 'usuarios', 'conferencistas'];
$recurso = null;
$posicion = null;
foreach ($recursos as $r) {
    $pos = array_search($r, $uri);
    if ($pos !== false) { $recurso = $r; $posicion = $pos; break; }
}
$action = $recurso !== null ? ($uri[$posicion + 1] ?? null) : null;

switch ("$recurso:$method:$action") {
    case "eventos:POST:crear":
        (new EventoController())->crear();
        break;
    case "eventos:POST:inscribir":
        (new EventoController())->inscribir();
        break;
    case "eventos:GET:ocupacion":
        (new EventoController())->ocupacion();
        break;
    case "eventos:GET:listar":
        (new EventoController())->listar();
        break;
    case "eventos:POST:asistencia":
        (new EventoController())->asistencia();
        break;
    case "eventos:POST:acreditacion":
        (new EventoController())->acreditacion();
        break;
    case "usuarios:POST:login":
        (new UsuarioController())->login();
        break;
    case "usuarios:POST:registro":
        (new UsuarioController())->registro();
        break;
    case "conferencistas:POST:crear":
        (new ConferencistaController())->crear();
        break;
    case "conferencistas:GET:listar":
        (new ConferencistaController())->listar();
        break;
    default:
        http_response_code(404);
        echo json_encode(["error" => "Endpoint no encontrado"]);
}
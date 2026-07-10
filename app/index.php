<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/session.php';

header("Content-Type: application/json");
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/controllers/EventoController.php';

$method = $_SERVER['REQUEST_METHOD'];
$uri = explode('/', trim($_SERVER['REQUEST_URI'], '/'));
$action = $uri[array_search('eventos', $uri) + 1] ?? null;

$controller = new EventoController();

switch ("$method:$action") {
    case "POST:crear":
        $controller->crear();
        break;
    case "POST:inscribir":
        $controller->inscribir();
        break;
    case "GET:ocupacion":
        $controller->ocupacion();
        break;
    case "GET:listar":
        $controller->listar();
        break;
    case "POST:asistencia":
        $controller->asistencia();
        break;
    case "POST:acreditacion":
        $controller->acreditacion();
        break;
    default:
        http_response_code(404);
        echo json_encode(["error" => "Endpoint no encontrado"]);
}
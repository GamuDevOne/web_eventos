<?php
header("Content-Type: application/json");  //router simple
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
    default:
        http_response_code(404);
        echo json_encode(["error" => "Endpoint no encontrado"]);
}
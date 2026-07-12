<?php
class EventoController {

    private $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    public function crear()
     {
        AuthMiddleware::requireRole('organizador');
        if (!isset($_SESSION['usuario_id'])) {
            http_response_code(401);
            echo json_encode(["status" => "error", "mensaje" => "No autenticado"]);
            return;
        }

        $data = json_decode(file_get_contents("php://input"), true);
        $organizador_id = $_SESSION['usuario_id'];

        if (!isset($data['nombre'], $data['cupo_total'], $data['fecha'])) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => "Faltan campos requeridos"]);
            return;
        }

        try {
            $stmt = $this->db->prepare("CALL sp_crear_evento(:nombre, :descripcion, :cupo_total, :fecha, :organizador_id)");
            $stmt->bindParam(':nombre', $data['nombre']);
            $stmt->bindParam(':descripcion', $data['descripcion']);
            $stmt->bindParam(':cupo_total', $data['cupo_total'], PDO::PARAM_INT);
            $stmt->bindParam(':fecha', $data['fecha']);
            $stmt->bindParam(':organizador_id', $organizador_id, PDO::PARAM_INT);
            $stmt->execute();

            $evento = $stmt->fetch(PDO::FETCH_ASSOC);
            echo json_encode(["status" => "ok", "mensaje" => "Evento creado", "evento" => $evento]);
        } catch (PDOException $e) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => $e->getMessage()]);
        }
    }

   public function inscribir(): void
{
    AuthMiddleware::requireRole('participante');

    $data = json_decode(
        file_get_contents('php://input'),
        true
    );

    if (!is_array($data)) {
        Response::error(
            'El contenido enviado no es un JSON válido.',
            400
        );
    }

    try {
        $eventoId = Validator::integer(
            $data['evento_id'] ?? null,
            'evento_id',
            1
        );

        $participanteId = (int) $_SESSION['usuario_id'];

        $stmt = $this->db->prepare(
            'CALL sp_inscribir_participante(
                :evento_id,
                :participante_id
            )'
        );

        $stmt->bindValue(
            ':evento_id',
            $eventoId,
            PDO::PARAM_INT
        );

        $stmt->bindValue(
            ':participante_id',
            $participanteId,
            PDO::PARAM_INT
        );

        $stmt->execute();

        $resultado = $stmt->fetch(PDO::FETCH_ASSOC);

        Response::success(
            'Inscripción realizada correctamente.',
            [
                'resultado' => $resultado
            ],
            201
        );
    } catch (InvalidArgumentException $e) {
        Response::error(
            $e->getMessage(),
            422
        );
    } catch (PDOException $e) {
        error_log(
            'Error al inscribir participante: ' . $e->getMessage()
        );

        Response::error(
            'No se pudo completar la inscripción.',
            400
        );
    } catch (Throwable $e) {
        error_log(
            'Error inesperado en inscripción: ' . $e->getMessage()
        );

        Response::error(
            'Ocurrió un error interno al procesar la inscripción.',
            500
        );
    }
}

    public function ocupacion() {
    $evento_id = $_GET['evento_id'] ?? null;

    if (!$evento_id) {
        http_response_code(400);
        echo json_encode(["status" => "error", "mensaje" => "Falta evento_id"]);
        return;
    }

    try {
        $stmt = $this->db->prepare("CALL sp_obtener_ocupacion(:evento_id)");
        $stmt->bindParam(':evento_id', $evento_id, PDO::PARAM_INT);
        $stmt->execute();

        $resultado = $stmt->fetch(PDO::FETCH_ASSOC);
        echo json_encode($resultado);
    } catch (PDOException $e) {
        http_response_code(400);
        echo json_encode(["status" => "error", "mensaje" => $e->getMessage()]);
    }
}

    public function listar() {
        try {
            $stmt = $this->db->prepare("CALL sp_listar_eventos()");
            $stmt->execute();

            $resultado = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode($resultado);
        } catch (PDOException $e) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => $e->getMessage()]);
        }
    }

    public function asistencia() {
        $data = json_decode(file_get_contents("php://input"), true);

        if (!isset($data['inscripcion_id'], $data['presente'])) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => "Faltan campos requeridos"]);
            return;
        }

        try {
            $stmt = $this->db->prepare("CALL sp_registrar_asistencia(:inscripcion_id, :presente)");
            $stmt->bindParam(':inscripcion_id', $data['inscripcion_id'], PDO::PARAM_INT);
            $stmt->bindParam(':presente', $data['presente'], PDO::PARAM_INT);
            $stmt->execute();

            $resultado = $stmt->fetch(PDO::FETCH_ASSOC);
            echo json_encode($resultado);
        } catch (PDOException $e) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => $e->getMessage()]);
        }
    }

    public function acreditacion() { 
        $data = json_decode(file_get_contents("php://input"), true);

        if (!isset($data['inscripcion_id'], $data['codigo_unico'], $data['url'])) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => "Faltan campos requeridos"]);
            return;
        }

        try {
            $stmt = $this->db->prepare("CALL sp_generar_acreditacion(:inscripcion_id, :codigo_unico, :url)");
            $stmt->bindParam(':inscripcion_id', $data['inscripcion_id'], PDO::PARAM_INT);
            $stmt->bindParam(':codigo_unico', $data['codigo_unico'], PDO::PARAM_STR); 
            $stmt->bindParam(':url', $data['url'], PDO::PARAM_STR);
            $stmt->execute();

            $resultado = $stmt->fetch(PDO::FETCH_ASSOC);
            echo json_encode($resultado);
        } catch (PDOException $e) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => $e->getMessage()]);
        }
    }
}
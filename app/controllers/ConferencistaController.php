<?php
class ConferencistaController {

    private $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    public function crear() {
        $data = json_decode(file_get_contents("php://input"), true);

        if (!isset($data['nombre'], $data['evento_id'])) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => "Faltan campos requeridos"]);
            return;
        }

        try {
            $stmt = $this->db->prepare("CALL sp_crear_conferencista(:nombre, :bio, :email, :evento_id)");
            $stmt->bindParam(':nombre', $data['nombre']);
            $stmt->bindParam(':bio', $data['bio']);
            $stmt->bindParam(':email', $data['email']);
            $stmt->bindParam(':evento_id', $data['evento_id'], PDO::PARAM_INT);
            $stmt->execute();

            $conferencista = $stmt->fetch(PDO::FETCH_ASSOC);
            echo json_encode(["status" => "ok", "conferencista" => $conferencista]);
        } catch (PDOException $e) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => $e->getMessage()]);
        }
    }

    public function listar() {
        $evento_id = $_GET['evento_id'] ?? null;

        if (!$evento_id) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => "Falta evento_id"]);
            return;
        }

        try {
            $stmt = $this->db->prepare("CALL sp_listar_conferencistas_por_evento(:evento_id)");
            $stmt->bindParam(':evento_id', $evento_id, PDO::PARAM_INT);
            $stmt->execute();

            $resultado = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode($resultado);
        } catch (PDOException $e) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => $e->getMessage()]);
        }
    }
}
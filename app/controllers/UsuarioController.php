<?php
class UsuarioController {

    private $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    public function registro() {
        $data = json_decode(file_get_contents("php://input"), true);

        if (!isset($data['nombre'], $data['email'], $data['password'], $data['rol'])) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => "Faltan campos requeridos"]);
            return;
        }

        $hash = password_hash($data['password'], PASSWORD_BCRYPT);

        try {
            $stmt = $this->db->prepare("CALL sp_registrar_usuario(:nombre, :email, :password_hash, :rol)");
            $stmt->bindParam(':nombre', $data['nombre']);
            $stmt->bindParam(':email', $data['email']);
            $stmt->bindParam(':password_hash', $hash);
            $stmt->bindParam(':rol', $data['rol']);
            $stmt->execute();

            $usuario = $stmt->fetch(PDO::FETCH_ASSOC);
            echo json_encode(["status" => "ok", "usuario" => $usuario]);
        } catch (PDOException $e) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => "No se pudo registrar (correo duplicado)"]);
        }
    }

    public function login() {
        $data = json_decode(file_get_contents("php://input"), true);

        if (!isset($data['email'], $data['password'])) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => "Faltan campos requeridos"]);
            return;
        }

        try {
            $stmt = $this->db->prepare("CALL sp_login_usuario(:email)");
            $stmt->bindParam(':email', $data['email']);
            $stmt->execute();
            $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$usuario || !password_verify($data['password'], $usuario['password_hash'])) {
                http_response_code(401);
                echo json_encode(["status" => "error", "mensaje" => "Credenciales inválidas"]);
                return;
            }

            $_SESSION['usuario_id'] = $usuario['id'];
            $_SESSION['rol'] = $usuario['rol'];
            unset($usuario['password_hash']);

            echo json_encode(["status" => "ok", "usuario" => $usuario]);
        } catch (PDOException $e) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => $e->getMessage()]);
        }
    }
}
<?php
class UsuarioController {

    private $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    private function generarCodigoUnico($prefijo) {
        do {
            $sufijo = strtoupper(substr(bin2hex(random_bytes(3)), 0, 5));
            $codigo = $prefijo . '-' . $sufijo;
            $stmt = $this->db->prepare("SELECT COUNT(*) FROM usuarios WHERE codigo = :codigo");
            $stmt->bindParam(':codigo', $codigo);
            $stmt->execute();
            $existe = $stmt->fetchColumn();
        } while ($existe > 0);
        return $codigo;
    }

    public function registro() {
        $data = json_decode(file_get_contents("php://input"), true);

        if (!isset($data['nombre'], $data['email'], $data['password'], $data['rol'])) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => "Faltan campos requeridos"]);
            return;
        }

        if (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => "El correo no tiene un formato válido"]);
            return;
        }

        if (strlen($data['password']) < 6) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => "La contraseña debe tener al menos 6 caracteres"]);
            return;
        }

        if (!in_array($data['rol'], ['organizador', 'participante'], true)) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => "Rol inválido"]);
            return;
        }

        $hash = password_hash($data['password'], PASSWORD_BCRYPT);
        $prefijo = $data['rol'] === 'organizador' ? 'ORG' : 'PAR';
        $codigo = $this->generarCodigoUnico($prefijo);

        try {
            $stmt = $this->db->prepare("CALL sp_registrar_usuario(:nombre, :email, :password_hash, :rol, :codigo)");
            $stmt->bindParam(':nombre', $data['nombre']);
            $stmt->bindParam(':email', $data['email']);
            $stmt->bindParam(':password_hash', $hash);
            $stmt->bindParam(':rol', $data['rol']);
            $stmt->bindParam(':codigo', $codigo);
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

   public function resolverIdPorCodigoOId($valor) {
        if (ctype_digit((string)$valor)) {
            return (int)$valor;
        }
        $stmt = $this->db->prepare("CALL sp_buscar_usuario_por_codigo(:codigo)");
        $stmt->bindParam(':codigo', $valor);
        $stmt->execute();
        $usuario = $stmt->fetch(PDO::FETCH_ASSOC);
        $stmt->closeCursor();
        return $usuario ? (int)$usuario['id'] : null;
    }
}
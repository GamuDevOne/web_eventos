<?php
class EventoController {

    private $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    public function crear() {
        if (!isset($_SESSION['usuario_id']) || ($_SESSION['rol'] ?? null) !== 'organizador') {
            http_response_code(403);
            echo json_encode(["status" => "error", "mensaje" => "No autorizado"]);
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
            $stmt->closeCursor();
            echo json_encode(["status" => "ok", "mensaje" => "Evento creado", "evento" => $evento]);
        } catch (PDOException $e) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => $e->getMessage()]);
        }
    }

    public function editar() {
        if (!isset($_SESSION['usuario_id']) || ($_SESSION['rol'] ?? null) !== 'organizador') {
            http_response_code(403);
            echo json_encode(["status" => "error", "mensaje" => "No autorizado"]);
            return;
        }

        $data = json_decode(file_get_contents("php://input"), true);

        if (!isset($data['id'], $data['nombre'], $data['cupo_total'], $data['fecha'])) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => "Faltan campos requeridos"]);
            return;
        }

        try {
            $stmt = $this->db->prepare("CALL sp_editar_evento(:id, :nombre, :descripcion, :cupo_total, :fecha)");
            $stmt->bindParam(':id', $data['id'], PDO::PARAM_INT);
            $stmt->bindParam(':nombre', $data['nombre']);
            $stmt->bindParam(':descripcion', $data['descripcion']);
            $stmt->bindParam(':cupo_total', $data['cupo_total'], PDO::PARAM_INT);
            $stmt->bindParam(':fecha', $data['fecha']);
            $stmt->execute();

            $evento = $stmt->fetch(PDO::FETCH_ASSOC);
            $stmt->closeCursor();
            echo json_encode(["status" => "ok", "mensaje" => "Evento actualizado", "evento" => $evento]);
        } catch (PDOException $e) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => $e->getMessage()]);
        }
    }

    public function eliminar() {
        if (!isset($_SESSION['usuario_id']) || ($_SESSION['rol'] ?? null) !== 'organizador') {
            http_response_code(403);
            echo json_encode(["status" => "error", "mensaje" => "No autorizado"]);
            return;
        }

        $data = json_decode(file_get_contents("php://input"), true);

        if (!isset($data['id'])) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => "Falta el id del evento"]);
            return;
        }

        try {
            $stmt = $this->db->prepare("CALL sp_eliminar_evento(:id)");
            $stmt->bindParam(':id', $data['id'], PDO::PARAM_INT);
            $stmt->execute();

            $resultado = $stmt->fetch(PDO::FETCH_ASSOC);
            $stmt->closeCursor();
            echo json_encode($resultado);
        } catch (PDOException $e) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => $e->getMessage()]);
        }
    }

    public function inscribir() {
        $data = json_decode(file_get_contents("php://input"), true);

        if (!isset($data['evento_id']) || (!isset($data['participante_id']) && !isset($data['codigo']))) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => "Faltan campos requeridos"]);
            return;
        }

        $valorParticipante = $data['codigo'] ?? $data['participante_id'];
        $usuarioController = new UsuarioController();
        $participante_id = $usuarioController->resolverIdPorCodigoOId($valorParticipante);

        if (!$participante_id) {
            http_response_code(404);
            echo json_encode(["status" => "error", "mensaje" => "No se encontró un participante con ese código o ID"]);
            return;
        }

        try {
            $stmt = $this->db->prepare("CALL sp_inscribir_participante(:evento_id, :participante_id)");
            $stmt->bindParam(':evento_id', $data['evento_id'], PDO::PARAM_INT);
            $stmt->bindParam(':participante_id', $participante_id, PDO::PARAM_INT);
            $stmt->execute();

            $resultado = $stmt->fetch(PDO::FETCH_ASSOC);
            $stmt->closeCursor();
            echo json_encode($resultado);
        } catch (PDOException $e) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => $e->getMessage()]);
        }
    }

    public function cancelar() {
        if (!isset($_SESSION['usuario_id'])) {
            http_response_code(401);
            echo json_encode(["status" => "error", "mensaje" => "No autenticado"]);
            return;
        }

        $data = json_decode(file_get_contents("php://input"), true);

        if (!isset($data['inscripcion_id'])) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => "Falta inscripcion_id"]);
            return;
        }

        $usuario_id = $_SESSION['usuario_id'];
        $es_organizador = ($_SESSION['rol'] ?? null) === 'organizador';

        try {
            $stmt = $this->db->prepare("CALL sp_cancelar_inscripcion(:inscripcion_id, :usuario_id, :es_organizador)");
            $stmt->bindParam(':inscripcion_id', $data['inscripcion_id'], PDO::PARAM_INT);
            $stmt->bindParam(':usuario_id', $usuario_id, PDO::PARAM_INT);
            $stmt->bindParam(':es_organizador', $es_organizador, PDO::PARAM_BOOL);
            $stmt->execute();

            $resultado = $stmt->fetch(PDO::FETCH_ASSOC);
            $stmt->closeCursor();
            echo json_encode($resultado);
        } catch (PDOException $e) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => $e->getMessage()]);
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
            $stmt->closeCursor();
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
            $stmt->closeCursor();
            echo json_encode($resultado);
        } catch (PDOException $e) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => $e->getMessage()]);
        }
    }

    public function listarInscripciones() {
        $evento_id = $_GET['evento_id'] ?? null;

        if (!$evento_id) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => "Falta evento_id"]);
            return;
        }

        try {
            $stmt = $this->db->prepare("CALL sp_listar_inscripciones_por_evento(:evento_id)");
            $stmt->bindParam(':evento_id', $evento_id, PDO::PARAM_INT);
            $stmt->execute();

            $resultado = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $stmt->closeCursor();
            echo json_encode($resultado);
        } catch (PDOException $e) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => $e->getMessage()]);
        }
    }

    public function misInscripciones() {
        if (!isset($_SESSION['usuario_id'])) {
            http_response_code(401);
            echo json_encode(["status" => "error", "mensaje" => "No autenticado"]);
            return;
        }

        $usuario_id = $_SESSION['usuario_id'];

        try {
            $stmt = $this->db->prepare("CALL sp_listar_inscripciones_por_usuario(:usuario_id)");
            $stmt->bindParam(':usuario_id', $usuario_id, PDO::PARAM_INT);
            $stmt->execute();

            $resultado = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $stmt->closeCursor();
            echo json_encode($resultado);
        } catch (PDOException $e) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => $e->getMessage()]);
        }
    }

    // Resuelve el inscripcion_id a partir de evento_id + usuario_id (usado por asistencia/acreditación manual)
    private function buscarInscripcion($evento_id, $usuario_id) {
        $stmt = $this->db->prepare("CALL sp_buscar_inscripcion(:evento_id, :usuario_id)");
        $stmt->bindParam(':evento_id', $evento_id, PDO::PARAM_INT);
        $stmt->bindParam(':usuario_id', $usuario_id, PDO::PARAM_INT);
        $stmt->execute();
        $fila = $stmt->fetch(PDO::FETCH_ASSOC);
        $stmt->closeCursor();
        return $fila ? (int)$fila['inscripcion_id'] : null;
    }

    public function asistencia() {
        $data = json_decode(file_get_contents("php://input"), true);

        if (!isset($data['evento_id'], $data['presente']) || (!isset($data['codigo']) && !isset($data['participante_id']))) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => "Faltan campos requeridos"]);
            return;
        }

        $valorParticipante = $data['codigo'] ?? $data['participante_id'];
        $usuarioController = new UsuarioController();
        $participante_id = $usuarioController->resolverIdPorCodigoOId($valorParticipante);

        if (!$participante_id) {
            http_response_code(404);
            echo json_encode(["status" => "error", "mensaje" => "No se encontró un participante con ese código o ID"]);
            return;
        }

        $inscripcion_id = $this->buscarInscripcion($data['evento_id'], $participante_id);
        if (!$inscripcion_id) {
            http_response_code(404);
            echo json_encode(["status" => "error", "mensaje" => "Ese participante no está inscrito en este evento"]);
            return;
        }

        try {
            $stmt = $this->db->prepare("CALL sp_registrar_asistencia(:inscripcion_id, :presente)");
            $stmt->bindParam(':inscripcion_id', $inscripcion_id, PDO::PARAM_INT);
            $stmt->bindParam(':presente', $data['presente'], PDO::PARAM_INT);
            $stmt->execute();

            $resultado = $stmt->fetch(PDO::FETCH_ASSOC);
            $stmt->closeCursor();
            echo json_encode($resultado);
        } catch (PDOException $e) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => $e->getMessage()]);
        }
    }

   /**
     * Genera una acreditación 100% digital (sin PDF): registra el código único
     * en la base de datos. Admite dos modos:
     *  - Directo: { inscripcion_id, codigo_unico? }  → usado desde lista-inscritos.html.
     *  - Manual:  { evento_id, codigo|participante_id, codigo_unico? } → módulo manual.
     */
    public function acreditacion() {
        $data = json_decode(file_get_contents("php://input"), true);

        $inscripcion_id = null;

        if (isset($data['inscripcion_id'])) {
            $inscripcion_id = (int)$data['inscripcion_id'];
        } else {
            if (!isset($data['evento_id']) || (!isset($data['codigo']) && !isset($data['participante_id']))) {
                http_response_code(400);
                echo json_encode(["status" => "error", "mensaje" => "Faltan campos requeridos"]);
                return;
            }

            $valorParticipante = $data['codigo'] ?? $data['participante_id'];
            $usuarioController = new UsuarioController();
            $participante_id = $usuarioController->resolverIdPorCodigoOId($valorParticipante);

            if (!$participante_id) {
                http_response_code(404);
                echo json_encode(["status" => "error", "mensaje" => "No se encontró un participante con ese código o ID"]);
                return;
            }

            $inscripcion_id = $this->buscarInscripcion($data['evento_id'], $participante_id);
            if (!$inscripcion_id) {
                http_response_code(404);
                echo json_encode(["status" => "error", "mensaje" => "Ese participante no está inscrito en este evento"]);
                return;
            }
        }

        $codigo_unico = trim($data['codigo_unico'] ?? '');
        if ($codigo_unico === '') {
            $codigo_unico = 'ACR-' . $inscripcion_id . '-' . strtoupper(substr(bin2hex(random_bytes(3)), 0, 5));
        }

        try {
            $stmt = $this->db->prepare("CALL sp_generar_acreditacion(:inscripcion_id, :codigo_unico, :url)");
            $stmt->bindParam(':inscripcion_id', $inscripcion_id, PDO::PARAM_INT);
            $stmt->bindParam(':codigo_unico', $codigo_unico, PDO::PARAM_STR);
            $stmt->bindValue(':url', null, PDO::PARAM_NULL);
            $stmt->execute();

            $resultado = $stmt->fetch(PDO::FETCH_ASSOC);
            $stmt->closeCursor();
            echo json_encode($resultado);
        } catch (PDOException $e) {
            http_response_code(400);
            echo json_encode(["status" => "error", "mensaje" => $e->getMessage()]);
        }
    }
}
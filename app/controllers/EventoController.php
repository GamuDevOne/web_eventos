<?php
class EventoController { //con mocks de datos, luego se reemplazarán con consultas reales a la base de datos..

    public function crear() {
        $data = json_decode(file_get_contents("php://input"), true);
        // TODO: reemplazar por INSERT real vía PDO
        echo json_encode([
            "status" => "ok",
            "mensaje" => "Evento creado",
            "evento" => $data
        ]);
    }

    public function inscribir() {
        $data = json_decode(file_get_contents("php://input"), true);
        // TODO: reemplazar por procedimiento almacenado validar_cupo
        echo json_encode([
            "status" => "ok",
            "mensaje" => "Inscripción registrada",
            "evento_id" => $data['evento_id'] ?? null,
            "participante_id" => $data['participante_id'] ?? null
        ]);
    }

    public function ocupacion() {
        $evento_id = $_GET['evento_id'] ?? null;
        // TODO: reemplazar por consulta real de ocupación
        echo json_encode([
            "evento_id" => $evento_id,
            "cupo_total" => 100,
            "cupo_ocupado" => 45,
            "porcentaje_ocupacion" => 45
        ]);
    }

    public function listar() {
        // TODO: reemplazar por SELECT real
        echo json_encode([
            ["id" => 1, "nombre" => "Congreso IA", "cupo_total" => 100, "cupo_ocupado" => 45],
            ["id" => 2, "nombre" => "Taller PHP", "cupo_total" => 50, "cupo_ocupado" => 50]
        ]);
    }
}
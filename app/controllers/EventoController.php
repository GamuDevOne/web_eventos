<?php

declare(strict_types=1);

class EventoController
{
    private PDO $db;

    public function __construct()
    {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    public function crear(): void
    {
        AuthMiddleware::requireRole('organizador');

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
            $nombre = Validator::string(
                $data['nombre'] ?? null,
                'nombre',
                3,
                150
            );

            $descripcion = trim(
                (string) ($data['descripcion'] ?? '')
            );

            if (mb_strlen($descripcion) > 1000) {
                throw new InvalidArgumentException(
                    'La descripción no puede superar 1000 caracteres.'
                );
            }

            $cupoTotal = Validator::integer(
                $data['cupo_total'] ?? null,
                'cupo_total',
                1,
                100000
            );

            $fecha = Validator::date(
                $data['fecha'] ?? null,
                'fecha'
            );

            $organizadorId = (int) $_SESSION['usuario_id'];

            $stmt = $this->db->prepare(
                'CALL sp_crear_evento(
                    :nombre,
                    :descripcion,
                    :cupo_total,
                    :fecha,
                    :organizador_id
                )'
            );

            $stmt->bindValue(
                ':nombre',
                $nombre,
                PDO::PARAM_STR
            );

            $stmt->bindValue(
                ':descripcion',
                $descripcion,
                PDO::PARAM_STR
            );

            $stmt->bindValue(
                ':cupo_total',
                $cupoTotal,
                PDO::PARAM_INT
            );

            $stmt->bindValue(
                ':fecha',
                $fecha,
                PDO::PARAM_STR
            );

            $stmt->bindValue(
                ':organizador_id',
                $organizadorId,
                PDO::PARAM_INT
            );

            $stmt->execute();

            $evento = $stmt->fetch(PDO::FETCH_ASSOC);

            Response::success(
                'Evento creado correctamente.',
                [
                    'evento' => $evento
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
                'Error al crear evento: ' . $e->getMessage()
            );

            Response::error(
                'No se pudo crear el evento.',
                500
            );
        } catch (Throwable $e) {
            error_log(
                'Error inesperado al crear evento: '
                . $e->getMessage()
            );

            Response::error(
                'Ocurrió un error interno al crear el evento.',
                500
            );
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
                'Error al inscribir participante: '
                . $e->getMessage()
            );

            Response::error(
                'No se pudo completar la inscripción.',
                409
            );
        } catch (Throwable $e) {
            error_log(
                'Error inesperado en inscripción: '
                . $e->getMessage()
            );

            Response::error(
                'Ocurrió un error interno al procesar la inscripción.',
                500
            );
        }
    }

    public function ocupacion(): void
    {
        try {
            $eventoId = Validator::integer(
                $_GET['evento_id'] ?? null,
                'evento_id',
                1
            );

            $stmt = $this->db->prepare(
                'CALL sp_obtener_ocupacion(:evento_id)'
            );

            $stmt->bindValue(
                ':evento_id',
                $eventoId,
                PDO::PARAM_INT
            );

            $stmt->execute();

            $resultado = $stmt->fetch(PDO::FETCH_ASSOC);

            Response::success(
                'Ocupación obtenida correctamente.',
                [
                    'ocupacion' => $resultado
                ]
            );
        } catch (InvalidArgumentException $e) {
            Response::error(
                $e->getMessage(),
                422
            );
        } catch (PDOException $e) {
            error_log(
                'Error al consultar ocupación: '
                . $e->getMessage()
            );

            Response::error(
                'No se pudo consultar la ocupación del evento.',
                500
            );
        } catch (Throwable $e) {
            error_log(
                'Error inesperado al consultar ocupación: '
                . $e->getMessage()
            );

            Response::error(
                'Ocurrió un error interno al consultar la ocupación.',
                500
            );
        }
    }

    public function listar(): void
    {
        try {
            $stmt = $this->db->prepare(
                'CALL sp_listar_eventos()'
            );

            $stmt->execute();

            $resultado = $stmt->fetchAll(PDO::FETCH_ASSOC);

            Response::success(
                'Eventos obtenidos correctamente.',
                [
                    'eventos' => $resultado
                ]
            );
        } catch (PDOException $e) {
            error_log(
                'Error al listar eventos: ' . $e->getMessage()
            );

            Response::error(
                'No se pudieron obtener los eventos.',
                500
            );
        } catch (Throwable $e) {
            error_log(
                'Error inesperado al listar eventos: '
                . $e->getMessage()
            );

            Response::error(
                'Ocurrió un error interno al consultar los eventos.',
                500
            );
        }
    }

    public function asistencia(): void
    {
        AuthMiddleware::requireRole('organizador');

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
            $inscripcionId = Validator::integer(
                $data['inscripcion_id'] ?? null,
                'inscripcion_id',
                1
            );

            $presenteOriginal = $data['presente'] ?? null;

            if (
                !in_array(
                    $presenteOriginal,
                    [0, 1, '0', '1', false, true],
                    true
                )
            ) {
                throw new InvalidArgumentException(
                    'El campo presente debe tener el valor 0 o 1.'
                );
            }

            $presente = (int) ((bool) $presenteOriginal);

            $stmt = $this->db->prepare(
                'CALL sp_registrar_asistencia(
                    :inscripcion_id,
                    :presente
                )'
            );

            $stmt->bindValue(
                ':inscripcion_id',
                $inscripcionId,
                PDO::PARAM_INT
            );

            $stmt->bindValue(
                ':presente',
                $presente,
                PDO::PARAM_INT
            );

            $stmt->execute();

            $resultado = $stmt->fetch(PDO::FETCH_ASSOC);

            Response::success(
                'Asistencia registrada correctamente.',
                [
                    'resultado' => $resultado
                ]
            );
        } catch (InvalidArgumentException $e) {
            Response::error(
                $e->getMessage(),
                422
            );
        } catch (PDOException $e) {
            error_log(
                'Error al registrar asistencia: '
                . $e->getMessage()
            );

            Response::error(
                'No se pudo registrar la asistencia.',
                500
            );
        } catch (Throwable $e) {
            error_log(
                'Error inesperado al registrar asistencia: '
                . $e->getMessage()
            );

            Response::error(
                'Ocurrió un error interno al registrar la asistencia.',
                500
            );
        }
    }

    public function acreditacion(): void
    {
        AuthMiddleware::requireRole('organizador');

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
            $inscripcionId = Validator::integer(
                $data['inscripcion_id'] ?? null,
                'inscripcion_id',
                1
            );

            $codigoUnico = Validator::string(
                $data['codigo_unico'] ?? null,
                'codigo_unico',
                3,
                100
            );

            $url = trim(
                (string) ($data['url'] ?? '')
            );

            if (
                $url === '' ||
                !filter_var($url, FILTER_VALIDATE_URL)
            ) {
                throw new InvalidArgumentException(
                    'La URL de la acreditación no es válida.'
                );
            }

            if (mb_strlen($url) > 500) {
                throw new InvalidArgumentException(
                    'La URL de la acreditación no puede superar 500 caracteres.'
                );
            }

            $stmt = $this->db->prepare(
                'CALL sp_generar_acreditacion(
                    :inscripcion_id,
                    :codigo_unico,
                    :url
                )'
            );

            $stmt->bindValue(
                ':inscripcion_id',
                $inscripcionId,
                PDO::PARAM_INT
            );

            $stmt->bindValue(
                ':codigo_unico',
                $codigoUnico,
                PDO::PARAM_STR
            );

            $stmt->bindValue(
                ':url',
                $url,
                PDO::PARAM_STR
            );

            $stmt->execute();

            $resultado = $stmt->fetch(PDO::FETCH_ASSOC);

            Response::success(
                'Acreditación generada correctamente.',
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
                'Error al generar acreditación: '
                . $e->getMessage()
            );

            Response::error(
                'No se pudo generar la acreditación.',
                500
            );
        } catch (Throwable $e) {
            error_log(
                'Error inesperado al generar acreditación: '
                . $e->getMessage()
            );

            Response::error(
                'Ocurrió un error interno al generar la acreditación.',
                500
            );
        }
    }
}
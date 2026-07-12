<?php

declare(strict_types=1);

class ConferencistaController
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
                2,
                150
            );

          $bio = trim((string) ($data['bio'] ?? ''));

if (mb_strlen($bio) > 1000) {
    throw new InvalidArgumentException(
        'La biografía no puede superar 1000 caracteres.'
    );
}

            $email = Validator::email(
                $data['email'] ?? null,
                'email'
            );

            $eventoId = Validator::integer(
                $data['evento_id'] ?? null,
                'evento_id',
                1
            );

            $stmt = $this->db->prepare(
                'CALL sp_crear_conferencista(
                    :nombre,
                    :bio,
                    :email,
                    :evento_id
                )'
            );

            $stmt->bindValue(
                ':nombre',
                $nombre,
                PDO::PARAM_STR
            );

            $stmt->bindValue(
                ':bio',
                $bio,
                PDO::PARAM_STR
            );

            $stmt->bindValue(
                ':email',
                $email,
                PDO::PARAM_STR
            );

            $stmt->bindValue(
                ':evento_id',
                $eventoId,
                PDO::PARAM_INT
            );

            $stmt->execute();

            $conferencista = $stmt->fetch(PDO::FETCH_ASSOC);

            Response::success(
                'Conferencista creado correctamente.',
                [
                    'conferencista' => $conferencista
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
                'Error al crear conferencista: ' . $e->getMessage()
            );

            Response::error(
                'No se pudo crear el conferencista.',
                400
            );
        } catch (Throwable $e) {
            error_log(
                'Error inesperado al crear conferencista: '
                . $e->getMessage()
            );

            Response::error(
                'Ocurrió un error interno al crear el conferencista.',
                500
            );
        }
    }

    public function listar(): void
    {
        AuthMiddleware::requireAnyRole([
            'organizador',
            'participante'
        ]);

        try {
            $eventoId = Validator::integer(
                $_GET['evento_id'] ?? null,
                'evento_id',
                1
            );

            $stmt = $this->db->prepare(
                'CALL sp_listar_conferencistas_por_evento(
                    :evento_id
                )'
            );

            $stmt->bindValue(
                ':evento_id',
                $eventoId,
                PDO::PARAM_INT
            );

            $stmt->execute();

            $resultado = $stmt->fetchAll(PDO::FETCH_ASSOC);

            Response::success(
                'Conferencistas obtenidos correctamente.',
                [
                    'conferencistas' => $resultado
                ]
            );
        } catch (InvalidArgumentException $e) {
            Response::error(
                $e->getMessage(),
                422
            );
        } catch (PDOException $e) {
            error_log(
                'Error al listar conferencistas: ' . $e->getMessage()
            );

            Response::error(
                'No se pudieron obtener los conferencistas.',
                500
            );
        } catch (Throwable $e) {
            error_log(
                'Error inesperado al listar conferencistas: '
                . $e->getMessage()
            );

            Response::error(
                'Ocurrió un error interno al consultar los conferencistas.',
                500
            );
        }
    }
}
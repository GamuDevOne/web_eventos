<?php

declare(strict_types=1);

class UsuarioController
{
    private PDO $db;

    public function __construct()
    {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    public function registro(): void
    {
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
                100
            );

            $email = Validator::email(
                $data['email'] ?? null,
                'email'
            );

            $password = Validator::password(
                $data['password'] ?? null
            );

            $rol = Validator::role(
                $data['rol'] ?? null
            );

            $hash = password_hash(
                $password,
                PASSWORD_BCRYPT
            );

            if ($hash === false) {
                throw new RuntimeException(
                    'No fue posible proteger la contraseña.'
                );
            }

            $stmt = $this->db->prepare(
                'CALL sp_registrar_usuario(
                    :nombre,
                    :email,
                    :password_hash,
                    :rol
                )'
            );

            $stmt->bindValue(
                ':nombre',
                $nombre,
                PDO::PARAM_STR
            );

            $stmt->bindValue(
                ':email',
                $email,
                PDO::PARAM_STR
            );

            $stmt->bindValue(
                ':password_hash',
                $hash,
                PDO::PARAM_STR
            );

            $stmt->bindValue(
                ':rol',
                $rol,
                PDO::PARAM_STR
            );

            $stmt->execute();

            $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

            Response::success(
                'Usuario registrado correctamente.',
                [
                    'usuario' => $usuario
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
                'Error al registrar usuario: ' . $e->getMessage()
            );

            Response::error(
                'No se pudo registrar el usuario. El correo podría estar registrado.',
                409
            );
        } catch (Throwable $e) {
            error_log(
                'Error inesperado en registro: ' . $e->getMessage()
            );

            Response::error(
                'Ocurrió un error interno al registrar el usuario.',
                500
            );
        }
    }

    public function login(): void
    {
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
            $email = Validator::email(
                $data['email'] ?? null,
                'email'
            );

            /*
             * En el login no usamos Validator::password(),
             * porque una contraseña antigua podría no cumplir
             * todavía con las reglas nuevas.
             */
            $password = Validator::string(
                $data['password'] ?? null,
                'contraseña',
                1,
                255
            );

            $stmt = $this->db->prepare(
                'CALL sp_login_usuario(:email)'
            );

            $stmt->bindValue(
                ':email',
                $email,
                PDO::PARAM_STR
            );

            $stmt->execute();

            $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

            if (
                !$usuario ||
                !password_verify(
                    $password,
                    $usuario['password_hash']
                )
            ) {
                Response::error(
                    'Credenciales inválidas.',
                    401
                );
            }

            session_regenerate_id(true);

            $_SESSION['usuario_id'] = $usuario['id'];
            $_SESSION['rol'] = $usuario['rol'];
            $_SESSION['ultima_actividad'] = time();

            unset($usuario['password_hash']);

            Response::success(
                'Inicio de sesión correcto.',
                [
                    'usuario' => $usuario
                ]
            );
        } catch (InvalidArgumentException $e) {
            Response::error(
                $e->getMessage(),
                422
            );
        } catch (PDOException $e) {
            error_log(
                'Error al iniciar sesión: ' . $e->getMessage()
            );

            Response::error(
                'Ocurrió un error interno al iniciar sesión.',
                500
            );
        } catch (Throwable $e) {
            error_log(
                'Error inesperado en login: ' . $e->getMessage()
            );

            Response::error(
                'Ocurrió un error interno al iniciar sesión.',
                500
            );
        }
    }
      public function logout(): void
    {
        AuthMiddleware::requireAuthentication();

        $_SESSION = [];

        if (ini_get('session.use_cookies')) {
            $params = session_get_cookie_params();

            setcookie(session_name(), '', [
                'expires' => time() - 42000,
                'path' => $params['path'],
                'domain' => $params['domain'],
                'secure' => $params['secure'],
                'httponly' => $params['httponly'],
                'samesite' => 'Lax'
            ]);
        }

        session_destroy();

        Response::success(
            'Sesión cerrada correctamente.'
        );
    }
}
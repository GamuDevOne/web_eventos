<?php

declare(strict_types=1);

class AuthMiddleware
{
    public static function requireAuthentication(): void
    {
        if (empty($_SESSION['usuario_id'])) {
          Response::error(
    'Debes iniciar sesión para realizar esta acción.',
    401
);
            exit;
        }
    }

    public static function requireRole(string $requiredRole): void
    {
        self::requireAuthentication();

        $currentRole = $_SESSION['rol'] ?? '';

        if ($currentRole !== $requiredRole) {
            http_response_code(403);

            echo json_encode([
                'status' => 'error',
                'mensaje' => 'No tienes permisos para realizar esta acción.'
            ], JSON_UNESCAPED_UNICODE);

            exit;
        }
    }

    public static function requireAnyRole(array $allowedRoles): void
    {
        self::requireAuthentication();

        $currentRole = $_SESSION['rol'] ?? '';

        if (!in_array($currentRole, $allowedRoles, true)) {
            http_response_code(403);

            echo json_encode([
                'status' => 'error',
                'mensaje' => 'No tienes permisos para realizar esta acción.'
            ], JSON_UNESCAPED_UNICODE);

            exit;
        }
    }
}
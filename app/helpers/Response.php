<?php

declare(strict_types=1);

class Response
{
    public static function json(
        array $data,
        int $statusCode = 200
    ): void {
        http_response_code($statusCode);

        echo json_encode(
            $data,
            JSON_UNESCAPED_UNICODE |
            JSON_UNESCAPED_SLASHES
        );

        exit;
    }

    public static function success(
        string $message,
        array $data = [],
        int $statusCode = 200
    ): void {
        self::json([
            'status' => 'success',
            'mensaje' => $message,
            'data' => $data
        ], $statusCode);
    }

    public static function error(
        string $message,
        int $statusCode = 400,
        array $errors = []
    ): void {
        self::json([
            'status' => 'error',
            'mensaje' => $message,
            'errores' => $errors
        ], $statusCode);
    }
}
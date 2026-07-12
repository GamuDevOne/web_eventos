<?php

declare(strict_types=1);

class ExceptionHandler
{
    public static function register(): void
    {
        set_exception_handler(
            [self::class, 'handleException']
        );

        set_error_handler(
            [self::class, 'handleError']
        );
    }

    public static function handleException(
        Throwable $exception
    ): void {
        error_log(
            sprintf(
                '[%s] %s en %s:%d',
                get_class($exception),
                $exception->getMessage(),
                $exception->getFile(),
                $exception->getLine()
            )
        );

        if ($exception instanceof InvalidArgumentException) {
            Response::error(
                $exception->getMessage(),
                422
            );
        }

        Response::error(
            'Ocurrió un error interno en el servidor.',
            500
        );
    }

    public static function handleError(
        int $severity,
        string $message,
        string $file,
        int $line
    ): bool {
        if (!(error_reporting() & $severity)) {
            return false;
        }

        throw new ErrorException(
            $message,
            0,
            $severity,
            $file,
            $line
        );
    }
}
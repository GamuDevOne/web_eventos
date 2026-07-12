<?php

declare(strict_types=1);

class Validator
{
    public static function required(
        mixed $value,
        string $fieldName
    ): mixed {
        if (
            $value === null ||
            (is_string($value) && trim($value) === '')
        ) {
            throw new InvalidArgumentException(
                "El campo {$fieldName} es obligatorio."
            );
        }

        return $value;
    }

    public static function string(
        mixed $value,
        string $fieldName,
        int $minLength = 1,
        int $maxLength = 255
    ): string {
        self::required($value, $fieldName);

        if (!is_string($value)) {
            throw new InvalidArgumentException(
                "El campo {$fieldName} debe ser texto."
            );
        }

        $value = trim($value);
        $length = mb_strlen($value);

        if ($length < $minLength || $length > $maxLength) {
            throw new InvalidArgumentException(
                "El campo {$fieldName} debe tener entre "
                . "{$minLength} y {$maxLength} caracteres."
            );
        }

        return $value;
    }

    public static function email(
        mixed $value,
        string $fieldName = 'correo'
    ): string {
        self::required($value, $fieldName);

        $value = trim((string) $value);

        if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException(
                "El campo {$fieldName} debe contener un correo válido."
            );
        }

        return mb_strtolower($value);
    }

    public static function integer(
        mixed $value,
        string $fieldName,
        int $min = 1,
        ?int $max = null
    ): int {
        self::required($value, $fieldName);

        $options = [
            'options' => [
                'min_range' => $min
            ]
        ];

        if ($max !== null) {
            $options['options']['max_range'] = $max;
        }

        $validatedValue = filter_var(
            $value,
            FILTER_VALIDATE_INT,
            $options
        );

        if ($validatedValue === false) {
            $message = "El campo {$fieldName} debe ser un número entero"
                . " mayor o igual a {$min}.";

            if ($max !== null) {
                $message = "El campo {$fieldName} debe ser un número entero"
                    . " entre {$min} y {$max}.";
            }

            throw new InvalidArgumentException($message);
        }

        return $validatedValue;
    }

    public static function password(
        mixed $value,
        string $fieldName = 'contraseña'
    ): string {
        self::required($value, $fieldName);

        if (!is_string($value)) {
            throw new InvalidArgumentException(
                "El campo {$fieldName} debe ser texto."
            );
        }

        if (strlen($value) < 8) {
            throw new InvalidArgumentException(
                "La contraseña debe tener al menos 8 caracteres."
            );
        }

        if (!preg_match('/[A-Z]/', $value)) {
            throw new InvalidArgumentException(
                "La contraseña debe incluir al menos una letra mayúscula."
            );
        }

        if (!preg_match('/[a-z]/', $value)) {
            throw new InvalidArgumentException(
                "La contraseña debe incluir al menos una letra minúscula."
            );
        }

        if (!preg_match('/[0-9]/', $value)) {
            throw new InvalidArgumentException(
                "La contraseña debe incluir al menos un número."
            );
        }

        return $value;
    }

    public static function role(mixed $value): string
    {
        $value = self::string($value, 'rol', 1, 30);

        $allowedRoles = [
            'organizador',
            'participante'
        ];

        if (!in_array($value, $allowedRoles, true)) {
            throw new InvalidArgumentException(
                'El rol debe ser organizador o participante.'
            );
        }

        return $value;
    }

    public static function date(
        mixed $value,
        string $fieldName = 'fecha'
    ): string {
        $value = self::string($value, $fieldName, 10, 10);

        $date = DateTime::createFromFormat('Y-m-d', $value);

        if (
            !$date ||
            $date->format('Y-m-d') !== $value
        ) {
            throw new InvalidArgumentException(
                "El campo {$fieldName} debe tener el formato YYYY-MM-DD."
            );
        }

        return $value;
    }
}
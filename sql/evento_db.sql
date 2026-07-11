-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 11-07-2026 a las 03:16:29
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `evento_db`
--
DROP DATABASE IF EXISTS evento_db;
CREATE DATABASE evento_db;
USE evento_db;

-- ========================================================
-- 1. CREACIÓN DE TABLAS
-- ========================================================

CREATE TABLE `acreditaciones` (
  `id` int(11) NOT NULL,
  `inscripcion_id` int(11) NOT NULL,
  `codigo_unico` varchar(50) NOT NULL,
  `fecha_emision` timestamp NOT NULL DEFAULT current_timestamp(),
  `url_descarga` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `asistencia` (
  `id` int(11) NOT NULL,
  `inscripcion_id` int(11) NOT NULL,
  `fecha_asistencia` datetime DEFAULT current_timestamp(),
  `presente` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `conferencistas` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `bio` text DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `evento_id` int(11) NOT NULL,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `eventos` (
  `id` int(11) NOT NULL,
  `nombre` varchar(150) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `cupo_total` int(11) NOT NULL CHECK (`cupo_total` > 0),
  `cupo_ocupado` int(11) DEFAULT 0 CHECK (`cupo_ocupado` >= 0),
  `fecha` datetime NOT NULL,
  `organizador_id` int(11) NOT NULL,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `inscripciones` (
  `id` int(11) NOT NULL,
  `evento_id` int(11) NOT NULL,
  `usuario_id` int(11) NOT NULL,
  `fecha_inscripcion` timestamp NOT NULL DEFAULT current_timestamp(),
  `estado` enum('confirmada','cancelada') DEFAULT 'confirmada'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `usuarios` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `rol` enum('organizador','participante') NOT NULL,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- ========================================================
-- 2. INSERCIÓN DE DATOS
-- ========================================================

INSERT INTO `usuarios` (`id`, `nombre`, `email`, `password_hash`, `rol`, `creado_en`) VALUES
(1, 'Organizador Principal', 'org@eventos.com', '$2b$10$72m758eU7PONdfC/JEZv4.0c4HyFXGqUXHc2br2aAkudCGijiFyIS', 'organizador', '2026-07-11 00:13:24'),
(2, 'Ana Pérez', 'ana@email.com', '$2b$10$tPRx/IHLTY625S975Hs.U.TJZFkNGI3TQSDIMy.wEC6IDe5kDA.lu', 'participante', '2026-07-11 00:13:24'),
(3, 'Carlos Gómez', 'carlos@email.com', '$2b$10$WObXJxaA.XL5QDph428H8Op3.d2SvaA1lMwJgz.TgYG1WPJwdmW9O', 'participante', '2026-07-11 00:13:24'),
(4, 'María López', 'maria@email.com', '$2b$10$BM8xV9.Oz1z7ZtUPxmJ1nepkFrapu6VSatJd8BAdOAbgwMaieriGC', 'participante', '2026-07-11 00:13:24'),
(5, 'Luis Fernández', 'luis@email.com', '$2b$10$PyZT0n5vgg/nwb6KulpF2erQguo1r99U3ymZImyzCR9pmywaIbIKC', 'participante', '2026-07-11 00:13:24');

INSERT INTO `eventos` (`id`, `nombre`, `descripcion`, `cupo_total`, `cupo_ocupado`, `fecha`, `organizador_id`, `creado_en`) VALUES
(1, 'Congreso de Tecnología 2026', 'Evento anual sobre innovaciones tecnológicas', 50, 3, '2026-08-15 09:00:00', 1, '2026-07-11 00:13:25'),
(2, 'Seminario de Marketing Digital', 'Estrategias avanzadas en marketing online', 30, 1, '2026-09-10 10:00:00', 1, '2026-07-11 00:13:25'),
(3, 'Taller de Desarrollo Ágil', 'Prácticas de Scrum y Kanban', 20, 1, '2026-07-20 14:00:00', 1, '2026-07-11 00:13:25');

INSERT INTO `conferencistas` (`id`, `nombre`, `bio`, `email`, `evento_id`, `creado_en`) VALUES
(1, 'Dra. Elena Ruiz', 'Experta en IA y Machine Learning', 'elena.ruiz@tech.com', 1, '2026-07-11 00:13:25'),
(2, 'Ing. Javier Mora', 'Consultor en transformación digital', 'javier.mora@digital.com', 1, '2026-07-11 00:13:25'),
(3, 'Lic. Sofía Torres', 'Especialista en SEO y SEM', 'sofia.torres@marketing.com', 2, '2026-07-11 00:13:25'),
(4, 'Dr. Andrés Castro', 'Coach ágil certificado', 'andres.castro@agile.com', 3, '2026-07-11 00:13:25');

INSERT INTO `inscripciones` (`id`, `evento_id`, `usuario_id`, `fecha_inscripcion`, `estado`) VALUES
(1, 1, 2, '2026-07-11 00:13:25', 'confirmada'),
(2, 1, 3, '2026-07-11 00:13:25', 'confirmada'),
(3, 1, 4, '2026-07-11 00:13:25', 'confirmada'),
(4, 2, 2, '2026-07-11 00:13:25', 'confirmada'),
(5, 3, 5, '2026-07-11 00:13:25', 'confirmada');

INSERT INTO `acreditaciones` (`id`, `inscripcion_id`, `codigo_unico`, `fecha_emision`, `url_descarga`) VALUES
(1, 1, 'ACR-001-ABC', '2026-07-11 00:13:26', '/acreditaciones/ACR-001-ABC.pdf'),
(2, 3, 'ACR-003-DEF', '2026-07-11 00:13:26', '/acreditaciones/ACR-003-DEF.pdf');

INSERT INTO `asistencia` (`id`, `inscripcion_id`, `fecha_asistencia`, `presente`) VALUES
(1, 1, '2026-07-10 19:13:25', 1),
(2, 2, '2026-07-10 19:13:25', 0),
(3, 3, '2026-07-10 19:13:25', 1);


-- ========================================================
-- 3. ÍNDICES Y RESTRICCIONES (LLAVES FORÁNEAS)
-- ========================================================

ALTER TABLE `acreditaciones`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `codigo_unico` (`codigo_unico`),
  ADD KEY `inscripcion_id` (`inscripcion_id`);

ALTER TABLE `asistencia`
  ADD PRIMARY KEY (`id`),
  ADD KEY `inscripcion_id` (`inscripcion_id`);

ALTER TABLE `conferencistas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `evento_id` (`evento_id`);

ALTER TABLE `eventos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `organizador_id` (`organizador_id`);

ALTER TABLE `inscripciones`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_inscripcion` (`evento_id`,`usuario_id`),
  ADD KEY `usuario_id` (`usuario_id`);

ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

-- AUTO_INCREMENT
ALTER TABLE `acreditaciones` MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;
ALTER TABLE `asistencia` MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;
ALTER TABLE `conferencistas` MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;
ALTER TABLE `eventos` MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;
ALTER TABLE `inscripciones` MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;
ALTER TABLE `usuarios` MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

-- Llaves Foráneas
ALTER TABLE `acreditaciones`
  ADD CONSTRAINT `acreditaciones_ibfk_1` FOREIGN KEY (`inscripcion_id`) REFERENCES `inscripciones` (`id`) ON DELETE CASCADE;

ALTER TABLE `asistencia`
  ADD CONSTRAINT `asistencia_ibfk_1` FOREIGN KEY (`inscripcion_id`) REFERENCES `inscripciones` (`id`) ON DELETE CASCADE;

ALTER TABLE `conferencistas`
  ADD CONSTRAINT `conferencistas_ibfk_1` FOREIGN KEY (`evento_id`) REFERENCES `eventos` (`id`) ON DELETE CASCADE;

ALTER TABLE `eventos`
  ADD CONSTRAINT `eventos_ibfk_1` FOREIGN KEY (`organizador_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

ALTER TABLE `inscripciones`
  ADD CONSTRAINT `inscripciones_ibfk_1` FOREIGN KEY (`evento_id`) REFERENCES `eventos` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `inscripciones_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;


-- ========================================================
-- 4. PROCEDIMIENTOS ALMACENADOS (STANDARDIZADOS)
-- ========================================================
DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_conferencista` (IN `p_nombre` VARCHAR(100), IN `p_bio` TEXT, IN `p_email` VARCHAR(100), IN `p_evento_id` INT)
BEGIN
    -- Mejor práctica: Atrapar errores y devolverlos
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'error' AS status, 'Error al crear el conferencista. Verifica que el evento_id exista.' AS mensaje;
    END;

    START TRANSACTION;
    INSERT INTO conferencistas (nombre, bio, email, evento_id)
    VALUES (p_nombre, p_bio, p_email, p_evento_id);
    COMMIT;

    SELECT 'success' AS status, 'Conferencista creado exitosamente' AS mensaje, id, nombre, bio, email, evento_id 
    FROM conferencistas WHERE id = LAST_INSERT_ID();
END$$


CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_evento` (IN `p_nombre` VARCHAR(150), IN `p_descripcion` TEXT, IN `p_cupo_total` INT, IN `p_fecha` DATETIME, IN `p_organizador_id` INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'error' AS status, 'Error al crear el evento. Verifica los datos ingresados.' AS mensaje;
    END;

    START TRANSACTION;
    INSERT INTO eventos (nombre, descripcion, cupo_total, fecha, organizador_id)
    VALUES (p_nombre, p_descripcion, p_cupo_total, p_fecha, p_organizador_id);
    COMMIT;
    
    SELECT 'success' AS status, 'Evento creado exitosamente' AS mensaje, id, nombre, descripcion, cupo_total, cupo_ocupado, fecha, organizador_id
    FROM eventos
    WHERE id = LAST_INSERT_ID();
END$$


CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_generar_acreditacion` (IN `p_inscripcion_id` INT, IN `p_codigo_unico` VARCHAR(50), IN `p_url` VARCHAR(255))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'error' AS status, 'Error al generar acreditación' AS mensaje;
    END;
    
    START TRANSACTION;
    INSERT INTO acreditaciones (inscripcion_id, codigo_unico, url_descarga)
    VALUES (p_inscripcion_id, p_codigo_unico, p_url);
    COMMIT;
    
    -- Estandarizado para devolver status junto con los datos
    SELECT 'success' AS status, 'Acreditación generada exitosamente' AS mensaje, id, inscripcion_id, codigo_unico, fecha_emision, url_descarga
    FROM acreditaciones
    WHERE id = LAST_INSERT_ID();
END$$


CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_inscribir_participante` (IN `p_evento_id` INT, IN `p_participante_id` INT)
BEGIN
    DECLARE v_cupo_total INT DEFAULT NULL;
    DECLARE v_cupo_ocupado INT;
    DECLARE v_ya_inscrito INT;
    
    -- Manejo de excepciones
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'error' AS status, 'Ocurrió un error en la inscripción (base de datos)' AS mensaje;
    END;
    
    -- CORRECCIÓN DEL BUG: Si el SELECT INTO no encuentra filas, setea NULL y permite continuar
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_cupo_total = NULL;
    
    START TRANSACTION;
    
    -- Verificar si el evento existe y obtener cupos
    SELECT cupo_total, cupo_ocupado INTO v_cupo_total, v_cupo_ocupado
    FROM eventos
    WHERE id = p_evento_id
    FOR UPDATE;  -- Bloqueo para evitar condiciones de carrera
    
    IF v_cupo_total IS NULL THEN
        SELECT 'error' AS status, 'El evento no existe' AS mensaje;
        ROLLBACK;
    ELSE
        -- Verificar si el participante ya está inscrito
        SELECT COUNT(*) INTO v_ya_inscrito
        FROM inscripciones
        WHERE evento_id = p_evento_id AND usuario_id = p_participante_id AND estado = 'confirmada';
        
        IF v_ya_inscrito > 0 THEN
            SELECT 'error' AS status, 'El participante ya está inscrito en este evento' AS mensaje;
            ROLLBACK;
        ELSE
            -- Validar cupo
            IF v_cupo_ocupado < v_cupo_total THEN
                -- Insertar inscripción
                INSERT INTO inscripciones (evento_id, usuario_id, estado)
                VALUES (p_evento_id, p_participante_id, 'confirmada');
                
                -- Actualizar cupo ocupado
                UPDATE eventos
                SET cupo_ocupado = cupo_ocupado + 1
                WHERE id = p_evento_id;
                
                COMMIT;
                SELECT 'success' AS status, 'Inscripción exitosa' AS mensaje;
            ELSE
                SELECT 'error' AS status, 'Cupo lleno' AS mensaje;
                ROLLBACK;
            END IF;
        END IF;
    END IF;
END$$


CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_listar_conferencistas_por_evento` (IN `p_evento_id` INT)
BEGIN
    SELECT id, nombre, bio, email, evento_id
    FROM conferencistas
    WHERE evento_id = p_evento_id;
END$$


CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_listar_eventos` ()
BEGIN
    SELECT id, nombre, cupo_total, cupo_ocupado, fecha
    FROM eventos
    ORDER BY fecha ASC;
END$$


CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_login_usuario` (IN `p_email` VARCHAR(100))
BEGIN
    SELECT id, nombre, email, password_hash, rol
    FROM usuarios
    WHERE email = p_email;
END$$


CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_ocupacion` (IN `p_evento_id` INT)
BEGIN
    SELECT id AS evento_id, cupo_total, cupo_ocupado,
           ROUND((cupo_ocupado / cupo_total) * 100, 2) AS porcentaje_ocupacion
    FROM eventos
    WHERE id = p_evento_id;
END$$


CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_asistencia` (IN `p_inscripcion_id` INT, IN `p_presente` BOOLEAN)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'error' AS status, 'Error al registrar asistencia' AS mensaje;
    END;
    
    START TRANSACTION;
    INSERT INTO asistencia (inscripcion_id, presente)
    VALUES (p_inscripcion_id, p_presente);
    COMMIT;
    
    SELECT 'success' AS status, 'Asistencia registrada' AS mensaje;
END$$


CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_usuario` (IN `p_nombre` VARCHAR(100), IN `p_email` VARCHAR(100), IN `p_password_hash` VARCHAR(255), IN `p_rol` ENUM('organizador','participante'))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'error' AS status, 'El correo ya está registrado o hubo un error' AS mensaje;
    END;

    START TRANSACTION;
    INSERT INTO usuarios (nombre, email, password_hash, rol)
    VALUES (p_nombre, p_email, p_password_hash, p_rol);
    COMMIT;

    SELECT 'success' AS status, 'Usuario registrado exitosamente' AS mensaje, id, nombre, email, rol 
    FROM usuarios WHERE id = LAST_INSERT_ID();
END$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
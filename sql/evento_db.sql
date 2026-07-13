-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 13-07-2026 a las 21:52:43
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

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_buscar_inscripcion` (IN `p_evento_id` INT, IN `p_usuario_id` INT)   BEGIN
    SELECT id AS inscripcion_id
    FROM inscripciones
    WHERE evento_id = p_evento_id AND usuario_id = p_usuario_id AND estado = 'confirmada'
    LIMIT 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_buscar_usuario_por_codigo` (IN `p_codigo` VARCHAR(12))   BEGIN
    SELECT id, codigo, nombre, email, rol FROM usuarios WHERE codigo = p_codigo;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cancelar_inscripcion` (IN `p_inscripcion_id` INT, IN `p_usuario_id` INT, IN `p_es_organizador` BOOLEAN)   BEGIN
    DECLARE v_evento_id INT DEFAULT NULL;
    DECLARE v_usuario_dueno INT;
    DECLARE v_fecha DATETIME;
    DECLARE v_estado VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'error' AS status, 'Ocurrió un error al cancelar la inscripción' AS mensaje;
    END;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_evento_id = NULL;

    START TRANSACTION;

    SELECT i.evento_id, i.usuario_id, i.estado, e.fecha
    INTO v_evento_id, v_usuario_dueno, v_estado, v_fecha
    FROM inscripciones i
    INNER JOIN eventos e ON e.id = i.evento_id
    WHERE i.id = p_inscripcion_id
    FOR UPDATE;

    IF v_evento_id IS NULL THEN
        SELECT 'error' AS status, 'La inscripción no existe' AS mensaje;
        ROLLBACK;
    ELSEIF v_estado = 'cancelada' THEN
        SELECT 'error' AS status, 'Esta inscripción ya estaba cancelada' AS mensaje;
        ROLLBACK;
    ELSEIF NOT p_es_organizador AND v_usuario_dueno <> p_usuario_id THEN
        SELECT 'error' AS status, 'No puedes cancelar la inscripción de otro participante' AS mensaje;
        ROLLBACK;
    ELSEIF TIMESTAMPDIFF(HOUR, NOW(), v_fecha) < 96 THEN
        SELECT 'error' AS status, 'Ya no se puede cancelar: faltan menos de 4 días para el evento' AS mensaje;
        ROLLBACK;
    ELSE
        UPDATE inscripciones SET estado = 'cancelada' WHERE id = p_inscripcion_id;
        UPDATE eventos SET cupo_ocupado = GREATEST(cupo_ocupado - 1, 0) WHERE id = v_evento_id;
        COMMIT;
        SELECT 'success' AS status, 'Inscripción cancelada correctamente' AS mensaje;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_conferencista` (IN `p_nombre` VARCHAR(100), IN `p_bio` TEXT, IN `p_email` VARCHAR(100), IN `p_evento_id` INT)   BEGIN
    INSERT INTO conferencistas (nombre, bio, email, evento_id)
    VALUES (p_nombre, p_bio, p_email, p_evento_id);

    SELECT id, nombre, bio, email, evento_id FROM conferencistas WHERE id = LAST_INSERT_ID();
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_evento` (IN `p_nombre` VARCHAR(150), IN `p_descripcion` TEXT, IN `p_cupo_total` INT, IN `p_fecha` DATETIME, IN `p_organizador_id` INT)   BEGIN
    INSERT INTO eventos (nombre, descripcion, cupo_total, fecha, organizador_id)
    VALUES (p_nombre, p_descripcion, p_cupo_total, p_fecha, p_organizador_id);
    
    SELECT id, nombre, descripcion, cupo_total, cupo_ocupado, fecha, organizador_id
    FROM eventos
    WHERE id = LAST_INSERT_ID();
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_editar_conferencista` (IN `p_id` INT, IN `p_nombre` VARCHAR(100), IN `p_bio` TEXT, IN `p_email` VARCHAR(100))   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'error' AS status, 'Error al editar el conferencista' AS mensaje;
    END;

    START TRANSACTION;
    UPDATE conferencistas SET nombre = p_nombre, bio = p_bio, email = p_email WHERE id = p_id;
    COMMIT;

    SELECT 'success' AS status, 'Conferencista actualizado exitosamente' AS mensaje, id, nombre, bio, email, evento_id
    FROM conferencistas WHERE id = p_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_editar_evento` (IN `p_id` INT, IN `p_nombre` VARCHAR(150), IN `p_descripcion` TEXT, IN `p_cupo_total` INT, IN `p_fecha` DATETIME)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'error' AS status, 'Error al editar el evento' AS mensaje;
    END;

    START TRANSACTION;
    UPDATE eventos SET nombre = p_nombre, descripcion = p_descripcion, cupo_total = p_cupo_total, fecha = p_fecha
    WHERE id = p_id;
    COMMIT;

    SELECT 'success' AS status, 'Evento actualizado exitosamente' AS mensaje,
           id, nombre, descripcion, cupo_total, cupo_ocupado, fecha, organizador_id
    FROM eventos WHERE id = p_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_conferencista` (IN `p_id` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'error' AS status, 'Error al eliminar el conferencista' AS mensaje;
    END;

    START TRANSACTION;
    DELETE FROM conferencistas WHERE id = p_id;
    COMMIT;

    SELECT 'success' AS status, 'Conferencista eliminado exitosamente' AS mensaje;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_evento` (IN `p_id` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'error' AS status, 'Error al eliminar el evento' AS mensaje;
    END;

    START TRANSACTION;
    DELETE FROM eventos WHERE id = p_id;
    COMMIT;

    SELECT 'success' AS status, 'Evento eliminado exitosamente' AS mensaje;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_generar_acreditacion` (IN `p_inscripcion_id` INT, IN `p_codigo_unico` VARCHAR(50), IN `p_url` VARCHAR(255))   BEGIN
    DECLARE v_presente INT DEFAULT NULL;
    DECLARE v_existe INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'error' AS status, 'Error al generar la acreditación digital' AS mensaje;
    END;

    SELECT presente INTO v_presente FROM asistencia WHERE inscripcion_id = p_inscripcion_id LIMIT 1;
    SELECT COUNT(*) INTO v_existe FROM acreditaciones WHERE inscripcion_id = p_inscripcion_id;

    IF v_presente IS NULL OR v_presente = 0 THEN
        SELECT 'error' AS status, 'Solo se puede acreditar a participantes que asistieron al evento' AS mensaje;
    ELSEIF v_existe > 0 THEN
        SELECT 'error' AS status, 'Este participante ya tiene una acreditación digital generada' AS mensaje;
    ELSE
        START TRANSACTION;
        INSERT INTO acreditaciones (inscripcion_id, codigo_unico, url_descarga)
        VALUES (p_inscripcion_id, p_codigo_unico, NULL);
        COMMIT;

        SELECT 'success' AS status, 'Acreditación digital generada exitosamente' AS mensaje,
               id, inscripcion_id, codigo_unico, fecha_emision
        FROM acreditaciones WHERE id = LAST_INSERT_ID();
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_inscribir_participante` (IN `p_evento_id` INT, IN `p_participante_id` INT)   BEGIN
    DECLARE v_cupo_total INT DEFAULT NULL;
    DECLARE v_cupo_ocupado INT;
    DECLARE v_fecha DATETIME;
    DECLARE v_ya_inscrito INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'error' AS status, 'Ocurrió un error en la inscripción (base de datos)' AS mensaje;
    END;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_cupo_total = NULL;

    START TRANSACTION;

    SELECT cupo_total, cupo_ocupado, fecha INTO v_cupo_total, v_cupo_ocupado, v_fecha
    FROM eventos WHERE id = p_evento_id FOR UPDATE;

    IF v_cupo_total IS NULL THEN
        SELECT 'error' AS status, 'El evento no existe' AS mensaje;
        ROLLBACK;
    ELSEIF v_fecha < NOW() THEN
        SELECT 'error' AS status, 'Este evento ya finalizó' AS mensaje;
        ROLLBACK;
    ELSEIF TIMESTAMPDIFF(HOUR, NOW(), v_fecha) < 48 THEN
        SELECT 'error' AS status, 'Las inscripciones cierran 2 días antes del evento' AS mensaje;
        ROLLBACK;
    ELSE
        SELECT COUNT(*) INTO v_ya_inscrito FROM inscripciones
        WHERE evento_id = p_evento_id AND usuario_id = p_participante_id AND estado = 'confirmada';

        IF v_ya_inscrito > 0 THEN
            SELECT 'error' AS status, 'El participante ya está inscrito en este evento' AS mensaje;
            ROLLBACK;
        ELSEIF v_cupo_ocupado < v_cupo_total THEN
            INSERT INTO inscripciones (evento_id, usuario_id, estado) VALUES (p_evento_id, p_participante_id, 'confirmada');
            UPDATE eventos SET cupo_ocupado = cupo_ocupado + 1 WHERE id = p_evento_id;
            COMMIT;
            SELECT 'success' AS status, 'Inscripción exitosa' AS mensaje;
        ELSE
            SELECT 'error' AS status, 'Cupo lleno' AS mensaje;
            ROLLBACK;
        END IF;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_listar_conferencistas_por_evento` (IN `p_evento_id` INT)   BEGIN
    SELECT id, nombre, bio, email, evento_id
    FROM conferencistas
    WHERE evento_id = p_evento_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_listar_eventos` ()   BEGIN
    SELECT id, nombre, descripcion, cupo_total, cupo_ocupado, fecha
    FROM eventos
    ORDER BY fecha ASC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_listar_inscripciones_por_evento` (IN `p_evento_id` INT)   BEGIN
    SELECT
        i.id AS inscripcion_id,
        i.evento_id,
        i.usuario_id,
        u.codigo AS participante_codigo,
        i.fecha_inscripcion,
        i.estado,
        u.nombre AS participante_nombre,
        u.email AS participante_email,
        a.presente,
        a.fecha_asistencia,
        ac.id AS acreditacion_id,
        ac.codigo_unico,
        ac.fecha_emision AS acreditacion_fecha_emision,
        e.fecha AS evento_fecha,
        e.nombre AS evento_nombre
    FROM inscripciones i
    INNER JOIN usuarios u ON u.id = i.usuario_id
    INNER JOIN eventos e ON e.id = i.evento_id
    LEFT JOIN asistencia a ON a.inscripcion_id = i.id
    LEFT JOIN acreditaciones ac ON ac.inscripcion_id = i.id
    WHERE i.evento_id = p_evento_id AND i.estado = 'confirmada'
    ORDER BY u.nombre ASC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_listar_inscripciones_por_usuario` (IN `p_usuario_id` INT)   BEGIN
    SELECT
        i.id AS inscripcion_id,
        i.evento_id,
        e.nombre AS evento_nombre,
        e.fecha AS evento_fecha,
        i.fecha_inscripcion,
        i.estado,
        a.presente,
        ac.codigo_unico,
        ac.fecha_emision AS acreditacion_fecha_emision
    FROM inscripciones i
    INNER JOIN eventos e ON e.id = i.evento_id
    LEFT JOIN asistencia a ON a.inscripcion_id = i.id
    LEFT JOIN acreditaciones ac ON ac.inscripcion_id = i.id
    WHERE i.usuario_id = p_usuario_id AND i.estado = 'confirmada'
    ORDER BY e.fecha ASC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_login_usuario` (IN `p_email` VARCHAR(100))   BEGIN
    SELECT id, codigo, nombre, email, password_hash, rol
    FROM usuarios WHERE email = p_email;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_obtener_ocupacion` (IN `p_evento_id` INT)   BEGIN
    SELECT 
        id AS evento_id,
        cupo_total,
        cupo_ocupado,
        ROUND((cupo_ocupado / cupo_total) * 100, 2) AS porcentaje_ocupacion
    FROM eventos
    WHERE id = p_evento_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_asistencia` (IN `p_inscripcion_id` INT, IN `p_presente` BOOLEAN)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'error' AS status, 'Error al registrar asistencia' AS mensaje;
    END;

    START TRANSACTION;
    INSERT INTO asistencia (inscripcion_id, presente) VALUES (p_inscripcion_id, p_presente)
    ON DUPLICATE KEY UPDATE presente = p_presente, fecha_asistencia = CURRENT_TIMESTAMP;
    COMMIT;

    SELECT 'success' AS status, 'Asistencia registrada' AS mensaje;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_usuario` (IN `p_nombre` VARCHAR(100), IN `p_email` VARCHAR(100), IN `p_password_hash` VARCHAR(255), IN `p_rol` ENUM('organizador','participante'), IN `p_codigo` VARCHAR(12))   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'error' AS status, 'El correo ya está registrado o hubo un error' AS mensaje;
    END;

    START TRANSACTION;
    INSERT INTO usuarios (nombre, email, password_hash, rol, codigo)
    VALUES (p_nombre, p_email, p_password_hash, p_rol, p_codigo);
    COMMIT;

    SELECT 'success' AS status, 'Usuario registrado exitosamente' AS mensaje, id, codigo, nombre, email, rol
    FROM usuarios WHERE id = LAST_INSERT_ID();
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `acreditaciones`
--

CREATE TABLE `acreditaciones` (
  `id` int(11) NOT NULL,
  `inscripcion_id` int(11) NOT NULL,
  `codigo_unico` varchar(50) NOT NULL,
  `fecha_emision` timestamp NOT NULL DEFAULT current_timestamp(),
  `url_descarga` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `acreditaciones`
--

INSERT INTO `acreditaciones` (`id`, `inscripcion_id`, `codigo_unico`, `fecha_emision`, `url_descarga`) VALUES
(1, 1, 'ACR-001-ABC', '2026-07-11 00:13:26', '/acreditaciones/ACR-001-ABC.pdf'),
(2, 3, 'ACR-003-DEF', '2026-07-11 00:13:26', '/acreditaciones/ACR-003-DEF.pdf'),
(3, 6, 'ACR-3-RD8B72-0X5I', '2026-07-13 19:13:34', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `asistencia`
--

CREATE TABLE `asistencia` (
  `id` int(11) NOT NULL,
  `inscripcion_id` int(11) NOT NULL,
  `fecha_asistencia` datetime DEFAULT current_timestamp(),
  `presente` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `asistencia`
--

INSERT INTO `asistencia` (`id`, `inscripcion_id`, `fecha_asistencia`, `presente`) VALUES
(1, 1, '2026-07-10 19:13:25', 1),
(2, 2, '2026-07-10 19:13:25', 0),
(3, 3, '2026-07-10 19:13:25', 1),
(4, 6, '2026-07-13 14:12:49', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `conferencistas`
--

CREATE TABLE `conferencistas` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `bio` text DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `evento_id` int(11) NOT NULL,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `conferencistas`
--

INSERT INTO `conferencistas` (`id`, `nombre`, `bio`, `email`, `evento_id`, `creado_en`) VALUES
(1, 'Dra. Elena Ruiz', 'Experta en IA y Machine Learning', 'elena.ruiz@tech.com', 1, '2026-07-11 00:13:25'),
(2, 'Ing. Javier Mora', 'Consultor en transformación digital', 'javier.mora@digital.com', 1, '2026-07-11 00:13:25'),
(3, 'Lic. Sofía Torres', 'Especialista en SEO y SEM', 'sofia.torres@marketing.com', 2, '2026-07-11 00:13:25'),
(4, 'Dr. Andrés Castro', 'Coach ágil certificado', 'andres.castro@agile.com', 3, '2026-07-11 00:13:25'),
(5, 'Dr. Azucar y pan', 'Experto en hacer pan', 'drazucar@gmail.com', 4, '2026-07-13 19:04:13');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `eventos`
--

CREATE TABLE `eventos` (
  `id` int(11) NOT NULL,
  `nombre` varchar(150) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `cupo_total` int(11) NOT NULL CHECK (`cupo_total` > 0),
  `cupo_ocupado` int(11) DEFAULT 0 CHECK (`cupo_ocupado` >= 0),
  `fecha` datetime NOT NULL,
  `organizador_id` int(11) NOT NULL,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp()
) ;

--
-- Volcado de datos para la tabla `eventos`
--

INSERT INTO `eventos` (`id`, `nombre`, `descripcion`, `cupo_total`, `cupo_ocupado`, `fecha`, `organizador_id`, `creado_en`) VALUES
(1, 'Congreso de Tecnología 2026', 'Evento anual sobre innovaciones tecnológicas', 50, 4, '2026-08-15 09:00:00', 1, '2026-07-11 00:13:25'),
(2, 'Seminario de Marketing Digital', 'Estrategias avanzadas en marketing online', 30, 1, '2026-09-10 10:00:00', 1, '2026-07-11 00:13:25'),
(3, 'Taller de Desarrollo Ágil', 'Prácticas de Scrum y Kanban', 20, 2, '2026-07-13 14:15:00', 1, '2026-07-11 00:13:25'),
(4, 'Evento de Robótica', 'nose', 2, 0, '2026-07-13 14:10:00', 1, '2026-07-13 19:03:18');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `inscripciones`
--

CREATE TABLE `inscripciones` (
  `id` int(11) NOT NULL,
  `evento_id` int(11) NOT NULL,
  `usuario_id` int(11) NOT NULL,
  `fecha_inscripcion` timestamp NOT NULL DEFAULT current_timestamp(),
  `estado` enum('confirmada','cancelada') DEFAULT 'confirmada'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `inscripciones`
--

INSERT INTO `inscripciones` (`id`, `evento_id`, `usuario_id`, `fecha_inscripcion`, `estado`) VALUES
(1, 1, 2, '2026-07-11 00:13:25', 'confirmada'),
(2, 1, 3, '2026-07-11 00:13:25', 'confirmada'),
(3, 1, 4, '2026-07-11 00:13:25', 'confirmada'),
(4, 2, 2, '2026-07-11 00:13:25', 'confirmada'),
(5, 3, 5, '2026-07-11 00:13:25', 'confirmada'),
(6, 3, 6, '2026-07-13 19:08:19', 'confirmada'),
(7, 1, 6, '2026-07-13 19:08:31', 'confirmada');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id` int(11) NOT NULL,
  `codigo` varchar(12) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `rol` enum('organizador','participante') NOT NULL,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id`, `codigo`, `nombre`, `email`, `password_hash`, `rol`, `creado_en`) VALUES
(1, 'ORG-0001', 'Organizador Principal', 'org@eventos.com', '$2b$10$72m758eU7PONdfC/JEZv4.0c4HyFXGqUXHc2br2aAkudCGijiFyIS', 'organizador', '2026-07-11 00:13:24'),
(2, 'PAR-0002', 'Ana Pérez', 'ana@email.com', '$2b$10$tPRx/IHLTY625S975Hs.U.TJZFkNGI3TQSDIMy.wEC6IDe5kDA.lu', 'participante', '2026-07-11 00:13:24'),
(3, 'PAR-0003', 'Carlos Gómez', 'carlos@email.com', '$2b$10$WObXJxaA.XL5QDph428H8Op3.d2SvaA1lMwJgz.TgYG1WPJwdmW9O', 'participante', '2026-07-11 00:13:24'),
(4, 'PAR-0004', 'María López', 'maria@email.com', '$2b$10$BM8xV9.Oz1z7ZtUPxmJ1nepkFrapu6VSatJd8BAdOAbgwMaieriGC', 'participante', '2026-07-11 00:13:24'),
(5, 'PAR-0005', 'Luis Fernández', 'luis@email.com', '$2b$10$PyZT0n5vgg/nwb6KulpF2erQguo1r99U3ymZImyzCR9pmywaIbIKC', 'participante', '2026-07-11 00:13:24'),
(6, 'PAR-D8B72', 'arroz y carne', 'arroz@gmail.com', '$2y$10$MZiFpoQhafx2KUrmJdk46uXBKNmJfzDehvKBDMttZWY9ImMZYWLeq', 'participante', '2026-07-13 19:07:20');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `acreditaciones`
--
ALTER TABLE `acreditaciones`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `codigo_unico` (`codigo_unico`),
  ADD KEY `inscripcion_id` (`inscripcion_id`);

--
-- Indices de la tabla `asistencia`
--
ALTER TABLE `asistencia`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_asistencia_inscripcion` (`inscripcion_id`);

--
-- Indices de la tabla `conferencistas`
--
ALTER TABLE `conferencistas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `evento_id` (`evento_id`);

--
-- Indices de la tabla `eventos`
--
ALTER TABLE `eventos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `organizador_id` (`organizador_id`);

--
-- Indices de la tabla `inscripciones`
--
ALTER TABLE `inscripciones`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_inscripcion` (`evento_id`,`usuario_id`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `unique_codigo` (`codigo`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `acreditaciones`
--
ALTER TABLE `acreditaciones`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `asistencia`
--
ALTER TABLE `asistencia`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `conferencistas`
--
ALTER TABLE `conferencistas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `eventos`
--
ALTER TABLE `eventos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `inscripciones`
--
ALTER TABLE `inscripciones`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `acreditaciones`
--
ALTER TABLE `acreditaciones`
  ADD CONSTRAINT `acreditaciones_ibfk_1` FOREIGN KEY (`inscripcion_id`) REFERENCES `inscripciones` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `asistencia`
--
ALTER TABLE `asistencia`
  ADD CONSTRAINT `asistencia_ibfk_1` FOREIGN KEY (`inscripcion_id`) REFERENCES `inscripciones` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `conferencistas`
--
ALTER TABLE `conferencistas`
  ADD CONSTRAINT `conferencistas_ibfk_1` FOREIGN KEY (`evento_id`) REFERENCES `eventos` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `eventos`
--
ALTER TABLE `eventos`
  ADD CONSTRAINT `eventos_ibfk_1` FOREIGN KEY (`organizador_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `inscripciones`
--
ALTER TABLE `inscripciones`
  ADD CONSTRAINT `inscripciones_ibfk_1` FOREIGN KEY (`evento_id`) REFERENCES `eventos` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `inscripciones_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

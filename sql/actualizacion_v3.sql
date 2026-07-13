USE evento_db;

-- ========================================================
-- 1. Columna "codigo" en usuarios (solo si no existe todavía)
-- ========================================================
SET @columnaExiste = (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'codigo'
);

SET @sql = IF(@columnaExiste = 0,
  'ALTER TABLE usuarios ADD COLUMN codigo VARCHAR(12) NULL AFTER id',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE usuarios SET codigo = 'ORG-0001' WHERE id = 1 AND (codigo IS NULL OR codigo = '');
UPDATE usuarios SET codigo = 'PAR-0002' WHERE id = 2 AND (codigo IS NULL OR codigo = '');
UPDATE usuarios SET codigo = 'PAR-0003' WHERE id = 3 AND (codigo IS NULL OR codigo = '');
UPDATE usuarios SET codigo = 'PAR-0004' WHERE id = 4 AND (codigo IS NULL OR codigo = '');
UPDATE usuarios SET codigo = 'PAR-0005' WHERE id = 5 AND (codigo IS NULL OR codigo = '');

SET @sql = 'ALTER TABLE usuarios MODIFY codigo VARCHAR(12) NOT NULL';
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @llaveExiste = (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND INDEX_NAME = 'unique_codigo'
);

SET @sql = IF(@llaveExiste = 0,
  'ALTER TABLE usuarios ADD UNIQUE KEY unique_codigo (codigo)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ========================================================
-- 2. Procedimientos almacenados (versión final consolidada)
--    Acreditación 100% digital: url_descarga ya no se usa (queda NULL).
-- ========================================================
DELIMITER $$

DROP PROCEDURE IF EXISTS `sp_editar_evento`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_editar_evento` (IN p_id INT, IN p_nombre VARCHAR(150), IN p_descripcion TEXT, IN p_cupo_total INT, IN p_fecha DATETIME)
BEGIN
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

DROP PROCEDURE IF EXISTS `sp_eliminar_evento`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_evento` (IN p_id INT)
BEGIN
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

DROP PROCEDURE IF EXISTS `sp_listar_eventos`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_listar_eventos` ()
BEGIN
    SELECT id, nombre, descripcion, cupo_total, cupo_ocupado, fecha
    FROM eventos
    ORDER BY fecha ASC;
END$$

DROP PROCEDURE IF EXISTS `sp_editar_conferencista`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_editar_conferencista` (IN p_id INT, IN p_nombre VARCHAR(100), IN p_bio TEXT, IN p_email VARCHAR(100))
BEGIN
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

DROP PROCEDURE IF EXISTS `sp_eliminar_conferencista`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_eliminar_conferencista` (IN p_id INT)
BEGIN
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

DROP PROCEDURE IF EXISTS `sp_inscribir_participante`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_inscribir_participante` (IN `p_evento_id` INT, IN `p_participante_id` INT)
BEGIN
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

DROP PROCEDURE IF EXISTS `sp_cancelar_inscripcion`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cancelar_inscripcion` (IN p_inscripcion_id INT, IN p_usuario_id INT, IN p_es_organizador BOOLEAN)
BEGIN
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

DROP PROCEDURE IF EXISTS `sp_registrar_asistencia`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_asistencia` (IN `p_inscripcion_id` INT, IN `p_presente` BOOLEAN)
BEGIN
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

-- Acreditación 100% DIGITAL: sin generación ni almacenamiento de PDF.
-- url_descarga se conserva en la tabla por compatibilidad pero ya no se usa (queda NULL).
DROP PROCEDURE IF EXISTS `sp_generar_acreditacion`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_generar_acreditacion` (IN `p_inscripcion_id` INT, IN `p_codigo_unico` VARCHAR(50), IN `p_url` VARCHAR(255))
BEGIN
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

-- Incluye acreditacion_fecha_emision para poder mostrar la credencial digital
DROP PROCEDURE IF EXISTS `sp_listar_inscripciones_por_evento`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_listar_inscripciones_por_evento` (IN p_evento_id INT)
BEGIN
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

-- Incluye acreditacion_fecha_emision para poder mostrar la credencial digital
DROP PROCEDURE IF EXISTS `sp_listar_inscripciones_por_usuario`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_listar_inscripciones_por_usuario` (IN p_usuario_id INT)
BEGIN
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

DROP PROCEDURE IF EXISTS `sp_registrar_usuario`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_usuario` (IN p_nombre VARCHAR(100), IN p_email VARCHAR(100), IN p_password_hash VARCHAR(255), IN p_rol ENUM('organizador','participante'), IN p_codigo VARCHAR(12))
BEGIN
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

DROP PROCEDURE IF EXISTS `sp_login_usuario`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_login_usuario` (IN p_email VARCHAR(100))
BEGIN
    SELECT id, codigo, nombre, email, password_hash, rol
    FROM usuarios WHERE email = p_email;
END$$

DROP PROCEDURE IF EXISTS `sp_buscar_usuario_por_codigo`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_buscar_usuario_por_codigo` (IN p_codigo VARCHAR(12))
BEGIN
    SELECT id, codigo, nombre, email, rol FROM usuarios WHERE codigo = p_codigo;
END$$

DROP PROCEDURE IF EXISTS `sp_buscar_inscripcion`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_buscar_inscripcion` (IN p_evento_id INT, IN p_usuario_id INT)
BEGIN
    SELECT id AS inscripcion_id
    FROM inscripciones
    WHERE evento_id = p_evento_id AND usuario_id = p_usuario_id AND estado = 'confirmada'
    LIMIT 1;
END$$

DELIMITER ;
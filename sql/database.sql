-- ============================================================
-- Script de Base de Datos para Plataforma de Gestión de Eventos
-- Proyecto Final – Grupo 6
-- ============================================================

-- Eliminar la base de datos si ya existe (para desarrollo limpio)
DROP DATABASE IF EXISTS evento_db;
CREATE DATABASE evento_db;
USE evento_db;

-- ============================================================
-- TABLAS
-- ============================================================

-- Tabla de usuarios (organizadores y participantes)
CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    rol ENUM('organizador', 'participante') NOT NULL,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla de eventos
CREATE TABLE eventos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    cupo_total INT NOT NULL CHECK (cupo_total > 0),
    cupo_ocupado INT DEFAULT 0 CHECK (cupo_ocupado >= 0),
    fecha DATETIME NOT NULL,
    organizador_id INT NOT NULL,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organizador_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CHECK (cupo_ocupado <= cupo_total)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla de conferencistas (asociados a un evento)
CREATE TABLE conferencistas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    bio TEXT,
    email VARCHAR(100),
    evento_id INT NOT NULL,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (evento_id) REFERENCES eventos(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla de inscripciones (participante – evento)
CREATE TABLE inscripciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    evento_id INT NOT NULL,
    usuario_id INT NOT NULL,
    fecha_inscripcion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('confirmada', 'cancelada') DEFAULT 'confirmada',
    FOREIGN KEY (evento_id) REFERENCES eventos(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    UNIQUE KEY unique_inscripcion (evento_id, usuario_id)  -- Evita duplicados
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla de asistencia (control de presencia)
CREATE TABLE asistencia (
    id INT AUTO_INCREMENT PRIMARY KEY,
    inscripcion_id INT NOT NULL,
    fecha_asistencia DATETIME DEFAULT CURRENT_TIMESTAMP,
    presente BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (inscripcion_id) REFERENCES inscripciones(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla de acreditaciones digitales
CREATE TABLE acreditaciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    inscripcion_id INT NOT NULL,
    codigo_unico VARCHAR(50) UNIQUE NOT NULL,
    fecha_emision TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    url_descarga VARCHAR(255),
    FOREIGN KEY (inscripcion_id) REFERENCES inscripciones(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- PROCEDIMIENTOS ALMACENADOS
-- ============================================================

DELIMITER //

-- ------------------------------------------------------------
-- 1. sp_crear_evento: Crea un nuevo evento y devuelve sus datos
--    Entrada: p_nombre, p_descripcion, p_cupo_total, p_fecha, p_organizador_id
--    Salida: SELECT con los datos del evento creado
-- ------------------------------------------------------------
CREATE PROCEDURE sp_crear_evento (
    IN p_nombre VARCHAR(150),
    IN p_descripcion TEXT,
    IN p_cupo_total INT,
    IN p_fecha DATETIME,
    IN p_organizador_id INT
)
BEGIN
    INSERT INTO eventos (nombre, descripcion, cupo_total, fecha, organizador_id)
    VALUES (p_nombre, p_descripcion, p_cupo_total, p_fecha, p_organizador_id);
    
    SELECT id, nombre, descripcion, cupo_total, cupo_ocupado, fecha, organizador_id
    FROM eventos
    WHERE id = LAST_INSERT_ID();
END //

-- ------------------------------------------------------------
-- 2. sp_inscribir_participante: Inscribe a un participante en un evento
--    validando cupo disponible. Devuelve estado y mensaje.
--    Entrada: p_evento_id, p_participante_id
--    Salida: SELECT con status y mensaje
-- ------------------------------------------------------------
CREATE PROCEDURE sp_inscribir_participante (
    IN p_evento_id INT,
    IN p_participante_id INT
)
BEGIN
    DECLARE v_cupo_total INT;
    DECLARE v_cupo_ocupado INT;
    DECLARE v_ya_inscrito INT;
    
    -- Manejo de excepciones
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'error' AS status, 'Ocurrió un error en la inscripción' AS mensaje;
    END;
    
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
END //

-- ------------------------------------------------------------
-- 3. sp_obtener_ocupacion: Devuelve ocupación de un evento
--    Entrada: p_evento_id
--    Salida: evento_id, cupo_total, cupo_ocupado, porcentaje_ocupacion
-- ------------------------------------------------------------
CREATE PROCEDURE sp_obtener_ocupacion (
    IN p_evento_id INT
)
BEGIN
    SELECT 
        id AS evento_id,
        cupo_total,
        cupo_ocupado,
        ROUND((cupo_ocupado / cupo_total) * 100, 2) AS porcentaje_ocupacion
    FROM eventos
    WHERE id = p_evento_id;
END //

-- ------------------------------------------------------------
-- 4. sp_listar_eventos: Lista todos los eventos con cupos
--    Salida: id, nombre, cupo_total, cupo_ocupado
-- ------------------------------------------------------------
CREATE PROCEDURE sp_listar_eventos()
BEGIN
    SELECT 
        id,
        nombre,
        cupo_total,
        cupo_ocupado
    FROM eventos
    ORDER BY fecha ASC;
END //

-- ------------------------------------------------------------
-- (Opcional) sp_registrar_asistencia: Marca asistencia a un participante
--    Entrada: p_inscripcion_id, p_presente
--    Salida: estado de operación
-- ------------------------------------------------------------
CREATE PROCEDURE sp_registrar_asistencia (
    IN p_inscripcion_id INT,
    IN p_presente BOOLEAN
)
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
END //

-- ------------------------------------------------------------
-- (Opcional) sp_generar_acreditacion: Genera acreditación para un inscrito
--    Entrada: p_inscripcion_id, p_codigo_unico, p_url
--    Salida: datos de la acreditación
-- ------------------------------------------------------------
CREATE PROCEDURE sp_generar_acreditacion (
    IN p_inscripcion_id INT,
    IN p_codigo_unico VARCHAR(50),
    IN p_url VARCHAR(255)
)
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
    SELECT 
        id,
        inscripcion_id,
        codigo_unico,
        fecha_emision,
        url_descarga
    FROM acreditaciones
    WHERE id = LAST_INSERT_ID();
END //

DELIMITER ;

-- ============================================================
-- DATOS DE PRUEBA
-- ============================================================

-- Insertar usuarios
INSERT INTO usuarios (nombre, email, password_hash, rol) VALUES
('Organizador Principal', 'org@eventos.com', SHA2('admin123', 256), 'organizador'),
('Ana Pérez', 'ana@email.com', SHA2('ana123', 256), 'participante'),
('Carlos Gómez', 'carlos@email.com', SHA2('carlos123', 256), 'participante'),
('María López', 'maria@email.com', SHA2('maria123', 256), 'participante'),
('Luis Fernández', 'luis@email.com', SHA2('luis123', 256), 'participante');

-- Insertar eventos (el organizador_id = 1)
INSERT INTO eventos (nombre, descripcion, cupo_total, cupo_ocupado, fecha, organizador_id) VALUES
('Congreso de Tecnología 2026', 'Evento anual sobre innovaciones tecnológicas', 50, 0, '2026-08-15 09:00:00', 1),
('Seminario de Marketing Digital', 'Estrategias avanzadas en marketing online', 30, 0, '2026-09-10 10:00:00', 1),
('Taller de Desarrollo Ágil', 'Prácticas de Scrum y Kanban', 20, 0, '2026-07-20 14:00:00', 1);

-- Insertar conferencistas
INSERT INTO conferencistas (nombre, bio, email, evento_id) VALUES
('Dra. Elena Ruiz', 'Experta en IA y Machine Learning', 'elena.ruiz@tech.com', 1),
('Ing. Javier Mora', 'Consultor en transformación digital', 'javier.mora@digital.com', 1),
('Lic. Sofía Torres', 'Especialista en SEO y SEM', 'sofia.torres@marketing.com', 2),
('Dr. Andrés Castro', 'Coach ágil certificado', 'andres.castro@agile.com', 3);

-- Insertar algunas inscripciones de prueba (participantes 2,3,4 en evento 1)
INSERT INTO inscripciones (evento_id, usuario_id, estado) VALUES
(1, 2, 'confirmada'),
(1, 3, 'confirmada'),
(1, 4, 'confirmada'),
(2, 2, 'confirmada'),
(3, 5, 'confirmada');

-- Actualizar cupo_ocupado manualmente para reflejar las inscripciones existentes
UPDATE eventos SET cupo_ocupado = (SELECT COUNT(*) FROM inscripciones WHERE evento_id = eventos.id AND estado = 'confirmada')
WHERE id IN (SELECT DISTINCT evento_id FROM inscripciones);

-- Insertar asistencias de ejemplo
INSERT INTO asistencia (inscripcion_id, presente) VALUES
(1, TRUE),
(2, FALSE),
(3, TRUE);

-- Insertar acreditaciones de ejemplo
INSERT INTO acreditaciones (inscripcion_id, codigo_unico, url_descarga) VALUES
(1, 'ACR-001-ABC', '/acreditaciones/ACR-001-ABC.pdf'),
(3, 'ACR-003-DEF', '/acreditaciones/ACR-003-DEF.pdf');

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================
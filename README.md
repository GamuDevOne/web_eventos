# Proyecto Final – Grupo 6
**Plataforma de Gestión de Eventos y Acreditaciones**

Tiempo total: 6 días
Integrantes: 5
**Entrega límite: 13 de julio 2026, 1:00 pm**

---

## 🎯 Objetivo

Desarrollar una plataforma web para administrar congresos, seminarios y talleres: registrar participantes, gestionar eventos, controlar asistencia y emitir acreditaciones digitales.

## 📋 Funcionalidades

- Registro/login con roles (Organizador y Participante).
- CRUD de eventos.
- CRUD de conferencistas.
- Registro de participantes.
- Inscripción a eventos.
- Control de asistencia.
- Generación de acreditaciones digitales.
- API REST propia.
- Intercambio de datos exclusivamente en JSON.

## 🧩 Reto: Control Inteligente de Aforo

- Cada evento tiene capacidad máxima.
- La API valida cupo disponible antes de inscribir.
- Impide inscripción si el evento está lleno.
- Actualiza automáticamente cupos disponibles.
- Muestra % de ocupación en tiempo real (Chart.js).

---

## 📂 Estructura del Proyecto (MVC)

```
/proyecto-eventos/
│── /app/
│   ├── /controllers/       # Lógica de controladores
│   ├── /models/            # Clases y conexión BD
│   ├── /views/             # Interfaces (HTML, CSS, JS)
│   └── index.php           # Punto de entrada
│
│── /config/                # Configuración (PDO, sesiones)
│── /public/                # Archivos públicos (CSS, JS, imágenes)
│── /docs/                  # Documentación técnica (PDF) y capturas
│── /sql/                   # Scripts de BD y procedimientos almacenados
│── README.md                # Guía del proyecto
```

---

## 👥 División de Tareas por Integrante

### Integrante 1 – Base de Datos
- Diseñar el **DER** (usuarios, roles, eventos, conferencistas, participantes, inscripciones, asistencia, acreditaciones).
- Crear **procedimientos almacenados**:
  - Validar cupos.
  - Registrar inscripciones.
  - Consultar ocupación.
- Insertar datos de prueba.
- Subir script inicial a `/sql/`.

### Integrante 2 – Backend/API REST
- Implementar endpoints principales:
  - `POST /api/eventos/crear`
  - `POST /api/eventos/inscribir`
  - `GET /api/eventos/ocupacion`
  - `GET /api/eventos/listar`
  - Endpoints de asistencia y generación de acreditaciones.
- Conectar con PDO y procedimientos almacenados.
- Respuestas exclusivamente en JSON.
- Probar en **Postman**.

### Integrante 3 – Frontend
- Formularios de login y registro.
- CRUD de eventos y conferencistas.
- Inscripción de participantes.
- Módulo de control de asistencia.
- Módulo de generación/visualización de acreditaciones.
- Dashboard con **Chart.js** mostrando ocupación en tiempo real.

### Integrante 4 – Seguridad y Validaciones
- Hash de contraseñas.
- Manejo de sesiones y cookies.
- Validación de formularios (evitar SQL injection).
- Control de acceso por roles (Organizador vs Participante).
- Manejo de excepciones.

### Integrante 5 – Documentación
- Documento técnico en PDF con:
  - Introducción.
  - Objetivo del proyecto.
  - Diagrama Entidad-Relación (DER).
  - Capturas de pantalla del sistema funcionando.
  - Explicación de estructura de carpetas, arquitectura MVC y API REST.
  - Capturas y explicación de código clave (controladores, endpoints, procedimientos almacenados, acceso PDO).
- Preparar guía de sustentación (ver sección Dinámica de Sustentación).

---

## 🛠️ Herramientas a Instalar/Usar

Además de **Visual Studio Code**, cada integrante debe instalar:
- **XAMPP** (PHP + MySQL + Apache).
- **Postman** (para probar API REST).
- **GitHub Desktop** o Git CLI (para sincronizar repositorio).
- **Chart.js** (para gráficos en el dashboard).
- **Composer** (si se usan librerías externas).
- **GitLens** (extensión VS Code para control de versiones).
- **MySQL Workbench** (opcional, para diseño de BD).

---

## 📅 Cronograma de Trabajo

- **Día 1**: Organización, roles, repositorio y DER.
- **Día 2**: Base de datos y procedimientos.
- **Día 3**: Backend/API REST.
- **Día 4**: Frontend.
- **Día 5**: Seguridad y validaciones.
- **Día 6**: Integración, pruebas y documentación final.

---

## 🎤 Dinámica de Sustentación

1. **Demostración del flujo de inscripción**: un integrante (Organizador) crea evento y habilita cupos; otro (Participante) se inscribe y verifica el registro.
2. **Prueba del reto**: demostrar validación de cupos y bloqueo al llegar al máximo, con actualización automática del % de ocupación.
3. **Defensa técnica en Postman**: consumo de endpoints (inscripción, ocupación), explicación del controlador, procedimiento almacenado de validación y acceso vía PDO.

- Exposición: 2 integrantes.
- Defensa técnica: 3 integrantes.

---

## ✅ Entregables Finales

- Código fuente completo en GitHub, organizado en MVC.
- Script SQL con BD, restricciones, procedimientos almacenados e inserciones de prueba.
- Documentación técnica en PDF (ver contenido en sección Integrante 5).
- Exposición y defensa técnica con pruebas en Postman y dashboard funcionando.

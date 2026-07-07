# Proyecto Final – Grupo 6
**Plataforma de Gestión de Eventos y Acreditaciones**

Tiempo total: 6 días
Integrantes: 5

---

## 📂 Estructura del Proyecto (MVC)

```
/proyecto-eventos/
│── /app/                  # Código fuente
│   ├── /controllers/      # Lógica de controladores
│   ├── /models/           # Clases y conexión BD
│   ├── /views/            # Interfaces (HTML, CSS, JS)
│   └── index.php          # Punto de entrada
│
│── /config/               # Configuración (PDO, sesiones)
│── /public/                # Archivos públicos (CSS, JS, imágenes)
│── /docs/                 # Documentación y capturas
│── /sql/                  # Scripts de BD y procedimientos
│── README.md               # Guía del proyecto
```

---

## 👥 División de Tareas por Integrante

### Integrante 1 – Base de Datos
- Diseñar el **DER** (usuarios, roles, eventos, conferencistas, participantes, inscripciones, asistencia).
- Crear **procedimientos almacenados**:
  - Validar cupos.
  - Registrar inscripciones.
  - Consultar ocupación.
- Subir script inicial a `/sql/`.

### Integrante 2 – Backend/API REST
- Implementar endpoints principales:
  - `POST /api/eventos/crear`
  - `POST /api/eventos/inscribir`
  - `GET /api/eventos/ocupacion`
  - `GET /api/eventos/listar`
- Conectar con PDO y procedimientos almacenados.
- Probar en **Postman**.

### Integrante 3 – Frontend
- Formularios de login y registro.
- CRUD de eventos y conferencistas.
- Inscripción de participantes.
- Dashboard con **Chart.js** mostrando ocupación en tiempo real.

### Integrante 4 – Seguridad y Validaciones
- Hash de contraseñas.
- Manejo de sesiones y cookies.
- Validación de formularios (evitar SQL injection).
- Roles: Organizador vs Participante.

### Integrante 5 – Documentación
- Redactar documentación técnica en PDF.
- Capturas de pantalla de cada módulo.
- Explicación de arquitectura MVC.
- Preparar guía de sustentación.

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

## ✅ Entregables Finales

- Proyecto completo en GitHub.
- Script SQL con BD y procedimientos.
- Documentación PDF con capturas y explicación.
- Sustentación con pruebas en Postman y dashboard funcionando.

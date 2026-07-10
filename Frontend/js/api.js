/* =========================================================================
   api.js
   Pertenece a: Integrante 3 - Frontend
   Proyecto: Plataforma de Gestión de Eventos y Acreditaciones (Grupo 6)

   Capa de acceso a la API REST del backend (app/index.php).
   Todas las páginas del Frontend importan este archivo con:
     <script src="api.js"></script>

   NOTA IMPORTANTE PARA EL EQUIPO:
   - Los endpoints de "eventos" (crear / inscribir / ocupacion / listar /
     asistencia / acreditacion) ya existen en EventoController.php
     (Integrante 2), por lo que quedan conectados de una vez.
   - Los endpoints de "usuarios" (login/registro) y "conferencistas"
     (crear/listar) TODAVÍA NO EXISTEN en el backend. Se dejan aquí ya
     escritos y marcados con "// TODO backend" para que apenas
     Integrante 2 / Integrante 4 los implementen, el Frontend funcione
     sin tener que tocar este archivo.
   ========================================================================= */

/* Ajustar esta ruta si el proyecto se sirve desde otra carpeta de XAMPP.
   Con la carpeta htdocs/web_eventos, el punto de entrada real es
   app/index.php, y el router busca el segmento "eventos" dentro de la URL,
   así que basta con mantener esa palabra en cada ruta. */
const API_BASE = "/web_eventos/app/index.php";

/**
 * Helper genérico de fetch con manejo de errores homogéneo.
 */
async function apiRequest(path, { method = "GET", body = null } = {}) {
  const opciones = {
    method,
    headers: { "Content-Type": "application/json" },
    credentials: "include", // envía la cookie de sesión (PHP session)
  };
  if (body !== null) opciones.body = JSON.stringify(body);

  let respuesta;
  try {
    respuesta = await fetch(`${API_BASE}${path}`, opciones);
  } catch (err) {
    throw new Error("No se pudo contactar al servidor. Verifica que XAMPP esté activo.");
  }

  let datos = null;
  try {
    datos = await respuesta.json();
  } catch (err) {
    /* respuesta vacía o no-JSON */
  }

  if (!respuesta.ok) {
    const mensaje = (datos && (datos.mensaje || datos.error)) || `Error ${respuesta.status}`;
    throw new Error(mensaje);
  }
  return datos;
}

/* -------------------------------------------------------------------------
   Eventos (conectado a EventoController.php)
   ------------------------------------------------------------------------- */
const EventosAPI = {
  crear(payload) {
    // payload: { nombre, descripcion, cupo_total, fecha }
    return apiRequest("/eventos/crear", { method: "POST", body: payload });
  },
  listar() {
    return apiRequest("/eventos/listar", { method: "GET" });
  },
  ocupacion(evento_id) {
    return apiRequest(`/eventos/ocupacion?evento_id=${encodeURIComponent(evento_id)}`, { method: "GET" });
  },
  inscribir(evento_id, participante_id) {
    return apiRequest("/eventos/inscribir", {
      method: "POST",
      body: { evento_id, participante_id },
    });
  },
  registrarAsistencia(inscripcion_id, presente) {
    return apiRequest("/eventos/asistencia", {
      method: "POST",
      body: { inscripcion_id, presente },
    });
  },
  generarAcreditacion(inscripcion_id, codigo_unico, url) {
    return apiRequest("/eventos/acreditacion", {
      method: "POST",
      body: { inscripcion_id, codigo_unico, url },
    });
  },
};

/* -------------------------------------------------------------------------
   Usuarios (login / registro)
   TODO backend: crear UsuarioController.php con acciones "login" y
   "registro", y agregar sus rutas en app/index.php (Integrante 2/4).
   ------------------------------------------------------------------------- */
const UsuariosAPI = {
  login(email, password) {
    // TODO backend: POST /usuarios/login
    return apiRequest("/usuarios/login", { method: "POST", body: { email, password } });
  },
  registrar({ nombre, email, password, rol }) {
    // TODO backend: POST /usuarios/registro
    return apiRequest("/usuarios/registro", {
      method: "POST",
      body: { nombre, email, password, rol },
    });
  },
};

/* -------------------------------------------------------------------------
   Conferencistas
   TODO backend: crear ConferencistaController.php con acciones "crear",
   "listar" (por evento_id) y opcionalmente "eliminar" (Integrante 2).
   La tabla `conferencistas` ya existe en sql/database.sql.
   ------------------------------------------------------------------------- */
const ConferencistasAPI = {
  crear({ nombre, bio, email, evento_id }) {
    // TODO backend: POST /conferencistas/crear
    return apiRequest("/conferencistas/crear", {
      method: "POST",
      body: { nombre, bio, email, evento_id },
    });
  },
  listarPorEvento(evento_id) {
    // TODO backend: GET /conferencistas/listar?evento_id=
    return apiRequest(`/conferencistas/listar?evento_id=${encodeURIComponent(evento_id)}`, {
      method: "GET",
    });
  },
};

/* -------------------------------------------------------------------------
   Utilidades de interfaz compartidas (sesión simulada + toast + navbar)
   ------------------------------------------------------------------------- */
const Sesion = {
  guardar(usuario) {
    localStorage.setItem("usuario_actual", JSON.stringify(usuario));
  },
  obtener() {
    try {
      return JSON.parse(localStorage.getItem("usuario_actual"));
    } catch (e) {
      return null;
    }
  },
  cerrar() {
    localStorage.removeItem("usuario_actual");
    window.location.href = "login.html";
  },
  requerir() {
    const usuario = Sesion.obtener();
    if (!usuario) {
      window.location.href = "login.html";
      return null;
    }
    return usuario;
  },
  // Usar en páginas exclusivas de organizador (eventos, conferencistas,
  // inscripcion, dashboard). Si un participante entra, lo manda a su vista.
  requerirOrganizador() {
    const usuario = Sesion.requerir();
    if (!usuario) return null;
    if (usuario.rol !== "organizador") {
      window.location.href = "participante.html";
      return null;
    }
    return usuario;
  },
  // Usar en páginas exclusivas de participante.
  requerirParticipante() {
    const usuario = Sesion.requerir();
    if (!usuario) return null;
    if (usuario.rol !== "participante") {
      window.location.href = "dashboard.html";
      return null;
    }
    return usuario;
  },
};
function mostrarToast(mensaje, tipo = "success") {
  let toast = document.getElementById("toastGlobal");
  if (!toast) {
    toast = document.createElement("div");
    toast.id = "toastGlobal";
    toast.className = "toast";
    document.body.appendChild(toast);
  }
  toast.textContent = mensaje;
  toast.className = `toast visible ${tipo}`;
  clearTimeout(toast._timer);
  toast._timer = setTimeout(() => toast.classList.remove("visible"), 3200);
}

/**
 * Pinta el nombre del usuario logueado en el navbar, si el elemento existe
 * en la página (id="nombreUsuario").
 */
function pintarUsuarioNavbar() {
  const usuario = Sesion.obtener();
  const el = document.getElementById("nombreUsuario");
  if (el && usuario) el.textContent = usuario.nombre || usuario.email;
}
const API_BASE = "/web_eventos/app/index.php";

async function apiRequest(path, { method = "GET", body = null } = {}) {
  const opciones = {
    method,
    headers: { "Content-Type": "application/json" },
    credentials: "include",
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
  } catch (err) {}

  if (!respuesta.ok) {
    const mensaje = (datos && (datos.mensaje || datos.error)) || `Error ${respuesta.status}`;
    throw new Error(mensaje);
  }
  return datos;
}

const EventosAPI = {
  crear(payload) {
    return apiRequest("/eventos/crear", { method: "POST", body: payload });
  },
  editar(payload) {
    return apiRequest("/eventos/editar", { method: "POST", body: payload });
  },
  eliminar(id) {
    return apiRequest("/eventos/eliminar", { method: "POST", body: { id } });
  },
  listar() {
    return apiRequest("/eventos/listar", { method: "GET" });
  },
  listarInscripciones(evento_id) {
    return apiRequest(`/eventos/inscripciones?evento_id=${encodeURIComponent(evento_id)}`, { method: "GET" });
  },
  misInscripciones() {
    return apiRequest("/eventos/misinscripciones", { method: "GET" });
  },
  ocupacion(evento_id) {
    return apiRequest(`/eventos/ocupacion?evento_id=${encodeURIComponent(evento_id)}`, { method: "GET" });
  },
  inscribir(evento_id, participanteIdOCodigo) {
    const esNumerico = /^\d+$/.test(String(participanteIdOCodigo).trim());
    const body = esNumerico
      ? { evento_id, participante_id: participanteIdOCodigo }
      : { evento_id, codigo: String(participanteIdOCodigo).trim() };
    return apiRequest("/eventos/inscribir", { method: "POST", body });
  },
  cancelarInscripcion(inscripcion_id) {
    return apiRequest("/eventos/cancelar", { method: "POST", body: { inscripcion_id } });
  },
  registrarAsistencia(evento_id, participanteIdOCodigo, presente) {
    const esNumerico = /^\d+$/.test(String(participanteIdOCodigo).trim());
    const body = esNumerico
      ? { evento_id, participante_id: participanteIdOCodigo, presente }
      : { evento_id, codigo: String(participanteIdOCodigo).trim(), presente };
    return apiRequest("/eventos/asistencia", { method: "POST", body });
  },
  // Ahora recibe un objeto: { inscripcion_id, codigo_unico } (modo directo, desde la lista)
  // o { evento_id, participanteIdOCodigo, codigo_unico } (modo manual). Ya no se envía url.
generarAcreditacion({ inscripcion_id, evento_id, participante_id, codigo, codigo_unico } = {}) {
    const body = { codigo_unico: codigo_unico || "" };
    if (inscripcion_id) {
      body.inscripcion_id = inscripcion_id;
    } else {
      body.evento_id = evento_id;
      if (codigo) {
        body.codigo = codigo;
      } else {
        body.participante_id = participante_id;
      }
    }
    return apiRequest("/eventos/acreditacion", { method: "POST", body });
  },
};

const UsuariosAPI = {
  login(email, password) {
    return apiRequest("/usuarios/login", { method: "POST", body: { email, password } });
  },
  registrar({ nombre, email, password, rol }) {
    return apiRequest("/usuarios/registro", { method: "POST", body: { nombre, email, password, rol } });
  },
};

const ConferencistasAPI = {
  crear({ nombre, bio, email, evento_id }) {
    return apiRequest("/conferencistas/crear", { method: "POST", body: { nombre, bio, email, evento_id } });
  },
  editar({ id, nombre, bio, email }) {
    return apiRequest("/conferencistas/editar", { method: "POST", body: { id, nombre, bio, email } });
  },
  eliminar(id) {
    return apiRequest("/conferencistas/eliminar", { method: "POST", body: { id } });
  },
  listarPorEvento(evento_id) {
    return apiRequest(`/conferencistas/listar?evento_id=${encodeURIComponent(evento_id)}`, { method: "GET" });
  },
};

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
  requerirOrganizador() {
    const usuario = Sesion.requerir();
    if (!usuario) return null;
    if (usuario.rol !== "organizador") {
      window.location.href = "participante.html";
      return null;
    }
    return usuario;
  },
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

function pintarUsuarioNavbar() {
  const usuario = Sesion.obtener();
  const el = document.getElementById("nombreUsuario");
  if (el && usuario) {
    el.textContent = usuario.nombre || usuario.email;
    if (usuario.codigo) el.title = `Código: ${usuario.codigo}`;
  }
}

function confirmarAccion(mensaje, textoBoton = "Sí, continuar") {
  return new Promise((resolve) => {
    let overlay = document.getElementById("overlayConfirmar");
    if (!overlay) {
      overlay = document.createElement("div");
      overlay.id = "overlayConfirmar";
      overlay.className = "modal-overlay";
      overlay.innerHTML = `
        <div class="modal" style="max-width:380px;">
          <div class="modal-header">
            <div><div class="eyebrow">Confirmar</div><h3 class="mb-0">¿Estás seguro?</h3></div>
          </div>
          <div class="modal-body">
            <p id="confirmarMensaje" style="margin-bottom:20px;"></p>
            <div style="display:flex; gap:10px; justify-content:flex-end;">
              <button class="btn btn-outline" id="confirmarCancelar">Cancelar</button>
              <button class="btn" id="confirmarAceptar" style="background:var(--color-danger); color:#fff;"></button>
            </div>
          </div>
        </div>`;
      document.body.appendChild(overlay);
    }
    overlay.querySelector("#confirmarMensaje").textContent = mensaje;
    const btnAceptar = overlay.querySelector("#confirmarAceptar");
    const btnCancelar = overlay.querySelector("#confirmarCancelar");
    btnAceptar.textContent = textoBoton;
    overlay.classList.add("abierto");

    const limpiar = (resultado) => {
      overlay.classList.remove("abierto");
      btnAceptar.removeEventListener("click", onAceptar);
      btnCancelar.removeEventListener("click", onCancelar);
      resolve(resultado);
    };
    const onAceptar = () => limpiar(true);
    const onCancelar = () => limpiar(false);
    btnAceptar.addEventListener("click", onAceptar);
    btnCancelar.addEventListener("click", onCancelar);
  });
}

/**
 * Muestra en un modal la credencial visual de una acreditación digital.
 * Reutilizable desde cualquier página que incluya api.js.
 */
function mostrarAcreditacionDigital({ participanteNombre, participanteCodigo, eventoNombre, eventoFecha, codigoUnico, fechaEmision }) {
  let overlay = document.getElementById("overlayAcreditacionDigital");
  if (!overlay) {
    overlay = document.createElement("div");
    overlay.id = "overlayAcreditacionDigital";
    overlay.className = "modal-overlay";
    overlay.innerHTML = `
      <div class="modal">
        <div class="modal-header">
          <div><div class="eyebrow">Acreditación</div><h3 class="mb-0">Credencial digital</h3></div>
          <button class="modal-close" id="cerrarAcreditacionDigital">&times;</button>
        </div>
        <div class="modal-body">
          <div class="acreditacion-visual" id="acreditacionVisualContenido"></div>
        </div>
      </div>`;
    document.body.appendChild(overlay);
    overlay.querySelector("#cerrarAcreditacionDigital").addEventListener("click", () => overlay.classList.remove("abierto"));
    overlay.addEventListener("click", (e) => { if (e.target === overlay) overlay.classList.remove("abierto"); });
  }

  const fechaEventoTexto = eventoFecha
    ? new Date(eventoFecha.replace(" ", "T")).toLocaleString("es-ES", { dateStyle: "long", timeStyle: "short" })
    : "—";
  const fechaEmisionTexto = fechaEmision
    ? new Date(fechaEmision.replace(" ", "T")).toLocaleString("es-ES", { dateStyle: "medium", timeStyle: "short" })
    : "—";

  const contenido = overlay.querySelector("#acreditacionVisualContenido");
  contenido.innerHTML = `
    <div class="acreditacion-sello">✓ Acreditación verificada</div>
    <div class="acreditacion-titulo">Certifica la participación de</div>
    <div class="acreditacion-nombre">${escaparHTMLGlobal(participanteNombre)}</div>
    <div class="acreditacion-codigo-participante">Código de participante: ${escaparHTMLGlobal(participanteCodigo || "—")}</div>
    <div class="acreditacion-evento">${escaparHTMLGlobal(eventoNombre)}</div>
    <div class="acreditacion-fecha-evento">Realizado el ${fechaEventoTexto}</div>
    <hr class="acreditacion-divisor">
    <div class="acreditacion-codigo-unico">${escaparHTMLGlobal(codigoUnico)}</div>
    <div class="acreditacion-emision">Emitida el ${fechaEmisionTexto}</div>
  `;

  overlay.classList.add("abierto");
}

function escaparHTMLGlobal(texto) {
  const div = document.createElement("div");
  div.textContent = texto ?? "";
  return div.innerHTML;
}
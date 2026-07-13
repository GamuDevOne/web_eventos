# Pasos pendientes – Integrantes 3 y 4

Backend actualizado (Integrante 2) con: login/registro de usuarios, CRUD de conferencistas, router generalizado, y seed de contraseñas migrado a bcrypt.

---

## Integrante 4 – Seguridad y sesiones

1. **Revisar `app/controllers/UsuarioController.php`**
   - Ya usa `password_hash()` (bcrypt) en `registro()` y `password_verify()` en `login()`.
   - Ya setea `$_SESSION['usuario_id']` y `$_SESSION['rol']` en login.
   - Confirmar que esto cumple con el estándar de seguridad del proyecto (manejo de sesiones, expiración, etc.).

2. **Validación de formularios / anti SQL injection**
   - Los controladores usan PDO con `bindParam`, lo cual ya previene SQL injection.
   - Falta: validar formato de email, longitud mínima de contraseña, y sanitizar `rol` (que solo acepte `organizador` o `participante`) en el backend, no solo en el HTML.

3. **Control de acceso por roles**
   - `EventoController::crear()` ya exige sesión activa (`$_SESSION['usuario_id']`).
   - Falta: restringir que solo usuarios con `rol = organizador` puedan crear eventos/conferencistas, y que participantes no accedan a esos endpoints (actualmente cualquier usuario logueado puede crear eventos).

4. **Manejo de excepciones**
   - Revisar que todos los controladores devuelvan códigos HTTP y mensajes JSON consistentes (ya implementado en Evento, Usuario y Conferencista Controllers) — validar que cumpla el criterio del proyecto.

---

## Integrante 3 – Frontend

1. **Conectar `login.html` al backend real**
   - Actualmente usa `validarLocal()` con un arreglo hardcoded de usuarios de prueba.
   - Reemplazar ese bloque por la llamada real, ya dejada comentada al final del archivo:
     ```js
     const resultado = await UsuariosAPI.login(email, password);
     if (resultado && resultado.status === "ok") {
       Sesion.guardar(resultado.usuario);
       window.location.href = resultado.usuario.rol === "organizador" ? "dashboard.html" : "participante.html";
     } else {
       throw new Error((resultado && resultado.mensaje) || "Credenciales inválidas");
     }
     ```
   - Eliminar el arreglo `USUARIOS_DEMO` y la función `validarLocal()`.

2. **Registro (`registro.html`)**
   - Ya está conectado a `UsuariosAPI.registrar()` — solo falta probar que funcione contra el backend real.

3. **Conferencistas (`conferencistas.html`)**
   - Ya está conectado a `ConferencistasAPI.crear()` y `ConferencistasAPI.listarPorEvento()` — el backend ya existe, solo falta probar el flujo completo en la web.

4. **`Frontend/index.html`**
   - Está vacío. Definir si es la landing/portada del sitio o si debe eliminarse. Si se mantiene, debería redirigir a `login.html` o mostrar una portada simple.

---

## Notas generales

- Los usuarios de prueba del seed (`org@eventos.com`, `ana@email.com`, etc.) ya tienen sus contraseñas migradas a bcrypt — las contraseñas originales (`admin123`, `ana123`, etc.) siguen funcionando.
- El workaround de `$_SESSION` simulado para probar `crear()` de eventos ya no es necesario: usar `/usuarios/login` real genera la sesión.

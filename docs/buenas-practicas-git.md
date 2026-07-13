# Checklist de Buenas Prácticas Git – Equipo

## 1. Antes de empezar a trabajar
- `git pull origin main` (o tu rama base)
- **Qué es:** trae los últimos cambios del repositorio remoto.
- **Por qué:** evita trabajar sobre código desactualizado y reduce conflictos.

## 2. Crear una rama para cada tarea
- `git checkout -b feature/nombre-tarea`
- **Qué es:** crea una rama nueva a partir de la actual.
- **Por qué:** aísla tu trabajo, no afecta el código de otros hasta que esté listo.
- Convención de nombres:
  - `feature/...` → nueva funcionalidad
  - `fix/...` → corrección de bug
  - `docs/...` → documentación

## 3. Commits pequeños y frecuentes
- `git add archivo` (evitar `git add .` si no revisaste todo)
- `git commit -m "tipo: descripción breve"`
- **Qué es:** guarda un punto de avance en el historial.
- **Por qué:** facilita revertir errores y entender qué cambió y cuándo.
- Ejemplo de mensajes:
  - `feat: agrega endpoint de inscripción`
  - `fix: corrige validación de cupos`
  - `docs: actualiza README`

## 4. Antes de subir cambios
- `git pull origin main` (o rebase si el equipo lo usa)
- **Por qué:** trae cambios nuevos antes de subir los tuyos, evita conflictos grandes.

## 5. Subir cambios
- `git push origin feature/nombre-tarea`
- **Qué es:** sube tu rama al repositorio remoto.
- **Por qué:** hace visible tu trabajo al resto del equipo.

## 6. Pull Request / Merge
- Crear un **Pull Request** hacia `main` (no hacer push directo a `main`).
- **Por qué:** permite revisión de código antes de integrar, evita romper el proyecto.
- Esperar al menos 1 revisión antes de mergear (si el equipo lo acuerda).

## 7. Resolver conflictos
- Si aparece conflicto: revisar el archivo, elegir el código correcto, eliminar marcas `<<<<<<<`, `=======`, `>>>>>>>`.
- Hacer `git add` + `git commit` para cerrar el conflicto.
- **Por qué:** un conflicto mal resuelto puede borrar trabajo de otro integrante.

## 8. Flujo simple para empezar (sin ramas todavía)

Si aún no usas ramas, mínimo sigue esto:

```
git status
git add archivo1 archivo2   # evita "git add ."
git commit -m "mensaje claro"
git pull origin main
git push origin main
```

**Por qué:** `git add .` puede subir archivos no deseados. Hacer `pull` antes del `push` evita conflictos.

Cuando estés listo para ramas, el único cambio es trabajar en una rama propia en vez de `main`:

```
git checkout -b feature/mi-tarea
# ... tus commits normales ...
git push origin feature/mi-tarea
```

Luego se crea un Pull Request en GitHub hacia `main`.

## 9. Reglas generales
- Nunca trabajar directo sobre `main`.
- Hacer `pull` **antes** de empezar y **antes** de subir.
- Un commit = un cambio lógico (no mezclar features distintas).
- Mensajes de commit claros y en presente ("agrega", no "agregado").
- Revisar `git status` antes de cada commit.

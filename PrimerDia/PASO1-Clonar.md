# Manual Rápido: Configuración Local del Repositorio `GDI-PRODUCTO`

## Objetivo

Dejar una carpeta local sincronizada con el repositorio remoto **`GestionDocumentalInteligente/Producto`** y crear el comando `gdi` para actualizar con un solo paso.

---

## 1. Crear la Carpeta Locales

1. Ir al Escritorio (o donde prefieras).
2. Crear carpeta con nombre exacto: **`Carpeta Locales`**
   Ruta ejemplo: `C:\Users\TUUSUARIO\Desktop\Carpeta Locales`
3. Asegurarse de que esté vacía (si tenía cosas viejas, moverlas afuera).

> *No usar otros nombres ni caracteres especiales (evitá, por ejemplo, 'LocalesGDI').*

---

## 2. Ejecutar el Código Inicial en PowerShell

### Abrir PowerShell

* Win → escribir **PowerShell** → Enter.

### Pegar este bloque (reemplazando `TUUSUARIO` por el usuario real de Windows) y presionar **Enter**:

```powershell
cd "C:\Users\TUUSUARIO\Desktop\Carpeta Locales"

# Si hubiera un repo previo, lo borramos para empezar limpio
if (Test-Path .git) { Remove-Item -Recurse -Force .git }

# Iniciar repo y vincular al remoto
git init
git remote add origin https://github.com/GestionDocumentalInteligente/Producto.git

# Traer historial/archivos desde main
git fetch origin
git checkout -b main origin/main

# Crear/abrir perfil de PowerShell y agregar función gdi
if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }

Add-Content $PROFILE @'
function gdi {
    Set-Location "C:\Users\TUUSUARIO\Desktop\Carpeta Locales"
    git pull --rebase origin main
    Write-Host "GDI actualizado" -ForegroundColor Green
}
Set-Alias gg gdi
'@

Write-Host "Instalado. Cerrá esta ventana y abrí una nueva para usar 'gdi'." -ForegroundColor Cyan
```

### Qué Hace el Script (Resumen)

| Bloque                             | Función                                                         |
| ---------------------------------- | --------------------------------------------------------------- |
| `cd`                               | Entra a la carpeta local creada.                                |
| Borrar `.git`                      | Limpia un repo viejo para evitar conflictos.                    |
| `git init`                         | Inicializa Git local.                                           |
| `git remote add origin`            | Vincula con el repositorio de GitHub.                           |
| `git fetch`                        | Descarga referencias del remoto.                                |
| `git checkout -b main origin/main` | Crea la rama `main` local idéntica a la remota.                 |
| Perfil PowerShell                  | Crea/abre archivo de perfil de usuario.                         |
| Función `gdi`                      | Define comando que navega a la carpeta y ejecuta actualización. |
| `Set-Alias gg gdi`                 | Alias corto alternativo.                                        |
| Mensaje final                      | Indica reiniciar la terminal para activar la función.           |

### Si aparece restricción de ejecución (opcional)

Ejecutar una sola vez:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Confirmar con **Y**.

---

## 3. Actualización

abris terminal y pones :

```powershell
gdi   # o gg
```

Eso trae la última versión (`git pull --rebase origin main`).


---

### 7. Resumen Ultra Corto

1. Crear carpeta `Carpeta Locales`.
2. Ejecutar script (reemplazando `TUUSUARIO`).
3. Cada día: `gdi`.
4. Para subir: `git add .` → `git commit -m "msg"` → `git push origin main`.

Listo.

---

## 🚨 ¿Tienes problemas?

<div align="center">

### 📋 **¿Necesitas ayuda?**

Si encuentras algún problema o tienes dudas, copia este texto y pégalo en tu agente de IA para obtener ayuda:

```markdown
# Solicitud de Ayuda - GDI

Estoy trabajando en el proyecto GDI (Gestión Documental Inteligente) y necesito asistencia con:

**Archivo:** PASO1.MD
**Sección:** [Especifica la sección donde tienes problemas]

**Problema:** [Describe tu problema específico]

**Contexto:** [Proporciona contexto adicional si es necesario]
```

</div>

--- 

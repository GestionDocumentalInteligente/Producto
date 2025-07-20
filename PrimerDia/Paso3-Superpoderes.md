# Paso 3: Superpoderes de IA

## CLAUDE: Configuración para Desarrollador

1. Ingresa a la configuración de Claude y selecciona la opción **Desarrollador**.
2. Accede al archivo JSON de configuración.
3. Copia y pega el **Código Claude MCP** (verifica la URL si deseas conectar, si no, solo utiliza la documentación).
   - **Recurso local:** [`Claude MCP`](./Claude%20MCP) ← Usa este archivo como referencia para la configuración.

4. Una vez hecho esto, haz clic en "Finalizar Tarea" con Claude abierto (esto reiniciará la app) y ya deberías tener en tus integraciones los MCP.
5. Luego, crea un nuevo proyecto y pega las instrucciones desde:
   - `GDI-PRODUCTO/PrimerDia/Promp Instrucciones Proyecto Claude n8n`

Una vez hecho esto, haz clic en "Finalizar Tarea" con Claude abierto (así se reinicia) y ya deberías tener en tus integraciones los MCP.

Ahora dale las instrucciones: crea un nuevo proyecto y pega las instrucciones. GDI-PRODUCTO\PrimerDia\Promp Intrucciones Proyecto Claude n8n

**Buen material:**
- [Video explicativo](https://youtu.be/_d7tK-Hx7fM?si=AvjG_AIZCMNM240-)

**Repositorios útiles en GitHub:**
- [n8n-mcp (czlonkowski)](https://github.com/czlonkowski/n8n-mcp?tab=readme-ov-file)
- [n8n-workflows (zie619)](https://github.com/zie619/n8n-workflows)
- [docs-mcp-server (arabold)](https://github.com/arabold/docs-mcp-server)
- [supabase-mcp (supabase-community)](https://github.com/supabase-community/supabase-mcp)

---

## CURSOR u otros: Agregar Documentos a la Base de Conocimiento

1. Desde el chat de Cursor, utiliza `@Documentos` para agregar información a la Base de Conocimiento.
2. Pega los siguientes enlaces o los que consideres relevantes.

### Conectar a Supabase
- Usa la configuración que se encuentra en la carpeta `mcp.json` ([ver archivo](./mcp.json)).
- En tu Cursor, ve a **Settings > Integrations > MCP** y pega el contenido de ese archivo.

### Requisitos previos
- Debes tener instalado **Node.js** y **npm**. Puedes instalarlos usando PowerShell:

```powershell
winget install OpenJS.NodeJS
```

---

**Ejemplo de links para agregar:**
- [FrameWorkGDI](https://ejemplo.com/manual-gdi)
- [Estructura BD GDI](https://ejemplo.com/glosario-gdi)

---

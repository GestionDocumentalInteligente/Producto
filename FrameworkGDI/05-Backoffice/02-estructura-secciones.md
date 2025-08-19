# Estructura del Backoffice

## 3.1 Secciones Principales

El Backoffice está organizado en **7 secciones principales**, cada una diseñada para configurar aspectos específicos del sistema:

| **Sección** | **Propósito** | **Elementos Configurables** |
|-------------|---------------|------------------------------|
| **Información General** | Datos oficiales e identidad visual de la municipalidad | Nombre oficial, tipo de entidad, datos fiscales, logotipo, colores institucionales, frase anual |
| **Accesos y Control** | Gestión de usuarios y permisos | Usuarios de super administrador |
| **Organigrama** | Estructura organizacional | Reparticiones, sectores, responsables |
| **Documentos** | Tipos de documentos disponibles | Plantillas, firmas, numeración |
| **Expedientes** | Tipos de expedientes del sistema | Configuración de trámites y procesos |
| **Integraciones** | Conectores externos | APIs, servicios terceros, autenticaciones |
| **API KEY** | Gestión de credenciales de servicios externos | Credenciales y tokens de acceso |

## 3.2 Impacto de las Configuraciones

Las configuraciones realizadas en el Backoffice tienen un impacto directo e inmediato en el sistema GDI principal:

```
BACKOFFICE -----> SISTEMA GDI PRINCIPAL
    │
    ├── Información General ────► Identidad visual y datos institucionales
    ├── Organigrama ───────────► Estructura de usuarios y permisos  
    ├── Documentos ────────────► Tipos disponibles en creación
    ├── Expedientes ───────────► Tipos disponibles en caratulación
    ├── Accesos y Control ─────► Gestión de super-administradores
    ├── Integraciones ─────────► Servicios externos conectados
    └── API Keys ──────────────► Credenciales para integraciones
```

### Efectos Inmediatos:

- **Cambios en Información General**: Se reflejan inmediatamente en logos, colores y datos de la interfaz principal
- **Modificaciones en Organigrama**: Actualizan la estructura de usuarios y permisos en tiempo real  
- **Configuración de Documentos**: Los nuevos tipos aparecen instantáneamente en los dropdowns de creación
- **Ajustes en Expedientes**: Los tipos configurados se habilitan de inmediato para caratulación
- **Gestión de Accesos**: Los cambios en super-administradores se aplican en la siguiente sesión
- **Integraciones y API Keys**: Las conexiones se establecen o cortan inmediatamente
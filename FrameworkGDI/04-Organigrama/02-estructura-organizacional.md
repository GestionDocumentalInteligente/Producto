# Estructura Organizacional

## 3.1 Composición de un Organismo Municipal

GDI organiza la estructura jerárquica en tres niveles principales:

```
ORGANISMO
├── REPARTICIONES (Secretarías/Direcciones)
│   ├── SECTORES (Departamentos/Áreas)
│   │   └── USUARIOS (Empleados/Funcionarios)
```

## 3.2 Niveles Jerárquicos

### NIVEL 1: REPARTICIÓN

- Representa las grandes áreas funcionales del municipio
- Ejemplos: Secretaría de Gobierno, Secretaría de Hacienda, Dirección de Obras Públicas
- Cada repartición tiene un **Titular** (Secretario/Director)
- Se identifica con un **Acrónimo** único (ej: "SEGOB", "SECHAC", "DIROB")

### NIVEL 2: SECTOR

- Subdivisions funcionales dentro de cada repartición
- Ejemplos: Departamento de Personal, Mesa de Entradas, Área de Sistemas
- Cada sector pertenece a una repartición específica
- Puede tener múltiples usuarios asignados
- Se identifica con un **Acrónimo** que desciende de la repartición (ej: "SEGOB-DP", "SECHAC-ME")

### NIVEL 3: USUARIO

- Empleados y funcionarios municipales
- Cada usuario pertenece a un sector específico
- Puede tener diferentes roles y permisos según su función

## 3.3 Entidades del Organigrama

### 3.3.1 Entidad Persona/Usuario

Representa a cada individuo que interactúa con el sistema.

```
USUARIO
├── Datos Personales
│   ├── CUIL: String (único, requerido)
│   ├── DNI: String (requerido)
│   ├── Nombre: String (requerido)
│   ├── Apellido: String (requerido)
│   ├── Email: String (único, requerido)
│   ├── Celular: String (opcional)
│   └── País: String (requerido)
├── Datos del Sistema
│   ├── ID: UUID (generado automáticamente)
│   ├── Username: String (único)
│   ├── Estado: Enum (activo/inactivo/suspendido)
│   ├── Fecha de alta: DateTime
│   └── Último acceso: DateTime
└── Relaciones
    ├── Sectores asignados: Array de sector_id (muchos a muchos)
    ├── Reparticiones donde es titular: Array de reparticion_id (muchos a muchos)
    └── Roles: Array de roles asignados
```

### 3.3.2 Entidad Repartición

Unidad organizacional de alto nivel (ej: Secretaría, Dirección General).

```
REPARTICIÓN
├── Información Básica
│   ├── ID: UUID (generado automáticamente)
│   ├── Nombre: String (ej: "Secretaría de Gobierno")
│   └── Acrónimo: String (único, ej: "SEGOB")
├── Responsable
│   └── Titulares: Array de user_id (muchos a muchos)
└── Relaciones
    ├── Sectores: Array de sector_id
    └── Usuarios totales: Calculado dinámicamente
```

### 3.3.3 Entidad Sector

```
SECTOR
├── Información Básica
│   ├── ID: UUID (generado automáticamente)
│   ├── Nombre: String (ej: "Departamento de Personal")
│   ├── Código: String (único dentro de la repartición)
│   └── Acrónimo: String (único dentro de la repartición)
├── Jerarquía
│   ├── Repartición padre: reparticion_id
│   └── Nivel: Integer (siempre 2)
├── Responsable
│   └── Jefes de sector: Array de user_id (muchos a muchos)
└── Relaciones
    └── Usuarios: Array de user_id
```

## 3.4 Reglas de Negocio Fundamentales

### [REGLA_NEGOCIO: ESTRUCTURA_JERÁRQUICA]
**RN001: Jerarquía Obligatoria**
- Todo usuario DEBE pertenecer a un sector
- Todo sector DEBE pertenecer a una repartición
- Una repartición puede tener múltiples sectores
- Un sector puede tener múltiples usuarios
- Un usuario puede pertenecer a múltiples sectores

### [REGLA_NEGOCIO: TITULARIDAD]
**RN002: Asignación de Titulares**
- Cada repartición PUEDE tener un titular asignado
- Un usuario puede ser titular de múltiples reparticiones
- Solo los titulares pueden gestionar usuarios de su repartición

### [REGLA_NEGOCIO: UNICIDAD]
**RN003: Identificadores Únicos**
- CUIL debe ser único en todo el sistema
- Email debe ser único en todo el sistema
- Acrónimo de repartición debe ser único
- Código de sector debe ser único dentro de su repartición
- Acrónimo de sector debe ser único dentro de su repartición

### [REGLA_NEGOCIO: PERMISOS_GESTIÓN]
**RN004: Gestión de Usuarios**
- Solo titulares pueden dar de alta/baja/pausar usuarios
- Los titulares solo pueden gestionar usuarios de su propia repartición
- Todos los usuarios pueden consultar el organigrama de su repartición
- Los usuarios agentes pueden ver "Mi Equipo" pero no gestionar
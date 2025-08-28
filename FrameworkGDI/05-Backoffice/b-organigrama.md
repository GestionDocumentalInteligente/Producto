# 🔄 Flujos de Gestión del Organigrama - Módulo GDI

Este documento detalla los flujos operativos para la gestión de la estructura organizacional en GDI, incluyendo la administración de usuarios, reparticiones y sectores.

## 1. Flujo de Configuración Inicial del Organigrama

### 1.1 Secuencia de Configuración Recomendada

**Prerrequisito:** Instancia de GDI configurada con Super-Administrador activo.

```
1. Crear Municipio → 2. Crear Reparticiones → 3. Crear Sectores → 4. Asignar Titulares → 5. Dar de Alta Usuarios
```

#### Paso 1: Configuración del Municipio
**Responsable:** Super-Administrador desde Backoffice  
**Ubicación:** Backoffice > Información General

```sql
-- Se configura automáticamente al setup inicial
INSERT INTO municipalities (
    name, 
    acronym, 
    official_name, 
    fiscal_id
) VALUES (
    'Terranova',
    'TN', 
    'Municipalidad de Terranova',
    '30-12345678-9'
);
```

#### Paso 2: Creación de Reparticiones Principales
**Responsable:** Super-Administrador  
**Ubicación:** Backoffice > Organigrama > Reparticiones

**Flujo Técnico:**
1. Accede a sección "Reparticiones"
2. Completa formulario de nueva repartición
3. Sistema valida unicidad de acrónimo
4. Genera `department_id` automáticamente

**Datos Requeridos:**
- Nombre completo (ej: "Secretaría de Gobierno")
- Acrónimo único (ej: "SEGOB")
- Descripción (opcional)

```sql
INSERT INTO departments (
    municipality_id,
    name, 
    acronym
) VALUES (
    ?, -- municipality_id
    'Secretaría de Gobierno',
    'SEGOB'
);
```

#### Paso 3: Creación de Sectores
**Responsable:** Super-Administrador  
**Ubicación:** Backoffice > Organigrama > Sectores

**Validaciones:**
- Repartición padre debe existir y estar activa
- Acrónimo único dentro de la repartición
- Nombre descriptivo obligatorio

```sql
INSERT INTO sectors (
    department_id,
    name,
    acronym
) VALUES (
    ?, -- department_id de la repartición padre
    'Mesa de Entradas',
    'MESA'
);
```

#### Paso 4: Asignación de Titulares
**Responsable:** Super-Administrador  
**Prerrequisito:** Usuario debe existir en el sistema

**Proceso:**
1. Selecciona repartición
2. Busca usuario por CUIL o nombre
3. Asigna como titular
4. Sistema otorga permisos de gestión automáticamente

```sql
INSERT INTO department_heads (
    user_id,
    department_id,
    designated_at
) VALUES (
    ?, -- user_id del titular
    ?, -- department_id
    NOW()
);
```

---

## 2. Gestión de Usuarios

### 2.1 Alta de Usuario por Titular de Repartición

**Responsable:** Usuario con rol "Titular" de repartición  
**Ubicación:** Sistema Principal > Mi Equipo > Agregar Usuario

#### Flujo Paso a Paso:

**Paso 1: Validación de Permisos**
```sql
-- Sistema verifica que usuario actual es titular
SELECT EXISTS (
    SELECT 1 FROM department_heads dh
    JOIN departments d ON dh.department_id = d.department_id
    JOIN sectors s ON d.department_id = s.department_id
    WHERE dh.user_id = ? -- usuario actual
      AND s.sector_id = ? -- sector donde quiere crear usuario
) as can_manage;
```

**Paso 2: Formulario de Alta**
**Datos Mínimos Requeridos:**
- CUIL (obligatorio, único)
- Email (obligatorio, único)
- Sector de asignación (dropdown con sectores de su repartición)
- Cargo/Función (descripción)

**Datos Opcionales:**
- Nombre completo
- Teléfono
- DNI

**Paso 3: Creación en Base de Datos**
```sql
BEGIN TRANSACTION;

-- 1. Crear usuario en estado "pendiente_activación"
INSERT INTO users (
    cuil,
    email,
    full_name,
    is_active
) VALUES (
    ?, ?, 'Usuario Pendiente', false
);

-- 2. Asignar a sector
INSERT INTO user_sectors (
    user_id,
    sector_id
) VALUES (
    ?, ? -- sector seleccionado
);

COMMIT;
```

**Paso 4: Proceso de Invitación**
1. Sistema genera token único de activación
2. Envía email automático con enlace de activación
3. Usuario completa su perfil
4. Sistema valida CUIL con datos ingresados
5. Activa cuenta automáticamente

#### Estados de Usuario Durante Alta:

```
creado → invitación_enviada → activación_completada → activo
   ↓           ↓                    ↓
 error    reenviar_invitación    validación_fallida
```

### 2.2 Gestión de Estados de Usuario

#### Pausar Usuario
**Trigger:** Titular selecciona "Pausar" en gestión de equipo  
**Efecto:** Usuario mantiene acceso limitado (solo lectura)  
**Uso típico:** Licencias médicas, vacaciones

```sql
UPDATE users 
SET is_active = false,
    updated_at = NOW()
WHERE user_id = ?;
```

#### Dar de Baja Usuario  
**Trigger:** Titular selecciona "Dar de Baja"  
**Efecto:** Usuario pierde acceso completo al sistema  
**Uso típico:** Desvinculaciones laborales

```sql
BEGIN TRANSACTION;

-- 1. Desactivar usuario
UPDATE users 
SET is_active = false,
    updated_at = NOW()
WHERE user_id = ?;

-- 2. Remover de sectores (opcional, según política)
DELETE FROM user_sectors 
WHERE user_id = ?;

-- 3. Remover titularidades (si las tiene)
DELETE FROM department_heads 
WHERE user_id = ?;

COMMIT;
```

#### Reactivar Usuario
**Trigger:** Titular selecciona "Reactivar"  
**Efecto:** Usuario recupera acceso según sus asignaciones

```sql
UPDATE users 
SET is_active = true,
    updated_at = NOW()
WHERE user_id = ?;
```

### 2.3 Reasignación de Usuarios Entre Sectores

**Responsable:** Titular de repartición  
**Limitación:** Solo dentro de sectores de su repartición

**Proceso:**
1. Selecciona usuario de su equipo
2. Modifica asignación de sector
3. Sistema valida que ambos sectores pertenecen a su repartición

```sql
-- Validación previa
SELECT COUNT(*) as valid_sectors
FROM sectors s
WHERE s.sector_id IN (?, ?) -- sector_origen, sector_destino
  AND s.department_id = ?; -- department del titular

-- Si valid_sectors = 2, proceder con reasignación
UPDATE user_sectors 
SET sector_id = ? -- nuevo sector
WHERE user_id = ? 
  AND sector_id = ?; -- sector anterior
```

---

## 3. Vista "Mi Equipo" - Diferencias por Rol

### 3.1 Vista para Agentes (Usuarios Estándar)

**Permisos:** Solo lectura  
**Contenido visible:**
- Organización de su repartición (tabs por sector)
- Lista de usuarios de su repartición con sectores
- Información de contacto de compañeros

**Flujo de Navegación:**
```
Mi Equipo → Pestaña "Organización" → [Sector 1] [Sector 2] [Sector N]
         → Pestaña "Usuarios" → Lista unificada con filtros
```

**Query de Datos:**
```sql
-- Usuarios de la misma repartición
SELECT 
    u.full_name,
    u.email,
    s.name as sector_name,
    s.acronym as sector_acronym
FROM users u
JOIN user_sectors us ON u.user_id = us.user_id
JOIN sectors s ON us.sector_id = s.sector_id
JOIN departments d ON s.department_id = d.department_id
WHERE d.department_id = (
    -- Repartición del usuario actual
    SELECT s2.department_id 
    FROM users u2
    JOIN user_sectors us2 ON u2.user_id = us2.user_id
    JOIN sectors s2 ON us2.sector_id = s2.sector_id
    WHERE u2.user_id = ? -- usuario actual
    LIMIT 1
)
ORDER BY s.name, u.full_name;
```

### 3.2 Vista para Titulares (Gestores de Repartición)

**Permisos:** Lectura + Gestión completa  
**Contenido adicional:**
- Botones de gestión (Agregar, Pausar, Dar de baja)
- Opciones de reasignación
- Estadísticas de su equipo

**Funcionalidades Exclusivas:**
- **Agregar usuarios:** Formulario de alta
- **Gestionar estados:** Activar/Pausar/Dar de baja
- **Reasignar sectores:** Mover usuarios entre sectores
- **Ver estadísticas:** Métricas de su repartición

**Query de Validación de Titular:**
```sql
-- Verificar si usuario es titular
SELECT EXISTS (
    SELECT 1 FROM department_heads dh
    WHERE dh.user_id = ? -- usuario actual
      AND dh.department_id = ? -- repartición a gestionar
) as is_head;
```

---

## 4. Flujos de Casos Especiales

### 4.1 Cambio de Titular de Repartición

**Responsable:** Super-Administrador únicamente  
**Ubicación:** Backoffice > Organigrama > Reparticiones

**Proceso:**
1. Selecciona repartición
2. Remueve titular actual (opcional)
3. Asigna nuevo titular
4. Sistema transfiere permisos automáticamente

```sql
BEGIN TRANSACTION;

-- 1. Remover titular anterior (opcional)
DELETE FROM department_heads 
WHERE department_id = ? 
  AND user_id = ?; -- titular anterior

-- 2. Asignar nuevo titular
INSERT INTO department_heads (
    user_id,
    department_id,
    designated_at
) VALUES (
    ?, -- nuevo titular
    ?, -- repartición
    NOW()
);

COMMIT;
```

### 4.2 Transferencia de Usuario Entre Reparticiones

**Responsable:** Super-Administrador únicamente  
**Complejidad:** Alta (afecta permisos y documentos)

**Proceso:**
1. Identifica documentos/expedientes activos del usuario
2. Evalúa impacto de la transferencia
3. Remueve de sectores actuales
4. Asigna a nuevo sector de destino
5. Actualiza permisos y roles

```sql
BEGIN TRANSACTION;

-- 1. Remover de sectores actuales
DELETE FROM user_sectors 
WHERE user_id = ?;

-- 2. Asignar a nuevo sector
INSERT INTO user_sectors (
    user_id,
    sector_id
) VALUES (
    ?, ? -- nuevo sector
);

-- 3. Actualizar roles si es necesario
-- (Lógica adicional según reglas de negocio)

COMMIT;
```

### 4.3 Reestructuración Organizacional

**Responsable:** Super-Administrador  
**Casos típicos:**
- Fusión de reparticiones
- División de sectores
- Creación de nuevas áreas

**Proceso para Fusión de Reparticiones:**
```sql
BEGIN TRANSACTION;

-- 1. Transferir sectores de repartición a fusionar
UPDATE sectors 
SET department_id = ? -- repartición destino
WHERE department_id = ?; -- repartición a eliminar

-- 2. Transferir titularidades
UPDATE department_heads 
SET department_id = ? -- repartición destino
WHERE department_id = ?; -- repartición a eliminar

-- 3. Desactivar repartición antigua
UPDATE departments 
SET is_active = false
WHERE department_id = ?; -- repartición a eliminar

COMMIT;
```

---

## 5. Carga Masiva de Usuarios

### 5.1 Funcionalidad de Importación CSV/Excel

**Responsable:** Super-Administrador desde Backoffice  
**Ubicación:** Backoffice > Organigrama > Carga Masiva

**Formato de Archivo:**
```csv
CUIL,Email,Nombre,Apellido,DNI,Reparticion_Acronimo,Sector_Acronimo,Cargo
20123456789,juan.perez@terranova.gob.ar,Juan,Pérez,12345678,SEGOB,MESA,Administrativo
27456789123,maria.garcia@terranova.gob.ar,María,García,45678912,SECHAC,TESO,Tesorera
```

**Proceso de Validación:**
1. **Estructura del archivo:** Validar columnas requeridas
2. **CUIL único:** Verificar que no existan duplicados
3. **Email único:** Validar format y unicidad
4. **Reparticiones/Sectores:** Confirmar que existen
5. **Integridad:** Validar relaciones organizacionales

**Flujo de Procesamiento:**
```sql
-- Procesamiento en lotes de 50 usuarios
BEGIN TRANSACTION;

-- 1. Crear usuarios en estado pendiente
INSERT INTO users (cuil, email, full_name, is_active)
SELECT cuil, email, CONCAT(nombre, ' ', apellido), false
FROM temp_import_table
WHERE validation_status = 'valid'
LIMIT 50;

-- 2. Asignar a sectores
INSERT INTO user_sectors (user_id, sector_id)
SELECT u.user_id, s.sector_id
FROM users u
JOIN temp_import_table t ON u.cuil = t.cuil
JOIN sectors s ON s.acronym = t.sector_acronimo
JOIN departments d ON s.department_id = d.department_id 
                   AND d.acronym = t.reparticion_acronimo;

COMMIT;
```

**Sistema de Invitaciones Masivas:**
- Envío automático de emails de activación
- Procesamiento en cola para evitar spam
- Seguimiento de estado de activaciones
- Reintento automático para emails fallidos

---

## 6. Reportes y Métricas del Organigrama

### 6.1 Dashboard de Gestión para Titulares

**Métricas Disponibles:**
- Total de usuarios en su repartición
- Usuarios activos vs inactivos
- Distribución por sector
- Usuarios pendientes de activación

```sql
-- Query para métricas del titular
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN u.is_active THEN 1 END) as active_users,
    COUNT(CASE WHEN NOT u.is_active THEN 1 END) as inactive_users,
    s.name as sector_name,
    COUNT(u.user_id) as users_per_sector
FROM users u
JOIN user_sectors us ON u.user_id = us.user_id
JOIN sectors s ON us.sector_id = s.sector_id
JOIN departments d ON s.department_id = d.department_id
JOIN department_heads dh ON d.department_id = dh.department_id
WHERE dh.user_id = ? -- titular actual
GROUP BY s.sector_id, s.name;
```

### 6.2 Reportes para Super-Administrador

**Reportes Disponibles:**
- Organigrama completo del municipio
- Distribución de personal por repartición
- Titulares sin asignar
- Usuarios sin sector asignado
- Histórico de cambios organizacionales

```sql
-- Reporte completo de estructura
SELECT 
    m.name as municipality,
    d.name as department,
    d.acronym as dept_acronym,
    s.name as sector,
    COUNT(u.user_id) as total_users,
    dh.user_id IS NOT NULL as has_head
FROM municipalities m
JOIN departments d ON m.id_municipality = d.municipality_id
LEFT JOIN sectors s ON d.department_id = s.department_id
LEFT JOIN user_sectors us ON s.sector_id = us.sector_id
LEFT JOIN users u ON us.user_id = u.user_id AND u.is_active = true
LEFT JOIN department_heads dh ON d.department_id = dh.department_id
GROUP BY m.id_municipality, d.department_id, s.sector_id, dh.user_id
ORDER BY d.name, s.name;
```

---

## 7. Validaciones y Controles de Integridad

### 7.1 Validaciones Automáticas del Sistema

**A Nivel de Base de Datos:**
- Constraints de clave foránea
- Unicidad de CUIL y email
- Unicidad de acrónimos por scope

**A Nivel de Aplicación:**
```sql
-- Función de validación de integridad
CREATE OR REPLACE FUNCTION validate_organizational_integrity()
RETURNS TABLE (
    issue_type TEXT,
    description TEXT,
    affected_records INTEGER
) AS $$
BEGIN
    -- Usuarios sin sector asignado
    RETURN QUERY
    SELECT 
        'ORPHAN_USERS'::TEXT,
        'Users without sector assignment'::TEXT,
        COUNT(*)::INTEGER
    FROM users u
    LEFT JOIN user_sectors us ON u.user_id = us.user_id
    WHERE us.user_id IS NULL AND u.is_active = true;
    
    -- Sectores sin usuarios
    RETURN QUERY
    SELECT 
        'EMPTY_SECTORS'::TEXT,
        'Sectors without active users'::TEXT,
        COUNT(*)::INTEGER
    FROM sectors s
    LEFT JOIN user_sectors us ON s.sector_id = us.sector_id
    LEFT JOIN users u ON us.user_id = u.user_id AND u.is_active = true
    WHERE u.user_id IS NULL;
    
    -- Reparticiones sin titular
    RETURN QUERY
    SELECT 
        'DEPARTMENTS_NO_HEAD'::TEXT,
        'Departments without assigned head'::TEXT,
        COUNT(*)::INTEGER
    FROM departments d
    LEFT JOIN department_heads dh ON d.department_id = dh.department_id
    WHERE dh.department_id IS NULL AND d.is_active = true;
END;
$$ LANGUAGE plpgsql;
```

### 7.2 Controles de Seguridad

**Control de Acceso:**
- Validación de permisos en cada operación
- Verificación de titularidad en tiempo real
- Logging de acciones administrativas

**Auditoría:**
- Registro de cambios en estructura organizacional
- Trazabilidad de altas/bajas de usuarios
- Historial de asignaciones y reasignaciones

---

## 8. Mantenimiento y Operaciones

### 8.1 Tareas de Mantenimiento Periódico

**Diario:**
- Cleanup de invitaciones expiradas
- Validación de integridad básica
- Envío de recordatorios de activación

**Semanal:**
- Reporte de métricas organizacionales
- Verificación de usuarios inactivos
- Limpieza de datos temporales

**Mensual:**
- Auditoría completa de estructura
- Reporte de cambios organizacionales
- Backup de configuración del organigrama

### 8.2 Procedimientos de Emergencia

**Restauración de Titular:**
```sql
-- En caso de pérdida accidental de titular
INSERT INTO department_heads (user_id, department_id, designated_at)
SELECT ?, ?, NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM department_heads 
    WHERE department_id = ?
);
```

**Recuperación de Usuario Bloqueado:**
```sql
-- Reactivación de emergencia
UPDATE users 
SET is_active = true,
    updated_at = NOW()
WHERE cuil = ? -- CUIL del usuario a recuperar
  AND NOT is_active;
```

---

## Enlaces Relacionados

- [Estructura Organizacional](./02b-estructura-org.md)
- [Roles y Permisos](./04-roles-permisos.md)
- [Modelo de Datos](./05-modelo-datos.md)
- [Backoffice - Configuración de Organigrama](../backoffice/organigrama.md)
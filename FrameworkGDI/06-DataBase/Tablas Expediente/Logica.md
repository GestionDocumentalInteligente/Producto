# Lógica de Negocio - Módulo Expedientes

## Numeración Automática
**Formato:** `EE-YYYY-NNNNNN-MUNI-DEPARTAMENTO`
- **YYYY:** Año actual
- **NNNNNN:** Secuencial por municipio/año
- **MUNI:** Acrónimo del municipio
- **DEPARTAMENTO:** Acrónimo del departamento numerador

**Lógica sector numerador:**
- Si `filing_sector_id` es NULL: usa departamento del creador
- Si `filing_sector_id` tiene valor: usa ese departamento/sector específico (la sigla es solo del departamento, la administración del sector)

## Tipos de Movimiento

### 1. CREATION
- Primer registro del expediente
- Genera carátula automáticamente (orden #0)
- Define departamento numerador según template
- `creates_document` siempre true
- `request_status` siempre "completed"

### 2. TRANSFER
- Cambia administración del expediente
- Actualiza `sector_admin_id`
- Puede incluir `assigned_user_id` opcional
- `creates_document` siempre true (genera Pase)
- `request_status` siempre "completed"

### 3. ACTION_REQUEST
- No modifica sector administrador
- Habilita sector temporal para actuación
- Crea registro en `requests`
- `creates_document` opcional
- `request_status` inicia como "pending"

### 4. RECORD_ASSIGNMENT
- Asigna responsable general del expediente
- Actualiza `assigned_user_id` del expediente
- `creates_document` siempre false
- No afecta permisos ni administración

### 5. REQUEST_ASSIGNMENT
- Asigna responsable a una solicitud específica
- Requiere `reference_movement_id`
- Actualiza `assigned_user_id` en tabla `requests`
- `creates_document` siempre false


## Control de Acceso
- **Sector Admin:** Control total
- **Sectores Habilitados:** Permisos temporales
- **Usuario Asignado:** Responsable específico (ingresa por sector, no puede haber un resaposable que no sea de Sector Admin)
- **RLS:** Filtrado automático por permisos


# 📊 Módulo Documentos - Modelo de Datos Completo

## Resumen Ejecutivo

El módulo de documentos utiliza 7 tablas principales que gestionan todo el ciclo de vida documental, desde la creación hasta la oficialización, incluyendo firmas, rechazos y numeración oficial.

## 1. TABLA PRINCIPAL: document_draft

**Descripción:** Contiene todos los documentos en proceso de creación y firma. Es la tabla central del módulo.

```sql
CREATE TABLE document_draft (
    document_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    document_type_id UUID NOT NULL,
    created_by UUID NOT NULL,
    reference TEXT NOT NULL,
    content JSONB NOT NULL,
    status document_status DEFAULT 'draft' NOT NULL,
    sent_to_sign_at TIMESTAMP,
    last_modified_at TIMESTAMP DEFAULT now(),
    is_deleted BOOLEAN DEFAULT false,
    audit_data JSONB,
    sent_by UUID,
    pad_id VARCHAR NOT NULL
);
```

**Campos Clave:**
- document_id: Identificador único del documento
- document_type_id: Referencia al tipo de documento configurado
- reference: Motivo o referencia del documento (nunca vacío)
- content: Contenido enriquecido en formato JSON
- status: Estado actual del documento (ver enum más abajo)
- pad_id: ID del editor colaborativo
- sent_by: Usuario que envió el documento a firmar
- is_deleted: Eliminación lógica para preservar integridad

**Relaciones:**
- document_type_id → document_types.document_type_id
- created_by → users.user_id
- sent_by → users.user_id

## 2. ENUM: document_status

**Estados Implementados:**
```sql
CREATE TYPE document_status AS ENUM (
    'draft',        -- En edición
    'sent_to_sign', -- Enviado al circuito de firmas
    'signed',       -- Firmado y oficial
    'rejected',     -- Rechazado por algún firmante
    'cancelled',    -- Cancelado antes de completar
    'archived'      -- Archivado después de firmado
);
```

**Flujo de Estados:**
```
draft → sent_to_sign → signed → archived
 ↓         ↓           ↑
deleted   rejected → (vuelta a draft)
          ↓
         cancelled
```

## 3. TABLA: document_signers

**Descripción:** Gestiona los firmantes asignados a cada documento y el orden de firma.

```sql
CREATE TABLE document_signers (
    document_signer_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    document_id UUID NOT NULL,
    user_id UUID NOT NULL,
    is_numerator BOOLEAN DEFAULT false,
    signing_order INTEGER,
    status document_signer_status,
    signed_at TIMESTAMP,
    observations TEXT,
    audit_data JSONB
);
```

**Campos Clave:**
- is_numerator: Indica si es el firmante que numera (último)
- signing_order: Orden secuencial de firma
- status: Estado del firmante individual

**Estados del Firmante:**
```sql
CREATE TYPE document_signer_status AS ENUM (
    'pending',   -- Esperando su turno
    'signed',    -- Ya firmó
    'rejected'   -- Rechazó el documento
);
```

**Relaciones:**
- document_id → document_draft.document_id
- user_id → users.user_id

## 4. TABLA: document_rejections

**Descripción:** Registra los rechazos de documentos con sus motivos.

```sql
CREATE TABLE document_rejections (
    rejection_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    document_id UUID NOT NULL,
    rejected_by UUID NOT NULL,
    reason TEXT,
    rejected_at TIMESTAMP DEFAULT now(),
    audit_data JSONB
);
```

**Propósito:**
- Trazabilidad de rechazos
- Motivos para corrección
- Auditoría del proceso

**Relaciones:**
- document_id → document_draft.document_id
- rejected_by → users.user_id

## 5. TABLA: document_types

**Descripción:** Define los tipos de documentos disponibles por municipio.

```sql
CREATE TABLE document_types (
    document_type_id UUID PRIMARY KEY,
    global_document_type_id UUID UNIQUE NOT NULL,
    name VARCHAR NOT NULL,
    acronym VARCHAR UNIQUE NOT NULL,
    description TEXT,
    required_signature required_signature_enum,
    is_active BOOLEAN DEFAULT true,
    audit_data JSONB
);
```

**Tipos de Firma Requerida:**
```sql
CREATE TYPE required_signature_enum AS ENUM (
    'ELECTRONIC_ALL_SIGNERS',    -- Firma electrónica todos
    'DIGITAL_ALL_SIGNERS',       -- Firma digital todos
    'DIGITAL_ONLY_NUMERATOR'     -- Solo numerador con firma digital
);
```

**Relaciones:**
- global_document_type_id → global_document_types.global_document_type_id

## 6. TABLA: numeration_requests

**Descripción:** Gestiona la reserva y asignación de números oficiales secuenciales.

```sql
CREATE TABLE numeration_requests (
    numeration_requests_id UUID PRIMARY KEY,
    document_type_id UUID NOT NULL,
    user_id UUID NOT NULL,
    department_id UUID NOT NULL,
    year SMALLINT NOT NULL,
    reserved_number VARCHAR UNIQUE NOT NULL,
    reserved_at TIMESTAMP NOT NULL,
    is_confirmed BOOLEAN DEFAULT false NOT NULL,
    confirmed_at TIMESTAMP,
    validation_status validation_status_enum NOT NULL,
    audit_data JSONB
);
```

**Estados de Validación:**
```sql
CREATE TYPE validation_status_enum AS ENUM (
    'valid',    -- Número válido y confirmado
    'invalid',  -- Número inválido
    'pending'   -- Esperando validación
);
```

**Propósito:**
- Reserva secuencial de números
- Evita duplicados
- Trazabilidad de asignaciones

**Relaciones:**
- document_type_id → document_types.document_type_id
- user_id → users.user_id
- department_id → departments.department_id

## 7. TABLA: official_documents

**Descripción:** Contiene los documentos que han completado el proceso y tienen validez legal oficial.

```sql
CREATE TABLE official_documents (
    document_id UUID PRIMARY KEY,
    document_type_id UUID NOT NULL,
    numeration_requests_id UUID NOT NULL,
    reference VARCHAR NOT NULL,
    content JSONB NOT NULL,
    official_number VARCHAR UNIQUE NOT NULL,
    year SMALLINT NOT NULL,
    department_id UUID NOT NULL,
    numerator_id UUID NOT NULL,
    signed_at TIMESTAMP NOT NULL,
    signed_pdf_url VARCHAR NOT NULL,
    signers JSONB,
    audit_data JSONB
);
```

**Campos Críticos:**
- official_number: Número oficial único asignado
- signed_pdf_url: URL del PDF firmado final
- numerator_id: Usuario que asignó el número oficial
- signers: Metadatos JSON de todos los firmantes

**Relaciones:**
- numeration_requests_id → numeration_requests.numeration_requests_id
- document_type_id → document_types.document_type_id
- department_id → departments.department_id
- numerator_id → users.user_id

## 8. TABLAS DE CONFIGURACIÓN Y PERMISOS

### enabled_document_types_by_department
```sql
CREATE TABLE enabled_document_types_by_department (
    id INTEGER PRIMARY KEY,
    document_type_id UUID NOT NULL,
    department_id UUID NOT NULL,
    audit_data JSONB
);
```
**Propósito:** Define qué tipos de documento puede usar cada repartición.

### document_types_allowed_by_rank
```sql
CREATE TABLE document_types_allowed_by_rank (
    id INTEGER PRIMARY KEY,
    document_type_id UUID NOT NULL,
    rank_id UUID NOT NULL,
    audit_data JSONB
);
```
**Propósito:** Define qué tipos puede firmar cada nivel jerárquico.

## DIAGRAMA DE RELACIONES

```
document_types ←── document_draft ──→ document_signers
      ↓                ↓                      ↓
enabled_types    document_rejections    users
      ↓                ↓                      ↓
departments      audit_logs           user_roles
      ↓
numeration_requests ──→ official_documents
```

## FLUJO COMPLETO DE DATOS

### 1. Creación:
```sql
INSERT INTO document_draft (
    document_type_id, created_by, reference, 
    content, pad_id, status
) VALUES (...);
```

### 2. Asignación de Firmantes:
```sql
INSERT INTO document_signers (
    document_id, user_id, signing_order, 
    is_numerator, status
) VALUES (...);
```

### 3. Envío a Firma:
```sql
UPDATE document_draft 
SET status = 'sent_to_sign', 
    sent_to_sign_at = now(),
    sent_by = ?
WHERE document_id = ?;
```

### 4. Proceso de Firma:
```sql
UPDATE document_signers 
SET status = 'signed', signed_at = now()
WHERE document_signer_id = ?;
```

### 5. Numeración (Numerador):
```sql
-- Reservar número
INSERT INTO numeration_requests (...);

-- Crear documento oficial
INSERT INTO official_documents (...);

-- Actualizar estado final
UPDATE document_draft 
SET status = 'signed' 
WHERE document_id = ?;
```

## CONSULTAS ÚTILES

### Documentos pendientes de un usuario:
```sql
SELECT dd.*, dt.name as document_type_name
FROM document_draft dd
JOIN document_signers ds ON dd.document_id = ds.document_id
JOIN document_types dt ON dd.document_type_id = dt.document_type_id
WHERE ds.user_id = ? 
  AND ds.status = 'pending'
  AND dd.status = 'sent_to_sign';
```

### Documentos oficiales de un período:
```sql
SELECT od.*, dt.name, dt.acronym
FROM official_documents od
JOIN document_types dt ON od.document_type_id = dt.document_type_id
WHERE od.year = 2025 
  AND od.signed_at BETWEEN ? AND ?;
```

### Estadísticas de rechazo por tipo:
```sql
SELECT dt.name, COUNT(dr.rejection_id) as total_rejections
FROM document_rejections dr
JOIN document_draft dd ON dr.document_id = dd.document_id
JOIN document_types dt ON dd.document_type_id = dt.document_type_id
GROUP BY dt.name;
```

## VALIDACIONES Y CONSTRAINTS

### Constraints Implementados:
- official_documents.official_number UNIQUE
- numeration_requests.reserved_number UNIQUE
- document_types.acronym UNIQUE
- Estados válidos via ENUMs
- Referencias foráneas con cascada

### Validaciones de Negocio:
- document_draft.reference nunca vacío
- document_draft.content nunca vacío
- Solo un numerador por documento (is_numerator = true)
- Orden de firma secuencial válido

**Nota:** Este modelo refleja la implementación real en Supabase al momento del análisis. La estructura puede evolucionar según las necesidades del proyecto.
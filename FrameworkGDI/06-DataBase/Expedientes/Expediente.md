# Módulo de Expedientes

## 📋 Tabla de Contenidos

1. [Descripción General](#descripción-general)
2. [Arquitectura de Base de Datos](#arquitectura-de-base-de-datos)
3. [Lógica de Negocio](#lógica-de-negocio)
4. [Gestión de Movimientos](#gestión-de-movimientos)
5. [Flujos de Trabajo](#flujos-de-trabajo)
6. [Relaciones y Dependencias](#relaciones-y-dependencias)


## 🏗️ Arquitectura de Base de Datos

### 1. Global Templates (`global_record_templates`)

**Propósito**: Define plantillas reutilizables a nivel global entre municipalidades.

```sql
CREATE TABLE public.global_record_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    type_name VARCHAR NOT NULL,
    description VARCHAR(150),
    acronym VARCHAR(6) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    audit_data JSONB DEFAULT '{}'
);
```

**Campos**:
- `id` - Identificador único global
- `type_name` - Nombre descriptivo del tipo de expediente. max 50 caracteres.
- `description` - Descripción detallada (máximo 150 caracteres)
- `acronym` - Sigla única globalmente (máximo 8 caracteres)
- `is_active` - Estado activo/inactivo de la plantilla
- `created_at` - Fecha de creación
- `audit_data` - Metadatos de auditoría en formato JSON

## 2. Local Templates (`record_templates`)

**Propósito**: Implementaciones específicas por municipio, conectadas opcionalmente a plantillas globales.

```sql
CREATE TABLE public.record_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    global_template_id UUID REFERENCES global_record_templates(id),
    type_name VARCHAR NOT NULL,
    description VARCHAR(150),
    acronym VARCHAR(6) UNIQUE NOT NULL,
    creation_channel VARCHAR CHECK (creation_channel IN ('web', 'api', 'both')) DEFAULT 'web',
    enabled_departments JSONB,
    filing_department_id UUID, -- FK externa a departments
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    audit_data JSONB DEFAULT '{}'
);
```

**Campos** de la tabla `record_templates` (Local Templates):

- `id` - Identificador único de la plantilla local (UUID).
- `global_template_id` - Referencia opcional a la plantilla global (`global_record_templates.id`).
- `type_name` - Nombre descriptivo del tipo de expediente (máximo 50 caracteres). Si está vinculado a una plantilla global, se hereda.
- `description` - Descripción detallada de la plantilla (máximo 150 caracteres).
- `acronym` - Sigla única para el tipo de expediente (máximo 6 caracteres). Si está vinculado a una plantilla global, se hereda.
- `creation_channel` - Canal habilitado para la creación de expedientes con esta plantilla: `'web'`, `'api'` o `'both'`.
- `enabled_departments` - JSONB con los sectores/departamentos habilitados para usar la plantilla.
- `filing_department_id` - ID del sector/departamento que define la sigla del número de expediente (FK externa a `departments`).  
    - Si es `NULL`, se utiliza la sigla del departamento/sector del usuario que crea el expediente.  
    - Si tiene valor, siempre se usará la sigla del departamento/sector seleccionado.
- `is_active` - Indica si la plantilla está activa o inactiva (booleano).
- `created_at` - Fecha y hora de creación de la plantilla (timestamp con zona horaria).
- `audit_data` - Metadatos de auditoría en formato JSONB (por ejemplo, usuario creador, historial de cambios).

**Lógica de Herencia**:
- **Conectado a Global**: `type_name` y `acronym` se toman de la plantilla global
- **Independiente**: Valores propios en todos los campos

### 3. Electronic Records (`records`)

**Propósito**: Tabla principal que contiene todos los expedientes del sistema.

```sql
CREATE TABLE public.records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    record_number VARCHAR UNIQUE NOT NULL,
    reference VARCHAR(250) NOT NULL,
    template_id UUID NOT NULL REFERENCES record_templates(id),
    
    -- Administración
    admin_department_id UUID NOT NULL, -- FK externa a departments
    assigned_user_id UUID, -- FK externa a users
    
    -- Origen
    creation_type VARCHAR CHECK (creation_type IN ('internal', 'external')) NOT NULL,
    external_initiator_tax_id VARCHAR,
    external_initiator_name VARCHAR,
    creator_user_id UUID NOT NULL, -- FK externa a users
    
    -- Control
    filing_date TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR CHECK (status IN ('inactive', 'active', 'archived')) DEFAULT 'inactive',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Campos JSON complejos
    linked_documents JSONB DEFAULT '{"documents": []}',
    proposed_documents JSONB DEFAULT '{"proposed": []}',
    enabled_departments JSONB DEFAULT '{"departments": []}',
    movements JSONB DEFAULT '{"movements": []}',
    
    audit_data JSONB DEFAULT '{}'
);
```

#### Campos de la tabla `records`

- `id`: Identificador único del expediente (UUID).
- `record_number`: Número único de expediente, generado según reglas del sistema.
- `reference`: Referencia o título del expediente (máximo 150 caracteres).
- `template_id`: Referencia a la plantilla local utilizada (`record_templates.id`).
- `admin_sector_id`: ID del sector/departamento actualmente responsable del expediente (FK a `sector`).
- `assigned_user_id`: Usuario actualmente asignado como responsable del expediente (FK a `users`). Puede ser `NULL`.
- `creation_type`: Indica si el expediente fue iniciado internamente (`internal`) o externamente (`external`).
- `external_initiator_tax_id`: ID Document del iniciador externo (si corresponde).
- `external_initiator_name`: Nombre del iniciador externo (si corresponde).
- `creator_user_id`: Usuario que creó el expediente (FK a `users`).
- `filing_date`: Fecha y hora de registro del expediente (timestamp con zona horaria).
- `status`: Estado actual del expediente: `inactive`, `active` o `archived`.
- `created_at`: Fecha y hora de creación del registro.
- `linked_documents`: JSONB con los documentos oficialmente vinculados al expediente.
- `proposed_documents`: JSONB con documentos en proceso de creación o propuesta.
- `enabled_sectors`: JSONB con los sectores que tienen permisos temporales sobre el expediente.
- `movements`: JSONB con el historial completo de movimientos y acciones del expediente.
- `audit_data`: Metadatos de auditoría (usuario creador, historial de cambios, etc.) en formato JSONB.

#### Estados del Expediente

- **INACTIVE**: Recién creado, sin documentos vinculados
- **ACTIVE**: Activado cuando se vincula documento tipo CAEX en orden 0
- **ARCHIVED**: Expediente finalizado/cerrado

#### Estructura de Campos JSON

**Campo `linked_documents`** - Documentos oficialmente vinculados:
```json
{
  "documents": [
    {
      "order_number": 0,
      "document_id": "uuid",
      "document_number": "IF-2025-000123-MT-INTE",
      "link_date": "2025-08-26T10:30:00Z",
      "linking_user_id": "uuid_usuario",
      "deactivation_date": null,
      "remediated_by": "uuid_document",
      "remediated_user_id": "uuid_usuario_remediated"
    }
  ]
}
```

**Campo `proposed_documents`** - Documentos en proceso de creación:
```json
{
  "proposed": [
    {
      "document_id": "uuid",
    "document_type": "official|draft|signatures_in_progress",
      "reference": "Propuesta de resolución administrativa",
      "proposal_date": "2025-08-26T10:30:00Z",
      "proposing_user_id": "uuid_usuario"
    }
  ]
}
```

**Campo `enabled_departments`** - Sectores con permisos temporales:
```json
{
  "departments": ["uuid_department1", "uuid_department2"]
}
```
**Campo `movements`**: Para más detalles sobre la estructura y uso de este campo, consulta [Movimientos.md](./Movimientos.md).


### 4. Action Requests (`action_requests`)

**Propósito**: Gestionar solicitudes de actuación abiertas entre sectores.

```sql
CREATE TABLE public.action_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    record_id UUID NOT NULL REFERENCES records(id),
    movement_id UUID NOT NULL,
    requesting_department_id UUID NOT NULL, -- FK externa a departments
    required_department_id UUID NOT NULL, -- FK externa a departments
    assigned_user_id UUID, -- FK externa a users
    reason VARCHAR(254) NOT NULL,
    status VARCHAR CHECK (status IN ('pending', 'in_progress', 'completed')) DEFAULT 'pending',
    creates_document BOOLEAN DEFAULT false,
    request_date TIMESTAMPTZ DEFAULT NOW(),
    response_date TIMESTAMPTZ,
    observations TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    audit_data JSONB DEFAULT '{}'
);
```

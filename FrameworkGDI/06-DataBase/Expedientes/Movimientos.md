# Especificación de Movimientos - Módulo Expedientes

## ENUM Tipos de Movimiento

```sql
CREATE TYPE tipo_movimiento_enum AS ENUM (
  'creacion',
  'transferencia', 
  'solicitud_actuacion',
  'asignacion_expediente',
  'asignacion_solicitud'
);
```

## Estructura Base del Objeto Movement

```typescript
interface Movement {
    id: string;                    // UUID del movimiento
    date: string;                  // ISO 8601 timestamp
    type: MovementType;            // Tipo de movimiento
    sector_id: string;             // UUID del sector que ejecuta
    user_id: string;               // UUID del usuario que ejecuta
    new_admin_sector_id?: string;  // UUID del nuevo sector admin (solo en transfer)
    acting_sector_id?: string;     // UUID del sector actuante (solo en action_request)
    reason: string;                // Motivo del movimiento
    assigned_user_id?: string | null;     // UUID del usuario asignado (puede ser null)
    request_status: RequestStatus; // Estado de la solicitud
    creates_document: string | boolean; // Si genera documento respaldo: true/false o UUID del documento si se asienta en el expediente.
    reference_movement_id?: string; // UUID movimiento referenciado
    metadata: Record<string, any>; // Datos adicionales
}

type MovementType = 'creation' | 'transfer' | 'action_request' | 'record_assignment' | 'request_assignment';
type RequestStatus = 'pending' | 'completed';
```

## Estructura JSON Base

```json
{
  "movements": [
    {
      "id": "uuid_movimiento",
      "date": "2025-08-26T10:30:00Z",
      "type": "creation|transfer|action_request|record_assignment|request_assignment",
      "sector_id": "uuid_sector",
      "user_id": "uuid_usuario",
      "reason": "Motivo del movimiento",
      "request_status": "pending|completed",
      "creates_document": true,
      "metadata": {}
    }
  ]
}
```

## Matriz de Campos por Tipo

| Campo | Creation | Transfer | Action Request | Record Assignment | Request Assignment |
|-------|----------|----------|----------------|------------------|-------------------|
| `new_admin_sector_id` | ❌ | ✅ | ❌ | ❌ | ❌ |
| `acting_sector_id` | ❌ | ❌ | ✅ | ❌ | ❌ |
| `assigned_user_id` | ❌ | 📎 | ❌ | ✅ | ✅ |
| `request_status` | completed | completed | pending | completed | completed |
| `creates_document` | ✅ | ✅ | 📎 | ❌ | ❌ |
| `reference_movement_id` | ❌ | ❌ | ❌ | ❌ | ✅ |

Leyenda:
- ✅ Requerido
- ❌ No aplica
- 📎 Opcional

## Ejemplos por Tipo de Movimiento

### 1. CREATION
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "date": "2025-08-26T09:15:00Z",
  "type": "creation",
  "sector_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "user_id": "123e4567-e89b-12d3-a456-426614174000",
  "reason": "Inicio de expediente de licitación",
  "request_status": "completed",
  "creates_document": true,
  "metadata": {
    "template_used": "LICPUB",
    "generated_number": "EE-2025-001000-TN-DGCO"
  }
}
```

### 2. TRANSFER
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440002",
  "date": "2025-08-26T14:30:00Z",
  "type": "transfer",
  "sector_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "user_id": "123e4567-e89b-12d3-a456-426614174000",
  "new_admin_sector_id": "b2c3d4e5-f6g7-890h-ijkl-234567890123",
  "reason": "Transferencia para dictamen legal",
  "request_status": "completed",
  "creates_document": true,
  "metadata": {
    "previous_sector": "MESA#ENT",
    "new_sector": "LEGAL#DICT"
  }
}
```

### 3. ACTION_REQUEST
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440003",
  "date": "2025-08-26T15:45:00Z",
  "type": "action_request",
  "sector_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "user_id": "123e4567-e89b-12d3-a456-426614174000",
  "acting_sector_id": "c3d4e5f6-g7h8-901i-jklm-345678901234",
  "reason": "Solicitud de informe técnico",
  "request_status": "pending",
  "creates_document": true,
  "metadata": {
    "request_type": "technical_report",
    "deadline_days": 5
  }
}
```

### 4. RECORD_ASSIGNMENT
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440004",
  "date": "2025-08-26T16:20:00Z",
  "type": "record_assignment",
  "sector_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "user_id": "123e4567-e89b-12d3-a456-426614174000",
  "assigned_user_id": "d4e5f6g7-h8i9-012j-klmn-456789012345",
  "reason": "Asignación de responsable general",
  "request_status": "completed",
  "creates_document": false,
  "metadata": {
    "assignment_type": "primary_handler"
  }
}
```

### 5. REQUEST_ASSIGNMENT
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440005",
  "date": "2025-08-26T17:00:00Z",
  "type": "request_assignment",
  "sector_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "user_id": "123e4567-e89b-12d3-a456-426614174000",
  "assigned_user_id": "e5f6g7h8-i9j0-123k-lmno-567890123456",
  "reference_movement_id": "550e8400-e29b-41d4-a716-446655440003",
  "reason": "Asignación de responsable para informe",
  "request_status": "completed",
  "creates_document": false,
  "metadata": {
    "assignment_type": "request_handler",
    "original_request": "technical_report"
  }
}
```

## Reglas de Negocio

1. Todo movimiento debe tener un `reason` descriptivo
2. `request_status` solo puede ser "pending" en `action_request`
3. `creates_document` es obligatorio true en `creation`
4. `reference_movement_id` solo aplica en `request_assignment`
5. En `transfer`, el `sector_id` debe ser el del administrador actual del expediente

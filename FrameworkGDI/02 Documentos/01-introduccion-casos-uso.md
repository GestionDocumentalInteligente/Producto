# 📋 Módulo Documentos GDI - Introducción y Casos de Uso

## ¿Qué es el Módulo Documentos?

El Módulo Documentos es el **núcleo central** de GDI, diseñado para la creación, gestión, colaboración y formalización de documentos electrónicos con **plena validez legal**. Va más allá del expediente tradicional, habilitando flujos colaborativos y dinámicos entre múltiples departments.

### Definición de Documento en GDI

Un **Documento** es cualquier entidad digitalizada que contiene información estructurada o no estructurada (texto, imágenes, tablas, etc.), generada o incorporada al sistema, con un propósito definido y que puede **adquirir validez legal** mediante procesos de firma y numeración.

Es la unidad fundamental de información sobre la cual se construyen los expedientes y las comunicaciones oficiales.

## 🎯 Propuesta de Valor Técnica

### Características Diferenciadoras

- **📝 Editor Colaborativo Nativo**: Múltiples usuarios pueden editar simultáneamente el mismo documento en tiempo real
- **🔄 Gestión Inteligente de Rechazos**: Sistema robusto de correcciones y mejoras iterativas
- **🗄️ Preservación de Integridad**: Eliminación lógica que mantiene trazabilidad histórica
- **⚖️ Validez Legal Garantizada**: Solo documentos en estado `signed` tienen plena validez jurídica
- **🏛️ Integración Organizacional**: Respeta la estructura de departments y jerarquías municipales

### Arquitectura Dual de Documentos

El sistema implementa una **separación clara** entre documentos en proceso y documentos oficiales:

**`document_draft`** → Documentos en creación, edición y firma  
**`official_documents`** → Documentos finalizados con validez legal

---

## 📖 Diccionario de Campos Clave: Documentos

Para entender mejor el ciclo de vida de un documento, estos son algunos de los campos más importantes de la base de datos y lo que representan para el negocio:

*   **`document_draft.status`**: Representa la etapa exacta del ciclo de vida del documento (`Borrador`, `Enviado a Firmar`, `Firmado`, etc.) y es lo que determina qué acciones puede o no puede hacer un usuario en la pantalla.

*   **`document_draft.pad_id`**: Es el identificador técnico que permite que varios usuarios editen el mismo documento a la vez en tiempo real. Es el corazón de la funcionalidad colaborativa.

*   **`document_signers.is_numerator`**: Este campo booleano (`true`/`false`) es crucial porque marca al firmante que tiene la responsabilidad final de oficializar el documento y asignarle un número. No es un firmante más, es quien cierra el proceso.

*   **La diferencia entre `created_by` y `sent_by`**: Es importante distinguirlos para la auditoría. `created_by` es el autor intelectual del borrador, mientras que `sent_by` es el usuario que toma la responsabilidad de iniciar formalmente el circuito de firmas (pueden ser personas distintas).

---

## 🔄 Estados del Documento - Implementación Real

### Estados Principales
```
📝 draft → 📤 sent_to_sign → ✅ signed → 📦 archived
   ↓           ↓              ↑
   🗑️ deleted  ❌ rejected → 🔄 (corrección)
               ↓
              🚫 cancelled
```

### Descripción de Estados

| Estado | Descripción | Acciones Permitidas |
|--------|-------------|-------------------|
| **`draft`** | En edición colaborativa | Editar contenido, asignar firmantes |
| **`sent_to_sign`** | Enviado al circuito de firmas | Firmar, rechazar, observaciones |
| **`signed`** | Firmado y con validez legal | Solo lectura, descarga, archivo |
| **`rejected`** | Rechazado por algún firmante | Revisar motivos, corregir, reenviar |
| **`cancelled`** | Cancelado antes de completar | Solo consulta histórica |
| **`archived`** | Archivado post-finalización | Solo consulta, no modificable |



## 👥 Editor Colaborativo

### Concepto de `pad_id`

Cada documento recibe un **identificador único de pad colaborativo** que permite:

- **✏️ Edición simultánea** de múltiples usuarios
- **🔄 Sincronización en tiempo real** de cambios
- **📝 Historial de versiones** durante la edición
- **👀 Indicadores de presencia** de editores activos

### Flujo de Colaboración

1. **Creación**: Usuario crea documento → se asigna `pad_id` único
2. **Invitación**: Otros usuarios acceden via permisos del department
3. **Edición**: Cambios se sincronizan automáticamente
4. **Finalización**: Al enviar a firma, se congela el contenido


## ❌ Gestión de Rechazos y Correcciones

### Sistema de Rechazos (`document_rejections`)

Cuando un firmante rechaza un documento:

1. **📋 Registro del rechazo** con motivo detallado
2. **🔄 Cambio de estado** a `rejected`
3. **📧 Notificación** al creador y equipo
4. **🛠️ Proceso de corrección** habilitado

### Tabla de Rechazos
```sql
CREATE TABLE public.document_rejections (
    rejection_id uuid DEFAULT gen_random_uuid() NOT NULL,
    document_id uuid NOT NULL,
    rejected_by uuid NOT NULL,
    reason text,
    rejected_at timestamp without time zone DEFAULT now(),
    audit_data jsonb
);
```

## 📊 Casos de Uso Principales

### 1. Creación de Documento Colaborativo

**Actor**: Empleado municipal  
**Objetivo**: Crear documento oficial con colaboración de equipo

**Flujo**:
1. Selecciona tipo de documento para su confección
2. Define referencia/motivo del documento
3. Sistema asigna `pad_id` para colaboración
4. Invita colegas para edición colaborativa
5. Finaliza contenido y configura firmantes

**Resultado**: Documento en estado `draft` listo para firma

### 2. Proceso de Firma Secuencial

**Actor**: Firmantes asignados  
**Objetivo**: Formalizar documento con firmas ordenadas

**Flujo**:
1. Documento llega con estado `sent_to_sign`
2. Firmante revisa contenido (solo lectura)
3. Decide: Firmar ✅ o Rechazar ❌
4. Si rechaza: ingresa motivo detallado
5. Sistema progresa al siguiente firmante o finaliza

**Resultado**: Documento `signed` o `rejected`

### 3. Gestión de Rechazo y Corrección

**Actor**: Creador del documento  
**Objetivo**: Corregir documento rechazado

**Flujo**:
1. Recibe notificación de rechazo
2. Revisa motivos en `document_rejections`
3. Reactiva editor colaborativo
4. Realiza correcciones necesarias
5. Reenvía a circuito de firmas

**Resultado**: Nueva versión mejorada del documento

### 4. Numeración y Oficialización

**Actor**: Numerador (último firmante)  
**Objetivo**: Asignar número oficial y finalizar

**Flujo**:
1. Recibe documento para numeración final
2. Sistema reserva número en `numeration_requests`
3. Firma y confirma numeración
4. Genera `official_documents` entry
5. Crea PDF firmado oficial

**Resultado**: Documento con validez legal plena

### 5. Consulta de Documentos Oficiales

**Actor**: Empleado municipal o ciudadano  
**Objetivo**: Acceder a documento oficial

**Flujo**:
1. Busca por número oficial o criterios
2. Sistema valida permisos de acceso
3. Muestra documento desde `official_documents`
4. Permite descarga de PDF firmado

**Resultado**: Acceso controlado a documento oficial

## 🔧 Componentes Técnicos Principales

### Motor de Edición
- **Document Editor Engine**: Editor enriquecido colaborativo
- **Pad Synchronization Service**: Sincronización en tiempo real

### Gestión de Firmas
- **Signing Workflow Orchestrator**: Orquestador del flujo de firmas
- **Signature Validation Service**: Validación de firmas digitales

### Numeración Oficial
- **OFFICIAL NUMBER Service**: Servicio de numeración secuencial
- **Concurrency Control**: Control de concurrencia para números únicos

### Inteligencia Artificial
- **AI Drafting Assistant (Terra)**: Asistente para redacción
- **Content Analysis**: Análisis y sugerencias de contenido

## 🔍 Trazabilidad y Auditoría

### Campos de Auditoría

Todas las tablas incluyen:
- **`audit_data`** (JSONB): Metadatos de cambios
- **Timestamps**: Creación, modificación, firma
- **User tracking**: Quién realizó cada acción

### Historial Completo

- ✅ **Creación**: Usuario, timestamp, department
- ✅ **Ediciones**: Cambios en editor colaborativo
- ✅ **Firmas**: Orden, timestamps, certificados
- ✅ **Rechazos**: Motivos, usuarios, correcciones
- ✅ **Numeración**: Proceso oficial, validaciones

## 🎖️ Validez Legal

### Requisitos para Validez Legal

Un documento alcanza **plena validez legal** cuando:

1. ✅ **Estado**: `signed`
2. ✅ **Número oficial**: Asignado en `official_documents`
3. ✅ **Numerador**: Firmado por usuario autorizado
4. ✅ **PDF firmado**: Generado y almacenado
5. ✅ **Trazabilidad**: Historial completo de firmas

### Formato de Número Oficial

```
<TIPO>-<AAAA>-<NNNNNN>-<SIGLA_ECO>-<SIGLA_DEPARTMENT>
```

**Ejemplo**: `DECRE-2025-000123-TN-INTEN`
- DECRE: Tipo (Decreto)
- 2025: Año
- 000123: Número correlativo
- TN: Municipio (Terranova)
- INTEN: Department numerador (Intendencia)

## 🚀 Beneficios del Sistema

### Para Empleados Municipales
- **⚡ Colaboración eficiente**: Editor en tiempo real
- **🔄 Proceso claro**: Estados y flujos definidos
- **❌ Gestión de errores**: Sistema robusto de correcciones

### Para la Municipalidad
- **⚖️ Validez legal garantizada**: Cumplimiento normativo
- **📊 Trazabilidad completa**: Auditoría total del proceso
- **💰 Eficiencia operativa**: Reducción de tiempos y errores
- **🔐 Seguridad robusta**: Control de acceso granular

### Para los Ciudadanos
- **🔍 Transparencia**: Acceso controlado a documentos públicos
- **⏱️ Agilidad**: Procesos más rápidos
- **✅ Confiabilidad**: Documentos con validez legal certificada

---
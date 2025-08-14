# Módulo Documentos GDI

## Índice

1. ¿Qué es el Módulo Documentos?
2. Casos de Uso Clave

## 1. ¿Qué es el Módulo Documentos?

El módulo de Documentos es el **corazón de GDI**, diseñado para la creación, gestión, colaboración y formalización de documentos electrónicos con plena validez legal. Se divide en dos aspectos clave: su configuración en el Backoffice y su uso operativo por parte de los usuarios.

### Definición de Documento

**Un Documento es:**
Cualquier entidad digitalizada que contiene información estructurada o no estructurada (texto, imágenes, tablas, etc.), generada o incorporada al sistema, con un propósito definido y que puede adquirir validez legal mediante procesos de firma y numeración. Es la unidad fundamental de información sobre la cual se construyen los expedientes y las comunicaciones.

### Características Principales

- ✅ **Validez legal**: Documentos electrónicos con plena validez jurídica
- ✅ **Colaboración**: Edición y revisión colaborativa antes de formalizar
- ✅ **Trazabilidad**: Control riguroso sobre la información oficial
- ✅ **Integración**: Base para expedientes y comunicaciones
- ✅ **Seguridad**: Integridad, autenticidad y control de acceso

## 2. Casos de Uso Clave

| Funcionalidad | Descripción |
|---------------|-------------|
| **Creación de Documentos** | Generación de nuevos documentos a partir de tipos predefinidos. |
| **Asistente de Redacción Inteligente** | Soporte de IA para la redacción, generación de contenido y adjuntos relevantes. |
| **Gestión de Permisos y Acceso** | Roles: Editor, Comentador, Lector, Sin acceso. |
| **Asignación y Flujo de Firmas** | Orquestación del proceso de firma digital/electrónica, selección de firmantes y numerador. |
| **Previsualización Dinámica** | Vistas previas en diferentes estados, con encabezados y marcas de agua según el estado. |
| **Numeración y Finalización** | Asignación de identificadores únicos y sellado del documento al firmar el numerador. |
| **Post-firma** | Acciones tras la finalización: solo lectura, descarga, impresión, vinculación a expediente. |

### Tipos de Usuarios y Roles

#### **Creador del Documento**
- Inicia el proceso de creación
- Configura firmantes y numerador
- Puede editar hasta iniciar el circuito de firmas

#### **Firmantes Intermedios**
- Revisan y firman el documento
- Acceso de solo lectura durante su turno
- Pueden rechazar y devolver a edición

#### **Numerador (Firmante Final)**
- Última firma del circuito
- Activa la numeración oficial
- Otorga validez legal definitiva

#### **Usuarios con Permisos ACL**
- Acceso mediante función "Compartir"
- Niveles: Editor, Comentador, Lector
- Solo durante estado "En Edición"

### Ciclo de Vida de un Documento

```
Creación → Edición → Previsualización → Circuito de Firmas → Documento Oficial
   ↓           ↓             ↓                ↓                     ↓
 Draft    Colaboración   Validación    Orquestación            Signed
```

### Validez Legal

**Un Documento Oficial** es aquel que ha completado exitosamente el proceso de formalización y cuenta con dos elementos que le otorgan **validez legal**:

- 🔢 **Número Oficial**: Identificador único `<TIPO>-<AAAA>-<NNNNNN>-<SIGLA_ECO>-<SIGLA_REPARTICIÓN>`
- ✍️ **Firma del Numerador**: Certificación digital que oficializa el documento

> **Importante**: Solo los documentos en estado `signed` tienen plena validez legal.

## Enlaces Relacionados

- [Flujo de Creación Completo](./02-flujo-creacion-completo.md)
- [Estados y Transiciones](./03-estados-transiciones.md)
- [Numeración y Nomenclatura](./04-numeracion-nomenclatura.md)
- [Acceso y Permisos](./05-acceso-permisos.md)
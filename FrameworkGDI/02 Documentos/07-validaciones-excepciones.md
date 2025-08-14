# Validaciones y Gestión de Excepciones

## Introducción

El módulo de Documentos de GDI implementa un sistema robusto de validaciones y manejo de excepciones para garantizar la integridad de los datos, la consistencia de los procesos y la capacidad de recuperación ante situaciones imprevistas. Este sistema opera en múltiples niveles, desde validaciones de entrada hasta gestión de casos especiales complejos.

## Validaciones del Sistema

### Validaciones de Entrada

#### Validaciones de Campos Obligatorios
- **Tipo de documento**: Debe existir y estar activo en el sistema
- **Referencia/Motivo**: Campo obligatorio con límite de caracteres
- **Firmantes**: Al menos un firmante debe estar asignado
- **Numerador**: Debe estar definido antes de iniciar el circuito

#### Validaciones de Formato
- **Longitud de referencia**: Máximo 254 caracteres
- **Caracteres permitidos**: Validación de caracteres especiales
- **Estructura de contenido**: HTML válido y bien formado

#### Validaciones de Negocio
- **Autorización de firmantes**: Verificación de permisos por tipo de documento
- **Existencia de usuarios**: Confirmación de que los firmantes existen
- **Estado de usuarios**: Verificación de que están activos en el sistema

### Validaciones por Estado

#### Estado `draft` (En Edición)
- **Contenido mínimo**: Documento debe tener contenido antes de enviar a firma
- **Firmantes configurados**: Al menos un firmante y un numerador asignados
- **Permisos de edición**: Usuario debe tener permisos para modificar

#### Estado `awaiting_signatures` (Esperando Firmas)
- **Inmutabilidad**: Validación de que el contenido no puede ser modificado
- **Integridad de firmantes**: Verificación de que los firmantes siguen activos
- **Secuencia de firmas**: Validación del orden de firmas configurado

#### Estado `signed` (Firmado)
- **Numeración válida**: Formato correcto del número oficial
- **Integridad del documento**: Validación de que no ha sido alterado
- **Firmas válidas**: Verificación de todas las firmas aplicadas

### Validaciones de Numeración

#### Formato del Número Oficial
- **Patrón válido**: `<TIPO>-<AAAA>-<NNNNNN>-<SIGLA_ECO>-<SIGLA_REPARTICIÓN>`
- **Componentes existentes**: Verificación de que cada parte es válida
- **Unicidad global**: Confirmación de que el número no existe

#### Secuencialidad
- **Orden cronológico**: Los números deben ser secuenciales por tipo
- **Sin duplicados**: Prevención de números repetidos
- **Sin saltos**: Detección de brechas en la secuencia

### Validaciones de Permisos

#### Validaciones RBAC
- **Pertenencia a repartición**: Usuario debe pertenecer a repartición autorizada
- **Rol activo**: Verificación de que el rol sigue vigente
- **Permisos por tipo**: Validación específica por tipo de documento

#### Validaciones ACL
- **Permisos explícitos**: Verificación de permisos otorgados directamente
- **Vigencia temporal**: Validación de fechas de expiración
- **Jerarquía de permisos**: Resolución de conflictos entre RBAC y ACL

## Gestión de Excepciones y Casos Especiales

### Casos Resueltos en el Sistema Actual

#### Rechazo de Documentos

**Comportamiento:**
- Cualquier firmante puede rechazar un documento en cualquier momento del proceso
- El rechazo es inmediato e irreversible para esa instancia del proceso

**Resultado:**
- El documento regresa automáticamente al estado "En Edición"
- Se mantiene todo el contenido y configuración original
- Se registra auditoría completa del rechazo

**Proceso de Recuperación:**
1. **Notificación automática**: El creador recibe notificación inmediata
2. **Acceso restaurado**: Recupera capacidad de edición completa
3. **Correcciones**: Puede realizar cambios según motivo del rechazo
4. **Reinicio**: Puede iniciar nuevamente el proceso de firmas

**Auditoría del Rechazo:**
- Usuario que rechazó el documento
- Timestamp exacto del rechazo
- Motivo del rechazo (si se proporciona)
- Estado previo del documento

#### Integridad de Numeración

**Prevención de Problemas:**
- **Servicio NUMERADOR_OFICIAL**: Garantiza secuencialidad atómica
- **Bloqueos de concurrencia**: Previene asignación simultánea
- **Validaciones cruzadas**: Verificación múltiple antes de asignar

**Control de Calidad:**
- **Funciones de base de datos**: Constraints que previenen duplicados
- **Verificación automática**: Checks periódicos de integridad
- **Alertas tempranas**: Notificación de inconsistencias

**Consistencia Garantizada:**
- **No documentos huérfanos**: La numeración solo ocurre al completar exitosamente
- **Rollback automático**: Reversión en caso de falla durante asignación
- **Recuperación**: Procedimientos para restaurar secuencias dañadas

#### Verificación de Autorización en Tiempo Real

**Validación Continua:**
- **Al momento de firma**: Verificación de titularidad actual
- **Durante el proceso**: Monitoreo de cambios de permisos
- **Antes de numeración**: Validación final del numerador

**Cambios Durante el Proceso:**
- **Pérdida de titularidad**: Bloqueo automático del proceso
- **Cambio de repartición**: Invalidación inmediata de permisos
- **Desactivación de usuario**: Suspensión del proceso

**Resolución de Conflictos:**
- **Única opción**: Cancelar proceso y reasignar firmantes
- **Notificación**: Alerta a todos los participantes
- **Auditoría**: Registro completo del conflicto y resolución

### Limitaciones Actuales del Sistema

#### Gestión de Ausencias

**Estado Actual:**
- No existe sistema automatizado de licencias o delegación temporal
- No hay mecanismo de escalación por inactividad
- Dependencia total de la disponibilidad del firmante

**Impacto:**
- Si un firmante clave no está disponible, el proceso se detiene indefinidamente
- No hay alertas automáticas por documentos estancados
- Requiere intervención manual para resolución

**Resolución Temporal:**
- Cancelación manual del proceso de firma
- Reasignación manual de firmantes
- Reinicio completo del circuito de firmas

**Mitigaciones Actuales:**
- Definición de múltiples firmantes cuando sea posible
- Comunicación previa sobre disponibilidad
- Procesos manuales de escalación

#### Edición Colaborativa

**Estado Actual:**
- No hay sistema de edición simultánea en tiempo real
- Sin control de versiones durante edición activa
- Sin indicadores de presencia de otros editores

**Limitaciones:**
- Riesgo de sobreescritura si múltiples usuarios editan
- Pérdida de cambios cuando hay conflictos
- Falta de sincronización entre editores

**Enfoque Actual:**
- Modelo de "un usuario por vez" en modo edición
- Autoguardado periódico para prevenir pérdida
- Mensajes de advertencia sobre conflictos

**Impacto:**
- Proceso de edición más lento en documentos complejos
- Necesidad de coordinación manual entre editores
- Posible frustración de usuarios en equipos colaborativos

#### Timeouts de Proceso

**Estado Actual:**
- No hay límites de tiempo configurables para procesos de firma
- Sin escalación automática por inactividad
- No hay alertas por documentos pendientes

**Implicaciones:**
- Los documentos pueden quedar indefinidamente en circuito
- Acumulación de procesos estancados
- Falta de visibilidad sobre documentos atrasados

**Gestión Manual:**
- Requiere monitoreo activo de procesos pendientes
- Intervención administrativa para resolución
- Comunicación manual con firmantes inactivos

### Casos No Contemplados (Requieren Desarrollo Futuro)

#### Delegación Temporal de Firmas

**Necesidad Identificada:**
- Gestión de ausencias por licencias, vacaciones o enfermedad
- Delegación de autoridad temporal a subordinados
- Continuidad de procesos críticos

**Funcionalidad Requerida:**
- Sistema de delegación configurable por usuario
- Validación de autoridad para delegar
- Límites temporales automáticos
- Auditoría completa de delegaciones

#### Escalación Automática

**Necesidad Identificada:**
- Procesos estancados por inactividad de firmantes
- Documentos críticos que requieren procesamiento urgente
- Alertas automáticas a supervisores

**Funcionalidad Requerida:**
- Configuración de tiempos límite por tipo de documento
- Jerarquías de escalación automática
- Notificaciones progresivas
- Bypass temporal para emergencias

#### Recuperación de Procesos Interrumpidos

**Necesidad Identificada:**
- Cambios organizacionales durante procesos activos
- Restructuraciones que afectan firmantes asignados
- Continuidad ante cambios de personal

**Funcionalidad Requerida:**
- Detección automática de cambios organizacionales
- Reasignación inteligente de firmantes
- Preservación del progreso del proceso
- Notificación de cambios a participantes

#### Edición Colaborativa en Tiempo Real

**Necesidad Identificada:**
- Trabajo simultáneo en documentos complejos
- Eficiencia en procesos de revisión
- Transparencia en cambios colaborativos

**Funcionalidad Requerida:**
- Edición simultánea con resolución de conflictos
- Indicadores de presencia de otros editores
- Control de versiones granular
- Comentarios y sugerencias en tiempo real

#### Archivado Automático

**Necesidad Identificada:**
- Gestión de documentos abandonados en estado draft
- Limpieza automática de procesos inactivos
- Optimización del rendimiento del sistema

**Funcionalidad Requerida:**
- Políticas configurables de archivado
- Notificaciones previas al archivado
- Capacidad de recuperación de archivos
- Métricas sobre documentos archivados

## Estrategias de Manejo de Errores

### Errores de Validación

#### Estrategia de Respuesta
- **Validación temprana**: Verificación en el frontend antes de envío
- **Mensajes claros**: Descripción específica del error y cómo corregirlo
- **Validación incremental**: Verificación paso a paso durante el proceso

#### Tipos de Errores
- **Errores de formato**: Datos que no cumplen con formato esperado
- **Errores de negocio**: Violaciones de reglas específicas del dominio
- **Errores de permisos**: Intentos de acceso no autorizado

### Errores de Sistema

#### Estrategia de Recuperación
- **Rollback automático**: Reversión de cambios parciales
- **Reintentos inteligentes**: Reintento con backoff exponencial
- **Degradación controlada**: Funcionalidad reducida pero operativa

#### Monitoreo y Alertas
- **Logs centralizados**: Registro detallado de todos los errores
- **Métricas en tiempo real**: Dashboards de salud del sistema
- **Alertas automáticas**: Notificación inmediata de errores críticos

### Errores de Integración

#### Servicios Externos
- **Circuit breakers**: Protección contra servicios externos fallidos
- **Fallback strategies**: Alternativas cuando servicios no están disponibles
- **Monitoreo de dependencias**: Verificación continua de servicios críticos

## Auditoría y Trazabilidad de Excepciones

### Registro de Eventos

#### Información Capturada
- **Timestamp exacto**: Momento del evento o error
- **Usuario afectado**: Identificación del usuario involucrado
- **Acción intentada**: Descripción de la operación que falló
- **Error específico**: Mensaje de error detallado
- **Contexto del sistema**: Estado del sistema al momento del error

#### Categorización
- **Errores de usuario**: Acciones incorrectas del usuario
- **Errores de sistema**: Fallos técnicos internos
- **Errores de integración**: Problemas con servicios externos
- **Errores de configuración**: Problemas de configuración del sistema

### Análisis y Métricas

#### Dashboards de Errores
- **Frecuencia por tipo**: Análisis de patrones de errores
- **Tendencias temporales**: Identificación de picos de errores
- **Afectación por usuario**: Usuarios con más errores
- **Resolución**: Tiempo promedio de resolución

#### Mejora Continua
- **Análisis de causa raíz**: Investigación profunda de errores recurrentes
- **Optimización de validaciones**: Mejora basada en errores frecuentes
- **Capacitación de usuarios**: Educación sobre errores comunes
- **Evolución del sistema**: Mejoras para prevenir errores futuros

## Enlaces Relacionados

- [Componentes Técnicos y Datos](./06-componentes-datos.md)
- [Seguridad](./08-seguridad.md)
- [Estados y Transiciones](./03-estados-transiciones.md)
- [Acceso y Permisos](./05-acceso-permisos.md)
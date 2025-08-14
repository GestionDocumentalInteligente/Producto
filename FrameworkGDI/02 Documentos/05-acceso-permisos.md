# Reglas de Acceso y Permisos

## Introducción

El sistema de acceso y permisos de GDI está diseñado para garantizar la seguridad y privacidad de los documentos, mientras permite la colaboración necesaria entre usuarios y reparticiones. El control se basa en la pertenencia organizacional, el estado del documento y permisos específicos otorgados.

## Reglas Generales de Visibilidad

### Principio de Pertenencia
- **Acceso por Repartición**: Los usuarios de una repartición ven únicamente los documentos de su repartición
- **Privacidad por defecto**: Los documentos en desarrollo no son visibles fuera de la repartición de origen
- **Búsqueda restringida**: Los documentos de otras reparticiones solo son accesibles mediante búsqueda por número oficial

### Niveles de Acceso
- **Acceso completo**: Crear, editar, compartir, eliminar
- **Solo lectura**: Visualizar contenido sin modificar
- **Sin acceso**: El documento no es visible para el usuario

## Acceso por Estado del Documento

### Estado `draft` (En Edición)

#### Acceso Completo
- **Creador del documento**: Acceso total para edición y configuración
- **Usuarios con permisos ACL**: Según nivel asignado (Editor, Comentador, Lector)

#### Acciones Permitidas
- ✅ Editar contenido
- ✅ Modificar configuración de firmantes
- ✅ Compartir con otros usuarios
- ✅ Previsualizar
- ✅ Eliminar documento

#### Restricciones
- ❌ Solo visible dentro de la repartición (excepto si está compartido)
- ❌ No indexado en búsquedas globales

### Estado `awaiting_signatures` (Esperando Firmas)

#### Acceso de Solo Lectura
- **Firmantes asignados**: Pueden revisar el contenido completo
- **Usuarios con permisos ACL**: Mantienen acceso según nivel configurado
- **Creador**: Solo lectura, sin capacidad de edición

#### Acciones Permitidas
- ✅ Ver contenido completo
- ✅ Descargar PDF
- ✅ Ver estado de firmas
- ✅ Firmar (solo firmantes autorizados)

#### Restricciones
- ❌ **Inmutabilidad total**: No se puede editar contenido
- ❌ No se pueden modificar firmantes
- ❌ No se puede compartir con nuevos usuarios

### Estado `signed` (Firmado)

#### Acceso Público Restringido
- **Dentro de la repartición**: Acceso de lectura para todos los usuarios
- **Otras reparticiones**: Solo accesible por búsqueda de número oficial
- **Usuarios con permisos ACL**: Mantienen acceso histórico

#### Acciones Permitidas
- ✅ Ver contenido completo
- ✅ Descargar PDF oficial
- ✅ Imprimir
- ✅ Vincular a expedientes
- ✅ Usar en referencias

#### Restricciones
- ❌ **Documento inmutable**: No se puede modificar
- ❌ No se pueden cambiar permisos
- ❌ No se puede eliminar

## Sistema de Compartir (ACL)

### Funcionalidad de Compartir

La única excepción a la visibilidad restringida es cuando un documento ha sido explícitamente compartido con el usuario a través de la funcionalidad de Compartir. En este caso, el Access Control Manager (ACM) otorga permisos específicos a nivel de objeto (ACLs) que permiten al usuario acceder al documento compartido, independientemente de su repartición de origen.

### Estados Aplicables
- **Solo en estado `draft`**: La función compartir está disponible únicamente para documentos en edición
- **Herencia de permisos**: Los permisos se mantienen cuando el documento cambia de estado
- **Revocación**: Los permisos pueden ser revocados en cualquier momento

### Niveles de Permisos ACL

#### Editor
- **Acceso**: Completo al documento
- **Acciones**:
  - ✅ Ver contenido
  - ✅ Editar contenido
  - ✅ Modificar configuración
  - ✅ Agregar comentarios
  - ✅ Compartir con otros usuarios

#### Comentador
- **Acceso**: Lectura y comentarios
- **Acciones**:
  - ✅ Ver contenido
  - ✅ Agregar comentarios
  - ✅ Responder comentarios
  - ❌ Editar contenido
  - ❌ Modificar configuración

#### Lector
- **Acceso**: Solo lectura
- **Acciones**:
  - ✅ Ver contenido
  - ✅ Descargar PDF
  - ❌ Editar contenido
  - ❌ Agregar comentarios
  - ❌ Compartir

#### Sin Acceso
- **Revocación**: El documento deja de ser visible para el usuario
- **Efecto**: Como si nunca hubiera sido compartido

### Gestión de Permisos Compartidos

#### Proceso de Compartir
1. **Creador/Editor** selecciona "Compartir documento"
2. **Busca usuario** por nombre o email
3. **Asigna nivel de permiso** (Editor, Comentador, Lector)
4. **Usuario notificado** por email
5. **Acceso inmediato** al documento compartido

#### Modificación de Permisos
- **Cambio de nivel**: Actualización inmediata de capacidades
- **Revocación**: Pérdida inmediata de acceso
- **Historial**: Auditoría completa de cambios de permisos

### Auditoría de Compartir

#### Registro de Eventos
- **Quién compartió**: Usuario que otorgó el permiso
- **Con quién**: Usuario que recibió el acceso
- **Cuándo**: Timestamp exacto de la acción
- **Qué nivel**: Tipo de permiso otorgado
- **Cambios**: Modificaciones posteriores de permisos

#### Consulta de Auditoría
- **Panel de administrador**: Vista de todos los documentos compartidos
- **Filtros disponibles**: Por usuario, fecha, tipo de permiso
- **Exportación**: Reportes de auditoría en CSV/PDF

## Control de Acceso por Firmantes

### Validación de Autorización para Firmar

#### Verificaciones en Tiempo Real
- **Titularidad activa**: Validación de que el usuario sigue siendo titular
- **Permisos específicos**: Verificación según configuración del tipo de documento
- **Estado del usuario**: Confirmación de que está activo en el sistema

#### Cambios Durante el Proceso
- **Pérdida de titularidad**: Bloqueo automático del proceso de firma
- **Cambio de repartición**: Invalidación de permisos de firma
- **Única resolución**: Cancelar proceso y reasignar firmantes

### Acceso de Firmantes

#### Durante el Proceso
- **Estado personal**: `firmar_ahora` cuando es su turno
- **Acceso completo**: Revisión total del documento
- **Capacidades**: Firmar o rechazar únicamente

#### Después de Firmar
- **Acceso mantenido**: Continúa viendo el documento
- **Solo lectura**: Sin capacidad de modificación
- **Notificaciones**: Informado de cambios de estado

## Búsqueda y Descubrimiento

### Búsqueda por Número Oficial

#### Acceso Global
- **Documentos firmados**: Búsqueda por número oficial desde cualquier repartición
- **Validación**: Solo documentos en estado `signed`
- **Resultado**: Acceso de solo lectura al documento

#### Casos de Uso
- **Referencias legales**: Citar documentos oficiales
- **Expedientes**: Vincular documentos existentes
- **Auditoría**: Verificar documentos específicos

### Limitaciones de Búsqueda
- **Documentos en borrador**: No aparecen en búsquedas globales
- **Documentos en firma**: No son descubribles por otras reparticiones
- **Permisos ACL**: No afectan la capacidad de búsqueda global

## Casos Especiales

### Transferencia de Personal
- **Cambio de repartición**: Pérdida de acceso a documentos de repartición anterior
- **Documentos compartidos**: Se mantienen los permisos ACL otorgados
- **Documentos creados**: Permanecen en la repartición original

### Documentos Huérfanos
- **Usuario eliminado**: Los documentos permanecen en la repartición
- **Repartición disuelta**: Transferencia controlada a repartición sucesora
- **Acceso administrativo**: Super-admins pueden gestionar documentos huérfanos

### Situaciones de Emergencia
- **Acceso de emergencia**: Procedimientos para casos críticos
- **Bypass temporal**: Solo con autorización de super-administrador
- **Auditoría especial**: Registro detallado de accesos de emergencia

## Mejores Prácticas

### Para Usuarios
- **Principio de menor privilegio**: Compartir solo con quienes necesitan acceso
- **Revisión periódica**: Verificar y revocar permisos innecesarios
- **Documentación**: Dejar claro el propósito del acceso compartido

### Para Administradores
- **Monitoreo regular**: Revisión de patrones de acceso inusuales
- **Políticas claras**: Definir reglas organizacionales para compartir
- **Capacitación**: Educar a usuarios sobre seguridad de documentos

## Enlaces Relacionados

- [Estados y Transiciones](./03-estados-transiciones.md)
- [Numeración y Nomenclatura](./04-numeracion-nomenclatura.md)
- [Componentes Técnicos](./06-componentes-datos.md)
- [Seguridad](./08-seguridad.md)
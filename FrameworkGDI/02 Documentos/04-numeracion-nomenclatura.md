# Nomenclatura y Numeración de IDs

## Introducción

La asignación de identificadores únicos a los documentos en GDI es un proceso fundamental que garantiza la trazabilidad, la unicidad y la fácil identificación de cada pieza de información dentro del sistema. La nomenclatura sigue un formato estandarizado, pero su comportamiento se adapta inteligentemente al tipo de documento, distinguiendo entre aquellos con carácter administrativo y los de uso general.

## Formato Estándar de Numeración

### Estructura del ID
```
<TIPO>-<AAAA>-<NNNNNN>-<SIGLA_ECO>-<SIGLA_REPARTICIÓN>
```

### Componentes del Formato

| **Componente** | **Descripción** | **Ejemplo** |
|----------------|-----------------|-------------|
| **TIPO** | Código del tipo de documento | IF, ACT, DECRE |
| **AAAA** | Año de la fecha oficial | 2025 |
| **NNNNNN** | Número secuencial cronológico | 000123 |
| **SIGLA_ECO** | Sigla de la municipalidad | TN (Terranova) |
| **SIGLA_REPARTICIÓN** | Sigla de la repartición del numerador | SEGOB |

### Ejemplos Completos

```
IF-2025-000123-TN-SEGOB
DECRE-2025-000045-TN-INTEN
ACT-2025-000789-TN-DIREC
```

## Escenarios de Numeración de Documentos

### Documentos con Carácter de Acto Administrativo

#### Características:
- **Integración con numeración histórica**: El sistema permite continuar la secuencia de documentos físicos existentes
- **Configuración inicial**: En el BackOffice se solicita el último número oficial del año actual
- **Propósito**: Mantener correlación con sistemas previos y asegurar continuidad

#### Proceso:
1. **Configuración en BackOffice**: Se ingresa el último número usado en formato papel
2. **Autoincremento**: El sistema continúa la secuencia desde ese número
3. **Validación**: Se verifica que no existan duplicados en el sistema

#### Ejemplos:
```
DECRE-2025-000067-TN-INTEN    (continúa desde decreto papel #66)
RESOL-2025-000234-TN-SEGOB    (continúa desde resolución papel #233)
```

### Documentos sin Carácter de Acto Administrativo

#### Características:
- **Numeración correlativa**: Secuencial desde cero cada año
- **Autoincremento**: El NNNNNN se incrementa automáticamente
- **Gestión centralizada**: El servicio OFFICIAL NUMBER maneja la secuencia

#### Proceso:
1. **Inicio de año**: Secuencia comienza en 000001
2. **Autoincremento**: Cada nuevo documento incrementa el número
3. **Gestión automática**: Sin intervención manual necesaria

#### Ejemplos:
```
IF-2025-000001-TN-SEGOB      (primer informe del año)
NO-2025-000001-TN-DIREC      (primera nota del año)
ME-2025-000001-TN-MESA       (primer memo del año)
```

## Servicio OFFICIAL NUMBER

### Funcionalidades

#### Generación Atómica
- **Concurrencia**: Manejo de múltiples solicitudes simultáneas
- **Unicidad**: Garantía de números únicos sin duplicados
- **Secuencialidad**: Números consecutivos sin saltos

#### Gestión por Tipo
- **Secuencias independientes**: Cada tipo de documento tiene su propia numeración
- **Reseteo anual**: Las secuencias se reinician cada año
- **Configuración flexible**: Diferentes comportamientos según el tipo

#### Integridad de Datos
- **Funciones de BD**: Prevención de duplicados a nivel de base de datos
- **Validación de formato**: Verificación del patrón estándar
- **No documentos huérfanos**: La numeración solo ocurre al completar exitosamente

### Algoritmo de Asignación

```
1. Firmante final (numerador) completa su firma
2. Sistema consulta OFFICIAL NUMBER para el tipo de documento
3. Se verifica la repartición del numerador
4. Se genera el número secuencial correspondiente
5. Se construye el ID completo con todos los componentes
6. Se asigna permanentemente al documento
7. Se actualiza el contador para el próximo documento
```

## Construcción del ID Completo

### Obtención de Componentes

#### TIPO
- **Fuente**: Configuración del tipo de documento en BackOffice
- **Formato**: 2-5 caracteres alfanuméricos en mayúsculas
- **Ejemplos**: IF, DECRE, RESOL, ACT

#### AAAA (Año)
- **Fuente**: Timestamp de la firma del numerador
- **Formato**: 4 dígitos del año
- **Importante**: Se usa el año de la firma oficial, no de creación

#### NNNNNN (Número Secuencial)
- **Fuente**: Servicio OFFICIAL NUMBER
- **Formato**: 6 dígitos con ceros a la izquierda
- **Rango**: 000001 a 999999

#### SIGLA_ECO (Ecosistema/Municipalidad)
- **Fuente**: Configuración general del sistema
- **Definido en**: BackOffice → Información General
- **Ejemplos**: TN, BA, SF

#### SIGLA_REPARTICIÓN
- **Fuente**: Repartición del usuario numerador
- **Determinado por**: Quién realiza la última firma
- **Importante**: NO es la repartición creadora, sino la del numerador

### Proceso de Validación

#### Verificaciones Automáticas
1. **Formato válido**: Cumple con el patrón establecido
2. **Componentes válidos**: Cada parte existe y es correcta
3. **Unicidad global**: No existe otro documento con el mismo ID
4. **Autorización**: El numerador tiene permisos para ese tipo de documento

#### Casos de Error
- **Tipo inexistente**: El tipo de documento no está configurado
- **Numerador inválido**: Usuario sin permisos para numerar
- **Cambio de año**: Manejo especial en el cambio de año
- **Límite alcanzado**: Secuencia llegó a 999999

## Consideraciones Especiales

### Cambio de Año
- **Reseteo automático**: Las secuencias vuelven a 000001
- **Proceso**: Ocurre automáticamente en la primera numeración del año
- **Auditoría**: Se registra el cambio de año en los logs

### Migración de Sistemas
- **Importación**: Posibilidad de importar numeración existente
- **Validación**: Verificación de no duplicados durante migración
- **Continuidad**: Mantener la secuencia histórica

### Respaldo y Recuperación
- **Backup**: Los contadores se respaldan regularmente
- **Recuperación**: Procedimientos para restaurar secuencias
- **Verificación**: Controles de integridad post-recuperación

## Enlaces Relacionados

- [Estados y Transiciones](./03-estados-transiciones.md)
- [Flujo de Creación Completo](./02-flujo-creacion-completo.md)
- [Acceso y Permisos](./05-acceso-permisos.md)
- [Componentes Técnicos](./06-componentes-datos.md)
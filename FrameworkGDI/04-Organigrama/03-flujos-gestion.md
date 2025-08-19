# Flujos de Gestión del Organigrama

## 4.1 Sección "Mi Equipo" - Vista para Agentes

<!-- [IMAGEN PANTALLA - Vista Agente Mi Equipo] -->

Cuando un **agente** entra a "Mi Equipo":

### Pestaña "Organización":
- En el panel izquierdo ve su repartición
- Ve tabs de sectores de su repartición (ej: "Sector Privado", "Sector 1", "Sector 2")
- Por defecto ve su propio sector
- Puede hacer click en otros tabs para ver otros sectores de la misma repartición
- Cada sector muestra los usuarios en formato de cards

### Pestaña "Usuarios":
- Ve una lista completa de TODOS los usuarios de su repartición
- Cada usuario muestra a qué sector pertenece (con tags)
- Vista unificada sin importar el sector

## 4.2 Sección "Mi Equipo" - Vista para Titulares

Cuando un **titular** entra a "Mi Equipo":

### Pestaña "Organización":
- Ve exactamente lo mismo que un agente de su repartición
- Tabs de sectores de su repartición
- Puede navegar entre sectores

### Pestaña "Usuarios":
- Ve la lista completa de usuarios de su repartición
- Cada usuario con su tag de sector

### Diferencia clave - Gestión:
- El titular ve botones y opciones de gestión
- Puede dar de **alta** nuevos usuarios
- Puede dar de **baja** usuarios existentes
- Puede **pausar** usuarios (ej: por licencia)

## 4.3 Flujo de Alta de Usuario (Solo Titulares)

<!-- [IMAGEN FLUJO - Proceso Alta Usuario] -->

### Proceso de alta de usuario:

**Paso 1:** Titular hace click en botón "Agregar"

**Paso 2:** Se abre formulario con datos mínimos requeridos:
- **CUIL**: Para identificación única del usuario
- **Email**: Para envío de invitación
- **Sector**: Dropdown con sectores de su repartición
- **Cargo**: Descripción del puesto

**Paso 3:** Sistema valida datos y crea usuario en estado "pendiente_activacion"

**Paso 4:** Sistema envía invitación por email con link de activación

**Paso 5:** La persona recibe invitación y accede al sistema (vía ARCA u otro método)

**Paso 6:** La persona completa sus datos personales:
- Nombre y Apellido
- DNI
- Celular
- País
- Otros datos requeridos

**Paso 7:** Sistema valida CUIL con datos ingresados y activa la cuenta

**Paso 8:** Usuario aparece como "activo" en la lista del titular

## 4.4 Gestión de Estados de Usuario (Solo Titulares)

### Pausar Usuario:
- Usuario mantiene acceso limitado
- Útil para licencias temporales
- El usuario puede consultar pero no gestionar

### Dar de Baja Usuario:
- Usuario pierde acceso completo al sistema
- Para desvinculaciones permanentes
- Se mantiene el registro histórico

### Reactivar Usuario:
- Vuelve a estado activo
- Recupera acceso completo
- Se restauran todos los permisos anteriores

### Estados disponibles:
- **Activo**: Acceso completo al sistema
- **Pausado**: Acceso limitado/solo consulta
- **Inactivo**: Sin acceso al sistema
- **Pendiente activación**: Usuario creado pero no activado
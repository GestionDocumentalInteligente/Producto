# GDI: Gestión Documental Inteligente


**Documentación Técnica** | Versión del documento: v1.0

## Propósito del Documento

Este documento es la fuente de verdad central y el punto de partida para cualquier miembro del equipo técnico que necesite comprender la estructura, el funcionamiento y la configuración del producto GDI a un nivel técnico profundo. Su propósito es:

* Acelerar la curva de aprendizaje de nuevos integrantes.
* Asegurar una comprensión unificada y consistente del sistema.
* Servir como referencia técnica para la toma de decisiones de diseño y desarrollo.

Esta documentación está dirigida a:


* Desarrolladores de software (nuevos y existentes).
* Ingenieros de QA (Quality Assurance).
* Arquitectos de software.
* Líderes técnicos.
* Sistemas de Inteligencia Artificial (IA) diseñados para comprender y asistir en el desarrollo y la gestión de productos de software.

## Visión General del Producto y su Framework

### ¿Qué es GDI?

GDI (Gestión Documental Inteligente) es la evolución natural del GDE (Gestión Documental Electrónica), diseñada bajo su normativa y optimizada específicamente para el ámbito municipal. Es una plataforma integral que transforma los procesos administrativos rígidos en flujos de trabajo dinámicos, flexibles y colaborativos, con el objetivo primordial de eliminar la burocracia y reducir drásticamente los tiempos de procesamiento.

Construida sobre principios de software libre y arquitectura abierta, GDI aborda las limitaciones de los sistemas anteriores, ofreciendo una solución robusta, escalable y colaborativa. Su diseño usuario-céntrico y la integración de tecnologías de vanguardia buscan redefinir la interacción entre la ciudadanía y la administración, siendo sus usuarios principales los empleados municipales y funcionarios que operan dentro de un organismo en la gestión de una ciudad.

### Propuesta de Valor Técnica y Factores diferenciadores

GDI se distingue por una serie de atributos técnicos y operativos clave que lo posicionan como una solución superior en el ámbito de la gestión documental pública:

**Interoperabilidad y Enfoque LATAM**: Diseñado con un modelo API-first y basado en estándares abiertos, GDI facilita la integración fluida con sistemas heterogéneos y promueve la estandarización a nivel LATAM. Esto permite la conexión y el intercambio de datos entre diversas entidades, construyendo un estándar digital único.

**Experiencia de Usuario (UX) Optimizada**: Las interfaces de usuario (UI) son meticulosamente diseñadas siguiendo los últimos estándares UI/UX, lo que se traduce en una curva de aprendizaje mínima y una productividad maximizada para todos los perfiles de usuario, desde operadores hasta administradores.

**Eficiencia de Costos y Sostenibilidad**: Al adoptar un modelo de software libre (licencia AGPLv3), GDI elimina los costos asociados a licencias propietarias y reduce significativamente los gastos operativos. Esto democratiza el acceso a tecnología de punta, permitiendo a las jurisdicciones reinvertir recursos en otras áreas críticas.

**Escalabilidad y Flexibilidad Arquitectónica**: Su arquitectura modular y distribuida permite una adaptación granular a las necesidades específicas de cada municipio o entidad, independientemente de su tamaño o complejidad. Esto asegura una escalabilidad horizontal y una implementación ágil en diversos entornos de despliegue (on-premise, cloud).

**Soberanía Tecnológica**: La elección de código abierto garantiza el control total sobre el stack tecnológico, eliminando el vendor lock-in y fomentando la autonomía digital de las instituciones. Permite la auditoría, personalización y evolución del sistema por parte de la propia comunidad.

### Contexto y Antecedentes

#### Evolución de la Gestión Documental Electrónica

La digitalización de la gestión pública en Argentina avanzó gradualmente con la implementación de sistemas como SADE (GCBA, 2009), GDE (nacional) y GDEBA (Provincia de Buenos Aires). Actualmente, más de 180 organismos operan en esta plataforma, sentando las bases para la transformación digital al migrar del papel a procesos optimizados.

Sin embargo, a pesar de estos avances, los sistemas de gestión documental electrónica existentes presentan limitaciones estructurales que obstaculizan una transformación digital integral:

* **Arquitecturas Obsoletas**: Monolitos con baja escalabilidad y dificultades para migrar a la nube.
* **Dependencia de Software Propietario**: Altos costos de licencias y barreras para integrar nuevas funcionalidades.
* **Escalabilidad Limitada**: Soluciones locales acotadas, sin visión abierta ni crecimiento horizontal.
* **Desafíos de Interoperabilidad**: La falta de estándares abiertos y APIs bien definidas genera silos de información y dificulta el intercambio fluido de datos entre diferentes sistemas, impidiendo una gestión pública verdaderamente integrada y eficiente.

Estas limitaciones refuerzan la necesidad de un sistema abierto y colaborativo, diseñado con el lenguaje del nuevo mundo digital.

### Nuestra Propuesta: la solución GDI

GDI aborda los desafíos identificados mediante un enfoque moderno y abierto, centrado en la flexibilidad, la eficiencia y la colaboración:

* **Arquitectura de Microservicios y Despliegue Cloud-Native**: Basada en microservicios desacoplados, lo que permite un desarrollo ágil, despliegue independiente de componentes y una escalabilidad horizontal elástica, optimizada para entornos de nube.

* **Integración Nativa de Tecnologías Emergentes**: Incluye funcionalidades avanzadas como la firma digital con plena validez jurídica, y una Asistencia de Redacción Inteligente impulsada por IA/RAG que facilita la creación de documentos con un tono establecido, la adjunción de referencias de expedientes y la generación de informes. Además, la Inteligencia Artificial (IA) nativa se utiliza para la automatización de procesos, clasificación y análisis de datos, transformando la gestión documental en una operación inteligente.

* **Paneles de Control (Dashboards IA) Personalizables**: Herramientas de visualización de datos intuitivas y configurables que permiten a los usuarios y administradores monitorear el rendimiento, la eficiencia y el estado de los procesos en tiempo real, facilitando la toma de decisiones basada en datos.

* **Modelo de Gobernanza Abierta y Colaborativa**: Distribuido bajo la licencia AGPLv3, GDI fomenta una comunidad activa de desarrolladores y usuarios. Este modelo de innovación abierta asegura la sostenibilidad, la evolución continua y la adaptación del sistema a las necesidades cambiantes, garantizando la soberanía digital y evitando el vendor lock-in.

### Módulos principales del sistema 

Los módulos principales son los pilares sobre los que se construye la gestión documental y organizacional de una ciudad. Cada uno representa un componente central del sistema, con funcionalidades específicas y profundas para la administración de recursos clave.

###  Documentos
El Módulo Documentos es el corazón de la gestión documental en GDI. Ofrece una gestión integral del ciclo de vida de todos los documentos, desde su creación hasta su archivo definitivo. Permite a los usuarios crear, editar, vincular  y buscar documentos. Asegura la integridad, autenticidad y trazabilidad de cada documento, garantizando un control riguroso sobre la información oficial.
###  Expedientes
El Módulo Expedientes es el contenedor digital para la gestión de trámites y procesos administrativos. Permite la gestión integral de expedientes creados por repartición o sector, incluyendo la capacidad de registrar actuaciones, realizar seguimiento de procesos, y gestionar todas las interacciones administrativas relacionadas. Facilita la colaboración inter-áreas y asegura la trazabilidad completa del ciclo de vida de cada trámite.
###  Organigrama
El Módulo Organigrama es la columna vertebral para la administración de la estructura interna de la municipalidad dentro del sistema. Su propósito fundamental es centralizar la gestión de usuarios, roles, reparticiones y la jerarquía organizacional, asegurando que el acceso y las responsabilidades se alineen con la estructura real de la entidad. Este módulo es esencial para mantener la coherencia operativa y la seguridad en todas las interacciones dentro del sistema.

<video width="99%" muted playsInline controls={true}>
  <source
    src="https://xguihxuzqibwxjnimxev.supabase.co/storage/v1/object/public/videos/docs/favorites.mp4"
    type="video/mp4"
  />
</video>








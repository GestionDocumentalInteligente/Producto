

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."estado_documento_enum" AS ENUM (
    'PENDIENTE_FIRMA',
    'FIRMADO',
    'ANULADO'
);


ALTER TYPE "public"."estado_documento_enum" OWNER TO "postgres";


CREATE TYPE "public"."estado_firma_enum" AS ENUM (
    'PENDIENTE',
    'FIRMADO',
    'RECHAZADO'
);


ALTER TYPE "public"."estado_firma_enum" OWNER TO "postgres";


CREATE TYPE "public"."firma_requerida_enum" AS ENUM (
    'ELECTRONICA_TODOS',
    'DIGITAL_TODOS',
    'DIGITAL_NUMERADOR'
);


ALTER TYPE "public"."firma_requerida_enum" OWNER TO "postgres";


CREATE TYPE "public"."pais_enum" AS ENUM (
    'AR',
    'BO',
    'BR',
    'CA',
    'CL',
    'CO',
    'CR',
    'CU',
    'DO',
    'EC',
    'SV',
    'GT',
    'HN',
    'MX',
    'NI',
    'PA',
    'PY',
    'PE',
    'UY',
    'US',
    'VE'
);


ALTER TYPE "public"."pais_enum" OWNER TO "postgres";


COMMENT ON TYPE "public"."pais_enum" IS 'Define los códigos de país estándar (ISO 3166-1 alfa-2) soportados por el sistema.';



CREATE OR REPLACE FUNCTION "public"."firmar_y_numerar_documento"("p_id_documento" "uuid", "p_id_usuario" "uuid", "p_id_tipo_documento" "uuid", "p_id_reparticion" "uuid" DEFAULT NULL::"uuid") RETURNS integer
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    habilitado_por_rango BOOLEAN;
    habilitado_por_reparticion BOOLEAN;
    nuevo_numero INTEGER;
    numerador_id INTEGER;
    v_zona_horaria VARCHAR(50);
    v_anio SMALLINT;
BEGIN
    -- Validar por rango (el usuario debe ser titular de la repartición)
    SELECT EXISTS (
        SELECT 1
        FROM tipos_documentos_habilitados_por_rango tdr
        JOIN usuarios u ON u.id_usuario = p_id_usuario
        JOIN reparticiones r ON r.id_reparticion = u.id_reparticion
        WHERE tdr.id_tipo_documento = p_id_tipo_documento
          AND tdr.id_rango = r.id_rango
          AND r.id_titular = p_id_usuario
    ) INTO habilitado_por_rango;

    -- Validar por repartición (el usuario debe pertenecer a la repartición)
    SELECT EXISTS (
        SELECT 1
        FROM tipos_documentos_habilitados_por_reparticion tdrp
        JOIN usuarios u ON u.id_usuario = p_id_usuario
        WHERE tdrp.id_tipo_documento = p_id_tipo_documento
          AND tdrp.id_reparticion = u.id_reparticion
    ) INTO habilitado_por_reparticion;

    IF NOT (habilitado_por_rango OR habilitado_por_reparticion) THEN
        RAISE EXCEPTION 'El usuario no está habilitado para firmar y numerar este documento';
    END IF;

    -- Obtener la zona horaria del municipio
    SELECT zona_horaria INTO v_zona_horaria
    FROM configuracion
    WHERE id_municipio = (SELECT id_municipio FROM documentos_oficiales WHERE id_documento = p_id_documento);

    -- Calcular el año local
    SELECT EXTRACT(YEAR FROM (now() AT TIME ZONE v_zona_horaria))::SMALLINT INTO v_anio;

    -- Buscar el menor número disponible (no reservado) o crear el siguiente correlativo
    SELECT id_numerador, numero INTO numerador_id, nuevo_numero
    FROM numerador_oficial
    WHERE id_tipo_documento = p_id_tipo_documento
      AND anio = v_anio
      AND ((id_reparticion IS NULL AND p_id_reparticion IS NULL) OR id_reparticion = p_id_reparticion)
      AND reservado = FALSE
      AND id_documento IS NULL
    ORDER BY numero ASC
    LIMIT 1;

    IF nuevo_numero IS NULL THEN
        -- No hay número libre, crear el siguiente correlativo
        SELECT COALESCE(MAX(numero), 0) + 1 INTO nuevo_numero
        FROM numerador_oficial
        WHERE id_tipo_documento = p_id_tipo_documento
          AND anio = v_anio
          AND ((id_reparticion IS NULL AND p_id_reparticion IS NULL) OR id_reparticion = p_id_reparticion);

        INSERT INTO numerador_oficial (
            id_tipo_documento, anio, id_reparticion, numero, reservado, fecha_reserva, historial_pedidos, id_documento, auditoria
        ) VALUES (
            p_id_tipo_documento, v_anio, p_id_reparticion, nuevo_numero, TRUE, now(),
            jsonb_build_array(jsonb_build_object('usuario', p_id_usuario, 'fecha', now(), 'motivo', 'asignacion')),
            p_id_documento,
            jsonb_build_array(jsonb_build_object('accion', 'CREACION', 'usuario', p_id_usuario, 'fecha', now()))
        ) RETURNING id_numerador INTO numerador_id;
    ELSE
        -- Reservar el número libre encontrado
        UPDATE numerador_oficial
        SET reservado = TRUE,
            fecha_reserva = now(),
            historial_pedidos = COALESCE(historial_pedidos, '[]'::jsonb) || jsonb_build_object('usuario', p_id_usuario, 'fecha', now(), 'motivo', 'asignacion'),
            id_documento = p_id_documento,
            auditoria = COALESCE(auditoria, '[]'::jsonb) || jsonb_build_array(jsonb_build_object('accion', 'ACTUALIZACION', 'usuario', p_id_usuario, 'fecha', now()))
        WHERE id_numerador = numerador_id;
    END IF;

    -- ACTUALIZA el documento con el número oficial asignado
    UPDATE documentos_oficiales
    SET numero_oficial = nuevo_numero,
        anio = v_anio,
        id_reparticion = p_id_reparticion,
        id_numerador = numerador_id,
        fecha_numeracion = now(),
        auditoria = COALESCE(auditoria, '[]'::jsonb) || jsonb_build_array(jsonb_build_object('accion', 'ACTUALIZACION', 'usuario', p_id_usuario, 'fecha', now()))
    WHERE id_documento = p_id_documento;

    RETURN nuevo_numero;
END;
$$;


ALTER FUNCTION "public"."firmar_y_numerar_documento"("p_id_documento" "uuid", "p_id_usuario" "uuid", "p_id_tipo_documento" "uuid", "p_id_reparticion" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."firmar_y_numerar_documento"("p_id_documento" "uuid", "p_id_usuario" "uuid", "p_id_tipo_documento" "uuid", "p_id_reparticion" "uuid") IS 'Valida si el usuario puede firmar y numerar el documento, asigna el número oficial y actualiza el documento.';


SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."configuracion" (
    "id_municipio" "uuid" NOT NULL,
    "direccion" character varying(255),
    "email_contacto" character varying(100),
    "sitio_web" character varying(100),
    "color_primario" character varying(7),
    "frase_anual" character varying(250),
    "id_logo" "uuid",
    "id_isologo" "uuid",
    "id_foto" "uuid",
    "zona_horaria" character varying(50) NOT NULL,
    "auditoria" "jsonb"
);


ALTER TABLE "public"."configuracion" OWNER TO "postgres";


COMMENT ON TABLE "public"."configuracion" IS 'Configuraciones, branding y datos de contacto específicos del municipio.';



CREATE TABLE IF NOT EXISTS "public"."documentos_oficiales" (
    "id_documento" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "id_tipo_documento" "uuid" NOT NULL,
    "referencia" character varying(250) NOT NULL,
    "numero_oficial" integer,
    "anio" smallint,
    "id_reparticion" "uuid",
    "id_numerador" integer,
    "fecha_numeracion" timestamp with time zone,
    "url_pdf_firmado" character varying(500),
    "estado" "public"."estado_documento_enum" DEFAULT 'PENDIENTE_FIRMA'::"public"."estado_documento_enum" NOT NULL,
    "auditoria" "jsonb",
    "firmantes" "jsonb"
);


ALTER TABLE "public"."documentos_oficiales" OWNER TO "postgres";


COMMENT ON TABLE "public"."documentos_oficiales" IS 'Registra cada documento individual generado, su estado y su versión final firmada.';



COMMENT ON COLUMN "public"."documentos_oficiales"."numero_oficial" IS 'Número correlativo oficial asignado al documento.';



COMMENT ON COLUMN "public"."documentos_oficiales"."anio" IS 'Año del número oficial.';



COMMENT ON COLUMN "public"."documentos_oficiales"."id_reparticion" IS 'Repartición asociada al número oficial (si aplica).';



COMMENT ON COLUMN "public"."documentos_oficiales"."id_numerador" IS 'Referencia al registro de numerador oficial usado.';



COMMENT ON COLUMN "public"."documentos_oficiales"."url_pdf_firmado" IS 'Ruta o URL al archivo PDF final y firmado.';



COMMENT ON COLUMN "public"."documentos_oficiales"."auditoria" IS 'Objeto JSON con datos de creación/modificación. Ej: [{"accion": "CREACION", "usuario": "uuid", "fecha": "timestamp"}].';



COMMENT ON COLUMN "public"."documentos_oficiales"."firmantes" IS 'Array JSONB con los firmantes, orden, tipo, fecha, etc. Ej: [{"usuario": "uuid", "orden": 1, "tipo": "DIGITAL", "fecha": "..."}]';



CREATE TABLE IF NOT EXISTS "public"."municipios" (
    "id_municipio" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "nombre" character varying(100) NOT NULL,
    "pais" "public"."pais_enum" NOT NULL,
    "acronimo" character varying(10) NOT NULL,
    "schema_name" character varying(50) NOT NULL,
    "identificador_fiscal" character varying(20),
    "activo" boolean DEFAULT true,
    "fecha_creacion" timestamp with time zone DEFAULT "now"(),
    "auditoria" "jsonb"
);


ALTER TABLE "public"."municipios" OWNER TO "postgres";


COMMENT ON TABLE "public"."municipios" IS 'Directorio maestro de todos los municipios (inquilinos) del sistema.';



COMMENT ON COLUMN "public"."municipios"."acronimo" IS 'Acrónimo único global del municipio, compuesto por el país y la sigla local.';



CREATE TABLE IF NOT EXISTS "public"."numerador_oficial" (
    "id_numerador" integer NOT NULL,
    "id_tipo_documento" "uuid" NOT NULL,
    "anio" smallint NOT NULL,
    "numero" integer,
    "id_reparticion" "uuid",
    "reservado" boolean DEFAULT true,
    "fecha_reserva" timestamp with time zone DEFAULT "now"(),
    "fecha_uso" timestamp with time zone,
    "historial_pedidos" "jsonb",
    "id_documento" "uuid",
    "auditoria" "jsonb"
);


ALTER TABLE "public"."numerador_oficial" OWNER TO "postgres";


COMMENT ON TABLE "public"."numerador_oficial" IS 'Controla la numeración oficial por tipo de documento, año y repartición (si aplica), con historial de pedidos y control de reserva/uso.';



CREATE SEQUENCE IF NOT EXISTS "public"."numerador_oficial_id_numerador_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."numerador_oficial_id_numerador_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."numerador_oficial_id_numerador_seq" OWNED BY "public"."numerador_oficial"."id_numerador";



CREATE TABLE IF NOT EXISTS "public"."permisos" (
    "id_permiso" integer NOT NULL,
    "nombre_permiso" character varying(50) NOT NULL,
    "descripcion" "text",
    "auditoria" "jsonb"
);


ALTER TABLE "public"."permisos" OWNER TO "postgres";


COMMENT ON TABLE "public"."permisos" IS 'Catálogo de permisos que pueden ser asignados a los roles.';



CREATE SEQUENCE IF NOT EXISTS "public"."permisos_id_permiso_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."permisos_id_permiso_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."permisos_id_permiso_seq" OWNED BY "public"."permisos"."id_permiso";



CREATE TABLE IF NOT EXISTS "public"."rangos" (
    "nombre_rango" character varying(20) NOT NULL,
    "sello_titular" character varying(20) NOT NULL,
    "auditoria" "jsonb",
    "id_rango" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL
);


ALTER TABLE "public"."rangos" OWNER TO "postgres";


COMMENT ON TABLE "public"."rangos" IS 'Catálogo de jerarquías para las reparticiones y los títulos de sus titulares.';



CREATE TABLE IF NOT EXISTS "public"."reparticiones" (
    "id_reparticion" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "nombre" character varying(50) NOT NULL,
    "acronimo" character varying(10) NOT NULL,
    "id_jurisdiccion_padre" "uuid",
    "id_titular" "uuid",
    "activo" boolean DEFAULT true,
    "auditoria" "jsonb",
    "id_rango" "uuid"
);


ALTER TABLE "public"."reparticiones" OWNER TO "postgres";


COMMENT ON TABLE "public"."reparticiones" IS 'Define las divisiones organizativas de nivel legal.';



CREATE TABLE IF NOT EXISTS "public"."rol_permisos" (
    "id_rol" integer NOT NULL,
    "id_permiso" integer NOT NULL,
    "auditoria" "jsonb"
);


ALTER TABLE "public"."rol_permisos" OWNER TO "postgres";


COMMENT ON TABLE "public"."rol_permisos" IS 'Asocia permisos a los roles definidos en el municipio.';



CREATE TABLE IF NOT EXISTS "public"."roles" (
    "id_rol" integer NOT NULL,
    "nombre_rol" character varying(50) NOT NULL,
    "descripcion" "text",
    "auditoria" "jsonb"
);


ALTER TABLE "public"."roles" OWNER TO "postgres";


COMMENT ON TABLE "public"."roles" IS 'Catálogo de roles de usuario disponibles en el municipio.';



CREATE SEQUENCE IF NOT EXISTS "public"."roles_id_rol_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."roles_id_rol_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."roles_id_rol_seq" OWNED BY "public"."roles"."id_rol";



CREATE TABLE IF NOT EXISTS "public"."sectores" (
    "id_sector" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "id_reparticion" "uuid" NOT NULL,
    "acronimo" character varying(10) NOT NULL,
    "activo" boolean DEFAULT true,
    "auditoria" "jsonb"
);


ALTER TABLE "public"."sectores" OWNER TO "postgres";


COMMENT ON TABLE "public"."sectores" IS 'Define los grupos de trabajo dentro de cada repartición.';



CREATE TABLE IF NOT EXISTS "public"."tipos_documentos" (
    "id_tipo_documento" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "id_tipo_documento_global" "uuid",
    "nombre" character varying(50) NOT NULL,
    "acronimo" character varying(5) NOT NULL,
    "descripcion" "text",
    "firma_requerida" "public"."firma_requerida_enum",
    "auditoria" "jsonb",
    "activo" boolean DEFAULT true
);


ALTER TABLE "public"."tipos_documentos" OWNER TO "postgres";


COMMENT ON TABLE "public"."tipos_documentos" IS 'Catálogo de tipos de documentos disponibles en este municipio (propios y globales adoptados).';



COMMENT ON COLUMN "public"."tipos_documentos"."id_tipo_documento_global" IS 'Si no es NULO, indica que este es un tipo de documento global y sus propiedades no son editables.';



COMMENT ON COLUMN "public"."tipos_documentos"."auditoria" IS 'Objeto JSON con datos de creación/modificación. Ej: [{"accion": "CREACION", "usuario": "uuid", "fecha": "timestamp"}].';



CREATE TABLE IF NOT EXISTS "public"."tipos_documentos_globales" (
    "id_tipo_documento_global" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "nombre" character varying(50) NOT NULL,
    "acronimo" character varying(5) NOT NULL,
    "descripcion" "text",
    "activo" boolean DEFAULT true,
    "auditoria" "jsonb"
);


ALTER TABLE "public"."tipos_documentos_globales" OWNER TO "postgres";


COMMENT ON TABLE "public"."tipos_documentos_globales" IS 'Catálogo de tipos de documentos estándar que cualquier municipio puede adoptar.';



CREATE TABLE IF NOT EXISTS "public"."tipos_documentos_habilitados_por_rango" (
    "id" integer NOT NULL,
    "id_tipo_documento" "uuid" NOT NULL,
    "auditoria" "jsonb",
    "id_rango" "uuid"
);


ALTER TABLE "public"."tipos_documentos_habilitados_por_rango" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."tipos_documentos_habilitados_por_rango_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."tipos_documentos_habilitados_por_rango_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."tipos_documentos_habilitados_por_rango_id_seq" OWNED BY "public"."tipos_documentos_habilitados_por_rango"."id";



CREATE TABLE IF NOT EXISTS "public"."tipos_documentos_habilitados_por_reparticion" (
    "id_tipo_documento" "uuid" NOT NULL,
    "id_reparticion" "uuid",
    "auditoria" "jsonb",
    "id" integer NOT NULL
);


ALTER TABLE "public"."tipos_documentos_habilitados_por_reparticion" OWNER TO "postgres";


COMMENT ON TABLE "public"."tipos_documentos_habilitados_por_reparticion" IS 'Permite que un tipo de documento sea usado solo por reparticiones listadas explícitamente.';



CREATE SEQUENCE IF NOT EXISTS "public"."tipos_documentos_habilitados_por_reparticion_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."tipos_documentos_habilitados_por_reparticion_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."tipos_documentos_habilitados_por_reparticion_id_seq" OWNED BY "public"."tipos_documentos_habilitados_por_reparticion"."id";



CREATE TABLE IF NOT EXISTS "public"."usuario_roles" (
    "id_usuario" "uuid" NOT NULL,
    "id_rol" integer NOT NULL,
    "auditoria" "jsonb"
);


ALTER TABLE "public"."usuario_roles" OWNER TO "postgres";


COMMENT ON TABLE "public"."usuario_roles" IS 'Asigna uno o más roles a cada usuario.';



CREATE TABLE IF NOT EXISTS "public"."usuario_sectores_habilitados" (
    "id_usuario" "uuid" NOT NULL,
    "id_sector" "uuid" NOT NULL,
    "auditoria" "jsonb"
);


ALTER TABLE "public"."usuario_sectores_habilitados" OWNER TO "postgres";


COMMENT ON TABLE "public"."usuario_sectores_habilitados" IS 'Define los sectores específicos a los que un usuario tiene acceso.';



CREATE TABLE IF NOT EXISTS "public"."usuarios" (
    "id_usuario" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id_auth" character varying(100) NOT NULL,
    "nombre_apellido" character varying(150) NOT NULL,
    "email" character varying(100) NOT NULL,
    "identificacion_pais" character varying(50),
    "id_reparticion" "uuid",
    "activo" boolean DEFAULT true,
    "verificacion_identidad" "jsonb",
    "ultimo_acceso" timestamp with time zone,
    "fecha_creacion" timestamp with time zone DEFAULT "now"(),
    "auditoria" "jsonb"
);


ALTER TABLE "public"."usuarios" OWNER TO "postgres";


COMMENT ON TABLE "public"."usuarios" IS 'Tabla central de usuarios para este municipio.';



COMMENT ON COLUMN "public"."usuarios"."verificacion_identidad" IS 'Objeto JSON con detalles de la verificación. Ej: {"metodo": "presencial", "fecha": "2025-07-15", "verificador": "uuid..."}';



ALTER TABLE ONLY "public"."numerador_oficial" ALTER COLUMN "id_numerador" SET DEFAULT "nextval"('"public"."numerador_oficial_id_numerador_seq"'::"regclass");



ALTER TABLE ONLY "public"."permisos" ALTER COLUMN "id_permiso" SET DEFAULT "nextval"('"public"."permisos_id_permiso_seq"'::"regclass");



ALTER TABLE ONLY "public"."roles" ALTER COLUMN "id_rol" SET DEFAULT "nextval"('"public"."roles_id_rol_seq"'::"regclass");



ALTER TABLE ONLY "public"."tipos_documentos_habilitados_por_rango" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tipos_documentos_habilitados_por_rango_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."tipos_documentos_habilitados_por_reparticion" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tipos_documentos_habilitados_por_reparticion_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."configuracion"
    ADD CONSTRAINT "configuracion_pkey" PRIMARY KEY ("id_municipio");



ALTER TABLE ONLY "public"."documentos_oficiales"
    ADD CONSTRAINT "documentos_oficiales_pkey" PRIMARY KEY ("id_documento");



ALTER TABLE ONLY "public"."municipios"
    ADD CONSTRAINT "municipios_acronimo_key" UNIQUE ("acronimo");



ALTER TABLE ONLY "public"."municipios"
    ADD CONSTRAINT "municipios_identificador_fiscal_key" UNIQUE ("identificador_fiscal");



ALTER TABLE ONLY "public"."municipios"
    ADD CONSTRAINT "municipios_pkey" PRIMARY KEY ("id_municipio");



ALTER TABLE ONLY "public"."municipios"
    ADD CONSTRAINT "municipios_schema_name_key" UNIQUE ("schema_name");



ALTER TABLE ONLY "public"."numerador_oficial"
    ADD CONSTRAINT "numerador_oficial_id_tipo_documento_anio_id_reparticion_num_key" UNIQUE ("id_tipo_documento", "anio", "id_reparticion", "numero");



ALTER TABLE ONLY "public"."numerador_oficial"
    ADD CONSTRAINT "numerador_oficial_pkey" PRIMARY KEY ("id_numerador");



ALTER TABLE ONLY "public"."permisos"
    ADD CONSTRAINT "permisos_nombre_permiso_key" UNIQUE ("nombre_permiso");



ALTER TABLE ONLY "public"."permisos"
    ADD CONSTRAINT "permisos_pkey" PRIMARY KEY ("id_permiso");



ALTER TABLE ONLY "public"."rangos"
    ADD CONSTRAINT "rangos_id_rango_uuid_pkey" PRIMARY KEY ("id_rango");



ALTER TABLE ONLY "public"."rangos"
    ADD CONSTRAINT "rangos_nombre_rango_key" UNIQUE ("nombre_rango");



ALTER TABLE ONLY "public"."reparticiones"
    ADD CONSTRAINT "reparticiones_acronimo_key" UNIQUE ("acronimo");



ALTER TABLE ONLY "public"."reparticiones"
    ADD CONSTRAINT "reparticiones_pkey" PRIMARY KEY ("id_reparticion");



ALTER TABLE ONLY "public"."rol_permisos"
    ADD CONSTRAINT "rol_permisos_pkey" PRIMARY KEY ("id_rol", "id_permiso");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_nombre_rol_key" UNIQUE ("nombre_rol");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id_rol");



ALTER TABLE ONLY "public"."sectores"
    ADD CONSTRAINT "sectores_id_reparticion_acronimo_key" UNIQUE ("id_reparticion", "acronimo");



ALTER TABLE ONLY "public"."sectores"
    ADD CONSTRAINT "sectores_pkey" PRIMARY KEY ("id_sector");



ALTER TABLE ONLY "public"."tipos_documentos"
    ADD CONSTRAINT "tipos_documentos_acronimo_key" UNIQUE ("acronimo");



ALTER TABLE ONLY "public"."tipos_documentos_globales"
    ADD CONSTRAINT "tipos_documentos_globales_acronimo_key" UNIQUE ("acronimo");



ALTER TABLE ONLY "public"."tipos_documentos_globales"
    ADD CONSTRAINT "tipos_documentos_globales_pkey" PRIMARY KEY ("id_tipo_documento_global");



ALTER TABLE ONLY "public"."tipos_documentos_habilitados_por_reparticion"
    ADD CONSTRAINT "tipos_documentos_habilitados_por_reparticion_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tipos_documentos"
    ADD CONSTRAINT "tipos_documentos_id_tipo_documento_global_key" UNIQUE ("id_tipo_documento_global");



ALTER TABLE ONLY "public"."tipos_documentos"
    ADD CONSTRAINT "tipos_documentos_pkey" PRIMARY KEY ("id_tipo_documento");



ALTER TABLE ONLY "public"."usuario_roles"
    ADD CONSTRAINT "usuario_roles_pkey" PRIMARY KEY ("id_usuario", "id_rol");



ALTER TABLE ONLY "public"."usuario_sectores_habilitados"
    ADD CONSTRAINT "usuario_sectores_habilitados_pkey" PRIMARY KEY ("id_usuario", "id_sector");



ALTER TABLE ONLY "public"."usuarios"
    ADD CONSTRAINT "usuarios_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."usuarios"
    ADD CONSTRAINT "usuarios_identificacion_pais_key" UNIQUE ("identificacion_pais");



ALTER TABLE ONLY "public"."usuarios"
    ADD CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id_usuario");



ALTER TABLE ONLY "public"."usuarios"
    ADD CONSTRAINT "usuarios_user_id_auth_key" UNIQUE ("user_id_auth");



CREATE UNIQUE INDEX "idx_tipo_doc_reparticion_unico" ON "public"."tipos_documentos_habilitados_por_reparticion" USING "btree" ("id_tipo_documento", "id_reparticion");



ALTER TABLE ONLY "public"."configuracion"
    ADD CONSTRAINT "configuracion_id_municipio_fkey" FOREIGN KEY ("id_municipio") REFERENCES "public"."municipios"("id_municipio");



ALTER TABLE ONLY "public"."documentos_oficiales"
    ADD CONSTRAINT "documentos_oficiales_id_numerador_fkey" FOREIGN KEY ("id_numerador") REFERENCES "public"."numerador_oficial"("id_numerador");



ALTER TABLE ONLY "public"."documentos_oficiales"
    ADD CONSTRAINT "documentos_oficiales_id_tipo_documento_fkey" FOREIGN KEY ("id_tipo_documento") REFERENCES "public"."tipos_documentos"("id_tipo_documento");



ALTER TABLE ONLY "public"."numerador_oficial"
    ADD CONSTRAINT "numerador_oficial_id_tipo_documento_fkey" FOREIGN KEY ("id_tipo_documento") REFERENCES "public"."tipos_documentos"("id_tipo_documento");



ALTER TABLE ONLY "public"."reparticiones"
    ADD CONSTRAINT "reparticiones_id_jurisdiccion_padre_fkey" FOREIGN KEY ("id_jurisdiccion_padre") REFERENCES "public"."reparticiones"("id_reparticion");



ALTER TABLE ONLY "public"."reparticiones"
    ADD CONSTRAINT "reparticiones_id_rango_uuid_fkey" FOREIGN KEY ("id_rango") REFERENCES "public"."rangos"("id_rango");



ALTER TABLE ONLY "public"."rol_permisos"
    ADD CONSTRAINT "rol_permisos_id_permiso_fkey" FOREIGN KEY ("id_permiso") REFERENCES "public"."permisos"("id_permiso") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."rol_permisos"
    ADD CONSTRAINT "rol_permisos_id_rol_fkey" FOREIGN KEY ("id_rol") REFERENCES "public"."roles"("id_rol") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sectores"
    ADD CONSTRAINT "sectores_id_reparticion_fkey" FOREIGN KEY ("id_reparticion") REFERENCES "public"."reparticiones"("id_reparticion");



ALTER TABLE ONLY "public"."tipos_documentos_habilitados_por_rango"
    ADD CONSTRAINT "tipos_documentos_habilitados_por_rango_id_rango_uuid_fkey" FOREIGN KEY ("id_rango") REFERENCES "public"."rangos"("id_rango");



ALTER TABLE ONLY "public"."tipos_documentos_habilitados_por_reparticion"
    ADD CONSTRAINT "tipos_documentos_habilitados_por_reparti_id_tipo_documento_fkey" FOREIGN KEY ("id_tipo_documento") REFERENCES "public"."tipos_documentos"("id_tipo_documento") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tipos_documentos_habilitados_por_reparticion"
    ADD CONSTRAINT "tipos_documentos_habilitados_por_reparticio_id_reparticion_fkey" FOREIGN KEY ("id_reparticion") REFERENCES "public"."reparticiones"("id_reparticion") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tipos_documentos"
    ADD CONSTRAINT "tipos_documentos_id_tipo_documento_global_fkey" FOREIGN KEY ("id_tipo_documento_global") REFERENCES "public"."tipos_documentos_globales"("id_tipo_documento_global");



ALTER TABLE ONLY "public"."usuario_roles"
    ADD CONSTRAINT "usuario_roles_id_rol_fkey" FOREIGN KEY ("id_rol") REFERENCES "public"."roles"("id_rol") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."usuario_roles"
    ADD CONSTRAINT "usuario_roles_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "public"."usuarios"("id_usuario") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."usuario_sectores_habilitados"
    ADD CONSTRAINT "usuario_sectores_habilitados_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "public"."usuarios"("id_usuario") ON DELETE CASCADE;





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."firmar_y_numerar_documento"("p_id_documento" "uuid", "p_id_usuario" "uuid", "p_id_tipo_documento" "uuid", "p_id_reparticion" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."firmar_y_numerar_documento"("p_id_documento" "uuid", "p_id_usuario" "uuid", "p_id_tipo_documento" "uuid", "p_id_reparticion" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."firmar_y_numerar_documento"("p_id_documento" "uuid", "p_id_usuario" "uuid", "p_id_tipo_documento" "uuid", "p_id_reparticion" "uuid") TO "service_role";


















GRANT ALL ON TABLE "public"."configuracion" TO "anon";
GRANT ALL ON TABLE "public"."configuracion" TO "authenticated";
GRANT ALL ON TABLE "public"."configuracion" TO "service_role";



GRANT ALL ON TABLE "public"."documentos_oficiales" TO "anon";
GRANT ALL ON TABLE "public"."documentos_oficiales" TO "authenticated";
GRANT ALL ON TABLE "public"."documentos_oficiales" TO "service_role";



GRANT ALL ON TABLE "public"."municipios" TO "anon";
GRANT ALL ON TABLE "public"."municipios" TO "authenticated";
GRANT ALL ON TABLE "public"."municipios" TO "service_role";



GRANT ALL ON TABLE "public"."numerador_oficial" TO "anon";
GRANT ALL ON TABLE "public"."numerador_oficial" TO "authenticated";
GRANT ALL ON TABLE "public"."numerador_oficial" TO "service_role";



GRANT ALL ON SEQUENCE "public"."numerador_oficial_id_numerador_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."numerador_oficial_id_numerador_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."numerador_oficial_id_numerador_seq" TO "service_role";



GRANT ALL ON TABLE "public"."permisos" TO "anon";
GRANT ALL ON TABLE "public"."permisos" TO "authenticated";
GRANT ALL ON TABLE "public"."permisos" TO "service_role";



GRANT ALL ON SEQUENCE "public"."permisos_id_permiso_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."permisos_id_permiso_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."permisos_id_permiso_seq" TO "service_role";



GRANT ALL ON TABLE "public"."rangos" TO "anon";
GRANT ALL ON TABLE "public"."rangos" TO "authenticated";
GRANT ALL ON TABLE "public"."rangos" TO "service_role";



GRANT ALL ON TABLE "public"."reparticiones" TO "anon";
GRANT ALL ON TABLE "public"."reparticiones" TO "authenticated";
GRANT ALL ON TABLE "public"."reparticiones" TO "service_role";



GRANT ALL ON TABLE "public"."rol_permisos" TO "anon";
GRANT ALL ON TABLE "public"."rol_permisos" TO "authenticated";
GRANT ALL ON TABLE "public"."rol_permisos" TO "service_role";



GRANT ALL ON TABLE "public"."roles" TO "anon";
GRANT ALL ON TABLE "public"."roles" TO "authenticated";
GRANT ALL ON TABLE "public"."roles" TO "service_role";



GRANT ALL ON SEQUENCE "public"."roles_id_rol_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."roles_id_rol_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."roles_id_rol_seq" TO "service_role";



GRANT ALL ON TABLE "public"."sectores" TO "anon";
GRANT ALL ON TABLE "public"."sectores" TO "authenticated";
GRANT ALL ON TABLE "public"."sectores" TO "service_role";



GRANT ALL ON TABLE "public"."tipos_documentos" TO "anon";
GRANT ALL ON TABLE "public"."tipos_documentos" TO "authenticated";
GRANT ALL ON TABLE "public"."tipos_documentos" TO "service_role";



GRANT ALL ON TABLE "public"."tipos_documentos_globales" TO "anon";
GRANT ALL ON TABLE "public"."tipos_documentos_globales" TO "authenticated";
GRANT ALL ON TABLE "public"."tipos_documentos_globales" TO "service_role";



GRANT ALL ON TABLE "public"."tipos_documentos_habilitados_por_rango" TO "anon";
GRANT ALL ON TABLE "public"."tipos_documentos_habilitados_por_rango" TO "authenticated";
GRANT ALL ON TABLE "public"."tipos_documentos_habilitados_por_rango" TO "service_role";



GRANT ALL ON SEQUENCE "public"."tipos_documentos_habilitados_por_rango_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."tipos_documentos_habilitados_por_rango_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."tipos_documentos_habilitados_por_rango_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."tipos_documentos_habilitados_por_reparticion" TO "anon";
GRANT ALL ON TABLE "public"."tipos_documentos_habilitados_por_reparticion" TO "authenticated";
GRANT ALL ON TABLE "public"."tipos_documentos_habilitados_por_reparticion" TO "service_role";



GRANT ALL ON SEQUENCE "public"."tipos_documentos_habilitados_por_reparticion_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."tipos_documentos_habilitados_por_reparticion_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."tipos_documentos_habilitados_por_reparticion_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."usuario_roles" TO "anon";
GRANT ALL ON TABLE "public"."usuario_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."usuario_roles" TO "service_role";



GRANT ALL ON TABLE "public"."usuario_sectores_habilitados" TO "anon";
GRANT ALL ON TABLE "public"."usuario_sectores_habilitados" TO "authenticated";
GRANT ALL ON TABLE "public"."usuario_sectores_habilitados" TO "service_role";



GRANT ALL ON TABLE "public"."usuarios" TO "anon";
GRANT ALL ON TABLE "public"."usuarios" TO "authenticated";
GRANT ALL ON TABLE "public"."usuarios" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";






























RESET ALL;

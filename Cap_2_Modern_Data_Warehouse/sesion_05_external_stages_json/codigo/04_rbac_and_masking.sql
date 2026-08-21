-- ============================================================================
-- 04_rbac_and_masking.sql — RBAC de negocio y Dynamic Data Masking sobre PII
--
-- ⚠️ REQUIERE SNOWFLAKE EDITION = ENTERPRISE (o superior). Verificado contra la cuenta
-- real de este curso (edición Standard, creada en la Sesión 4): CREATE MASKING POLICY
-- falla con:
--   000002 (0A000): Unsupported feature 'MASKING POLICY'.
-- Ver README.md, sección "Prerrequisitos", antes de intentar correr este archivo.
--
-- Requiere 02 ya ejecutado (STG_LEADS_FLATTENED con datos).
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE WH_DATAOPS;
USE DATABASE PARCH_AND_POSEY;
USE SCHEMA MARKETING;

-- ----------------------------------------------------------------------------
-- Tres roles de negocio, tres niveles de necesidad de ver PII
-- ----------------------------------------------------------------------------

CREATE ROLE IF NOT EXISTS ROLE_DATA_ENGINEER
    COMMENT = 'Opera el pipeline, necesita el dato crudo para depurar';
CREATE ROLE IF NOT EXISTS ROLE_DATA_ANALYST
    COMMENT = 'Analiza campañas, necesita contexto parcial, no el contacto completo';
CREATE ROLE IF NOT EXISTS ROLE_BUSINESS_MANAGER
    COMMENT = 'Consume reportes agregados; nunca necesita ver un teléfono real';

-- Sin USAGE + SELECT, un rol nuevo no ve nada — RBAC es "todo cerrado por defecto".
GRANT USAGE ON WAREHOUSE WH_DATAOPS TO ROLE ROLE_DATA_ENGINEER;
GRANT USAGE ON WAREHOUSE WH_DATAOPS TO ROLE ROLE_DATA_ANALYST;
GRANT USAGE ON WAREHOUSE WH_DATAOPS TO ROLE ROLE_BUSINESS_MANAGER;

GRANT USAGE ON DATABASE PARCH_AND_POSEY TO ROLE ROLE_DATA_ENGINEER;
GRANT USAGE ON DATABASE PARCH_AND_POSEY TO ROLE ROLE_DATA_ANALYST;
GRANT USAGE ON DATABASE PARCH_AND_POSEY TO ROLE ROLE_BUSINESS_MANAGER;

GRANT USAGE ON SCHEMA MARKETING TO ROLE ROLE_DATA_ENGINEER;
GRANT USAGE ON SCHEMA MARKETING TO ROLE ROLE_DATA_ANALYST;
GRANT USAGE ON SCHEMA MARKETING TO ROLE ROLE_BUSINESS_MANAGER;

GRANT SELECT ON TABLE STG_LEADS_FLATTENED TO ROLE ROLE_DATA_ENGINEER;
GRANT SELECT ON TABLE STG_LEADS_FLATTENED TO ROLE ROLE_DATA_ANALYST;
GRANT SELECT ON TABLE STG_LEADS_FLATTENED TO ROLE ROLE_BUSINESS_MANAGER;

-- Para poder alternar de rol en Snowsight y ver la demo con tu propio usuario.
-- Reemplaza <TU_USUARIO> por tu nombre real antes de ejecutar estas tres líneas.
GRANT ROLE ROLE_DATA_ENGINEER    TO USER <TU_USUARIO>;
GRANT ROLE ROLE_DATA_ANALYST     TO USER <TU_USUARIO>;
GRANT ROLE ROLE_BUSINESS_MANAGER TO USER <TU_USUARIO>;

-- ----------------------------------------------------------------------------
-- Antes de enmascarar: mira el dato tal cual está hoy
-- ----------------------------------------------------------------------------

SELECT contact_name, phone FROM STG_LEADS_FLATTENED ORDER BY contact_name;

-- ----------------------------------------------------------------------------
-- Masking Policy — un teléfono, tres visibilidades
-- ----------------------------------------------------------------------------

-- ¿Por qué CURRENT_ROLE() y no CURRENT_USER() dentro de la política? Porque RBAC
-- gobierna por ROL, no por identidad: el mismo usuario puede operar hoy como analista y
-- mañana como ingeniero, y lo que debe ver depende de bajo qué sombrero está trabajando en
-- ese momento, no de quién es.
CREATE OR REPLACE MASKING POLICY mask_phone AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() = 'ROLE_DATA_ENGINEER' THEN val
        WHEN CURRENT_ROLE() = 'ROLE_DATA_ANALYST'  THEN CONCAT(LEFT(val, 6), '-****')
        ELSE '***-***-****'
    END;

-- ¿Por qué esto se aplica UNA vez sobre la columna, y no como un CASE repetido en cada
-- query de cada dashboard? Porque así hay un solo punto de control: la próxima persona
-- que conecte Tableau, Streamlit o un notebook a esta tabla hereda la protección
-- automáticamente, sin que nadie tenga que acordarse de "no seleccionar esa columna sin
-- enmascarar". La política vive con el dato, no con cada consumidor del dato.
ALTER TABLE STG_LEADS_FLATTENED MODIFY COLUMN phone SET MASKING POLICY mask_phone;

-- ----------------------------------------------------------------------------
-- Demostración: el mismo SELECT, tres roles, tres resultados
-- ----------------------------------------------------------------------------

-- La máscara se evalúa "al vuelo", dentro del plan de ejecución de Snowflake — no existe
-- una segunda copia enmascarada de la tabla en ningún lado. Cambia el rol activo y vuelve
-- a correr exactamente el mismo SELECT.

USE ROLE ROLE_DATA_ENGINEER;
SELECT contact_name, phone FROM STG_LEADS_FLATTENED ORDER BY contact_name;
-- Esperado: el teléfono completo, sin máscara.

USE ROLE ROLE_DATA_ANALYST;
SELECT contact_name, phone FROM STG_LEADS_FLATTENED ORDER BY contact_name;
-- Esperado: código de país y prefijo visibles, resto enmascarado (ej. "+1-555-****").

USE ROLE ROLE_BUSINESS_MANAGER;
SELECT contact_name, phone FROM STG_LEADS_FLATTENED ORDER BY contact_name;
-- Esperado: "***-***-****" en todas las filas.

USE ROLE ACCOUNTADMIN; -- volver al rol de administración para seguir trabajando

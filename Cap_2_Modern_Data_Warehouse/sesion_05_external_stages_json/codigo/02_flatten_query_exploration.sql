-- ============================================================================
-- 02_flatten_query_exploration.sql — Notación de punto y LATERAL FLATTEN
--
-- Requiere haber corrido 01_setup_stage_and_raw.sql (RAW_LEADS poblada).
-- ============================================================================

USE WAREHOUSE WH_DATAOPS;
USE DATABASE PARCH_AND_POSEY;
USE SCHEMA MARKETING;

-- ----------------------------------------------------------------------------
-- Paso 1 — Notación de punto: los campos "planos" del JSON
-- ----------------------------------------------------------------------------

-- raw_data:campo devuelve VARIANT, no el tipo real — por eso el `::TIPO` al final.
-- Sin el cast, hasta un número se ve como '"1500.50"' (con comillas) para cualquier
-- herramienta que consuma esta query. El cast es lo que "sale" de schema-on-read hacia
-- un tipo con el que SQL sabe operar (sumar, comparar, agrupar).
SELECT
    raw_data:campaign_id::STRING       AS campaign_id,
    raw_data:campaign_name::STRING     AS campaign_name,
    raw_data:target_website::STRING    AS target_website,
    raw_data:budget_spent_usd::FLOAT   AS budget_spent_usd,
    raw_data:utm_source::STRING        AS utm_source
FROM RAW_LEADS
ORDER BY campaign_id;

-- ----------------------------------------------------------------------------
-- Paso 2 — LATERAL FLATTEN: desenrollar el array de contactos
-- ----------------------------------------------------------------------------

-- Imagina cada fila de RAW_LEADS como una factura, y `high_profile_contacts` como sus
-- ítems: un array de 1 a N contactos por campaña. LATERAL FLATTEN es, en esencia, un JOIN
-- implícito de la fila padre contra cada elemento de su propio array — multiplica la fila
-- de la campaña una vez por cada contacto que tenga. Una campaña con 2 contactos se
-- convierte en 2 filas; con 0, en 0 filas (FLATTEN normal descarta arrays vacíos).
SELECT
    raw_data:campaign_id::STRING            AS campaign_id,
    c.value:name::STRING                    AS contact_name,
    c.value:phone::STRING                   AS phone,
    c.value:personal_address::STRING        AS personal_address,
    c.value:social_media_handle::STRING     AS social_media_handle,
    c.value:preferred_contact_method::STRING AS preferred_contact_method
FROM RAW_LEADS,
     LATERAL FLATTEN(input => raw_data:high_profile_contacts) c
ORDER BY campaign_id;

-- ¿Por qué `social_media_handle` sale NULL en algunas filas y no en otras, sin que nada
-- falle? Los contactos de la primera semana (14/08) nunca tuvieron ese campo; los de las
-- semanas siguientes sí. En schema-on-write, esa diferencia habría exigido un ALTER TABLE
-- antes de poder cargar el segundo archivo (la Sesión 4 completa). Aquí, cada objeto JSON
-- trae las claves que trae, y preguntar por una que no existe simplemente da NULL — es la
-- ventaja central de schema-on-read, vista con datos reales.

-- ----------------------------------------------------------------------------
-- Paso 3 — Materializar el resultado aplanado
-- ----------------------------------------------------------------------------

-- ¿Por qué no dejamos esta consulta como una vista y ya? Porque cada vez que alguien la
-- ejecutara, Snowflake tendría que reescanear y reaplanar TODO RAW_LEADS de nuevo — barato
-- hoy con unas pocas campañas, costoso el día que sean millones. Materializar en una tabla
-- de staging separa "cuándo se aplana" (una vez, cuando llega el dato) de "cuándo se
-- consulta" (todas las veces que un analista abra un dashboard).
CREATE TABLE IF NOT EXISTS STG_LEADS_FLATTENED (
    campaign_id              STRING,
    campaign_name            STRING,
    target_website           STRING,
    budget_spent_usd         FLOAT,
    utm_source               STRING,
    contact_name             STRING,
    phone                    STRING,
    personal_address         STRING,
    social_media_handle      STRING,
    preferred_contact_method STRING,
    _flattened_at            TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Un contacto por fila — salida de LATERAL FLATTEN sobre RAW_LEADS';

-- Reconstrucción completa: simple y suficiente a esta escala. La Sesión 4 discutió por
-- qué esta estrategia ("truncar y recargar todo") deja de servir a volumen alto —la
-- misma conversación aplica aquí, y la resolvería una Task incremental, fuera del
-- alcance de esta sesión.
TRUNCATE TABLE STG_LEADS_FLATTENED;

INSERT INTO STG_LEADS_FLATTENED (
    campaign_id, campaign_name, target_website, budget_spent_usd, utm_source,
    contact_name, phone, personal_address, social_media_handle, preferred_contact_method
)
SELECT
    raw_data:campaign_id::STRING,
    raw_data:campaign_name::STRING,
    raw_data:target_website::STRING,
    raw_data:budget_spent_usd::FLOAT,
    raw_data:utm_source::STRING,
    c.value:name::STRING,
    c.value:phone::STRING,
    c.value:personal_address::STRING,
    c.value:social_media_handle::STRING,
    c.value:preferred_contact_method::STRING
FROM RAW_LEADS,
     LATERAL FLATTEN(input => raw_data:high_profile_contacts) c;

-- Verificación
SELECT COUNT(*) AS contactos FROM STG_LEADS_FLATTENED;
SELECT * FROM STG_LEADS_FLATTENED ORDER BY campaign_id LIMIT 10;

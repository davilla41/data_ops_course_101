-- ============================================================================
-- 01_setup_stage_and_raw.sql — External Stage, File Format y capa RAW semi-estructurada
--
-- Sesión 5. Ejecutar en Snowsight, en el mismo warehouse/base de datos de la Sesión 4
-- (WH_DATAOPS / PARCH_AND_POSEY). Requiere que el bucket S3 sea de lectura pública —
-- ver README.md, sección "Prerrequisitos".
-- ============================================================================

USE WAREHOUSE WH_DATAOPS;
USE DATABASE PARCH_AND_POSEY;

-- Un schema propio para el dominio de mercadeo. RAW (Capítulo 2, Sesión 4) guarda datos
-- relacionales de Parch & Posey; MARKETING guarda un dominio distinto, con una forma de
-- dato distinta. Separar por dominio, no solo por capa, evita que un schema se vuelva el
-- cajón de sastre de "todo lo que no es la tabla principal".
CREATE SCHEMA IF NOT EXISTS MARKETING
    COMMENT = 'Datos de campañas de mercadeo — JSON semi-estructurado, Sesión 5';

USE SCHEMA MARKETING;

-- ----------------------------------------------------------------------------
-- File Format
-- ----------------------------------------------------------------------------

-- ¿Por qué STRIP_OUTER_ARRAY = TRUE? Cada archivo de mercadeo es un array JSON de
-- campañas: `[ {...}, {...} ]`. Sin esta opción, Snowflake cargaría el archivo completo
-- como UNA sola fila VARIANT (todo el array adentro) — tendrías que desanidar hasta el
-- nivel de campaña con FLATTEN antes de poder tocar un solo campo. Con la opción activa,
-- Snowflake separa el array en una fila por elemento durante la carga: una fila = una
-- campaña, ya en la puerta de entrada.
CREATE OR REPLACE FILE FORMAT ff_marketing_json
    TYPE = JSON
    STRIP_OUTER_ARRAY = TRUE
    COMMENT = 'Formato para los exports semanales de leads de mercadeo';

-- ----------------------------------------------------------------------------
-- External Stage
-- ----------------------------------------------------------------------------

-- ¿Por qué apuntamos directo a un bucket público en vez de crear un Storage Integration
-- con rol IAM? Porque este es un dataset de curso, no un secreto de producción: un bucket
-- público de solo lectura elimina toda la ceremonia de AWS (rol IAM, política de
-- confianza, intercambio de external ID) que sí seria obligatoria con datos reales de una
-- empresa. En un proyecto real, jamás apuntarías un stage a datos sensibles sin
-- credenciales — usarías STORAGE INTEGRATION.
CREATE OR REPLACE STAGE stg_marketing_leads_s3
    URL = 's3://data-ops-course-marketing-leads-2026/'
    FILE_FORMAT = ff_marketing_json
    COMMENT = 'Bucket público con los exports semanales de mercadeo (solo lectura)';

-- Explorar el bucket sin cargar nada — LIST solo pregunta al object store qué archivos
-- hay, no mueve ni un byte hacia Snowflake.
LIST @stg_marketing_leads_s3;

-- Consultar el contenido de un archivo DIRECTO desde el stage, antes de cargarlo a una
-- tabla. $1 representa "la fila completa" tal como la entiende el FILE_FORMAT — en este
-- caso, un objeto JSON por campaña, gracias al STRIP_OUTER_ARRAY de arriba.
SELECT $1
FROM @stg_marketing_leads_s3 (FILE_FORMAT => ff_marketing_json)
LIMIT 5;

-- ----------------------------------------------------------------------------
-- Tabla RAW — schema-on-read
-- ----------------------------------------------------------------------------

-- ¿Por qué esta tabla tiene UNA sola columna de negocio (VARIANT) en vez de columnas
-- tipadas como en la Sesión 4? Porque aquí invertimos el orden: no declaramos el schema
-- antes de ver el dato (schema-on-write), lo interpretamos cuando lo consultamos
-- (schema-on-read). Si mercadeo agrega un campo nuevo al JSON la próxima semana, esta
-- tabla no necesita ningún ALTER TABLE — la fila entra igual, el campo nuevo simplemente
-- queda disponible en el VARIANT para quien lo quiera leer.
CREATE TABLE IF NOT EXISTS RAW_LEADS (
    raw_data       VARIANT,
    _stg_file_name STRING,
    _stg_loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Leads de mercadeo, un registro JSON por fila, sin transformar';

-- COPY INTO con metadata de procedencia: METADATA$FILENAME registra de qué archivo salió
-- cada fila. En un aterrizaje "sucio" a propósito (ver la lección de la capa RAW en la
-- Sesión 4), saber el origen exacto de cada fila es lo que te permite depurar sin
-- adivinar cuándo algo salió mal.
COPY INTO RAW_LEADS (raw_data, _stg_file_name, _stg_loaded_at)
FROM (
    SELECT $1, METADATA$FILENAME, CURRENT_TIMESTAMP()
    FROM @stg_marketing_leads_s3
)
FILE_FORMAT = (FORMAT_NAME = ff_marketing_json)
ON_ERROR = ABORT_STATEMENT;

-- Verificación
SELECT COUNT(*) AS filas_cargadas FROM RAW_LEADS;
SELECT * FROM RAW_LEADS LIMIT 3;

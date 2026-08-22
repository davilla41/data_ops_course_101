-- ============================================================================
-- 03_tasks_and_dag_management.sql — Orquestación nativa: DAG con Snowflake Tasks
--
-- Requiere 01 y 02 ya ejecutados. Root task repite la ingesta (01); child task repite el
-- aplanamiento (02) — ambos vueltos a escribir aquí como sentencias únicas por task.
-- ============================================================================

USE WAREHOUSE WH_DATAOPS;
USE DATABASE PARCH_AND_POSEY;
USE SCHEMA MARKETING;

-- ----------------------------------------------------------------------------
-- Privilegio oculto: EXECUTE TASK
-- ----------------------------------------------------------------------------

-- ¿Por qué un rol necesita este GRANT si ya es dueño (OWNERSHIP) de la tabla y del
-- schema? Porque en Snowflake, "poder crear y modificar objetos" y "poder ejecutar tareas
-- programadas" son privilegios completamente separados a propósito: una tarea corre sola,
-- sin que nadie la esté mirando, potencialmente cada pocos minutos. Que cualquier rol con
-- privilegios normales de tabla pudiera además programar ejecuciones automáticas sería un
-- vector de abuso de cómputo. EXECUTE TASK es un privilegio de CUENTA, no de objeto — y es
-- el que más se les olvida otorgar a quienes arman un DAG por primera vez.
GRANT EXECUTE TASK ON ACCOUNT TO ROLE DATAOPS_LOADER;

-- ----------------------------------------------------------------------------
-- Root Task — ingesta programada
-- ----------------------------------------------------------------------------

-- SCHEDULE con CRON: '0 * * * * America/Bogota' = al minuto 0 de cada hora. En producción
-- esto sería diario o semanal (mercadeo exporta una vez por semana) — aquí usamos una
-- cadencia corta para poder observar el DAG correr sin esperar días durante la clase.
CREATE OR REPLACE TASK TASK_INGEST_S3
    WAREHOUSE = WH_DATAOPS
    SCHEDULE = 'USING CRON 0 * * * * America/Bogota'
    COMMENT = 'Root de la DAG: reingesta el bucket de mercadeo'
AS
    COPY INTO RAW_LEADS (raw_data, _stg_file_name, _stg_loaded_at)
    FROM (
        SELECT $1, METADATA$FILENAME, CURRENT_TIMESTAMP()
        FROM @stg_marketing_leads_s3
    )
    FILE_FORMAT = (FORMAT_NAME = ff_marketing_json)
    ON_ERROR = ABORT_STATEMENT;

-- ----------------------------------------------------------------------------
-- Child Task — transformación dependiente
-- ----------------------------------------------------------------------------

-- ¿Por qué esta task hija usa AFTER en vez de su propio SCHEDULE? Un SCHEDULE propio la
-- haría correr a una hora fija, sin ninguna garantía de que la ingesta ya haya terminado
-- —dos relojes independientes que coinciden por suerte, no por diseño—. AFTER crea un DAG
-- verdadero: esta task solo se dispara cuando TASK_INGEST_S3 termina, y solo si terminó
-- con éxito. La dependencia es lógica, no de horario.
CREATE OR REPLACE TASK TASK_FLATTEN_LEADS
    WAREHOUSE = WH_DATAOPS
    COMMENT = 'Child de la DAG: aplana RAW_LEADS hacia STG_LEADS_FLATTENED'
    AFTER TASK_INGEST_S3
AS
    INSERT OVERWRITE INTO STG_LEADS_FLATTENED (
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

-- ----------------------------------------------------------------------------
-- Administración: nacen suspendidas, hay que activarlas
-- ----------------------------------------------------------------------------

-- ¿Por qué CREATE TASK nunca deja una task corriendo de inmediato? Es una salvaguarda
-- deliberada: crear el objeto y activar su ejecución automática son dos decisiones
-- distintas. Si CREATE ya implicara "y empieza a correr en tu warehouse cada hora", un
-- CREATE OR REPLACE accidental durante una demo dispararía cómputo real sin que nadie lo
-- pidiera explícitamente.
SHOW TASKS; -- ambas deben aparecer en estado "suspended"

-- Activar el DAG completo de una sola vez — el helper resuelve el orden correcto sin que
-- tengas que pensarlo (equivale a activar cada task del DAG, de hijas a raíz).
SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('TASK_INGEST_S3');

SHOW TASKS; -- ahora ambas deben aparecer "started"

-- Disparar el DAG manualmente, sin esperar al CRON — esto es lo que harás en la demo.
EXECUTE TASK TASK_INGEST_S3;

-- Dar ~10-15 segundos y consultar el historial de ejecución.
SELECT name, state, error_code, error_message, scheduled_time, completed_time
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
WHERE name IN ('TASK_INGEST_S3', 'TASK_FLATTEN_LEADS')
ORDER BY scheduled_time DESC
LIMIT 10;

-- ----------------------------------------------------------------------------
-- Apagar el DAG — el orden aquí SÍ es obligatorio, y al revés de lo que se esperaría
-- ----------------------------------------------------------------------------

-- ¿Por qué hay que suspender la ROOT antes de poder cambiar cualquier cosa en el DAG —
-- incluida la propia raíz? Mientras la raíz está activa, Snowflake bloquea cualquier
-- cambio estructural sobre ella o sobre sus tareas dependientes: evita reconfigurar un DAG
-- a mitad de una ejecución en curso. Intentar `ALTER TASK ... SET SCHEDULE` o
-- `ALTER TASK <hija> SUSPEND` con la raíz todavía activa falla con el error 091421:
-- "Unable to update graph... since that root task is not suspended." Verificado contra la
-- cuenta real de este curso — no es una advertencia teórica.
ALTER TASK TASK_INGEST_S3 SUSPEND;
ALTER TASK TASK_FLATTEN_LEADS SUSPEND;

SHOW TASKS; -- ambas de vuelta a "suspended"

-- Con la raíz ya suspendida, ahora sí se puede cambiar su programación sin recrearla.
ALTER TASK TASK_INGEST_S3 SET SCHEDULE = 'USING CRON 0 */6 * * * America/Bogota';

# Momento 1 — CI/CD en Base de Datos

**Módulo:** Tendencias emergentes en desarrollo de software (SI6010-5979) · Pos ST1707
**Peso sobre la nota final:** **30 %**
**Capítulo:** 1 — Fundamentos de DataOps
**Se sustenta en:** [Sesión 3 — Sustentación Momento 1](../Cap_1_Fundamentos_DataOps/sesion_03_sustentacion_momento1/) · viernes **14/08/2026**, 18:00–21:00, aula 35-203
**Stack:** Neon.tech (PostgreSQL) · Flyway · GitHub + GitHub Actions

---

## 1. Objetivo

Demostrar que el estudiante es capaz de **tratar el esquema de una base de datos como
código**: versionarlo, evolucionarlo mediante migraciones reproducibles y desplegarlo de
forma automatizada, sin intervención manual sobre el servidor de base de datos.

Al terminar este momento, el estudiante debe poder responder con evidencia:

- ¿Cuál es el estado exacto del esquema en cada entorno, y quién lo cambió?
- ¿Puedo reconstruir la base de datos desde cero con un solo comando?
- ¿Qué pasa cuando alguien intenta desplegar una migración que rompe algo?

---

## 2. Contexto del caso

Partimos del estado base construido en la Sesión 1: una base de datos PostgreSQL en
Neon.tech con el modelo de **Parch & Posey** cargado. El equipo de negocio solicita
cambios evolutivos al modelo (nuevos campos, nuevas tablas de soporte, restricciones de
integridad). Hasta ahora esos cambios se aplicaban conectándose con un cliente SQL y
ejecutando DDL a mano — con las consecuencias conocidas: deriva entre entornos, ausencia
de trazabilidad e imposibilidad de reconstruir el estado.

El encargo es **eliminar ese trabajo manual**.

---

## 3. Alcance

### Incluido en el alcance

1. **Repositorio propio** del estudiante (o fork del repositorio del curso) con las
   migraciones versionadas.
2. **Dos entornos** en Neon.tech gestionados desde el mismo repositorio:
   - `dev` — branch de desarrollo de la base de datos.
   - `main` / `prod` — branch principal.
3. **Migraciones Flyway** que cubran, como mínimo:
   - El *baseline* del esquema de Parch & Posey (`V1__baseline_parch_posey.sql`).
   - Al menos **tres migraciones evolutivas** posteriores (`V2__`, `V3__`, `V4__`) que
     incluyan al menos: una tabla nueva, una columna añadida a una tabla existente, y una
     restricción o índice.
   - Al menos **una migración repetible** (`R__`) — por ejemplo, una vista analítica.
4. **Workflow de GitHub Actions** que ejecute `flyway migrate` de forma automática:
   - En cada *pull request* → ejecuta `flyway validate` (o migración contra `dev`).
   - En cada *merge* a `main` → ejecuta `flyway migrate` contra el entorno principal.
5. **Manejo de secretos** vía GitHub Secrets — **cero credenciales en el repositorio**.

### Fuera del alcance

- Snowflake, dbt y cualquier capa analítica (esos son los Momentos 2 y 3).
- Estrategias de rollback automatizado (se discuten conceptualmente, no se implementan).
- Migraciones de datos masivos (>10 000 filas) o tuning de rendimiento.

---

## 4. Entregables

| # | Entregable | Formato | Dónde |
|---|---|---|---|
| E1 | Repositorio con historial de commits significativo | URL de GitHub | Enviado por el canal del curso |
| E2 | Carpeta `migrations/` (o `sql/`) con las migraciones Flyway | Archivos `.sql` versionados | En el repositorio |
| E3 | Workflow `.github/workflows/*.yml` funcional | YAML | En el repositorio |
| E4 | Evidencia de al menos **una ejecución exitosa** y **una ejecución fallida corregida** | Capturas o enlaces a los runs de GitHub Actions | `docs/evidencias/` del repositorio |
| E5 | `README.md` del repositorio: cómo se ejecuta localmente, cómo se agrega una migración nueva, qué secretos requiere | Markdown | Raíz del repositorio |
| E6 | Sustentación oral | 10 min de exposición + 5 min de preguntas | Sesión 3 — 14/08/2026 |

### Sobre la sustentación (E6)

Cada estudiante (o equipo) dispone de **10 minutos**. Se espera:

1. **Demo en vivo** (no diapositivas de código): crear una migración nueva, hacer commit,
   abrir el PR, mostrar el workflow ejecutándose y el cambio reflejado en Neon.
2. Explicación de **una decisión técnica** que hayan tomado y su alternativa descartada.
3. Respuesta a preguntas del docente sobre el comportamiento del pipeline ante fallos.

> ⚠️ **Un pipeline que solo funciona en la máquina del estudiante no cumple el objetivo
> del momento.** La ejecución debe ocurrir en GitHub Actions.

---

## 5. Condiciones de entrega

- **Fecha límite de código:** viernes **14/08/2026, 17:00** (una hora antes de la sesión).
  Se evalúa el estado del branch `main` en ese instante.
- **Modalidad:** individual o en parejas. Si es en parejas, **ambos** deben tener commits
  en el historial y ambos sustentan.
- **Entregas tardías:** se califican sobre el 70 % hasta 48 horas después; posteriormente
  no se reciben.

---

## 6. Rúbrica de evaluación

**Total: 100 puntos** → equivalen al 30 % de la nota final.

### C1. Migraciones Flyway — 30 puntos

| Nivel | Puntos | Descripción |
|---|---|---|
| Excelente | 27–30 | Convención de nombres correcta y consistente. Baseline + ≥3 migraciones evolutivas + ≥1 repetible. Cada migración es atómica y tiene un propósito único y claro. SQL comentado donde no es obvio. `flyway migrate` desde cero reconstruye la BD sin errores. |
| Bueno | 21–26 | Todas las migraciones requeridas existen y corren, pero hay migraciones que mezclan cambios no relacionados o nombres poco descriptivos. |
| Suficiente | 15–20 | Faltan una o dos migraciones requeridas, o la reconstrucción desde cero requiere pasos manuales no documentados. |
| Insuficiente | 0–14 | Migraciones que no corren, esquema aplicado a mano, o ausencia de baseline. |

### C2. Workflow de CI/CD — 30 puntos

| Nivel | Puntos | Descripción |
|---|---|---|
| Excelente | 27–30 | Workflow se dispara correctamente en PR y en merge a `main`. Diferencia entornos. Falla ruidosamente cuando debe fallar. Usa versiones fijadas de las actions. Tiempos de ejecución razonables. |
| Bueno | 21–26 | El workflow funciona en el camino feliz pero no distingue entornos, o el trigger de PR no aporta validación real. |
| Suficiente | 15–20 | Existe un workflow que ejecuta Flyway, pero se dispara manualmente (`workflow_dispatch`) o solo en un evento. |
| Insuficiente | 0–14 | No hay workflow, o nunca ha corrido exitosamente. |

### C3. Gestión de secretos y seguridad — 15 puntos

| Nivel | Puntos | Descripción |
|---|---|---|
| Excelente | 14–15 | Cero credenciales en el repositorio (verificado también en el historial). GitHub Secrets correctamente configurados. `.gitignore` cubre `flyway.conf`, `.env` y similares. |
| Bueno | 10–13 | Secretos gestionados correctamente en el estado actual, pero hay credenciales en commits antiguos del historial. |
| Suficiente | 6–9 | Uso parcial de secretos; algún parámetro sensible (host, usuario) hardcodeado. |
| Insuficiente | 0–5 | Contraseñas o connection strings completos en el repositorio. |

### C4. Manejo de fallos y evidencia — 10 puntos

| Nivel | Puntos | Descripción |
|---|---|---|
| Excelente | 9–10 | Documenta una falla real, su diagnóstico y su corrección. Evidencia clara de ambos runs. Explica qué hizo el pipeline y por qué. |
| Bueno | 6–8 | Muestra la falla y la corrección, pero sin análisis de la causa. |
| Suficiente | 3–5 | Solo hay evidencia de ejecuciones exitosas. |
| Insuficiente | 0–2 | Sin evidencia. |

### C5. Documentación del repositorio — 5 puntos

| Nivel | Puntos | Descripción |
|---|---|---|
| Excelente | 5 | `README.md` permite que un tercero reproduzca el setup completo sin preguntar nada. Lista secretos requeridos y comandos exactos. |
| Bueno | 3–4 | Documentación presente pero con vacíos que exigen inferencia. |
| Suficiente | 1–2 | README mínimo o genérico. |
| Insuficiente | 0 | Sin documentación. |

### C6. Sustentación oral — 10 puntos

| Nivel | Puntos | Descripción |
|---|---|---|
| Excelente | 9–10 | Demo en vivo fluida dentro del tiempo. Justifica decisiones técnicas con criterio propio. Responde con solvencia preguntas sobre comportamiento ante fallos. |
| Bueno | 6–8 | Demo funciona; explicación correcta pero descriptiva más que argumentativa. |
| Suficiente | 3–5 | Presenta capturas en lugar de demo en vivo, o excede significativamente el tiempo. |
| Insuficiente | 0–2 | No sustenta, o no puede explicar código de su propio repositorio. |

---

## 7. Preguntas típicas de la sustentación

Prepárate para responder:

1. Si dos compañeros crean `V5__` al mismo tiempo en branches distintos y ambos hacen
   merge, ¿qué pasa? ¿Cómo lo previenes?
2. ¿Por qué Flyway no permite modificar una migración ya aplicada? ¿Qué mecanismo usa para
   detectarlo?
3. ¿Cuándo usarías una migración repetible (`R__`) en lugar de una versionada (`V__`)?
4. Tu workflow falló a mitad de una migración. ¿En qué estado quedó la base de datos?
5. ¿Cómo agregarías un entorno `staging` sin duplicar el workflow?

---

## 8. Recursos

- Sesión 1 — [Estado base](../Cap_1_Fundamentos_DataOps/sesion_01_estado_base/)
- Sesión 2 — [CI/CD con Flyway](../Cap_1_Fundamentos_DataOps/sesion_02_cicd_flyway/)
- Plantilla de workflow — [`.github/workflows/flyway-migrate.yml`](../.github/workflows/flyway-migrate.yml)
- Documentación oficial de Flyway — https://documentation.red-gate.com/flyway
- Neon branching — https://neon.tech/docs/introduction/branching

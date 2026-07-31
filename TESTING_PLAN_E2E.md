# Plan de pruebas End-to-End

**Módulo:** Tendencias emergentes en desarrollo de software (SI6010-5979) · Pos ST1707
**Propósito:** verificar, sesión por sesión, que todo el material del curso **funciona**
antes de dictarlo, y dejar registro de los pasos que requieren intervención humana contra
servicios cloud reales.

---

> 🚧 **ESQUELETO.** Este documento está intencionalmente incompleto. Los procedimientos
> paso a paso de cada sesión se redactan **al final de la serie de prompts**, cuando ya
> exista el código real de cada sesión y se pueda escribir contra artefactos verificables
> en lugar de contra intenciones.
>
> Lo único completo hoy es la **sección 0** (estado del entorno local, verificado el
> 31/07/2026) y la **sección 9** (pendientes bloqueantes).

---

## 0. Estado del entorno local

Verificado el **31/07/2026** sobre macOS (Darwin 25.5.0, Apple Silicon), shell `bash`.

### 0.1 Herramientas instaladas y verificadas

| Herramienta | Versión | Estado | Notas |
|---|---|---|---|
| `uv` | 0.8.15 | ✅ Instalado | Gestor de proyectos/paquetes Python del curso |
| `git` | 2.45.2 | ✅ Instalado | |
| `gh` (GitHub CLI) | 2.97.0 | ⚠️ Instalado, **sin autenticar** | Ver sección 9.1 |
| `flyway` | 13.1.0 (OSS Edition) | ✅ Instalado | Vía `brew install flyway`; trae su propio JRE |
| Homebrew | 4.5.8 | ✅ Instalado | |
| Python (sistema) | 3.9.6 | ℹ️ Presente | **No se usa directamente.** `uv` gestiona su propia versión de Python por proyecto |

### 0.2 Herramientas deliberadamente NO instaladas globalmente

| Herramienta | Por qué no | Cómo se instalará |
|---|---|---|
| `dbt-core` / `dbt-snowflake` | Convención del curso: nada de Python global | `uv add dbt-snowflake` dentro de [`Cap_3_Transformacion_Entrega/sesion_07_dbt_incremental/proyecto/`](Cap_3_Transformacion_Entrega/sesion_07_dbt_incremental/proyecto/) |
| `snowflake-connector-python` | Ídem | `uv add snowflake-connector-python` dentro del proyecto de ingesta de la Sesión 4 |
| Driver de PostgreSQL (`psycopg`) | Ídem | `uv add "psycopg[binary]"` dentro del proyecto de ingesta de la Sesión 4 |

> **Regla del repositorio:** ningún `pip install` global, ningún `venv` creado a mano,
> ningún `requirements.txt` escrito a mano. Si un workflow externo lo exige, se genera con
> `uv export --format requirements-txt --no-hashes`.

**Prueba de resolución (31/07/2026).** Aunque no se instaló nada globalmente, se verificó
que el stack completo resuelve sin conflictos, en un directorio temporal desechable:

```bash
uv pip compile req.in --python-version 3.12   # dbt-core, dbt-snowflake,
                                              # snowflake-connector-python, psycopg[binary], pandas
```

Versiones resueltas — útiles como referencia al hacer `uv add` en las sesiones:

| Paquete | Versión resuelta |
|---|---|
| `dbt-core` | 1.12.0 |
| `dbt-snowflake` | 1.12.0 |
| `dbt-adapters` | 1.24.5 |
| `snowflake-connector-python` | 4.7.1 |
| `psycopg` | 3.3.4 |
| `pandas` | 3.0.5 |

⚠️ El Python del sistema es **3.9.6**, insuficiente para este stack. La resolución se hizo
contra **Python 3.12**; cada proyecto debe fijar `requires-python = ">=3.12"` en su
`pyproject.toml` y dejar que `uv` descargue el intérprete.

### 0.3 Comandos de verificación del entorno

```bash
uv --version
git --version
gh --version
gh auth status          # debe reportar una cuenta autenticada
flyway -v
```

### 0.4 Instalación en una máquina limpia

```bash
# uv (script oficial de Astral)
curl -LsSf https://astral.sh/uv/install.sh | sh

# macOS — Homebrew
brew install flyway gh

# Autenticación de GitHub
gh auth login
```

---

## 1. Sesión 1 — Estado base

**Fecha:** 01/08/2026 · **Aula:** 34-302

### 1.1 Precondiciones
### 1.2 Verificación local
### 1.3 Verificación contra Neon.tech *(human-in-the-loop)*
### 1.4 Criterios de aceptación
### 1.5 Problemas conocidos y workarounds

---

## 2. Sesión 2 — CI/CD con Flyway

**Fecha:** 08/08/2026 · **Aula:** 33-302

### 2.1 Precondiciones
### 2.2 Verificación local de las migraciones
### 2.3 Verificación del workflow en GitHub Actions *(human-in-the-loop)*
### 2.4 Prueba de fallo controlado
### 2.5 Criterios de aceptación
### 2.6 Problemas conocidos y workarounds

---

## 3. Sesión 3 — Sustentación Momento 1

**Fecha:** 14/08/2026 · **Aula:** 35-203 · *evaluativa*

### 3.1 Verificación del enunciado y la rúbrica
### 3.2 Simulacro de calificación sobre una entrega de referencia
### 3.3 Logística de la sesión (proyector, red, tiempos)
### 3.4 Criterios de aceptación

---

## 4. Sesión 4 — Ingesta hacia Snowflake

**Fecha:** 15/08/2026 · **Aula:** 34-302

### 4.1 Precondiciones
### 4.2 Verificación del proyecto `uv` (`uv sync`, `uv run`)
### 4.3 Verificación del setup de Snowflake *(human-in-the-loop)*
### 4.4 Verificación de la extracción desde Neon *(human-in-the-loop)*
### 4.5 Criterios de aceptación
### 4.6 Problemas conocidos y workarounds

---

## 5. Sesión 5 — Internal Stages

**Fecha:** 21/08/2026 · **Aula:** 35-203

### 5.1 Precondiciones
### 5.2 Verificación de `PUT` y `COPY INTO` *(human-in-the-loop)*
### 5.3 Prueba de idempotencia (doble ejecución)
### 5.4 Verificación de bitácora y validaciones
### 5.5 Criterios de aceptación
### 5.6 Problemas conocidos y workarounds

---

## 6. Sesión 6 — Sustentación Momento 2

**Fecha:** 22/08/2026 · **Aula:** 33-302 · *evaluativa*

### 6.1 Verificación del enunciado y la rúbrica
### 6.2 Simulacro de calificación sobre una entrega de referencia
### 6.3 Logística de la sesión
### 6.4 Criterios de aceptación

---

## 7. Sesión 7 — dbt e incremental models

**Fecha:** 28/08/2026 · **Aula:** 35-203

### 7.1 Precondiciones
### 7.2 Verificación del proyecto dbt (`dbt parse`, `dbt compile`)
### 7.3 Verificación de `dbt build` contra Snowflake *(human-in-the-loop)*
### 7.4 Verificación del comportamiento incremental (1.ª vs 2.ª corrida)
### 7.5 Verificación de la app Streamlit in Snowflake *(human-in-the-loop)*
### 7.6 Criterios de aceptación
### 7.7 Problemas conocidos y workarounds

---

## 8. Sesión 8 — Sustentación Momento 3 (Final)

**Fecha:** 29/08/2026 · **Aula:** 34-302 · *evaluativa y final*

### 8.1 Verificación del enunciado y la rúbrica
### 8.2 Ensayo completo del cambio E2E (Neon → Flyway → Snowflake → dbt → Streamlit)
### 8.3 Simulacro de calificación sobre una entrega de referencia
### 8.4 Logística de la sesión final
### 8.5 Criterios de aceptación

---

## 9. Pendientes bloqueantes

Acciones que **el docente debe ejecutar manualmente** — quedaron fuera del alcance
automatizable del scaffold.

### 9.1 ✅ Repositorio remoto en GitHub — RESUELTO (31/07/2026)

| Campo | Valor |
|---|---|
| URL | https://github.com/davilla41/data_ops_course_101 |
| Visibilidad | **Público** — los estudiantes clonan directamente |
| Branch por defecto | `main` |
| Cuenta | `davilla41` (scopes `repo`, `workflow`, `read:org`, `gist`) |
| Workflow registrado | *Flyway Migrate* — estado `active` |

El scaffold completo (32 archivos) está pusheado y `main` local rastrea `origin/main`.

```bash
# Verificación
git remote -v
gh repo view davilla41/data_ops_course_101
gh workflow list
```

### 9.2 🟡 Configurar GitHub Secrets del workflow de Flyway

La plantilla [`.github/workflows/flyway-migrate.yml`](.github/workflows/flyway-migrate.yml)
espera seis secretos que aún no existen:

`FLYWAY_URL_DEV`, `FLYWAY_USER_DEV`, `FLYWAY_PASSWORD_DEV`,
`FLYWAY_URL_PROD`, `FLYWAY_USER_PROD`, `FLYWAY_PASSWORD_PROD`.

```bash
gh secret set FLYWAY_URL_DEV --body 'jdbc:postgresql://<host>/<db>?sslmode=require'
# ... repetir para cada secreto
```

Hasta que existan, el workflow fallará — es el comportamiento esperado, no un defecto.

### 9.3 🟡 Confirmar la asignación de aulas de los sábados

El programa indica que los sábados alternan entre **34-302** y **33-302**, sin especificar
cuál corresponde al 01/08. Todo el material asume, **de forma provisional**, la secuencia:

| Fecha | Aula asumida |
|---|---|
| 01/08 | 34-302 |
| 08/08 | 33-302 |
| 15/08 | 34-302 |
| 22/08 | 33-302 |
| 29/08 | 34-302 |

Los viernes (14/08, 21/08, 28/08) son siempre **35-203** — ese dato sí está confirmado.

**Estado:** el docente confirmó el 31/07/2026 que la secuencia queda así por ahora y que
la ajustará tras verificar con la coordinación del programa. **No es bloqueante** para
generar el contenido de las sesiones.

Archivos a corregir si la secuencia resulta invertida: [README.md](README.md) (tabla de
cronograma, sección 4) y el `README.md` de cada una de las cinco sesiones de sábado.

### 9.4 🟡 Provisionar las cuentas cloud del docente

Ninguna se probó en este scaffold (fuera de alcance por diseño): Neon.tech, Snowflake
trial, dbt Cloud.

⚠️ **Los trials de Snowflake duran 30 días.** Si se activa el 01/08 vence
aproximadamente el **31/08** — apenas después de la sesión final del 29/08. Margen
estrecho: **no activar el trial antes del 01/08**.

### 9.5 🟢 Agregar los datos semilla de Parch & Posey

[`data/`](data/) tiene solo su README. Los CSV se agregan con el contenido de la Sesión 1.

---

## 10. Registro de ejecuciones del plan

| Fecha | Secciones ejecutadas | Resultado | Quién |
|---|---|---|---|
| 31/07/2026 | 0 — entorno local | ✅ `uv` 0.8.15, `git` 2.45.2, `flyway` 13.1.0 instalados y verificados. Stack Python resuelto contra 3.12 sin conflictos. | Scaffold inicial |
| 31/07/2026 | 9.1 — repositorio remoto | ✅ `davilla41/data_ops_course_101` creado público, 32 archivos pusheados, workflow *Flyway Migrate* registrado como `active` | Scaffold inicial |
| | | | |

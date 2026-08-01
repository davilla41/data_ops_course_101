# Plan de pruebas End-to-End

**Módulo:** Tendencias emergentes en desarrollo de software (SI6010-5979) · Pos ST1707
**Propósito:** verificar, sesión por sesión, que todo el material del curso **funciona**
antes de dictarlo, y dejar registro de los pasos que requieren intervención humana contra
servicios cloud reales.

---

> 🚧 **EN CONSTRUCCIÓN.** Cada sección se redacta cuando existe el código real de su
> sesión, para escribir contra artefactos verificables en lugar de contra intenciones.
>
> **Completas:** sección 0 (entorno local), sección 1 (Sesión 1) y sección 9 (pendientes).
> **Esqueleto:** secciones 2 a 8.

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

**Fecha:** 01/08/2026 · **Aula:** 34-302 · **Estado:** ✅ **verificado de extremo a extremo**
el 31/07/2026, incluida la carga contra Neon real y la comprobación de aislamiento.

### 1.1 Precondiciones

| # | Condición | Comando de verificación | Estado 31/07/2026 |
|---|---|---|---|
| P1 | `uv` instalado | `uv --version` | ✅ 0.8.15 |
| P2 | Los 5 JSON semilla presentes | `ls data/*.json \| wc -l` → `5` | ✅ |
| P3 | Proyecto `uv` de la sesión sincronizable | `cd .../codigo && uv sync` | ✅ Python 3.12.13, 2 paquetes |
| P4 | Node ≥ 18 (solo para renderizar la presentación) | `node --version` | ✅ v18.15.0 |
| P5 | Proyecto de Neon con branches `main` y `dev` | Neon Console | ✅ `parch_posey_dataops`, AWS us-east-2 |

### 1.2 Verificación local — datos semilla

Ejecutado el 31/07/2026. No requiere base de datos.

```bash
python3 - <<'PY'
import json
L = lambda f: json.load(open(f'data/{f}.json'))
reg, sr, ac, od, we = L('regions'), L('sales_reps'), L('accounts'), L('orders'), L('web_events')
assert not [r for r in sr if r['region_id'] not in {x['id'] for x in reg}]
assert not [a for a in ac if a['sales_rep_id'] not in {x['id'] for x in sr}]
assert not [o for o in od if o['account_id'] not in {x['id'] for x in ac}]
assert not [w for w in we if w['account_id'] not in {x['id'] for x in ac}]
print('OK', [len(x) for x in (reg, sr, ac, od, we)])
PY
```

**Resultado esperado:** `OK [4, 50, 351, 6912, 9073]`
**Resultado obtenido:** ✅ coincide. Sin huérfanos, sin nulos, `id` únicos en las 5 tablas.

### 1.3 Verificación local — el script contra PostgreSQL efímero

Ejecutado el 31/07/2026 contra `postgres:16-alpine` en Docker. **Esto no reemplaza la
verificación contra Neon**, pero valida toda la lógica del script sin depender de la nube.

```bash
docker run -d --name pg_dataops_test \
  -e POSTGRES_PASSWORD=test -e POSTGRES_DB=parch_posey \
  -p 55432:5432 postgres:16-alpine

cd Cap_1_Fundamentos_DataOps/sesion_01_estado_base/codigo
uv sync
export NEON_DEV_DATABASE_URL="postgresql://postgres:test@localhost:55432/parch_posey"

uv run inyeccion_semilla.py --solo-verificar   # A
uv run inyeccion_semilla.py                    # B
uv run inyeccion_semilla.py                    # C — idempotencia
NEON_MAIN_DATABASE_URL="$NEON_DEV_DATABASE_URL" uv run inyeccion_semilla.py   # D — guardrail

docker rm -f pg_dataops_test
```

| Caso | Esperado | Obtenido |
|---|---|---|
| A — base vacía | Las 5 tablas como `(no existe)`, exit 0 | ✅ |
| B — carga inicial | 16 390 filas, todos los conteos `OK`, exit 0 | ✅ en 0.56 s |
| C — re-ejecución | Mismos conteos, sin duplicados, exit 0 | ✅ |
| D — guardrail `dev`==`main` | Aborta con mensaje explícito, **exit 1** | ✅ |

Comprobaciones adicionales sobre los datos ya cargados:

| Verificación | Esperado | Obtenido |
|---|---|---|
| Truncado de timestamp de 7 dígitos | `2015-10-06T17:31:14.0000000` → `2015-10-06 17:31:14` | ✅ |
| Precisión de `lat` / `long` | `40.23849561` / `-75.10329704` sin pérdida | ✅ |
| Tipos en `accounts` | `integer`, `text`, `numeric` — ningún `TEXT` numérico | ✅ |
| Foreign keys creadas | 4 | ✅ |
| Rango de `orders.occurred_at` | 2013-12-04 → 2017-01-02 | ✅ |
| Canales distintos en `web_events` | 6 | ✅ |

### 1.4 🛑 PUNTO DE PARADA — se requiere intervención humana

**Aquí el trabajo automatizable se agota.** Crear un proyecto en Neon exige un flujo
interactivo por navegador (registro, verificación de correo, selección de región): no hay
forma desatendida de hacerlo, y este plan no debe tocar servicios cloud reales por
iniciativa propia.

#### Lo que debe hacer el docente

1. Entrar a https://console.neon.tech y crear el proyecto:
   - **Name:** `parch_posey_dataops` · **Postgres:** 16 · **Region:** AWS `us-east-2`
   - **Neon Auth:** desactivado. Añadiría un schema `neon_auth` que luego habría que
     excluir del baseline de Flyway en la Sesión 2.
2. **Renombrar la branch por defecto de `production` a `main`.** Neon la crea como
   `production`; todo el material del curso asume `main`, para que el paralelo con git
   sea literal.
3. **Branches** → **Create branch**:
   - **Name:** `dev` · **Parent:** `main` · **Branch data and schema**
   - ⚠️ **Auto-delete: `Never`.** El valor por defecto (*After 1 day*) destruiría la
     branch —y el baseline de la Sesión 2— al día siguiente.
4. Copiar los dos connection strings (**Dashboard** → **Connection string**, cambiando la
   branch en el desplegable). Usar **Show password**: con la contraseña oculta se copian
   los asteriscos.

#### Cómo entregar las credenciales

Crear el archivo `.env` y **pegar los valores con un editor**:

```bash
cd Cap_1_Fundamentos_DataOps/sesion_01_estado_base/codigo
cp .env.example .env
code .env        # o el editor que prefieras
```

Debe quedar una variable por línea, sin comillas y sin espacios alrededor del `=`:

```dotenv
NEON_DEV_DATABASE_URL=postgresql://usuario:password@ep-xxxx-dev...aws.neon.tech/neondb?sslmode=require
NEON_MAIN_DATABASE_URL=postgresql://usuario:password@ep-yyyy...aws.neon.tech/neondb?sslmode=require
```

Verificar sin exponer las contraseñas:

```bash
sed -E 's#://[^:]+:[^@]+@#://***:***@#' .env
```

Deben aparecer dos URLs enmascaradas **con hosts distintos**. Si coinciden, no se cambió
el desplegable de branch en el Console.

> ⚠️ **No usar `read -rs` para esto.** Se intentó y falla: al pegar un bloque de varias
> líneas en la terminal, `read` no espera input del teclado — consume la línea siguiente
> del propio pegado y la guarda como si fuera el connection string. El `.env` termina
> conteniendo el texto del comando. Editar el archivo directamente es más simple y no
> tiene ese modo de fallo.

> **Sobre el manejo del secreto.** `.env` está excluido en el
> [`.gitignore`](.gitignore) raíz — confirmar con `git status --ignored | grep .env`.
> Cualquiera con acceso a esta sesión de terminal puede leer el archivo; si eso importa,
> usar una branch de Neon desechable y resetear la contraseña al terminar
> (**Neon Console** → **Roles** → **Reset password**).

#### Lo que se ejecuta después de recibir las credenciales

```bash
cd Cap_1_Fundamentos_DataOps/sesion_01_estado_base/codigo

uv run inyeccion_semilla.py --solo-verificar    # 1. dev debe estar vacía
uv run inyeccion_semilla.py                     # 2. carga real
uv run inyeccion_semilla.py --solo-verificar    # 3. confirmar 16 390 filas
```

Y la comprobación de aislamiento, que es el objetivo pedagógico de la sesión. Se apunta la
variable de dev al connection string de main y se vacía la de main para no disparar el
guardrail (la ejecución es de solo lectura):

```bash
NEON_DEV_DATABASE_URL="$(grep '^NEON_MAIN_DATABASE_URL=' .env | cut -d= -f2-)" \
NEON_MAIN_DATABASE_URL="" \
  uv run inyeccion_semilla.py --solo-verificar
```

**Ejecutado el 31/07/2026 contra el proyecto real:**

| Verificación | Esperado | Obtenido |
|---|---|---|
| Carga contra la branch `dev` | 16 390 filas, todos los conteos `OK` | ✅ |
| Estado de `dev` tras la carga | `4 / 50 / 351 / 6912 / 9073` | ✅ |
| Estado de `main` tras la carga | Las 5 tablas como `(no existe)` | ✅ **aislamiento confirmado** |

### 1.5 Verificación de la presentación

```bash
# desde la raíz del repositorio
npx @marp-team/marp-cli@latest \
  Cap_1_Fundamentos_DataOps/sesion_01_estado_base/presentacion/presentacion.md \
  --images png -o /tmp/slides/s.png
```

| Verificación | Esperado | Obtenido 31/07/2026 |
|---|---|---|
| Renderiza sin errores | exit 0 | ✅ |
| Número de slides | 15 | ✅ |
| Tema `dataops` aplicado (no fallback a `default`) | Serif en títulos, filete verde, footer gris itálico | ✅ |
| Ningún slide desborda el área visible | Revisión visual de los 15 PNG | ✅ tras corregir slides 4, 5, 9 y 11 |

### 1.6 Criterios de aceptación

- [x] Los 5 JSON semilla tienen integridad referencial completa y 16 390 registros.
- [x] `uv sync` reconstruye el entorno desde `uv.lock` en una máquina limpia.
- [x] El script crea el schema y carga los datos en una sola transacción.
- [x] Re-ejecutar el script no duplica datos.
- [x] El guardrail aborta con exit 1 cuando `dev` y `main` coinciden.
- [x] La presentación renderiza a 15 slides sin desbordes.
- [x] La carga funciona contra una branch `dev` real de Neon.
- [x] La branch `main` queda vacía tras la carga — el aislamiento del branching funciona.

**Sesión 1 verificada de extremo a extremo.** No quedan pendientes.

### 1.7 Problemas conocidos y workarounds

| Síntoma | Causa | Solución |
|---|---|---|
| El `.env` contiene el texto del comando en vez del connection string | Se usó `read -rs` pegando un bloque multilínea: `read` consumió la línea siguiente del pegado | Editar `.env` directamente en el editor — ver §1.4 |
| La branch `dev` desapareció al día siguiente | Se dejó **Auto-delete: After 1 day** al crearla | Recrearla con **Auto-delete: Never** y volver a cargar la semilla |
| Se copian asteriscos en lugar de la contraseña | El Console oculta la contraseña por defecto | Pulsar **Show password** antes de copiar |
| `SSL connection has been closed unexpectedly` | Falta `?sslmode=require` en el connection string | Copiar la URL completa del Console, no armarla a mano |
| La primera query tarda ~1 s o da timeout | Neon suspende el cómputo por inactividad; la branch está despertando | Reintentar. Es comportamiento normal, no un error |
| `ERROR: falta la variable NEON_DEV_DATABASE_URL` | No existe `.env`, o se ejecutó desde otro directorio | `cp .env.example .env` dentro de `codigo/` |
| `No se encontró la raíz del repositorio` | El script se ejecutó fuera del clon de git (ej. copiado a otra carpeta) | Ejecutar dentro del repositorio; el script busca `.git/` + `data/` subiendo por el árbol |
| El guardrail aborta con credenciales correctas | Se pegó el mismo connection string en ambas variables | Volver al Console y cambiar el desplegable de branch antes de copiar |
| `Marp: unknown theme "dataops"` en VS Code | Falta registrar el themeSet en el workspace | Ya resuelto en [`.vscode/settings.json`](.vscode/settings.json); recargar la ventana |

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

### 9.5 ✅ Datos semilla de Parch & Posey — RESUELTO (31/07/2026)

Los cinco archivos JSON están en [`data/`](data/) y verificados: 16 390 registros,
integridad referencial completa, sin nulos, `id` únicos. Ver [`data/README.md`](data/README.md)
y la sección §1.2 de este documento.

### 9.6 ✅ Proyecto de Neon para la Sesión 1 — RESUELTO (31/07/2026)

| Campo | Valor |
|---|---|
| Proyecto | `parch_posey_dataops` · Postgres 16 · AWS `us-east-2` |
| Branch principal | `main` — renombrada desde `production`; **vacía** |
| Branch de trabajo | `dev` — con el estado base cargado (16 390 filas) |
| Neon Auth | Desactivado |

Detalle de la verificación en **§1.4**.

> ℹ️ **Nota para la Sesión 2.** Los connection strings en uso son los de endpoint
> **`-pooler`**. Funcionan para la carga con psycopg2, pero Neon recomienda la conexión
> **directa** (sin `-pooler`) para DDL y migraciones. Si Flyway se comporta de forma
> extraña, ese es el primer sospechoso: probar el endpoint directo antes de investigar
> otra cosa.

---

## 10. Registro de ejecuciones del plan

| Fecha | Secciones ejecutadas | Resultado | Quién |
|---|---|---|---|
| 31/07/2026 | 0 — entorno local | ✅ `uv` 0.8.15, `git` 2.45.2, `flyway` 13.1.0 instalados y verificados. Stack Python resuelto contra 3.12 sin conflictos. | Scaffold inicial |
| 31/07/2026 | 9.1 — repositorio remoto | ✅ `davilla41/data_ops_course_101` creado público, 32 archivos pusheados, workflow *Flyway Migrate* registrado como `active` | Scaffold inicial |
| 31/07/2026 | 1.2, 1.3, 1.5 — Sesión 1 local | ✅ Semilla íntegra (16 390 reg.). Script validado contra `postgres:16-alpine`: carga, idempotencia, guardrail y tipos. Presentación: 15 slides sin desbordes | Contenido Sesión 1 |
| 31/07/2026 | 1.4 — Sesión 1 contra Neon | ✅ Proyecto `parch_posey_dataops` creado. Carga en `dev` correcta (16 390 filas); `main` verificada vacía — aislamiento confirmado | Docente + verificación asistida |

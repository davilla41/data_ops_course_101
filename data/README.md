# Datos semilla — Parch & Posey

Esta carpeta aloja los **datos semilla públicos** del caso de estudio del módulo:
**Parch & Posey**, un distribuidor ficticio de papel usado ampliamente como dataset
didáctico para SQL analítico.

## Modelo de datos

Cinco tablas relacionadas:

| Tabla | Descripción | Llave | Relación |
|---|---|---|---|
| `region` | Regiones comerciales | `id` | — |
| `sales_reps` | Representantes de ventas | `id` | `region_id` → `region.id` |
| `accounts` | Cuentas de clientes | `id` | `sales_rep_id` → `sales_reps.id` |
| `orders` | Órdenes de compra, con cantidades y montos por línea de producto (standard, gloss, poster) | `id` | `account_id` → `accounts.id` |
| `web_events` | Eventos de visita web por canal (organic, adwords, direct, facebook, twitter, banner) | `id` | `account_id` → `accounts.id` |

Volumen aproximado: ~7 000 órdenes, ~9 000 eventos web, ~350 cuentas. Es un dataset
pequeño **a propósito** — el foco del módulo es la ingeniería del pipeline, no el
procesamiento de gran volumen.

## Contenido previsto

```
data/
├── README.md          ← este archivo
├── seed/              ← CSV crudos de las 5 tablas (se versionan)
└── output/            ← artefactos generados por los scripts (ignorado por git)
```

- **`seed/`** — se versiona. Son archivos pequeños y son la fuente de verdad del caso.
- **`output/`** — **no** se versiona (excluido en [.gitignore](../.gitignore)). Aquí
  escriben los scripts de extracción de la Sesión 4 antes de subir a un Internal Stage.

## Cómo se usa a lo largo del módulo

| Sesión | Uso |
|---|---|
| 1 — Estado base | Carga inicial de los CSV en la base de datos Neon (PostgreSQL) |
| 2 — CI/CD con Flyway | El esquema de estas tablas es el baseline de las migraciones |
| 4 y 5 — Ingesta | Se extraen desde Neon y se cargan a Snowflake vía Internal Stage |
| 7 — dbt | Son las `sources` del proyecto de transformación |

## Origen y licencia

Parch & Posey es un dataset didáctico de dominio público, popularizado por el curso *SQL
for Data Analysis* de Udacity. No contiene datos personales reales — todas las cuentas,
nombres y transacciones son sintéticos.

---

> 🚧 **Pendiente:** los archivos CSV se agregan al generar el contenido de la
> [Sesión 1](../Cap_1_Fundamentos_DataOps/sesion_01_estado_base/).

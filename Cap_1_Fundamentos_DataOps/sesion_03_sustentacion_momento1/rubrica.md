# Rúbrica — Momento 1: CI/CD en Base de Datos

**Sesión:** 3 — viernes 14/08/2026, 18:00–21:00, aula 35-203
**Peso:** 30 % de la nota final · **Total: 100 puntos**

> 📄 **El enunciado completo, con objetivo, alcance, entregables y condiciones de entrega,
> está en [`evaluaciones/momento_1_cicd_bd.md`](../../evaluaciones/momento_1_cicd_bd.md).**
> Este archivo es el resumen operativo de calificación para el día de la sustentación.

---

## Criterios y puntajes

| # | Criterio | Puntos | Qué se busca |
|---|---|---|---|
| C1 | Migraciones Flyway | **30** | Baseline + ≥3 evolutivas + ≥1 repetible. Nombres correctos, migraciones atómicas, reconstrucción desde cero sin errores. |
| C2 | Workflow de CI/CD | **30** | Se dispara en PR y en merge a `main`, diferencia entornos, falla ruidosamente cuando debe. |
| C3 | Gestión de secretos | **15** | Cero credenciales en el repositorio (también en el historial). GitHub Secrets bien usados. |
| C4 | Manejo de fallos y evidencia | **10** | Una falla real documentada, diagnosticada y corregida, con evidencia de ambos runs. |
| C5 | Documentación del repositorio | **5** | Un tercero reproduce el setup sin preguntar nada. |
| C6 | Sustentación oral | **10** | Demo en vivo en 10 min, decisiones justificadas, respuestas solventes. |
| | **Total** | **100** | |

Los descriptores por nivel (Excelente / Bueno / Suficiente / Insuficiente) de cada
criterio están detallados en la
[sección 6 del enunciado](../../evaluaciones/momento_1_cicd_bd.md#6-rúbrica-de-evaluación).

---

## Checklist rápido de verificación

Antes de calificar, confirmar sobre el repositorio del estudiante:

- [ ] `flyway migrate` reconstruye la base desde cero sin intervención manual.
- [ ] Existe migración baseline, ≥3 versionadas (`V__`) y ≥1 repetible (`R__`).
- [ ] Hay al menos un run **exitoso** en GitHub Actions.
- [ ] Hay al menos un run **fallido** con su corrección posterior documentada.
- [ ] `git log -p` no revela credenciales en ningún commit.
- [ ] El `README.md` lista los secretos requeridos y los comandos exactos.
- [ ] Si es entrega en parejas: **ambos** tienen commits y **ambos** sustentan.

---

## Logística de la sesión

| Bloque | Duración | Actividad |
|---|---|---|
| Apertura | 15 min | Encuadre de la evaluación y orden de sustentaciones |
| Sustentaciones | ~2 h 15 min | 15 min por equipo (10 exposición + 5 preguntas) |
| Cierre | 30 min | Retroalimentación grupal y puente hacia el Capítulo 2 |

**Requisito técnico:** los equipos deben verificar conectividad y credenciales **antes**
de su turno. Problemas de setup no descuentan tiempo de sustentación de los demás.

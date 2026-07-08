# SF Crime Data Warehouse

An end-to-end analytics engineering project built with **dbt + DuckDB**, transforming raw San Francisco crime data into an analytics-ready dimensional model.

Demonstrates: source profiling, dimensional modeling, grain resolution, and dbt-enforced data quality testing.

---

## Project Overview

Transforms raw SFPD incident records into a clean warehouse that answers:

- How has crime changed over time?
- Which neighborhoods/districts see the most incidents?
- What crime categories are most common?
- What percentage of offenses are resolved?

**Fact grain:** one row = one offense (`Incident Number + Incident Code`), reflecting its latest authoritative state.

Incident Number = the overall case.
Incident ID = a write-up/report filed for that case, containing a batch of offense codes.
Incident Code = one offense within that batch.

**dbt implementation:** staging's native grain is `incident_id + incident_code` (one row per offense-per-report, per SFPD docs); intermediate collapses that to `incident_number + incident_code` via `ROW_NUMBER()` (resolution priority → latest report_datetime → `incident_id` as final tiebreak); marts/fact select only `incident_number + incident_code` — `incident_id` did its job upstream and never surfaces downstream.

---

## Architecture

```
Raw Crime CSV → Landing → Staging (dbt) → Intermediate (dedup) → Marts → BI
```

| Tool | Purpose |
|---|---|
| DuckDB | Local analytical database |
| dbt | Transformations, testing, docs |
| Python/pandas | Source profiling |

---

## Key Finding: Source Grain vs. Analytical Grain

Initial design assumed `Incident Number` was the atomic crime entity. Profiling revealed a three-level hierarchy, later confirmed by [SFPD's official data dictionary](https://sfdigitalservices.gitbook.io/dataset-explainers/sfpd-incident-report-2018-to-present):

```
Incident Number (the case / "Case Number")
    └── Incident ID (a report: Initial, Vehicle Supplement, or Coplogic Supplement)
            └── Incident Code (an offense recorded on that report)
```

A single case can span multiple reports filed over time (initial + supplements), and each report can carry one or more offense codes. `Incident ID + Incident Code` is the source system's own documented unique row — verified in this warehouse via a `dbt_utils.unique_combination_of_columns` test on staging (passing across all 937k rows).

> **Profiling and source documentation confirmed that `Incident Number` represents a case that can span multiple reports and offenses. The warehouse models the fact table at the `Incident Number + Incident Code` grain to preserve offense-level detail, with uniqueness verified by dbt tests at both the staging (`incidentId + incidentCode`) and intermediate (`incidentNumber + incidentCode`) layers.**

This grain choice means one incident (e.g. a burglary arrest involving conspiracy and possession charges) correctly produces multiple fact rows — one per offense — rather than arbitrarily collapsing to a single category.

---

## Deduplication Logic

Each offense (`Incident Number + Incident Code`) may have multiple report updates over its lifecycle. The intermediate layer collapses these to one authoritative row:

1. Prefer a finalized resolution (`Cite or Arrest Adult`, `Exceptional Adult`, `Unfounded`) over `Open or Active`.
2. Among candidates, take the latest `Report Datetime`.
3. On a true timestamp tie (common when two separate reports — e.g. an Initial and a Supplement — land at the same rounded timestamp), break with `Incident ID` descending, since it's the system-assigned, monotonically increasing report identifier.

```sql
row_number() over (
    partition by incidentNumber, incidentCode
    order by
        case when resolution in ('Cite or Arrest Adult','Exceptional Adult','Unfounded')
             then 1 else 0 end desc,
        reportDatetime desc,
        incidentId desc
) as rn
```

**Impact:**

| Statistic | Value |
|---|---:|
| Raw report rows | 937,866 |
| Canonical offense rows | 883,613 |
| Rows collapsed | 54,253 (5.78%) |
| Avg. reports per incident | 1.40 |
| Avg. reports per incident-offense | 1.06 |

The low collapse rate confirms most removed rows are report-lifecycle noise (supplements/updates), not distinct analytical events — the grain choice loses minimal information while eliminating duplication.

---

## dbt Model Structure

```
models/
├── staging/
│   └── stg_crime_incidents.sql        (native grain: incidentId + incidentCode)
├── intermediate/
│   └── int_latest_crime_incidents.sql (dedup → incidentNumber + incidentCode)
└── marts/
    ├── facts/
    │   └── fct_incident_offenses.sql
    └── dimensions/
        ├── dim_date.sql
        ├── dim_geo.sql
        └── dim_offense_category.sql
```

**Staging** preserves source fidelity (clean types, standardize category strings, filter invalid/placeholder incident numbers like `000000000`). **Intermediate** applies the dedup business rule above. **Marts** expose analyst-friendly naming — e.g. `offenseCategory` instead of the source's `Incident Category`, since the fact table's grain is the offense, not the whole case.

---

## Fact & Dimensions

**`fct_incident_offenses`** — grain: 1 row = 1 Incident Number + 1 Incident Code. Contains offense/geo/category keys, resolution, lat/long as descriptive attributes (low-cardinality, no reuse case — kept in-fact rather than dimensionalized).

| Dimension | Supports |
|---|---|
| `dim_date` | Trends, seasonality, day-of-week |
| `dim_geo` | Neighborhood, district, lat/long |
| `dim_offense_category` | Standardized category, broad grouping (Violent/Property/etc.), severity rank |

Incident-level metrics (e.g. "how many police cases occurred?") remain available via `COUNT(DISTINCT incident_number)` against the fact table.

---

## Data Quality Tests

```yaml
- name: stg_crime_incidents
  tests:
    - dbt_utils.unique_combination_of_columns:
        arguments:
          combination_of_columns: [incidentId, incidentCode]

- name: int_latest_crime_incidents
  tests:
    - dbt_utils.unique_combination_of_columns:
        arguments:
          combination_of_columns: [incidentNumber, incidentCode]
```

Plus standard `not_null`/`unique` checks on dimension surrogate keys and `accepted_values` on `resolution`.

---

## Running Locally

```bash
pip install -r requirements.txt
dbt deps
dbt debug
dbt build          # run all models + tests
```

Run a specific layer:
```bash
dbt build --select staging
dbt build --select intermediate
dbt build --select marts.facts
dbt build --select marts.dimensions
```

---

## Future Improvements

- Incremental models for new incident ingestion
- Airflow orchestration
- Cloud warehouse deployment
- BI dashboard layer
- Snapshots to track offense resolution history over time

---

## Lessons Learned

The core challenge wasn't SQL — it was determining the correct business grain. `Incident Number` looked like the natural entity, but source profiling and SFPD's own documentation revealed a case → report → offense hierarchy that would have silently dropped offense-level detail if modeled naively. The final design preserves that detail while still supporting incident-level rollups, backed by dbt tests that make the grain claim verifiable rather than assumed.

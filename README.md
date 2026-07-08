# SF Crime Data Warehouse

An end-to-end data engineering and analytics warehouse project built using **dbt + DuckDB** to transform raw San Francisco crime data into analytics-ready dimensional models.

The project demonstrates modern analytics engineering practices including:

* Data ingestion and staging
* Data cleaning and standardization
* Dimensional modeling
* Fact/dimension design
* Data quality testing
* Reproducible transformations using dbt

---

# Project Overview

The goal of this project is to transform raw crime records into a clean analytical warehouse that enables users to answer questions such as:

* How has crime changed over time?
* Which neighborhoods experience the most incidents?
* What categories of crime are most common?
* How do crime patterns differ by police district?
* What percentage of incidents are resolved?

The final warehouse models crime data at the **incident-offense grain**, where each row represents the latest authoritative state of one offense associated with a police incident.
---

# Architecture

```
Raw Crime Dataset
        |
        v
Landing Layer
        |
        v
Staging Models (dbt)
        |
        v
Analytics Marts
        |
        v
BI / Analytics
```

## Technology Stack

| Tool     | Purpose                             |
| -------- | ----------------------------------- |
| DuckDB   | Local analytical database           |
| dbt      | SQL transformations and modeling    |
| Python   | Data preparation/scripts            |
| DataGrip (recommended) | Database exploration and validation |

---

# Data Modeling Approach

## Fact Table Grain

The primary analytical fact table is modeled at the incident-offense grain:

> One row = one Incident Number + one Incident Code

During data profiling, it was discovered that a single Incident Number may contain multiple offense classifications (Incident Codes). Each offense can also have multiple report records over its lifecycle as officers submit initial reports, supplements, and resolution updates.

For example:

```text
Incident Number: 260065646

Burglary
Conspiracy
Burglary Tools
```

These represent separate offenses associated with the same police incident rather than duplicate records.

The warehouse therefore preserves offense-level detail while removing duplicate report updates, allowing downstream users to analyze both offense-level metrics and incident-level metrics without losing information.

---

# Source Data Grain vs Analytical Grain

The source crime dataset contains three conceptual levels of information:

1. Police incident (Incident Number)
2. Offense classifications within that incident (Incident Code)
3. Multiple report records describing updates to each offense over time

For example:

```text
Incident Number
    |
    +-- Burglary
    |     |
    |     +-- Initial Report
    |     +-- Supplemental Report
    |
    +-- Conspiracy
    |     |
    |     +-- Initial Report
    |     +-- Supplemental Report
    |
    +-- Burglary Tools
          |
          +-- Initial Report
          +-- Supplemental Report
```

Although these records belong to the same police incident, they represent distinct offenses whose report histories evolve independently.

### Choosing the Analytical Grain

Rather than collapsing all offenses into a single incident record, the warehouse preserves the finest meaningful analytical grain:

> One row = one Incident Number + one Incident Code

This allows the warehouse to retain every offense classification while eliminating duplicate report updates generated throughout an investigation.

### Resolving Multiple Reports

Because each offense may have multiple reports over time, the intermediate layer selects a single authoritative record for every Incident Number + Incident Code combination.

The selection logic is:

1. Prefer finalized resolutions (Cite or Arrest Adult, Exceptional Adult, Unfounded).
2. If multiple finalized reports exist, select the most recent report.
3. If no finalized report exists, select the latest available report.

This produces one canonical analytical record for each offense while preserving the complete set of offenses associated with every incident.

---

# dbt Model Structure

```
models/

├── staging/
│   └── stg_crime_incidents.sql

├── intermediate/
│   └── int_latest_crime_incidents.sql

└── marts/
    ├── fact_crime_incidents.sql
    ├── dim_date.sql
    ├── dim_geo.sql
    └── dim_incident_category.sql
```

---

# Staging Layer

Purpose:

* Remove invalid records
* Clean raw fields
* Standardize naming conventions
* Cast data types
* Normalize categories

Examples:

Raw:

```
Incident Category
Analysis Neighborhood
Police District
```

becomes:

```
incidentCategory
neighborhood
district
```

The staging layer intentionally preserves source information while making it easier to consume.

---

# Intermediate Layer
Purpose:

Apply business logic that should not exist in staging.

Example:
* Resolve multiple report records for each offense
* Deduplicate report history
* Select the latest authoritative state for every Incident Number + Incident Code

This layer answers:

> "What is the latest analytical representation of this offense?"

Example ranking / deduplication (keeping rn=1): 
Incident Code	Report	Resolution	Priority	rn	Why?
05171	Jan 5	Cite or Arrest Adult	1	1	Latest finalized report
05171	Jan 3	Open or Active	0	2	Lower priority
05171	Jan 1	Open or Active	0	3	Older open report
26080	Jan 4	Open or Active	0	1	No finalized reports, so latest report wins
26080	Jan 1	Open or Active	0	2	Older report
27130	Jan 2	Unfounded	1	1	Finalized beats newer Open report
27130	Jan 6	Open or Active	0	2	Newer, but lower priority
27130	Jan 1	Open or Active	0	3	Oldest report
---

Original rows: 937,866
Latest offense rows: 883,613
Rows removed: 54,253
Reduction: 5.78%

| Statistic                                     |    Value |
| --------------------------------------------- | -------: |
| Average reports per incident                  | **1.40** |
| Average reports per incident-offense          | **1.06** |
| Maximum reports for a single incident         |  **229** |
| Maximum reports for a single incident-offense |  **186** |

In short, deduplicated incident-offense records by retaining the latest authoritative report for each offense: removed operational report history, not analytical events.

# Analytics Marts

The final models are designed for BI and analysis.

## Fact: Incident Offenses
Grain:

```
1 row = 1 Incident Number + 1 Incident Code
```

Contains:

* Incident identifiers
* Dates
* Category keys
* Geography keys
* Resolution status

---

## Dimensions

### Date Dimension

Supports:

* Year analysis
* Monthly trends
* Day-of-week analysis

---

### Geography Dimension

Supports:

* Neighborhood analysis
* Police district analysis
* Location-based reporting

---

### Crime Category Dimension

Provides standardized crime classifications.

---

# Data Quality Considerations

dbt tests validate:

* Unique incident identifiers
* Required fields
* Referential integrity
* Valid categories
* Non-null critical attributes

Example:

```yaml
tests:
  - unique
  - not_null
```

---

# Key Design Decisions

## Why Incident-Offense Grain Instead of Report Grain?
The source dataset is captured at the report level, where multiple records may describe the same offense as an investigation progresses.

Modeling directly at report grain would require every downstream user to understand police reporting workflows and avoid counting supplemental reports as separate analytical events.

Instead, the warehouse resolves report history into one authoritative record per Incident Number + Incident Code.

This preserves every offense while removing operational noise introduced by repeated report updates.

Incident-level analysis remains available through aggregation using Incident Number.

---

## Why Keep Raw Report Information?

Although analytics use incident grain, the raw/report-level data is preserved because it may support future analysis:

* Time to resolution
* Number of updates per incident
* Data correction history
* Reporting workflow analysis

---

# Running Locally

## Install dependencies

```bash
pip install -r requirements.txt

dbt deps  (to install db utils)
```

## Validate dbt connection

```bash
dbt debug
```

## Run transformations

```bash
dbt run --select staging
dbt run --select intermediate       
dbt run --select path:models/marts/dimensions

or 

dbt build
```

## Run tests

```bash
dbt test
```

---

# Future Improvements

Potential extensions:

* Add incremental models for new crime ingestion
* Add Airflow orchestration
* Deploy warehouse to cloud storage/warehouse
* Add BI dashboard layer
* Track incident history using snapshots

---

# Lessons Learned

This project demonstrates that analytics engineering is not only about writing SQL transformations. The most important decisions involve:

* Choosing the correct business grain
* Separating source data from analytical models
* Moving business logic upstream
* Designing tables around user questions rather than source-system structure

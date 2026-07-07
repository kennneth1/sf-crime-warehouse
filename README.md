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

The final warehouse models crime data at the **incident grain**, where each row represents one unique crime incident.

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

The primary analytical fact table uses:

> One row = one unique crime incident

The source dataset contains multiple report records for some incidents. These represent updates or changes to an incident record rather than separate crimes.

Example:

```
Incident Number: 12345

Report 1:
  Category = Theft
  Resolution = NULL

Report 2:
  Category = Theft
  Resolution = Arrest

Report 3:
  Category = Theft
  Resolution = Closed
```

The warehouse resolves these multiple records into a single analytical incident.

This prevents downstream users from accidentally counting multiple reports as multiple crimes.

---

# Handling Multiple Reports Per Incident

The source system contains report-level records, but analytics are primarily performed at the incident level.

The transformation logic:

1. Partition records by incident number
2. Prefer the most complete/current incident representation
3. Retain the latest known state of the incident

Example logic:

```
For each incident:

If resolved:
    choose the latest resolved record

If unresolved:
    choose the latest available record
```

This creates a single authoritative incident record.

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

Examples:

* Deduplicate incidents
* Resolve multiple reports per incident
* Select authoritative incident records

This layer answers:

> "What single record represents this crime incident?"

---

# Analytics Marts

The final models are designed for BI and analysis.

## Fact: Crime Incidents

Grain:

```
1 row = 1 incident
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

## Why Incident Grain Instead of Report Grain?

Report grain is more atomic but less useful for general analytics.

A report-level fact table requires every downstream user to remember:

* Multiple reports may represent one crime
* Counts must use distinct incident IDs
* Latest-record logic must be applied

The warehouse instead resolves this complexity upstream.

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
```

## Validate dbt connection

```bash
dbt debug
```

## Run transformations

```bash
dbt run
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

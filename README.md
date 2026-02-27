# CMS HCAHPS Healthcare Analytics Project

## Overview

This project analyzes 2024 CMS HCAHPS (Hospital Consumer Assessment of Healthcare Providers and Systems) data using MySQL to evaluate how hospital characteristics relate to patient satisfaction outcomes.

The primary KPI analyzed:

> **% of patients who would definitely recommend the hospital**
> Measure ID: `H_RECMND_DY`

The goal is to demonstrate an end-to-end healthcare analytics workflow:

* Raw data ingestion
* Schema design and indexing
* Staging → production ETL
* Data validation
* Business question analysis
* Exported outputs and visualizations

---

# Project Architecture

The repository follows a structured pipeline:

```
sql/
  schema/      → Production table definitions (typed tables)
  etl/         → Stage table creation + cleaning + loading logic
  analysis/    → Business question queries
outputs/       → CSV exports from final queries
visuals/       → Charts exported from Excel
```

Execution order:

1. Create production schema (`schema/`)
2. Import raw CSV files into staging tables
3. Run ETL logic (`etl/`)
4. Execute analysis queries (`analysis/`)
5. Export result sets and create visuals

---

# Data Model

### Dimension Table: `hospital_info_raw`

* Primary key: `facility_id`
* Hospital attributes:

  * State
  * Ownership
  * Hospital type
  * Emergency services
  * CMS overall star rating

### Fact Table: `hcahps_raw`

Grain:

> One row per facility_id + measure_id + answer_description + start_date

Key metrics:

* Answer percent
* Linear mean value
* Completed surveys
* Response rate
* Reporting period dates

Indexes are included to support analytical filtering by:

* `measure_id`
* `start_date`
* `facility_id`

---

# Data Engineering Workflow

### 1. Staging Layer

Raw CMS CSV files are imported into TEXT-only staging tables to prevent type conversion failures.

Key design decisions:

* All fields initially stored as TEXT
* Column names mirror CSV headers exactly
* No transformation at ingestion

### 2️. Cleaning & Validation

During ETL:

* Keys normalized using `TRIM()`
* States standardized using `UPPER()`
* Numeric values validated using `REGEXP` before casting
* Dates parsed using `STR_TO_DATE`
* Empty strings converted to NULL

### 3️. Deduplication

HCAHPS staging data contained duplicate rows at the defined grain.

Duplicates were removed by grouping at:

```
facility_id + measure_id + answer_description + start_date
```

This ensures primary key integrity in `hcahps_raw`.

---

# Business Questions

## Q1 — Do CMS Star Ratings Align with Patient Experience?

**Reporting Period:** 2024
**Sample Size:** 2,843 hospitals with both star rating and recommend data

### Method

* Filter to measure `H_RECMND_DY`
* Restrict to latest reporting period
* Exclude NULL ratings
* Compute:

  * Average recommend percentage
  * Weighted average using completed surveys

### Results (Weighted)

| Rating | Recommend % |
| ------ | ----------- |
| 1 Star | 58.9%       |
| 2 Star | 63.4%       |
| 3 Star | 68.5%       |
| 4 Star | 73.2%       |
| 5 Star | 77.9%       |

Each incremental star level corresponds to approximately a **5 percentage point increase** in patient willingness to recommend.

### Interpretation

CMS overall star ratings demonstrate a clear and consistent positive relationship with patient-reported experience.

While ratings incorporate broader quality measures beyond satisfaction alone, higher-rated hospitals show meaningfully stronger patient recommendation rates.

See:

* `outputs/q1_rating_alignment.csv`
* `visuals/q1_rating_vs_recommend.png`

---
Here is your Q2 README section written in the exact same structure and tone as Q1.

---

## Q2 — Does Hospital Ownership Relate to Patient Experience?

**Reporting Period:** 2024
**Sample Size:** 3,964 hospitals with recommend data (ownership groups ≥ 25 hospitals; ≥100 completed surveys per hospital)

### Method

* Filter to measure `H_RECMND_DY`
* Restrict to reporting period `2024-01-01`
* Lock to answer category `"YES", patients would definitely recommend the hospital`
* Exclude hospitals with fewer than 100 completed surveys
* Require ownership groups to contain at least 25 hospitals
* Compute:

  * Average recommend percentage
  * Weighted average using completed surveys

### Results (Weighted)

| Ownership Type                           | Recommend % |
| ---------------------------------------- | ----------- |
| Physician                                | 80.4%       |
| Department of Defense                    | 78.6%       |
| Veterans Health Administration           | 74.8%       |
| Government – State                       | 74.0%       |
| Government – Hospital District/Authority | 70.5%       |
| Voluntary non-profit – Private           | 70.1%       |
| Voluntary non-profit – Other             | 69.5%       |
| Voluntary non-profit – Church            | 69.5%       |
| Government – Local                       | 68.2%       |
| Proprietary                              | 64.6%       |

The gap between the highest and lowest ownership types is approximately **15.8 percentage points**.

### Interpretation

Hospital ownership structure is associated with meaningful differences in patient-reported willingness to recommend.

Physician-owned and federal hospitals demonstrate the highest weighted recommendation rates, while proprietary hospitals show the lowest.

Because results are weighted by survey volume, lower-performing high-volume ownership types represent larger population-level impact. These findings are associative rather than causal and likely reflect variation in hospital size, service mix, and patient complexity.

See:

* `outputs/q2_ownership_effect_weighted_thresholded.csv`
* `visuals/q2_ownership_effect_weighted.png`

---

# Reproducibility

To reproduce the project:

1. Run schema scripts
2. Import CMS CSV files into staging tables
3. Execute ETL scripts
4. Run analysis queries
5. Export result sets

All SQL required to rebuild the pipeline is included in this repository.

---

# Technical Stack

* MySQL 8.0
* Structured SQL (DDL, DML, analytical queries)
* CSV exports
* Excel visualizations

---


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

* `outputs/q2_ownership_effect.csv`
* `visuals/q2_ownership_vs_recommend.png`

---

## Q3 — Are There State-Level Disparities in Patient Experience?

**Reporting Period:** 2024
**Sample Size:** States with ≥ 20 hospitals and ≥ 100 completed surveys per hospital (41 states total)

### Method

* Filter to measure `H_RECMND_DY`
* Restrict to reporting period `2024-01-01`
* Lock to answer category `"YES", patients would definitely recommend the hospital`
* Exclude hospitals with fewer than 100 completed surveys
* Require states to contain at least 20 hospitals
* Compute:

  * Average recommend percentage
  * Weighted average using completed surveys

### Results (Weighted)

#### Top Performing States

| State         | Recommend % |
| ------------- | ----------- |
| Utah (UT)     | 75.3%       |
| Kansas (KS)   | 74.2%       |
| Idaho (ID)    | 74.1%       |
| Colorado (CO) | 73.7%       |
| Nebraska (NE) | 73.7%       |

#### Lowest Performing States

| State              | Recommend % |
| ------------------ | ----------- |
| New Mexico (NM)    | 64.6%       |
| New York (NY)      | 64.8%       |
| Michigan (MI)      | 65.3%       |
| Arizona (AZ)       | 65.4%       |
| West Virginia (WV) | 65.9%       |

The gap between highest and lowest performing states is approximately **10.7 percentage points** (75.31% − 64.58%).

### Interpretation

Patient-reported hospital recommendation rates vary meaningfully by state. Mountain West and Plains states demonstrate consistently higher weighted recommendation rates, while several large and urbanized states show lower performance.

Because results are weighted by survey volume and filtered for minimum hospital thresholds, differences are unlikely to reflect sampling noise. Instead, disparities may reflect variation in healthcare system structure, patient complexity, hospital density, and regional operational dynamics.

See:

* `outputs/q3_state_disparities.csv`
* `visuals/q3_state_disparities_ranked.png`

---

## Q4 — Where Do CMS Ratings and Patient Experience Diverge?

**Reporting Period:** 2024
**Sample Size:** 2,843 hospitals with non-null star rating and ≥100 completed surveys

### Method

* Filter to measure `H_RECMND_DY`
* Restrict to reporting period `2024-01-01`
* Lock to answer category `"YES", patients would definitely recommend the hospital`
* Exclude hospitals with fewer than 100 completed surveys
* Exclude NULL star ratings
* Rank hospitals into quintiles by recommend percentage using `NTILE(5)`
* Flag:

  * Rating ≥ 4 AND bottom quintile recommend %
  * Rating ≤ 2 AND top quintile recommend %

### Results

* **43 hospitals** rated 4–5 stars fall into the bottom 20% of patient recommendation rates.
* **36 hospitals** rated 1–2 stars fall into the top 20% of patient recommendation rates.

These mismatches occur despite the overall positive relationship observed between star ratings and recommend rates in Q1.

### Interpretation

CMS star ratings and patient-reported recommendation rates generally align at the aggregate level (Q1). However, a meaningful subset of hospitals demonstrates divergence.

Highly rated hospitals in the bottom quintile of patient recommendation suggest that CMS star ratings incorporate broader quality domains beyond patient satisfaction alone. Conversely, some lower-rated hospitals achieve top-tier patient recommendation performance.

These outliers highlight the importance of examining hospital-level variation rather than relying solely on composite quality indicators.

See:
* `outputs/q4_ranked_dataset.csv`
* `outputs/q4_high_rating_low_recommend.csv`
* `outputs/q4_low_rating_high_recommend.csv`
* `visuals/q4_rating_vs_recommend_scatter.png`

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

# Executive Summary

Across 2024 CMS HCAHPS data, patient willingness to recommend hospitals demonstrates consistent alignment with CMS star ratings, increasing approximately 5 percentage points per star level. Ownership structure shows the largest categorical variation (~15.8 percentage point gap between highest and lowest ownership types), exceeding interstate differences (~10.7 percentage points). Geographic variation is present but clustered, with most states falling within a narrow performance band around the national average. While ratings and patient experience align at an aggregate level, approximately 5% of hospitals demonstrate meaningful divergence between star ratings and patient recommendation performance.

---

# Limitations

* **Cross-sectional design:** Analysis is limited to a single reporting period (2024) and does not assess temporal trends or causality.
* **No case-mix or complexity adjustment:** Differences by ownership and state may reflect variation in hospital size, service lines, patient acuity, or payer mix rather than structural effects alone.
* **Survey-based metric:** The recommend percentage reflects patient-reported experience and may not capture broader clinical quality dimensions incorporated into CMS star ratings.

---

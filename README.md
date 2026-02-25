# Fintech Risk Analytics Dashboard

## Project Overview

This project builds an end-to-end fintech underwriting analytics solution to identify high-risk loan applicants using behavioural repayment data, financial ratios, and customer segmentation.

The workflow integrates **Excel (data preparation)**, **PostgreSQL (ETL & feature engineering)**, and **Power BI (dashboard visualisation)** to transform raw multi-table loan datasets into a unified analytics dataset and interactive business dashboard.

---

## 🎯 Business Objective

Financial institutions need to evaluate customer credit risk before approving loans.
The goal of this project is to:

* Identify high-risk customer segments
* Analyse repayment behaviour patterns
* Study income, dependency, and loan history effects on default probability
* Build an interactive dashboard to support underwriting decisions

---

## 🛠️ Tools & Technologies

* **Excel** → Data cleaning, column formatting, initial structure validation
* **PostgreSQL** → Data ingestion, staging tables, ETL pipeline, feature engineering
* **Power BI** → Interactive dashboard design and visualization

---

## 📂 Dataset Description

The project uses three main datasets:

1. **Application Data** → Current customer loan applications
2. **Previous Application Data** → Historical loan records
3. **Installment Payments Data** → Detailed repayment behaviour

These datasets were combined to create a **customer-level underwriting master dataset**.

---

# Project Workflow (Step-by-Step)

---

## 1️⃣ Data Preparation in Excel

### Tasks performed:

* Verified dataset structure and headers
* Standardized column names to lowercase
* Checked missing values and numeric formatting
* Exported cleaned CSV files for database loading

---

## 2️⃣ Data Loading into PostgreSQL

### Steps:

* Created staging tables for each dataset
* Imported CSV files using COPY command
* Used flexible numeric data types for staging tables

### Example staging structure:

```
temp_application
temp_previous_application
temp_installments_payments
```

---

## 3️⃣ Feature Engineering in SQL

### Built multi-layer ETL workflow:

```
RAW → FEATURE TABLE → SEGMENT TABLE → MASTER DATASET
```

### Key engineered features:

* Loan-to-Income Ratio
* Income Segmentation
* Dependency Segmentation
* Payment Delay Calculation
* Previous Loan Count
* Average Previous Credit
* Payment Ratio

These features were aggregated to the **customer level** to prevent row duplication.

---

## 4️⃣ Creating Customer-Level Master Dataset

All engineered features were combined into:

```
fintech_underwriting_master
```

Using LEFT JOINs to ensure all applicants remained included.

---

## 5️⃣ Exploratory Risk Analysis (SQL)

Performed SQL aggregation analysis to evaluate:

* Default rate by income segment
* Default rate by dependency level
* Default rate by repayment delay
* Default rate by loan history

These insights guided dashboard design.

---

## 6️⃣ Power BI Dashboard Development

Built a **3-Page Interactive Dashboard**:

---

### 📈 Page 1 — Risk Overview

Includes:

* KPI Cards
* Default Rate by Income
* Default Rate by Dependency
* Payment Behaviour Distribution

<img width="1398" height="796" alt="Image" src="https://github.com/user-attachments/assets/cda18dae-7604-445a-b615-da3d7b4fa059" />

---

### 📊 Page 2 — Behavioural Risk Analysis

Includes:

* Default Rate by Delay Group
* Default Rate by Loan History
* Scatter Plot showing behavioural risk distribution

<img width="1403" height="792" alt="Image" src="https://github.com/user-attachments/assets/3e08ff8a-5d38-4024-8f5c-d889c8ffb8ad" />

---

### 👥 Page 3 — Customer Segmentation

Includes:

* Heatmap matrix showing income vs dependency risk
* Supporting summary chart

<img width="1403" height="782" alt="Image" src="https://github.com/user-attachments/assets/41c858d1-2214-40a3-ac59-dba5955cceea" />

---

## 🎛️ Interactive Features

* Global slicers for Income Segment and Delay Group
* Conditional formatting heatmaps
* Scatter visualisation for behavioural modelling

---

# 📊 Key Insights from Analysis

* Customers with moderate payment delays showed higher default rates
* Higher dependency levels increased default probability
* Customers with multiple prior loans exhibited greater credit risk
* Income level alone did not fully explain default behaviour

---


# 👤 Author

Yogesh Kumar Pal

Fintech Risk Analytics Project

Tools: Excel | PostgreSQL | Power BI

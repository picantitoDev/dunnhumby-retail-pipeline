# 🛒 Retail Data Platform: The Dunnhumby Journey

**2,500 households. 2 years of daily transactions. Over 92,000 products.**
*An End-to-End ELT Pipeline transforming raw retail data into actionable insights on customer loyalty, marketing ROI, and demographic trends.*

---

## 📋 Table of Contents

1. [Problem Description](#-problem-description)
2. [The Dataset](#-the-dataset)
3. [Architecture Overview](#-architecture-overview)
4. [Technology Stack](#-technology-stack)
5. [Data Ingestion](#-data-ingestion)
6. [Data Lake (Storage)](#-data-lake)
7. [Data Warehouse (Modeling)](#-data-warehouse)
8. [Transformations (dbt)](#-transformations)
9. [Dashboard & Insights](#-dashboard--insights)
10. [Reproducibility](#-reproducibility)

---

## 🎯 Problem Description

### The Context: "The Complete Journey"
In the grocery retail sector, understanding customer behavior is the key to survival. To explore this, dunnhumby released **"The Complete Journey"** dataset—a comprehensive record of household-level transactions over two years from a group of frequent shoppers. Unlike typical datasets that sample only specific categories, this tracks *every single purchase* a household makes, alongside their demographic profiles and direct marketing contact history. 

### The Engineering Challenge
Extracting value from this dataset presents a significant data engineering bottleneck. In its raw form, the data is fragmented across complex, highly relational, and siloed CSV files. Querying this raw web of transactions, coupons, and campaigns directly is slow, expensive, and lacks enforced data quality rules.

### The Solution
This project builds a fully automated **ELT (Extract, Load, Transform)** pipeline to solve this issue. By orchestrating the ingestion of the Dunnhumby dataset into a Data Lake, cleansing it with distributed processing (Spark), and modeling it in a cloud Data Warehouse (BigQuery) using dbt, we create a robust analytical platform. 

This platform is specifically designed to answer the core business questions posed by the dataset:
1. **Spending Trends:** How many customers are spending more over time versus less, and which product categories are driving these shifts?
2. **Demographic Impact:** Which demographic factors (e.g., household size, presence of children, income) most strongly affect customer spend and category engagement?
3. **Marketing Effectiveness:** Is there concrete evidence to suggest that direct marketing and targeted coupons improve overall customer engagement?

---

## 📊 The Dataset

The pipeline processes the **"Dunnhumby - The Complete Journey"** dataset, automatically ingested via the [Kaggle API](https://www.kaggle.com/datasets/frtgnn/dunnhumby-the-complete-journey).

| Attribute | Details |
| :--- | :--- |
| **Domain** | Grocery Retail / Fast-Moving Consumer Goods (FMCG) |
| **Scale** | 2,500 households, 92,339 products, ~2.5 million transactions |
| **Time Window** | 2 years of daily transactional data |
| **Ingestion Method** | Automated batch download via Kaggle API |

### Core Data Entities
The raw data is contained in several key files that our pipeline unifies to build the analytical platform:

* **🛒 Transactions (`transaction_data`):** Records every item scanned at the register, prices, and discounts[cite: 39, 45, 46].
* **👥 Customer Profiles (`hh_demographic`):** Demographic data for households, including income, marital status, and household size.
* **🎯 Marketing & Coupons (`campaign_table`, `campaign_desc`, `coupon`, `coupon_redempt`):** Details of 30 marketing campaigns and the specific coupons households received and redeemed.
* **📦 Product Metadata (`product`, `causal_data`):** The store catalog and in-store features like weekly mailers or special displays.

## 🏗️ Architecture Overview

The pipeline follows a modern **ELT (Extract, Load, Transform)** pattern, fully orchestrated by Kestra and provisioned via Terraform. It moves data from raw CSVs on the web to an optimized Star Schema in BigQuery.

```text
┌─────────────────────────────────────────────────────────────┐
│  0. INFRASTRUCTURE AS CODE (Terraform)                      │
│  Provisions GCS Data Lake, BigQuery Datasets, and IAM       │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  1. INGESTION (Kestra Subflow)                              │
│  Kaggle API → Download & Unzip → GCS (Bronze Layer)         │
│  gs://<gcs_bucket>/bronze/*.csv                             │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  2. DATA LAKE PROCESSING (PySpark via Kestra)               │
│  Reads CSVs → Drops Nulls/Duplicates → Writes Parquet       │
│  gs://<gcs_bucket>/silver/*.parquet                         │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  3. WAREHOUSE MAPPING (BigQuery External Tables)            │
│  Maps GCS Silver Parquet files directly to BQ Staging       │
│  Dataset: <project>.staging.ext_<table>                     │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  4. ANALYTICAL MODELING (dbt Core via Kestra)               │
│  Staging → Intermediate → Marts                             │
│  Runs `dbt build` against BigQuery                          │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  5. INSIGHTS (Looker Studio / BI)                           │
│  Consumer Behavior Dashboard                                │
└─────────────────────────────────────────────────────────────┘
```
## 🛠️ Technology Stack

| Layer | Technology |
| :--- | :--- |
| **Cloud** | Google Cloud Platform (GCP) |
| **Infrastructure as Code** | Terraform |
| **Orchestration** | Kestra v1.1 (Docker) |
| **Ingestion** | Kaggle API + Bash (`wget`, `unzip`) |
| **Compute / Processing** | PySpark (Containerized) |
| **Data Lake** | Google Cloud Storage (GCS) |
| **Data Warehouse** | Google BigQuery |
| **Transformation** | dbt (`dbt-bigquery:1.9.0`) |
| **Dashboard** | Looker Studio |
| **Language** | Python 3.11, SQL |
| **Package Manager** | uv |

## 🚀 Reproducibility (Setup & Run)

This project has been heavily optimized for easy deployment. Everything is managed via Infrastructure as Code (Terraform) and orchestrated completely inside Docker (Kestra). There is **no need** to manually install Spark, dbt, or configure complex cloud jobs.

---

## Prerequisites

Ensure your local environment or VM meets the following requirements:

- [Google Cloud SDK (gcloud CLI)](https://cloud.google.com/sdk/docs/install) — installed and authenticated
- [Terraform](https://developer.hashicorp.com/terraform/downloads) — version >= 1.3.0
- [Docker Engine](https://docs.docker.com/engine/install/) & [Docker Compose](https://docs.docker.com/compose/install/) — installed and running
- A GCP project with billing enabled

---

## Step 1 — Clone the Repository

Clone the project to your local machine and navigate into the directory:

```bash
git clone https://github.com/picantitoDev/dunnhumby-retail-pipeline.git
cd dunnhumby-retail-pipeline
```

---

## Step 2 — GCP Authentication

Before provisioning infrastructure, authenticate your local environment with Google Cloud so Terraform has the necessary permissions:

```bash
# Login with your Google account
gcloud auth login

# Set application default credentials
gcloud auth application-default login

# Set your GCP project
gcloud config set project <your-project-id>
gcloud auth application-default set-quota-project <your-project-id>
```

---

## Step 3 — Provision Infrastructure (Terraform)

Terraform will automatically create:

- A **GCS Data Lake** bucket
- **BigQuery datasets** (`staging`, `intermediate`, `marts`)
- A dedicated **Service Account** with the correct IAM roles

Navigate to the `terraform` folder and copy the variables template:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific GCP details:

```hcl
# terraform.tfvars
project_id = "my-gcp-project-12345"
region     = "us-central1"
gcs_bucket = "my-dunnhumby-datalake-prod"
```

Initialize and deploy the infrastructure:

```bash
terraform init
terraform plan
terraform apply --auto-approve
```

> **Note:** This process automatically generates a secure Service Account key and saves it to `../keys/google-creds.json`.

---

## Step 4 — Configure Orchestration (Docker & Kestra)

Navigate to the `orchestration` folder and copy the environment template:

```bash
cd ../orchestration
cp .env.example .env
```

Edit the `.env` file to match the resources Terraform just created:

```env
# Kestra Admin Credentials
KESTRA_ADMIN_USER=your-admin-email@example.com
KESTRA_ADMIN_PASSWORD=your-admin-password

# Google Cloud Configuration
KESTRA_GCP_PROJECT_ID=your-gcp-project-id
KESTRA_GCP_LOCATION=your-gcp-region
KESTRA_GCP_BUCKET_NAME=your-gcs-bucket-name

# BigQuery Datasets
KESTRA_GCP_DATASET_STAGING=staging
KESTRA_GCP_DATASET_INTERMEDIATE=intermediate
KESTRA_GCP_DATASET_MARTS=marts
```

**Inject GCP Credentials into Kestra:** Run the following command inside `/orchestration` to encode the Google JSON credentials (generated by Terraform) into base64 and append them to your `.env` file as a Kestra secret:

```bash
echo -e "\nSECRET_GCP_SERVICE_ACCOUNT=$(cat ../keys/google-creds.json | base64 -w 0)" >> .env
```

---

## Step 5 — Run the Pipeline

Everything is configured. Boot up the Kestra orchestrator:

```bash
docker compose up -d
```

Once the containers are running:

1. Open your browser and go to the **Kestra UI**: [http://localhost:8080](http://localhost:8080)
2. Navigate to **Flows** in the left sidebar.
3. Select the `end_to_end_pipeline` flow.
4. Click **Execute** and watch the pipeline begin.
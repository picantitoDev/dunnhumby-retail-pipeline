# -------------------
# APIs NECESARIAS
# -------------------
resource "google_project_service" "services" {
  for_each = toset([
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "iam.googleapis.com"
  ])

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

# -------------------
# SERVICE ACCOUNT
# -------------------
resource "google_service_account" "pipeline_sa" {
  account_id   = "dunnhumby-pipeline-sa"
  display_name = "Dunnhumby Retail Pipeline Service Account"
}

# Roles para BigQuery y Storage
resource "google_project_iam_member" "pipeline_roles" {
  for_each = toset([
    "roles/bigquery.admin",        # Para que dbt cree tablas y vistas
    "roles/storage.objectAdmin"    # Para lectura/escritura en el Data Lake
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.pipeline_sa.email}"
}

resource "google_service_account_key" "pipeline_key" {
  service_account_id = google_service_account.pipeline_sa.name
}

resource "local_file" "sa_key_file" {
  content  = base64decode(google_service_account_key.pipeline_key.private_key)
  filename = "${path.module}/../keys/google-creds.json"
}

# -------------------
# GCS (DATA LAKE)
# -------------------
resource "google_storage_bucket" "lake" {
  name          = var.gcs_bucket
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true

  labels = {
    project = "dunnhumby-retail"
  }
}

# -------------------
# BIGQUERY DATASETS (Capas de dbt)
# -------------------

resource "google_bigquery_dataset" "staging" {
  dataset_id = "staging"
  location   = var.region
  labels     = { layer = "staging" }
}

resource "google_bigquery_dataset" "intermediate" {
  dataset_id = "intermediate"
  location   = var.region
  labels     = { layer = "intermediate" }
}

resource "google_bigquery_dataset" "marts" {
  dataset_id = "marts"
  location   = var.region
  labels     = { layer = "marts" }
}
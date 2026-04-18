output "bucket_name" {
  value = google_storage_bucket.lake.name
}

output "staging_dataset" {
  value = google_bigquery_dataset.staging.dataset_id
}

output "marts_dataset" {
  value = google_bigquery_dataset.marts.dataset_id
}

output "service_account_email" {
  value = google_service_account.pipeline_sa.email
}
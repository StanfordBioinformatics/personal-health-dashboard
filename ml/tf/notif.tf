resource "google_storage_notification" "notification" {
  bucket            = google_storage_bucket.bucket.name
  payload_format    = "JSON_API_V1"
  topic             = module.encrypted_payload.id
  event_types       = ["OBJECT_FINALIZE"]
  custom_attributes = { app = "decrypt" }
  depends_on        = [google_pubsub_topic_iam_binding.binding]
}

data "google_storage_project_service_account" "gcs_account" {
}

resource "google_pubsub_topic_iam_binding" "binding" {
  topic   = module.encrypted_payload.id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}
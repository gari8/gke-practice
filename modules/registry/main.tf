resource "google_artifact_registry_repository" "repo" {
  format        = "DOCKER"
  repository_id = var.repository_id
  project       = var.project
  location      = var.region
}

resource "google_artifact_registry_repository_iam_member" "repo_iam" {
  project    = var.project
  location   = var.region
  member     = "serviceAccount:${var.service_account_email}"
  repository = google_artifact_registry_repository.repo.repository_id
  role       = "roles/artifactregistry.writer"
}
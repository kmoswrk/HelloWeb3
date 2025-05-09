resource "google_project_service" "iamcredentials" {
  project = var.gcp_project_id
  service = "iamcredentials.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false # Set to true if you want to disable it on destroy
}

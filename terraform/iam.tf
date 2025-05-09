# iam.tf

# --- Service Account for the Polygon Monitor Application (Workload Identity) ---
resource "google_service_account" "app_gsa" {
  project      = var.gcp_project_id
  account_id   = "polygon-monitor-app-sa"
  display_name = "Service Account for Polygon Monitor Application"
}

resource "google_service_account_iam_member" "app_gsa_workload_identity_user" {
  service_account_id = google_service_account.app_gsa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[${var.polygon_monitor_app_k8s_namespace}/${var.polygon_monitor_app_k8s_sa_name}]"

  # Add this explicit dependency
  depends_on = [
    google_container_cluster.primary,
    google_project_service.iamcredentials
  ]
}

# --- Service Account for "Polygon Monitor Read-Only Kubernetes User" (GCP IAM level) ---
resource "google_service_account" "gke_readonly_viewer_gsa" {
  project      = var.gcp_project_id
  account_id   = "polygon-monitor-viewer-sa"
  display_name = "Polygon Monitor GKE Viewer SA"
}

resource "google_project_iam_member" "gke_readonly_viewer_binding" {
  project = var.gcp_project_id
  role    = "roles/container.viewer"
  member  = "serviceAccount:${google_service_account.gke_readonly_viewer_gsa.email}"
}

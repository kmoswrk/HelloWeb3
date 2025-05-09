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

  depends_on = [
    google_container_cluster.primary,
    google_project_service.iamcredentials # Ensure this service is enabled
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

# --- IAM Permissions for the GitHub Actions Service Account ---
# This is the Service Account used by your GitHub Actions workflow
# (via Workload Identity Provider) to interact with GCP.
resource "google_project_iam_member" "github_actions_gsa_compute_network_viewer" {
  project = var.gcp_project_id
  role    = "roles/compute.networkViewer" # Grants permission to get global address details

  # IMPORTANT: Replace this with the actual email of the Service Account
  # that your GitHub Actions workflow uses. This email is typically stored
  # in your GitHub repository secret (e.g., secrets.GCP_SERVICE_ACCOUNT).
  # Example: "serviceAccount:your-github-runner-sa@your-gcp-project-id.iam.gserviceaccount.com"
  member = "serviceAccount:cicd-github-actions@grounded-pivot-459013-d1.iam.gserviceaccount.com"
}

# You might also need to grant the GitHub Actions GSA other roles
# depending on what your CI/CD pipeline does. For example, to deploy to GKE:
# resource "google_project_iam_member" "github_actions_gsa_gke_developer" {
#   project = var.gcp_project_id
#   role    = "roles/container.developer" # Allows deploying to GKE, getting credentials
#   member  = "serviceAccount:YOUR_GITHUB_ACTIONS_GSA_EMAIL_HERE" # Use the same GSA email
# }

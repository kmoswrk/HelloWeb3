resource "google_compute_global_address" "app_static_ip" {
  project = var.gcp_project_id
  name    = "${var.polygon_monitor_gke_cluster_name}-ingress-ip" # Or any descriptive name
}

output "app_ingress_static_ip_address" {
  description = "Static Global IP address for the application Ingress."
  value       = google_compute_global_address.app_static_ip.address
}

output "app_ingress_static_ip_name" {
  description = "Name of the Static Global IP address resource for Ingress."
  value       = google_compute_global_address.app_static_ip.name
}

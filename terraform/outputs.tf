# outputs.tf

output "gcp_project_id" {
  description = "GCP Project ID where resources are deployed."
  value       = var.gcp_project_id
}

output "gcp_region" {
  description = "GCP Region where resources are deployed."
  value       = var.gcp_region
}

output "polygon_monitor_vpc_name" {
  description = "Name of the VPC network created."
  value       = google_compute_network.vpc.name
}

output "polygon_monitor_subnet_name" {
  description = "Name of the GKE subnet created."
  value       = google_compute_subnetwork.gke_subnet.name
}

output "polygon_monitor_gke_cluster_name" {
  description = "Name of the GKE cluster."
  value       = google_container_cluster.primary.name
}

output "gke_cluster_endpoint" {
  description = "Endpoint for the GKE cluster."
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "CA certificate for the GKE cluster (base64 encoded)."
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "polygon_monitor_gke_node_pool_name" {
  description = "Name of the GKE cluster's primary node pool."
  value       = google_container_node_pool.primary_nodes.name
}

output "polygon_monitor_app_gsa_email" {
  description = "Email of the GCP Service Account for the Polygon Monitor application (for Workload Identity annotation)."
  value       = google_service_account.app_gsa.email
}

output "polygon_monitor_app_k8s_sa_name" {
  description = "Name of the Kubernetes Service Account for the Polygon Monitor application."
  value       = var.polygon_monitor_app_k8s_sa_name
}

output "polygon_monitor_app_k8s_namespace" {
  description = "Kubernetes namespace for the Polygon Monitor application."
  value       = var.polygon_monitor_app_k8s_namespace
}

output "polygon_monitor_gke_readonly_viewer_gsa_email" {
  description = "Email of the GCP Service Account for Polygon Monitor GKE read-only viewing."
  value       = google_service_account.gke_readonly_viewer_gsa.email
}

output "kubeconfig_command" {
  description = "Command to configure kubectl for the created GKE cluster."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${google_container_cluster.primary.location} --project ${var.gcp_project_id}"
}

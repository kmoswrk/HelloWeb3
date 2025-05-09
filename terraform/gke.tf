# gke.tf

resource "google_container_cluster" "primary" {
  project  = var.gcp_project_id
  name     = var.polygon_monitor_gke_cluster_name # Uses new variable
  location = var.gcp_region

  network                  = google_compute_network.vpc.id
  subnetwork               = google_compute_subnetwork.gke_subnet.id
  logging_service          = "logging.googleapis.com/kubernetes"
  monitoring_service       = "monitoring.googleapis.com/kubernetes"
  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {
    cluster_secondary_range_name  = var.polygon_monitor_subnet_pods_range_name     # Uses new variable
    services_secondary_range_name = var.polygon_monitor_subnet_services_range_name # Uses new variable
  }

  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  release_channel {
    channel = var.gke_release_channel
  }

  enable_shielded_nodes = true
}

resource "google_container_node_pool" "primary_nodes" {
  project  = var.gcp_project_id
  name     = var.polygon_monitor_gke_node_pool_name # Uses new variable
  cluster  = google_container_cluster.primary.name
  location = google_container_cluster.primary.location

  initial_node_count = var.gke_node_count

  autoscaling {
    min_node_count = var.gke_node_count
    max_node_count = var.gke_node_count + 2
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.gke_node_machine_type
    disk_size_gb = var.gke_node_disk_size_gb
    image_type   = var.gke_node_image_type
    preemptible  = false

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  depends_on = [google_container_cluster.primary]
}

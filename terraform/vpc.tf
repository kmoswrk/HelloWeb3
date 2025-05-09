# vpc.tf

resource "google_compute_network" "vpc" {
  project                 = var.gcp_project_id
  name                    = var.polygon_monitor_vpc_name # Uses new variable
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "gke_subnet" {
  project                  = var.gcp_project_id
  name                     = var.polygon_monitor_subnet_name # Uses new variable
  ip_cidr_range            = var.polygon_monitor_subnet_ip_cidr_range
  region                   = var.gcp_region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = var.polygon_monitor_subnet_pods_range_name # Uses new variable
    ip_cidr_range = var.polygon_monitor_subnet_pods_ip_cidr_range
  }

  secondary_ip_range {
    range_name    = var.polygon_monitor_subnet_services_range_name # Uses new variable
    ip_cidr_range = var.polygon_monitor_subnet_services_ip_cidr_range
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  depends_on = [google_compute_network.vpc]
}

resource "google_compute_firewall" "allow_internal" {
  project = var.gcp_project_id
  name    = "${var.polygon_monitor_vpc_name}-allow-internal" # Updated name
  network = google_compute_network.vpc.self_link

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  source_ranges = [
    var.polygon_monitor_subnet_ip_cidr_range,
    var.polygon_monitor_subnet_pods_ip_cidr_range,
    var.polygon_monitor_subnet_services_ip_cidr_range
  ]
}

resource "google_compute_firewall" "allow_ssh_iap" {
  project = var.gcp_project_id
  name    = "${var.polygon_monitor_vpc_name}-allow-ssh-iap" # Updated name
  network = google_compute_network.vpc.self_link
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["gke-node"]
}

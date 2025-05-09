variable "gcp_project_id" {
  description = "The GCP project ID to deploy resources into."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region for the resources."
  type        = string
}

variable "gcp_zone" {
  description = "The GCP zone for regional resources if needed (e.g., for some GKE node pools if not using regional)."
  type        = string
  default     = null # Make it optional, GKE can be regional
}

variable "polygon_monitor_vpc_name" {
  description = "Name for the VPC network."
  type        = string
  default     = "polygon-monitor-vpc"
}

variable "polygon_monitor_subnet_name" {
  description = "Name for the GKE subnet."
  type        = string
  default     = "polygon-monitor-gke-subnet"
}

variable "polygon_monitor_subnet_ip_cidr_range" {
  description = "The primary IP range for the GKE subnet."
  type        = string
  default     = "10.10.0.0/20" # Adjust as needed
}

variable "polygon_monitor_subnet_pods_range_name" {
  description = "The name of the secondary IP range for GKE pods."
  type        = string
  default     = "polygon-monitor-pods-range"
}

variable "polygon_monitor_subnet_pods_ip_cidr_range" {
  description = "The secondary IP range for GKE pods."
  type        = string
  default     = "10.20.0.0/16" # Adjust as needed
}

variable "polygon_monitor_subnet_services_range_name" {
  description = "The name of the secondary IP range for GKE services."
  type        = string
  default     = "polygon-monitor-services-range"
}

variable "polygon_monitor_subnet_services_ip_cidr_range" {
  description = "The secondary IP range for GKE services."
  type        = string
  default     = "10.30.0.0/20" # Adjust as needed
}

variable "polygon_monitor_gke_cluster_name" {
  description = "Name for the GKE cluster."
  type        = string
  default     = "polygon-monitor-cluster"
}

variable "gke_release_channel" {
  description = "The release channel for the GKE cluster (REGULAR, STABLE, RAPID)."
  type        = string
  default     = "REGULAR"
  validation {
    condition     = contains(["STABLE", "REGULAR", "RAPID", "UNSPECIFIED"], var.gke_release_channel)
    error_message = "Invalid GKE release channel. Must be one of: STABLE, REGULAR, RAPID, UNSPECIFIED."
  }
}

variable "polygon_monitor_gke_node_pool_name" {
  description = "Name for the GKE cluster's primary node pool."
  type        = string
  default     = "polygon-monitor-default-pool"
}

variable "gke_node_machine_type" {
  description = "Machine type for GKE nodes."
  type        = string
  default     = "e2-medium" # Cost-effective for general workloads
}

variable "gke_node_count" {
  description = "Initial number of nodes in the GKE node pool. Can be per-zone or total for regional."
  type        = number
  default     = 1 # Start small
}

variable "gke_node_disk_size_gb" {
  description = "Disk size for GKE nodes in GB."
  type        = number
  default     = 30
}

variable "gke_node_image_type" {
  description = "The image type to use for GKE nodes."
  type        = string
  default     = "COS_CONTAINERD"
}

variable "polygon_monitor_app_k8s_namespace" {
  description = "Kubernetes namespace where the application's KSA will reside."
  type        = string
  default     = "polygon-monitor" # Changed from 'default'
}

variable "polygon_monitor_app_k8s_sa_name" {
  description = "Name of the Kubernetes Service Account for the application (used for Workload Identity)."
  type        = string
  default     = "polygon-monitor-app-ksa" # Changed from 'hello-web3-sa'
}

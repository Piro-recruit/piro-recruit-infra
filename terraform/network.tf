# terraform/network.tf
# VPC 네트워크 생성
resource "google_compute_network" "main" {
  name                    = "${var.app_name}-vpc"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"
}

# 서브넷 생성
resource "google_compute_subnetwork" "main" {
  name          = "${var.app_name}-subnet"
  ip_cidr_range = var.vpc_cidr
  region        = var.region
  network       = google_compute_network.main.id

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = var.services_cidr
  }
}

# 방화벽 규칙 - HTTP/HTTPS
resource "google_compute_firewall" "allow_http_https" {
  name    = "${var.app_name}-allow-http-https"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# 방화벽 규칙 - SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.app_name}-allow-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_ips
  target_tags   = ["ssh-access"]
}

# 방화벽 규칙 - Jenkins
resource "google_compute_firewall" "allow_jenkins" {
  name    = "${var.app_name}-allow-jenkins"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = var.allowed_jenkins_ips
  target_tags   = ["jenkins-server"]
}

# 방화벽 규칙 - PostgreSQL (내부 통신)
resource "google_compute_firewall" "allow_postgres" {
  name    = "${var.app_name}-allow-postgres"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = [var.vpc_cidr]
  target_tags   = ["database"]
}


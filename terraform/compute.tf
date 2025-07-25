# terraform/compute.tf
# App Server 인스턴스
resource "google_compute_instance" "app_server" {
  name         = "${var.app_name}-app-server"
  machine_type = var.app_server_machine_type
  zone         = var.zone

  tags = ["web-server", "ssh-access"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.app_server_disk_size
      type  = var.disk_type
    }
  }

  network_interface {
    network    = google_compute_network.main.name
    subnetwork = google_compute_subnetwork.main.name

    access_config {
      # 외부 IP 할당
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${file(var.ssh_public_key_path)}"
  }

  metadata_startup_script = file("${path.module}/scripts/app_server_setup.sh")

  service_account {
    scopes = ["cloud-platform"]
  }

  labels = var.common_tags
}

# Jenkins Server 인스턴스
resource "google_compute_instance" "jenkins_server" {
  name         = "${var.app_name}-jenkins-server"
  machine_type = var.jenkins_server_machine_type
  zone         = var.zone
  allow_stopping_for_update = true
  tags = ["jenkins-server", "ssh-access"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.jenkins_server_disk_size
      type  = var.disk_type
    }
  }

  network_interface {
    network    = google_compute_network.main.name
    subnetwork = google_compute_subnetwork.main.name

    access_config {
      # 외부 IP 할당
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${file(var.ssh_public_key_path)}"
  }

  metadata_startup_script = file("${path.module}/scripts/jenkins_setup.sh")

  service_account {
    scopes = ["cloud-platform"]
  }

  labels = var.common_tags
}


 
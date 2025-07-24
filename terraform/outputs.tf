# terraform/outputs.tf
output "app_server_external_ip" {
  description = "App Server 외부 IP"
  value       = google_compute_instance.app_server.network_interface[0].access_config[0].nat_ip
}

output "jenkins_server_external_ip" {
  description = "Jenkins Server 외부 IP"
  value       = google_compute_instance.jenkins_server.network_interface[0].access_config[0].nat_ip
}

output "database_connection_string" {
  description = "Database 연결 문자열"
  value       = "postgresql://${var.db_username}:${var.db_password}@${google_sql_database_instance.main.ip_address[0].ip_address}:5432/${var.db_name}"
  sensitive   = true
}

output "database_ip" {
  description = "Database IP"
  value       = google_sql_database_instance.main.ip_address[0].ip_address
}

output "ssh_commands" {
  description = "SSH 접속 명령어"
  value = {
    app_server     = "ssh ${var.ssh_username}@${google_compute_instance.app_server.network_interface[0].access_config[0].nat_ip}"
    jenkins_server = "ssh ${var.ssh_username}@${google_compute_instance.jenkins_server.network_interface[0].access_config[0].nat_ip}"
  }
}

output "jenkins_url" { 
  description = "Jenkins 접속 URL"
  value       = "http://${google_compute_instance.jenkins_server.network_interface[0].access_config[0].nat_ip}:8080"
}

output "app_url" {
  description = "애플리케이션 접속 URL"
  value       = "http://${google_compute_instance.app_server.network_interface[0].access_config[0].nat_ip}"
}


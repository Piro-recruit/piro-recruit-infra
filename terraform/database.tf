# terraform/database.tf
# Cloud SQL PostgreSQL 인스턴스
resource "google_sql_database_instance" "main" {
  name             = "${var.app_name}-postgres-instance"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = var.db_tier
    
    disk_size       = var.db_disk_size
    disk_type       = var.db_disk_type
    disk_autoresize = true

    backup_configuration {
      enabled                        = true
      start_time                    = var.db_backup_start_time
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 3
      backup_retention_settings {
        retained_backups = var.db_retained_backups
      }
    }

    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.main.id
      
      authorized_networks {
        name  = "app-server"
        value = google_compute_instance.app_server.network_interface[0].access_config[0].nat_ip
      }
    }

    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }
    
    database_flags {
      name  = "log_connections"
      value = "on"
    }
  }

  deletion_protection = false  # 개발 환경에서는 false
}

# PostgreSQL 데이터베이스 생성
resource "google_sql_database" "app_database" {
  name     = var.db_name
  instance = google_sql_database_instance.main.name
}

# PostgreSQL 사용자 생성
resource "google_sql_user" "app_user" {
  name     = var.db_username
  instance = google_sql_database_instance.main.name
  password = var.db_password
}

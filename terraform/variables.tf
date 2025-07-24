# terraform/variables.tf
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-northeast3"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "asia-northeast3-a"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "piro-recruiting"
}

# 서버 스펙 관련 변수
variable "app_server_machine_type" {
  description = "App Server machine type"
  type        = string
  default     = "e2-medium"
}

variable "jenkins_server_machine_type" {
  description = "Jenkins Server machine type"
  type        = string
  default     = "e2-micro"
}

variable "app_server_disk_size" {
  description = "App Server disk size (GB)"
  type        = number
  default     = 30
}

variable "jenkins_server_disk_size" {
  description = "Jenkins Server disk size (GB)"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "Disk type"
  type        = string
  default     = "pd-standard"
}

# 네트워크 관련 변수
variable "vpc_cidr" {
  description = "VPC CIDR range"
  type        = string
  default     = "10.0.0.0/24"
}

variable "services_cidr" {
  description = "Services CIDR range"
  type        = string
  default     = "10.1.0.0/24"
}

variable "allowed_ssh_ips" {
  description = "Allowed SSH IP ranges"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # 실제로는 개발자 IP로 제한
}

variable "allowed_jenkins_ips" {
  description = "Allowed Jenkins access IP ranges"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # 실제로는 개발자 IP로 제한
}

# 데이터베이스 관련 변수
variable "db_tier" {
  description = "Database tier"
  type        = string
  default     = "db-f1-micro"
}

variable "db_disk_size" {
  description = "Database disk size (GB)"
  type        = number
  default     = 10
}

variable "db_disk_type" {
  description = "Database disk type"
  type        = string
  default     = "PD_SSD"
}

variable "db_backup_start_time" {
  description = "Database backup start time"
  type        = string
  default     = "03:00"
}

variable "db_retained_backups" {
  description = "Number of retained backups"
  type        = number
  default     = 7
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "piro_recruiting_db"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "app_user"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# SSH 키 관련 변수
variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_username" {
  description = "SSH username"
  type        = string
  default     = "ubuntu"
}

# 태그 관련 변수
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "prod"
    Project     = "piro-recruiting"
    ManagedBy   = "terraform"
  }
}

